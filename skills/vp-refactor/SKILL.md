---
name: vp-refactor
description: AI assistance for auditing and improving existing Validated Pattern repos against VP Operator requirements and Sandbox/Tested/Maintained tier criteria. Use when a developer has run `patternizer init` and needs to know what to fill in, or when preparing a pattern for tier submission — not when initializing from scratch.
related_skills: [patternizer, vp-deploy-test]
---

# Validated Pattern Refactor Skill

## When to Use

- Developer has run `patternizer init` and asks "what do I fill in now?"
- Pattern deploys manually but fails when installed via the Validated Patterns Operator
- Preparing a pattern for Sandbox tier submission to validatedpatterns.io
- Upgrading an existing pattern from the old `common/` submodule structure to `Makefile-common`
- Developer asks "is my pattern ready to submit?"
- Values files are incomplete or operators are not deploying correctly
- `pattern-metadata.yaml` is missing or incorrectly structured
- Secrets are committed to the repository or not using the correct file location

## Instructions

This skill defines an audit process, not a tool wrapper. When activated, collect the required input from the developer, then work through the audit areas below in order. For each area, assess the current state, identify gaps, and provide specific remediation steps.

Do NOT use this skill when a developer is initializing a new pattern from scratch — use the **patternizer** skill instead.

## Required Input

Before auditing, collect the following from the developer:

| Input | Required | Example |
|-------|----------|---------|
| Pattern repository path or URL | Yes | `~/my-pattern/` or GitHub URL |
| Cluster group name | Yes | `hub`, `datacenter` |
| OpenShift cluster access | If testing | `oc login` token or kubeconfig path |
| Target tier | If known | Sandbox, Tested, Maintained |
| Operators the pattern installs | Yes | ACM, OpenShift GitOps, cert-manager |
| Secrets required by the pattern | Yes | AWS credentials, pull secret, API tokens |

## Audit Areas

Work through each area in order. Report findings as a pass/fail table at the end (see Output Format).

---

### 1. Post-Init Values File Completeness

Two files control all deployments. Both must be populated before `./pattern.sh make install` will succeed.

**`values-global.yaml` — mandatory field:**

`main.clusterGroupName` is the topological router. ArgoCD uses this string to find the cluster-specific values file. The string must have a 1:1 match with a `values-<string>.yaml` filename.

```yaml
main:
  clusterGroupName: hub   # targets values-hub.yaml
```

A mismatch causes catastrophic failure — ArgoCD injects no workloads and no error is reported until the sync times out.

**`values-<cluster>.yaml` — three mandatory blocks in dependency order:**

| Block | Purpose | Failure if missing |
|-------|---------|-------------------|
| `namespaces:` | Provisions Kubernetes namespaces before anything else | ArgoCD sync halts — operators deploy into non-existent namespaces |
| `subscriptions:` | Declares OLM operators; must target namespaces above | Workloads fail — Custom Resources for uninstalled operators are rejected |
| `applications:` | Creates ArgoCD Application CRs; must point to valid Helm charts | Nothing deploys |

Verify all three blocks are present and that `subscriptions:` namespaces match entries in `namespaces:`, and `applications:` paths resolve to directories containing `Chart.yaml`.

See `references/values-files-guide.md` for the full schema and a minimal working example.

---

### 2. Operator Subscription Correctness

**Catalog sources — pick the right tier:**

| Source | Provenance | Support |
|--------|-----------|---------|
| `redhat-operators` | First-party Red Hat software | Fully supported under OpenShift entitlement |
| `certified-operators` | Third-party ISV software | Supported by the ISV vendor |
| `community-operators` | Open-source community projects | Best-effort only, no SLA |

**Never use OperatorHub.io to find channel or CSV values** — the cluster's internal catalog may lag or mirror different builds. Always query the cluster directly from the `openshift-marketplace` namespace:

