---
name: static-validation
description: >-
  Offline static validation for Helm, Kustomize, and AgnosticD repos — render
  manifests, validate against Kubernetes and OpenShift CRD schemas, enforce
  policies (no privileged pods, resource limits, pinned image tags), scan for
  committed secrets, and lint YAML/Helm/Ansible. Runs with no cluster
  credentials as the first rung of the evidence ladder.
license: Apache-2.0
compatibility: >-
  Requires bash 4.4+ and git on RHEL 8/9 or compatible Linux. Optional tools
  detected at runtime: helm 3.x, kustomize 5.x, kubeconform 0.6+, conftest
  0.5+ or kyverno CLI, gitleaks 8.x, yamllint 1.x, ansible-lint 24.x.
  Designed for Cursor and Claude Code.
metadata:
  related-skills: "agnosticd, agnosticd-refactor, patternizer, vp-refactor, field-sourced-content, rhel-devops-auditor"
---

# Static Validation Skill

## When to Use

- Before any deployment — run offline checks to catch errors without needing a cluster
- After modifying Helm charts, Kustomize overlays, or AgnosticD roles/configs
- In CI pipelines as the first quality gate before `agnosticd-deploy-test` or `vp-deploy-test`
- To produce rung-1 evidence artifacts (`docs/evidence/<spec>/rung1/`) for a Spec Kit workflow
- User says "validate this chart", "check my manifests", "lint this project", or "scan for secrets"
- User asks "will this render?" or "does this pass schema validation?"

Do NOT use this skill for:
- Live cluster validation — use **agnosticd-deploy-test** or **vp-deploy-test** (those require a running cluster)
- Deep AgnosticD config auditing — use **agnosticd-refactor** (this skill only lints and renders)
- Deep Validated Pattern auditing — use **vp-refactor** (this skill only lints and renders)
- Project structure auditing — use **rhel-devops-auditor** (this skill checks content, not structure)

## Instructions

This skill defines a five-phase process. Each phase is independent — if a required tool is missing, skip that phase and report it rather than failing the entire run.

## Gotchas

- **kubeconform schemas:** The default kubeconform schema set covers upstream Kubernetes only. OpenShift CRDs (Routes, DeploymentConfigs, etc.) and operator CRDs require additional schema sources. See the `references/crd-schema-sources.md` document for pinned sources and refresh instructions
- **ansible-lint requires a venv:** On RHEL 8/9, `ansible-lint` should be installed in a Python virtual environment to avoid conflicts with the system Ansible
- **conftest policies must exist:** Phase 4 policy checks require OPA Rego policies to be present in the repo (typically under `policy/`) or passed via `--policy`. If no policies exist, skip conftest and recommend creating a baseline policy set
- **Rendered output may contain secrets placeholders:** `helm template` renders `values-secret.yaml` references as literal `{{ }}` — this is expected and not a gitleaks finding. Do not treat template placeholder strings as leaked secrets
- **kustomize build requires valid bases:** If a Kustomize overlay references a remote base that is unavailable offline, the render will fail. Report as WARN (network dependency) rather than FAIL
- **helm lint vs helm template:** `helm lint` checks chart structure and values; `helm template` renders the full manifest. Run both — lint catches issues template misses (and vice versa)
- **AgnosticD syntax check is shallow:** `ansible-playbook --syntax-check` only validates YAML and Jinja2 syntax, not variable resolution or task logic

## Required Input

| Input | Required | Default | Notes |
|-------|----------|---------|-------|
| Repository path | Yes | Current working directory | Must contain Helm, Kustomize, or AgnosticD files |
| Repo type | No | Auto-detected | `helm`, `kustomize`, `agnosticd`, or `mixed` |
| CRD schema bundle path | No | Downloads if missing | Path to cloned `datreeio/CRDs-catalog` for OpenShift schemas |
| Evidence output directory | No | `docs/evidence/<spec>/rung1/` | Where to write evidence artifacts |
| Policy directory | No | `policy/` in repo root | OPA Rego policies for conftest |

### Auto-detection

Determine repo type by scanning for marker files:

| Marker | Detected type |
|--------|--------------|
| `Chart.yaml` | `helm` |
| `kustomization.yaml` or `kustomization.yml` | `kustomize` |
| `ansible/configs/` or `ansible/roles/` | `agnosticd` |
| Multiple markers present | `mixed` (run all applicable phases) |

