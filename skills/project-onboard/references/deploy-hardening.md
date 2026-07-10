# deploy.sh Hardening Best Practices

Best practices for consuming projects that ship a `deploy.sh` alongside their
`onboard.yml` manifest. These are the responsibility of each consuming project,
not the project-onboard skill itself.

---

## Reading the Config File

The `onboard` skill writes a flat YAML config file (e.g., `agnosticd/config.yml`).
Add this block near the top of `deploy.sh` to read it, with environment variables
taking precedence:

```bash
CONFIG_FILE="$(dirname "$0")/config.yml"
if [[ -f "$CONFIG_FILE" ]]; then
  while IFS=': ' read -r key value; do
    key=$(echo "$key" | tr -d ' ')
    value=$(echo "$value" | tr -d '"' | tr -d "'")
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    upper_key=$(echo "$key" | tr '[:lower:]' '[:upper:]')
    if [[ -z "${!upper_key:-}" ]]; then
      export "$upper_key=$value"
    fi
  done < "$CONFIG_FILE"
fi
```

This means:
- `make deploy` reads saved config
- `NUM_STUDENTS=5 make deploy` overrides just that value
- No config file → script falls back to its own defaults (backward compatible)

---

## Cross-Platform sed

`sed -i` behaves differently on GNU (Linux) and BSD (macOS). Use a helper function:

```bash
sed_inplace() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}
```

Replace all bare `sed -i` calls with `sed_inplace` throughout the script.

---

## SSH Retry with Exponential Backoff

Bastion hosts may not be reachable immediately after provisioning. Use a retry helper
instead of a single SSH attempt:

```bash
ssh_with_retry() {
  local host="$1" pass="$2" max_attempts="${3:-5}"
  shift 3
  local attempt=1 delay=10
  while (( attempt <= max_attempts )); do
    if sshpass -p "$pass" ssh -o StrictHostKeyChecking=no \
         -o ConnectTimeout=10 "student@${host}" "$@" 2>/dev/null; then
      return 0
    fi
    echo "   SSH attempt $attempt/$max_attempts failed, retrying in ${delay}s..."
    sleep "$delay"
    delay=$((delay * 2))
    attempt=$((attempt + 1))
  done
  echo "   ERROR: SSH to $host failed after $max_attempts attempts."
  return 1
}
```

---

## Prerequisite Fail-Fast Checks

Add fail-fast checks at the top of `deploy.sh` for every tool the script uses.
Do not let the script proceed 200 lines before discovering `sshpass` is missing:

```bash
for cmd in podman aws sshpass jq python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is required but not found. Run: make setup"
    exit 1
  fi
done
```

---

## Parallel Process Error Handling

When running background processes (e.g., provisioning multiple student clusters),
collect exit codes and fail if any are non-zero:

```bash
pids=()
for i in $(seq 1 "$NUM_STUDENTS"); do
  provision_student "$i" &
  pids+=($!)
done

failed=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    echo "ERROR: Process $pid failed"
    failed=$((failed + 1))
  fi
done

if (( failed > 0 )); then
  echo "ERROR: $failed/$NUM_STUDENTS student provisioning(s) failed."
  exit 1
fi
```

---

## Post-Provision Health Check

Do not assume the cluster is healthy after provisioning. Verify API reachability
and critical operators before proceeding to workload deployment:

```bash
echo "Waiting for cluster API..."
for i in $(seq 1 30); do
  if oc --kubeconfig "$KUBECONFIG" get nodes &>/dev/null; then
    echo "Cluster API is reachable."
    break
  fi
  sleep 10
done

echo "Checking critical operators..."
not_ready=$(oc get csv -A --no-headers 2>/dev/null | grep -v Succeeded | wc -l)
if (( not_ready > 0 )); then
  echo "WARNING: $not_ready operators not in Succeeded state."
fi
```

---

## AgnosticD Vars: Copy, Do Not Symlink

Symlinks to files in `agnosticd-v2-vars/` (or `agnosticd-v2-secrets/`) break
when `agd` runs inside containers or when the working directory changes during
provisioning. Always **copy** vars and secrets files instead of symlinking them:

```bash
# Bad: symlinks break inside containers and across working directories
ln -s "${AGNOSTICD_VARS}/my-vars.yml" ./vars.yml

# Good: copy the file so it is self-contained
cp "${AGNOSTICD_VARS}/my-vars.yml" ./vars.yml
```

If the vars file is generated from a template (e.g., by substituting config
values), write the output directly to the target path rather than creating an
intermediate symlink:

```bash
# Good: generate in place
envsubst < templates/vars.yml.tpl > "${DEPLOY_DIR}/vars.yml"

# Bad: generate to a temp dir and symlink
envsubst < templates/vars.yml.tpl > /tmp/vars.yml
ln -s /tmp/vars.yml "${DEPLOY_DIR}/vars.yml"
```

---

## Consistent grep/awk Fallbacks

All `grep` and `awk` extractions that can legitimately return empty results should
have fallback values. Inconsistent handling causes `set -e` to terminate the script
on expected empty results:

```bash
# Bad: exits on empty grep match with set -e
result=$(grep "pattern" "$file")

# Good: empty string fallback
result=$(grep "pattern" "$file" 2>/dev/null || echo "")
```

---

## Secrets File Naming Alignment

If documentation says secrets files are named `secrets-<ACCOUNT>.yml`, the script
must use the same pattern. Audit for mismatches between:

- `onboard.yml` prompt key for account name
- Secrets file naming in `deploy.sh`
- Documentation references in `DEPLOYMENT.md`

---

## Recommended Makefile Targets

Projects using the project-onboard skill should ship a Makefile for convenience:

```makefile
.PHONY: setup deploy teardown status

setup:
	@echo "Run the project-onboard skill in Claude Code or Cursor to set up this project."
	@echo "Alternatively, review DEPLOYMENT.md for manual setup instructions."

deploy:
	./agnosticd/deploy.sh

teardown:
	./agnosticd/teardown.sh

status:
	./agnosticd/status.sh
```

The `setup` target can remind users to invoke the project-onboard skill rather than
attempting to run onboarding as a shell script.

---

## Issue Reference

Common deploy.sh issues sorted by severity:

### Critical

| Issue | Fix |
|-------|-----|
| Cross-platform `sed -i` breaks on macOS | Use `sed_inplace` helper above |
| Symlinked vars/secrets files break in containers | Copy files instead of symlinking |
| Missing prerequisite checks | Add fail-fast block at script top |
| Missing config files referenced in code | Create the file or fail-fast with a clear error |
| User-data path inconsistency | Standardize on one path pattern |

### High

| Issue | Fix |
|-------|-----|
| No SSH retry | Use `ssh_with_retry` helper above |
| Background process failures silently swallowed | Collect exit codes per process |
| Quota/config mismatch (wrong instance types) | Read instance types from the actual vars files |
| Hardcoded image versions (e.g., pinned to v4.14) | Derive from cluster version or use `latest` |

### Medium

| Issue | Fix |
|-------|-----|
| Fragile build wait (`tail -1` picks wrong object) | Filter by build phase, wait for newest |
| No post-provision health check | Verify API + operators before proceeding |
| Inconsistent grep fallbacks | Audit all extractions, add `\|\| echo ""` |
| Secrets file naming mismatch between docs and code | Align docs, scripts, and manifest |