```bash
# Step 1 — find package name and confirm source
oc get packagemanifests -n openshift-marketplace | grep <keyword>

# Step 2 — get the default channel
oc get packagemanifest <name> -n openshift-marketplace \
  -o jsonpath='{.status.defaultChannel}'

# Step 3 — get the startingCSV for that channel
oc get packagemanifest <name> -n openshift-marketplace \
  -o jsonpath='{.status.channels[?(@.name=="<channel>")].currentCSV}'
```

**`startingCSV` is mandatory for GitOps immutability.** Omitting it allows OLM to upgrade unpredictably — the same Git commit produces different cluster states at different times. It can also cause InstallPlan generation to fail, leaving the workload perpetually in a `Pending` state.

For each subscription entry, verify all four fields are present and exactly match cluster catalog output. See `references/operator-discovery.md` for the complete workflow with examples.

---

### 3. Charts Directory Structure

**Minimum Helm chart structure** — ArgoCD does not parse unstructured YAML directories. Every `path:` in `applications:` must resolve to a directory with these three components:

```
charts/hub/my-app/
├── Chart.yaml       ← REQUIRED: absence causes ArgoCD to reject directory entirely
├── values.yaml      ← REQUIRED: default variable declarations (overridden by global/cluster values)
└── templates/       ← REQUIRED: Kubernetes resource files (static YAML or Go templates)
```

**`applications:` field-to-ArgoCD mapping:**

| Values field | ArgoCD Application CR field | Common failure |
|---|---|---|
| `name` | `metadata.name` | Duplicate names across applications cause conflicts |
| `namespace` | `spec.destination.namespace` | Namespace must exist in `namespaces:` block |
| `project` | `spec.project` | Wrong project causes auth errors for cluster-scoped resources |
| `path` | `spec.source.path` | Path is **relative from repo root** — not from `charts/` |

**Path resolution rule:** `path: charts/hub/my-app` is correct. `path: my-app` will fail because ArgoCD resolves paths from the repository root, not from any subdirectory.

For each `applications:` entry, verify:
1. The `path:` directory exists in the pattern repo
2. `Chart.yaml` is present at that path
3. `namespace:` matches an entry in the `namespaces:` block
4. `project:` matches an existing ArgoCD AppProject

See `references/charts-directory.md` for the Chart.yaml field reference and common failure modes.

---

### 4. Secrets Model Compliance

**Step 1 — Check for committed secrets (highest priority fix):**

```bash
git log --all --full-history -- "*values-secret*"
git grep -l "password\|token\|secret\|key" -- "*.yaml" | grep -v "ExternalSecret\|SecretStore"
```

If `values-secret.yaml` appears in git history, it must be purged from history — not just deleted in the latest commit.

**Step 2 — Verify `--with-secrets` was used at init:**

Patterns requiring secrets need HashiCorp Vault + External Secrets Operator. Check whether the VP subscription definitions include ESO:

```bash
grep -r "external-secrets\|vault" values-*.yaml
```

If secrets are needed but ESO is absent, the pattern was initialized without `--with-secrets`. The values files will need Vault and ESO subscriptions added manually or the pattern should be re-initialized.

**Step 3 — Verify `values-secret.yaml` location:**

The `make load-secrets` target searches these paths in order:
1. `~/.config/validatedpatterns/values-secret-<pattern_name>.yaml` ← required location
2. `~/.config/hybrid-cloud-patterns/values-secret-<pattern_name>.yaml`

The file must **never** be inside the cloned repository directory. Moving it to `~/.config/validatedpatterns/` is mandatory, non-negotiable.

**Step 4 — Verify the secrets flow works:**

```bash
./pattern.sh make load-secrets
```

If this command fails to find the file, it means either the file is missing or it is in the wrong location. See `references/secrets-management.md` for the full Vault+ESO architecture and safe workflow.

---

### 5. VP Operator Compatibility

The VP Operator and the CLI (`./pattern.sh make install`) have distinct requirements. Test both paths separately.

**Three required Operator form fields:**