If no marker files are found, ask the user to specify the repo type.

---

## Phase 1 — Tool Discovery

Detect which validation tools are available. Do not fail — report what is available and what is missing.

| Tool | Check command | Install hint (RHEL) | Install hint (macOS) | Used in |
|------|---------------|--------------------|--------------------|---------|
| `helm` | `helm version --short` | `sudo dnf install helm` | `brew install helm` | Phase 2, 5 |
| `kustomize` | `kustomize version` | `sudo dnf install kustomize` or [releases](https://github.com/kubernetes-sigs/kustomize/releases) | `brew install kustomize` | Phase 2 |
| `kubeconform` | `kubeconform -v` | [releases](https://github.com/yannh/kubeconform/releases) | `brew install kubeconform` | Phase 3 |
| `conftest` | `conftest --version` | [releases](https://github.com/open-policy-agent/conftest/releases) | `brew install conftest` | Phase 4 |
| `gitleaks` | `gitleaks version` | [releases](https://github.com/gitleaks/gitleaks/releases) | `brew install gitleaks` | Phase 4 |
| `yamllint` | `yamllint --version` | `sudo dnf install yamllint` or `pip install yamllint` | `brew install yamllint` | Phase 5 |
| `ansible-lint` | `ansible-lint --version` | `pip install ansible-lint` (in venv) | `brew install ansible-lint` | Phase 5 |
| `ansible-playbook` | `ansible-playbook --version` | `sudo dnf install ansible-core` | `brew install ansible` | Phase 2 |

```
Static Validation — Phase 1: Tool Discovery
══════════════════════════════════════════════════════
 Tool              Version        Status
 helm              3.14.2         AVAILABLE
 kustomize         5.3.0          AVAILABLE
 kubeconform       0.6.4          AVAILABLE
 conftest          0.52.0         AVAILABLE
 gitleaks          8.18.1         AVAILABLE
 yamllint          1.35.1         AVAILABLE
 ansible-lint      —              NOT FOUND → pip install ansible-lint
 ansible-playbook  —              NOT FOUND → sudo dnf install ansible-core
══════════════════════════════════════════════════════
 Available: 6/8 — Phases 2-5 can proceed (AgnosticD syntax check will be skipped)
```

If zero tools are available, stop and provide installation instructions for all tools.

---

## Phase 2 — Render

Confirm that manifests build successfully from the chart, overlay, or Ansible structure.

### Helm

For each `Chart.yaml` found in the repo:

```bash
helm template <release-name> <chart-path> \
  --values <chart-path>/values.yaml \
  --output-dir <evidence-dir>/rendered/helm/
```

If the chart has multiple values files (e.g. `values-hub.yaml`, `values-datacenter.yaml`), render once per values file:

```bash
helm template <release-name> <chart-path> \
  --values <chart-path>/values.yaml \
  --values <chart-path>/values-hub.yaml \
  --output-dir <evidence-dir>/rendered/helm-hub/
```

**Pass condition:** Exit code 0 and rendered YAML files present in output directory.

**Fail examples:**
- Missing required values → report which values are missing
- Invalid template syntax → report the template file and error
- Missing chart dependencies → `helm dependency build` needed first

### Kustomize

For each `kustomization.yaml` or `kustomization.yml` found:

```bash
kustomize build <overlay-path> > <evidence-dir>/rendered/kustomize/<overlay-name>.yaml
```

**Pass condition:** Exit code 0 and valid YAML output.

**Fail examples:**
- Missing base references → report which bases are unavailable (WARN if remote, FAIL if local)
- Invalid patches → report the patch file and error

### AgnosticD

For each playbook or role entry point under `ansible/`:

```bash
ansible-playbook --syntax-check <playbook-path>
```

**Pass condition:** Exit code 0 ("playbook: <path> — syntax check passed").

**Fail examples:**
- Jinja2 syntax errors → report file and line
- Invalid YAML → report parse error location

### Phase 2 Report

```
Static Validation — Phase 2: Render
══════════════════════════════════════════════════════
 Target                          Type        Status   Output
 charts/myapp/                   helm        PASS     rendered/helm/myapp/
 overlays/production/            kustomize   PASS     rendered/kustomize/production.yaml
 ansible/configs/myconfig/       agnosticd   FAIL     syntax error in tasks/main.yml:42
══════════════════════════════════════════════════════
 Rendered: 2/3 targets
```

Save all rendered output to `<evidence-dir>/rendered/`.

---

## Phase 3 — Schema Validation

Validate rendered manifests against Kubernetes and OpenShift CRD schemas using kubeconform.

### Schema sources

kubeconform uses `--schema-location` to find JSON schemas. Configure two sources:

1. **Kubernetes core schemas** (built-in to kubeconform, or from `yannh/kubernetes-json-schema`):
   ```
   default
   ```

2. **OpenShift and operator CRD schemas** (from `datreeio/CRDs-catalog`):
   ```
   https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json
   ```

   For offline use, clone the catalog locally:
   ```bash
   git clone --depth 1 https://github.com/datreeio/CRDs-catalog.git ~/.local/share/crd-schemas
   ```
   Then reference it as:
   ```
   ~/.local/share/crd-schemas/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json
   ```

See `references/crd-schema-sources.md` for the full schema source documentation and refresh procedure.

### Running kubeconform

For each rendered manifest from Phase 2:

```bash
kubeconform \
  -strict \
  -summary \
  -output json \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  -kubernetes-version <target-version> \
  <rendered-manifest> \
  > <evidence-dir>/schema/<manifest-name>.json
```

Use `-kubernetes-version 1.28` as default (OpenShift 4.15 baseline). If the user specifies a cluster version, map it:

| OpenShift | Kubernetes |
|-----------|-----------|
| 4.12 | 1.25 |
| 4.13 | 1.26 |
| 4.14 | 1.27 |
| 4.15 | 1.28 |
| 4.16 | 1.29 |
| 4.17 | 1.30 |

### Phase 3 Report

```
Static Validation — Phase 3: Schema Validation
══════════════════════════════════════════════════════
 Manifest                        Valid   Invalid  Unknown  Errors
 rendered/helm/myapp/            42      1        3        Deployment: invalid replicas type
 rendered/kustomize/production   18      0        0        —
══════════════════════════════════════════════════════
 Total: 60 valid, 1 invalid, 3 unknown (CRD schema not found)
```

**Unknown resources:** Resources with `unknown` status means kubeconform could not find a schema for that CRD. This is expected for custom operators. Report as WARN, not FAIL, and suggest adding the CRD schema to the schema bundle.

Save JSON output to `<evidence-dir>/schema/`.

---

## Phase 4 — Policy and Secrets

### 4a. Policy checks (conftest)

If conftest is available and policies exist (in `policy/` or a user-specified path):

```bash
conftest test \
  --policy <policy-dir> \
  --output json \
  <rendered-manifests> \
  > <evidence-dir>/policy/conftest-results.json
```

**Recommended baseline policies** (suggest creating these if none exist):

| Policy | Rego rule | Purpose |
|--------|----------|---------|
| No privileged containers | `deny[msg]` if `securityContext.privileged == true` | Security baseline |
| Resource limits required | `deny[msg]` if no `resources.limits` | Cluster stability |
| Pinned image tags | `warn[msg]` if image tag is `latest` or missing | Reproducibility |
| No host network | `deny[msg]` if `hostNetwork == true` | Security baseline |
| No host PID | `deny[msg]` if `hostPID == true` | Security baseline |

If no policy directory is found:

```
Static Validation — Phase 4a: Policy — SKIP
  No policy directory found at policy/
  Recommendation: Create baseline Rego policies under policy/
  See references/REFERENCE.md for example policies
```

### 4b. Secrets scanning (gitleaks)

Scan the entire repository for committed secrets:

```bash
gitleaks detect \
  --source <repo-path> \
  --report-format json \
  --report-path <evidence-dir>/policy/gitleaks-report.json \
  --no-banner
```

**Pass condition:** Exit code 0 (no leaks found).

**Known false positives to suppress:**
- Helm template placeholders (`{{ .Values.secret }}`)
- Example/dummy values in documentation
- Base64-encoded Kubernetes Secret manifests in test fixtures

If gitleaks finds secrets:

```
Static Validation — Phase 4b: Secrets Scan — FAIL
══════════════════════════════════════════════════════
 File                           Rule            Match
 values-secret.yaml             generic-api-key API_KEY=sk-...
 deploy/config.yml              password        password: hunter2
══════════════════════════════════════════════════════
 Findings: 2 — CRITICAL: remove secrets from git history

 Remediation:
   1. Add files to .gitignore
   2. Remove from git history:
      git filter-branch --force --index-filter \
        'git rm --cached --ignore-unmatch <file>' HEAD
   3. Rotate any exposed credentials immediately
```

### Phase 4 Report

```
Static Validation — Phase 4: Policy and Secrets
══════════════════════════════════════════════════════
 Check                     Status   Findings
 conftest (5 policies)     WARN     1 warning (image tag :latest)
 gitleaks                  PASS     0 secrets found
══════════════════════════════════════════════════════
```

Save results to `<evidence-dir>/policy/`.

---

## Phase 5 — Lint

### 5a. YAML lint

Run yamllint on all YAML files in the repo:

```bash
yamllint \
  --format parsable \
  --strict \
  <repo-path> \
  > <evidence-dir>/lint/yamllint-results.txt 2>&1
```

If a `.yamllint` or `.yamllint.yml` config exists in the repo, yamllint uses it automatically. Otherwise, use a sensible default:

```yaml
extends: default
rules:
  line-length:
    max: 200
  truthy:
    check-keys: false
  comments:
    min-spaces-from-content: 1
```

### 5b. Helm lint

For each chart:

```bash
helm lint <chart-path> \
  --values <chart-path>/values.yaml \
  > <evidence-dir>/lint/helm-lint-<chart-name>.txt 2>&1
```

### 5c. Ansible lint

For AgnosticD repos, run ansible-lint on roles and playbooks:

```bash
ansible-lint \
  --format json \
  --offline \
  <ansible-path> \
  > <evidence-dir>/lint/ansible-lint-results.json 2>&1
```

The `--offline` flag prevents ansible-lint from downloading Galaxy roles, keeping the run fully offline.

### Phase 5 Report

```
Static Validation — Phase 5: Lint
══════════════════════════════════════════════════════
 Linter          Files    Errors   Warnings   Status
 yamllint        47       0        3          WARN
 helm lint       2        0        0          PASS
 ansible-lint    —        —        —          SKIP (not installed)
══════════════════════════════════════════════════════
```

Save results to `<evidence-dir>/lint/`.

---

## Final Summary Report

```
=== Static Validation Report ===
Project: <name>     Date: <timestamp>
Type: <helm|kustomize|agnosticd|mixed>
Evidence: <evidence-dir>

Phase 1: Tool Discovery            8/8 available
Phase 2: Render                    PASS (3/3 targets)
Phase 3: Schema Validation         WARN (1 invalid, 3 unknown CRDs)
Phase 4: Policy and Secrets        PASS
Phase 5: Lint                      WARN (3 yamllint warnings)

Overall: PASS WITH WARNINGS (0 errors, 6 warnings)
══════════════════════════════════════════════════════

Evidence artifacts saved to: docs/evidence/<spec>/rung1/
  rendered/    — Rendered manifests from Phase 2
  schema/      — kubeconform JSON results from Phase 3
  policy/      — conftest and gitleaks results from Phase 4
  lint/        — yamllint, helm lint, ansible-lint results from Phase 5
```

### Scoring

- **Overall PASS:** All phases pass with no errors
- **Overall PASS WITH WARNINGS:** All phases pass but warnings exist (unknown CRDs, yamllint style issues, `:latest` image tags)
- **Overall FAIL:** At least one phase has errors (invalid schemas, committed secrets, render failures, critical lint errors)

## Remediation Plan

When the overall result contains errors, generate a prioritized remediation plan:

| Priority | Condition | Action |
|----------|-----------|--------|
| CRITICAL | Secrets found in git (Phase 4b) | Remove from git history immediately, rotate credentials |
| BLOCKING | Render failure (Phase 2) | Fix template/overlay/playbook syntax before any other checks |
| HIGH | Schema validation errors (Phase 3) | Fix invalid resource specs against the target Kubernetes version |
| HIGH | Policy violations — deny rules (Phase 4a) | Fix security and resource policy violations |
| MEDIUM | Policy warnings — warn rules (Phase 4a) | Address image tag pinning, recommended practices |
| MEDIUM | Lint errors (Phase 5) | Fix YAML/Helm/Ansible lint issues |
| LOW | Unknown CRD schemas (Phase 3) | Add missing CRD schemas to the schema bundle |
| LOW | Lint warnings (Phase 5) | Style improvements, non-blocking |

Present the plan as an ordered list containing only the items that actually failed:

```
Static Validation Remediation Plan — <project-name>
──────────────────────────────────────────────────────
Priority  #  Finding                                Action
BLOCKING  1  Helm render failed (missing dep)       Run: helm dependency build charts/myapp/
HIGH      2  Deployment replicas: invalid type       Fix: charts/myapp/templates/deployment.yaml:14
MEDIUM    3  Image tag :latest on nginx              Pin to specific tag in values.yaml
──────────────────────────────────────────────────────
Created 3 todos. Resolve in order — CRITICAL/BLOCKING items first.
```

## Evidence Artifacts

All output is saved to `docs/evidence/<spec>/rung1/` with this structure:

```
docs/evidence/<spec>/rung1/
├── rendered/
│   ├── helm/<chart-name>/        # helm template output
│   ├── kustomize/<overlay>.yaml  # kustomize build output
│   └── agnosticd/                # syntax check results
├── schema/
│   ├── <manifest>-results.json   # kubeconform JSON output
│   └── summary.txt               # human-readable summary
├── policy/
│   ├── conftest-results.json     # conftest output
│   └── gitleaks-report.json      # gitleaks output
├── lint/
│   ├── yamllint-results.txt      # yamllint output
│   ├── helm-lint-<chart>.txt     # helm lint output
│   └── ansible-lint-results.json # ansible-lint output
└── report.txt                    # final summary report
```

The `<spec>` placeholder is the project or chart name. Timestamps are embedded in `report.txt`, not in filenames, to keep paths stable for CI diffing.

## OpenShift CRD Schema Source

This section addresses the open design question: where to get OpenShift and operator CRD schemas for kubeconform.

**Recommended source:** [datreeio/CRDs-catalog](https://github.com/datreeio/CRDs-catalog)

This community-maintained catalog includes JSON schemas for:
- OpenShift CRDs (Route, DeploymentConfig, BuildConfig, etc.)
- Operator CRDs (ArgoCD Application, ExternalSecret, VaultSecret, etc.)
- 600+ additional Kubernetes operator CRDs

**Why this source:**
- Actively maintained with automated updates
- Covers the OpenShift and operator CRDs most relevant to Validated Patterns and AgnosticD
- Compatible with kubeconform's `--schema-location` URL template pattern
- Can be used online (GitHub raw URLs) or offline (cloned locally)

**Refresh procedure:** See `references/crd-schema-sources.md` for pinned versions and update instructions.

## Re-run After Fixes

After the developer resolves remediation items, re-run only the phases that contained failures:

```
Re-running failed phases only:
  Phase 2 (Render) — re-checking after helm dependency build
  Phase 3 (Schema) — re-validating after spec fix

Skipping Phase 1 (tools unchanged), Phase 4 (passed), Phase 5 (passed).
```

Compare results against the previous run:

```
Re-run Results — <project-name>
──────────────────────────────────────────────────────
 Item  Finding                         Previous   Now
 1     Helm render failed              FAIL    →  PASS  resolved
 2     Deployment replicas invalid     FAIL    →  PASS  resolved
 3     Image tag :latest               WARN    →  WARN  still present
──────────────────────────────────────────────────────
 Resolved: 2/3   Remaining: 1 (MEDIUM)
```

## Escalation

- **AgnosticD lint/syntax failures** → Activate **agnosticd-refactor** for deep config auditing
- **Validated Pattern Helm/schema failures** → Activate **vp-refactor** for chart and values auditing
- **Project structure issues discovered during scanning** → Activate **rhel-devops-auditor** for structural audit
- **All static checks pass, ready for live validation** → Activate **agnosticd-deploy-test** or **vp-deploy-test** as the next rung of the evidence ladder
- **Research needed for CRD schemas or policies** → Activate **skill-researcher** to resolve
