---
title: "ADR-021: Static Validation Skill"
nav_order: 21
parent: Architecture Decision Records
---

# ADR-021: Static Validation Skill

* Status: accepted
* Date: 2026-10-29
* Deciders: Architecture Team

## Context and Problem Statement

The current skills cover AgnosticD, Validated Patterns, and deploy testing, but none covers offline static checks. These are the first step of the evidence ladder in an infrastructure Spec Kit workflow: checks a worker agent can run with **no cluster credentials**, before any dry-run or live reconcile.

Infrastructure repos (Helm charts, Kustomize overlays, AgnosticD configs) can have rendering errors, schema violations, policy breaches, committed secrets, and lint issues that are all detectable without a running cluster. Catching these before deployment saves time and prevents broken deployments.

## Decision Drivers

* No existing skill covers offline, pre-deployment static analysis
* Deploy-test skills (ADR-015) require a live cluster — they cannot run in CI without credentials
* Users need confidence that manifests are valid before spending time on provisioning
* The evidence ladder pattern requires a "rung 1" offline evidence layer
* kubeconform's default schemas do not cover OpenShift or operator CRDs — a documented, pinned source is needed

## Decision Outcome

Create a `static-validation` skill that runs five phases of offline checks and saves results as evidence artifacts.

### Five Phases

| Phase | Tool(s) | Purpose |
|-------|---------|---------|
| 1 — Tool Discovery | `command -v` | Detect installed tools; gracefully skip phases for missing tools |
| 2 — Render | `helm template`, `kustomize build`, `ansible-playbook --syntax-check` | Confirm manifests build from charts, overlays, and roles |
| 3 — Schema Validation | `kubeconform` | Validate against Kubernetes + OpenShift CRD schemas |
| 4 — Policy and Secrets | `conftest`, `gitleaks` | Enforce OPA policies; scan for committed secrets |
| 5 — Lint | `yamllint`, `helm lint`, `ansible-lint` | Catch YAML style issues, chart structure problems, Ansible anti-patterns |

### Evidence Artifacts

All output is saved to `docs/evidence/<spec>/rung1/` with subdirectories for each phase:

```
docs/evidence/<spec>/rung1/
├── rendered/       — Phase 2 output
├── schema/         — Phase 3 output
├── policy/         — Phase 4 output
├── lint/           — Phase 5 output
└── report.txt      — Final summary
```

### Tool Selection Rationale

| Tool | Why this tool | Alternatives considered |
|------|-------------|----------------------|
| **kubeconform** | Faster than kubeval, actively maintained, supports custom schema locations via URL templates | kubeval (deprecated), kubectl --dry-run=client (requires cluster types) |
| **conftest** | OPA-based, widely adopted, supports multiple input formats, policies are version-controllable Rego files | kyverno CLI (also viable — skill supports both), polaris (less flexible) |
| **gitleaks** | Purpose-built for git secret scanning, low false-positive rate, configurable rules | truffleHog (heavier), git-secrets (AWS-focused) |
| **yamllint** | Standard YAML linter, configurable, fast | prettier (not YAML-focused) |
| **ansible-lint** | Official Ansible linter, covers rules beyond YAML syntax | ansible-playbook --syntax-check (only syntax, no best practices) |

### CRD Schema Source Decision

**Selected:** [datreeio/CRDs-catalog](https://github.com/datreeio/CRDs-catalog)

This community-maintained catalog provides JSON schemas for 600+ CRDs including all the OpenShift and operator CRDs relevant to Validated Patterns and AgnosticD workloads (Route, DeploymentConfig, ArgoCD Application, ExternalSecret, OLM Subscription, etc.).

**Why this source:**
- Actively maintained with automated weekly updates
- Compatible with kubeconform's `--schema-location` URL template pattern
- Works both online (GitHub raw URLs) and offline (local clone)
- Broad coverage eliminates the need to maintain our own CRD schema collection

**Refresh procedure:** Clone locally, `git pull` to update, pin commit hash for reproducible CI. Full documentation in `skills/static-validation/references/crd-schema-sources.md`.

### Validation Lifecycle Position

The static-validation skill is the first rung, running before all deploy-test skills:

```
static-validation → agnosticd-deploy-test → student-readiness → workshop-tester
static-validation → vp-deploy-test → vp-deploy-validator → vp-submission
(offline, no cluster)  (live cluster)
```

### Key Design Decisions

1. **Self-contained skill** — no upstream repo dependency; all tool documentation is in `references/`
2. **Graceful degradation** — missing tools cause phase SKIPs, not failures; the skill works with whatever subset of tools is installed
3. **Auto-detection** — repo type (helm/kustomize/agnosticd/mixed) is detected from marker files, not required as input
4. **Evidence-first** — all output is saved as artifacts for traceability and CI diffing
5. **WARN vs FAIL for unknowns** — kubeconform `unknown` resources (missing CRD schemas) are WARN, not FAIL, to avoid false positives from custom operators
6. **Cursor rule included** — `rules/static-validation.mdc` activates on chart, overlay, and Ansible file patterns

### Positive Consequences

* Catches rendering errors, schema violations, and committed secrets before any cluster is involved
* Produces evidence artifacts usable in Spec Kit workflows and CI pipelines
* Graceful degradation means partial checks are better than no checks
* Documents and pins CRD schema sources, resolving the kubeconform coverage gap
* Slots naturally into the existing validation lifecycle as rung 1

### Negative Consequences

* Depends on external tools that must be installed separately (not bundled)
* CRD schema catalog requires periodic refresh to stay current
* OPA Rego policies must be authored per project (skill provides examples but not a complete policy set)
* Schema validation is only as good as the schema source — custom operator CRDs may still show as unknown

## Links

* Related: [ADR-015](015-deployment-pipeline-testing.html) (deployment pipeline testing)
* Related: [ADR-019](019-rhel-devops-auditor.html) (RHEL DevOps auditor)
* Related: [ADR-013](013-refactor-skills.html) (refactor skills)
* Related: [ADR-011](011-e2e-validation-and-troubleshooting.html) (validation and troubleshooting)
* External: [datreeio/CRDs-catalog](https://github.com/datreeio/CRDs-catalog) (CRD schema source)
* External: [kubeconform](https://github.com/yannh/kubeconform) (schema validation tool)
* External: [conftest](https://www.conftest.dev/) (OPA policy testing)
* External: [gitleaks](https://github.com/gitleaks/gitleaks) (secret scanning)