| Field | Maps to | Most common error |
|-------|---------|-------------------|
| Cluster Group Name | `main.clusterGroupName` | Must match values filename (e.g. `hub` for `values-hub.yaml`) |
| Target Repo URL | GitOps source for the Operator | Left pointing at upstream VP template instead of developer's fork |
| Target Revision | Branch/tag/commit to deploy | `HEAD` tracks `main`; use feature branch name during testing |

**Critical Operator limitation:** The VP Operator runs inside the cluster and has no access to the developer's local filesystem. It **cannot run `make load-secrets`**. If the pattern requires secrets:
- Deploy pattern components via the Operator UI
- Then authenticate locally and run `./pattern.sh make load-secrets` separately

**Verify Operator compatibility checklist:**

```bash
# 1. Pattern repo is publicly accessible (Operator pulls directly from Git)
curl -s https://github.com/<your-org>/<pattern-name> | grep -c "repository"

# 2. Your fork URL differs from the upstream VP URL
grep -r "validatedpatterns/" values-*.yaml  # should show your fork, not upstream

# 3. Check Operator-created resources
oc get pattern -A
oc get application -n openshift-gitops
```

See `references/vp-operator-guide.md` for the full CLI vs Operator comparison and when to use each.

---

### 6. `pattern-metadata.yaml` Presence

`pattern-metadata.yaml` is the identity document for the pattern within the VP ecosystem. It is parsed by upstream aggregators, CI pipelines, and the VP website for indexing and catalog display.

**`patternizer init` does not generate this file.** Developers must create it manually at the repository root.

**Consequences of absence:**
- The pattern is invisible to the VP framework catalog
- Automated indexing cannot process the repository
- Any tier submission (Sandbox, Tested, Maintained) results in immediate rejection

**Check:**
```bash
ls -la pattern-metadata.yaml   # must exist at repo root
```

**Known content requirements** (from research):
- Formalized display name for the VP catalog
- Architectural description (what the pattern deploys and why)
- Targeted enterprise use cases (the business problems solved)
- Technical prerequisites (e.g. required vector databases, inference providers for LLM patterns)

> (SCHEMA PENDING — RQ-6 partial: The exact YAML field names require inspection of upstream reference patterns. See `references/pattern-metadata.md` for the pending items and recommended upstream sources to check.)

