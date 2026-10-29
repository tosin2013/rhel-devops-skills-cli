---
title: Static Validation
parent: Skills
nav_order: 17
---

# Static Validation Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The Static Validation skill guides the AI assistant through fully offline checks for Helm charts, Kustomize overlays, and AgnosticD repos. It is the first rung of the evidence ladder — checks that run with **no cluster credentials**, before any dry-run or live reconcile.

The skill covers five phases: rendering manifests, validating against Kubernetes and OpenShift CRD schemas, enforcing OPA policies, scanning for committed secrets, and linting YAML/Helm/Ansible files. All output is saved as evidence artifacts under `docs/evidence/<spec>/rung1/`.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "validate this chart", "check my manifests", or "lint this project"
- Wanting to verify that Helm charts or Kustomize overlays render correctly before deploying
- Checking manifests against Kubernetes and OpenShift CRD schemas
- Scanning a repo for committed secrets before opening a PR
- Building rung-1 evidence artifacts for a Spec Kit workflow
- Preparing to run `agnosticd-deploy-test` or `vp-deploy-test` and want offline checks first

## Five-Phase Process

```
Phase 1 — Tool Discovery
  Detect installed validation tools (helm, kustomize, kubeconform, etc.)
  Report missing tools with install instructions
  Skip phases gracefully when tools are absent

Phase 2 — Render
  helm template for charts, kustomize build for overlays
  ansible-playbook --syntax-check for AgnosticD roles
  Save rendered manifests as evidence artifacts

Phase 3 — Schema Validation
  kubeconform against Kubernetes + OpenShift CRD schemas
  Uses datreeio/CRDs-catalog for OpenShift and operator CRDs
  Unknown CRDs are WARN, not FAIL

Phase 4 — Policy and Secrets
  conftest with OPA Rego policies (no privileged pods, resource limits, etc.)
  gitleaks detect for committed secrets
  CRITICAL findings if secrets are found in git

Phase 5 — Lint
  yamllint on all YAML files
  helm lint for charts
  ansible-lint --offline for AgnosticD roles
```

## CRD Schema Sources

kubeconform's default schemas only cover upstream Kubernetes. For OpenShift and operator CRDs, the skill uses [datreeio/CRDs-catalog](https://github.com/datreeio/CRDs-catalog), which covers 600+ CRDs including:

- OpenShift (Route, DeploymentConfig, BuildConfig, ImageStream)
- ArgoCD (Application, ApplicationSet, AppProject)
- External Secrets (ExternalSecret, SecretStore)
- OLM (Subscription, CatalogSource, ClusterServiceVersion)
- ACM (ManagedCluster, Policy, PlacementRule)

The catalog can be used online via GitHub raw URLs or cloned locally for fully offline validation.

## Evidence Artifacts

All output is saved under `docs/evidence/<spec>/rung1/`:

```
docs/evidence/<spec>/rung1/
├── rendered/       — Rendered manifests (helm template, kustomize build)
├── schema/         — kubeconform JSON results
├── policy/         — conftest and gitleaks results
├── lint/           — yamllint, helm lint, ansible-lint results
└── report.txt      — Final summary report
```

## Failure Escalation

When the static validation finds failures, the skill provides a structured escalation path:

| Failure | Escalation |
|---------|-----------|
| AgnosticD lint/syntax failures | Activate **agnosticd-refactor** for deep config auditing |
| Validated Pattern Helm/schema failures | Activate **vp-refactor** for chart and values auditing |
| Project structure issues discovered | Activate **rhel-devops-auditor** for structural audit |
| All static checks pass | Activate **agnosticd-deploy-test** or **vp-deploy-test** as next rung |

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [AgnosticD](agnosticd.html) | Operational skill — static-validation lints and renders AgnosticD configs |
| [AgnosticD Refactor](agnosticd-refactor.html) | Escalation target for AgnosticD lint and syntax failures |
| [VP Refactor](vp-refactor.html) | Escalation target for Helm/Kustomize schema and render failures |
| [Patternizer](patternizer.html) | Operational skill — static-validation checks patterns initialized by patternizer |
| [Field-Sourced Content](field-sourced-content.html) | Operational skill — static-validation checks field content Helm charts |
| [RHEL DevOps Auditor](rhel-devops-auditor.html) | Escalation target for structural issues discovered during scanning |
| [AgnosticD Deploy Test](agnosticd-deploy-test.html) | Next rung — activate after static checks pass for live validation |
| [VP Deploy Test](vp-deploy-test.html) | Next rung — activate after static checks pass for live validation |

See [ADR-021](../adrs/021-static-validation-skill.html) for the full design rationale.

## Install

```bash
./install.sh install --skill static-validation
```