If the file is missing, create it at the repo root based on the structure from the [multicloud-gitops](https://github.com/validatedpatterns/multicloud-gitops/blob/main/pattern-metadata.yaml) reference pattern.

---

### 7. Sandbox Tier Submission Checklist

Check these items directly against the [VP tier requirements](https://validatedpatterns.io/learn/about-pattern-tiers-types/):

**Required for Sandbox tier:**

| Item | Check | Status |
|------|-------|--------|
| Deploys on fresh OCP without modification | `./pattern.sh make install` succeeds on a clean cluster | Verify |
| No private/closed-source apps required | All container images are publicly accessible | Verify |
| README with problem statement | `README.md` exists and describes the business problem solved | Verify |
| Architecture diagram | Diagram is present in `README.md` or `docs/` | Verify |
| Documented support policy | Support policy (community, best-effort, etc.) is stated | Verify |
| Open for contributions | Repository is public, CONTRIBUTING or PR guidelines exist | Verify |

**Not required for Sandbox but needed for Tested tier:**
- Business use case with working demo
- Test plan (manual or automated) that passes at least once per quarter
- Publicly visible test results JSON file
- Implementation review by the VP team

---

### 8. Imperative Jobs Assessment

The `imperative:` section is an escape hatch for tasks that cannot be expressed as OLM subscriptions or Helm chart resources. ArgoCD deploys CronJobs in an `imperative` namespace that run Ansible playbooks inside the cluster.

**Assess whether imperative jobs are needed:**

If the developer has any of these after `./pattern.sh make install`, they are candidates for the `imperative:` section:
- Shell scripts or `oc` commands run manually after install
- Vault unsealing steps
- Certificate distribution tasks
- RHACM API calls for multi-cluster configuration
- AAP controller registration tasks
- Bare-metal network configuration

**If imperative jobs are present, verify these four requirements:**

**1. Jobs defined as a YAML list (not a hash):**
```yaml
# CORRECT — list preserves order for Helm rendering
clusterGroup:
  imperative:
    jobs:
      - name: bootstrap-vault
        playbook: ansible/playbooks/bootstrap-vault.yaml
      - name: distribute-ca
        playbook: ansible/playbooks/distribute-ca.yaml
```
YAML hashes lose ordering when parsed by Helm. Execution order is critical for bootstrapping sequences.

**2. Playbooks exist in `ansible/playbooks/`:**
```bash
ls ansible/playbooks/
```
The default container image (`registry.redhat.io/ansible-automation-platform-22/ee-supported-rhel8:latest`) expects playbooks at this path.

**3. All playbooks are strictly idempotent:**
Jobs run every 10 minutes by default (`*/10 * * * *`). Non-idempotent playbooks will overwrite configurations, exhaust API rate limits, or destabilize the cluster on each cycle. Verify every playbook checks state before acting.

**4. Vault unsealing (if Vault is used) runs on a 9-minute schedule:**
```yaml
# Vault unsealing uses a tighter schedule than the default 10-min cycle
schedule: "*/9 * * * *"
```

See `references/imperative-jobs.md` for the full CronJob architecture and configurable options (`timeout`, `serviceAccountName`, Ansible verbosity).

---

## Output Format

Present audit results as a pass/fail table with a tier-readiness summary:

```
VP Pattern Refactor Audit — Pattern: <pattern-name>
──────────────────────────────────────────────────────────
 #  Area                            Status  Notes
 1  Values file completeness        FAIL    values-hub.yaml missing subscriptions: block
 2  Operator subscriptions          FAIL    cert-manager channel "stable-v1" not found on OCP 4.17
 3  Charts directory structure      PASS    All application paths resolve to valid Helm charts
 4  Secrets model compliance        FAIL    values-secret.yaml committed to repo — must be removed
 5  VP Operator compatibility       SKIP    Research pending — RQ-5
 6  pattern-metadata.yaml           FAIL    File missing from repository root
 7  Sandbox tier checklist          PARTIAL README present, no architecture diagram
 8  Imperative jobs                 N/A     Pattern is fully declarative
──────────────────────────────────────────────────────────
 Result: 3 FAIL, 1 PASS, 1 PARTIAL, 1 SKIP (research pending), 1 N/A
 Sandbox tier readiness: NOT READY (fix #4, #6, and #7 first)
 Priority fixes: #4 (secrets in repo), #6 (pattern-metadata.yaml), #1 (subscriptions block)
```

## Escalation

When audit findings reveal deeper issues:

1. **Pattern won't initialize** → Use the **patternizer** skill for `init` and `upgrade` guidance
2. **Operator not deploying after subscription is correct** → Check `oc get csv -A` and `oc get installplan -A`
3. **ArgoCD Application stuck in OutOfSync** → Check `oc get app -n openshift-gitops` and inspect sync errors
4. **Secrets not injecting** → Review [VP Secrets Management docs](https://validatedpatterns.io/learn/secrets-management-in-the-validated-patterns-framework/)
5. **Sandbox tier questions** → See [VP contribution guide](https://validatedpatterns.io/contribute/) and [tier requirements](https://validatedpatterns.io/learn/about-pattern-tiers-types/)

## Best Practices

- Run this audit immediately after `patternizer init`, before attempting `./pattern.sh make install`
- Fix secrets compliance (area 4) before anything else — committed secrets must be removed from git history, not just deleted
- Address Sandbox tier checklist items (area 7) in parallel with technical fixes — the README and diagram are quick wins that unblock tier review
- Use `(RESEARCH NEEDED)` SKIP results as a tracking list — revisit when the corresponding research question is answered
- Test with the VP Operator (area 5) separately from `./pattern.sh` — they have different requirements
