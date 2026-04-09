---
title: VP Deploy Validator
parent: Skills
nav_order: 12
---

# VP Deploy Validator Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The VP Deploy Validator skill teaches the AI assistant to health-check an already-running Validated Pattern deployment without reinstalling. It verifies ArgoCD Application convergence, secrets delivery via External Secrets Operator, and imperative job completion — giving an operator confidence the pattern is healthy before running exercises or going live.

Use this skill instead of `vp-deploy-test` when the pattern was deployed by CI/CD, another team member, or automation and you just want a quick confidence check.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Checking whether a live Validated Pattern deployment is healthy
- Running a pre-demo confidence check without triggering a reinstall
- Spot-checking convergence after a values file update, chart version bump, or cluster upgrade
- Confirming a `vp-refactor` fix took effect without a full reinstall
- Monitoring a running demo or workshop pattern

## Three-Phase Health Check

The skill runs three read-only phases — nothing is installed or modified.

### Phase 1 — Pre-flight

Verify OCP access and that the VP stack (VP Operator, OpenShift GitOps) is present on the cluster.

### Phase 2 — ArgoCD Application Health Scan

Check all ArgoCD Applications for `Healthy/Synced` status. Classify any failures:

| Symptom | Likely cause | Action |
|---------|-------------|--------|
| `SyncFailed: ComparedTo error` | Helm values rendering error | Escalate to **vp-refactor**, Audit Area 3 |
| `OutOfSync: Unknown` | ArgoCD can't reach Git repo | Verify repo credentials and URL |
| `Degraded: Missing resource` | Operator subscription not resolving | Escalate to **vp-refactor**, Audit Area 1 |
| `Progressing` (stuck) | Timing issue or resource creation | Wait and re-check; escalate if stuck |

### Phase 3 — Secrets and Jobs Health Scan

- **ExternalSecrets**: Verify all ExternalSecret resources show `Ready=True` / `SecretSynced`
- **Imperative jobs**: Verify CronJobs have at least one completed Job
- **Confidence hand-off**: If all pass, recommend activating `student-readiness` then `workshop-tester`

## Confidence Statement

When all phases pass, the skill produces:

> "All VP health checks passed. An operator can run this pattern with high confidence. Recommended next steps: student-readiness, then workshop-tester."

## Confidence Chain

```
vp-deploy-test → vp-deploy-validator → student-readiness → workshop-tester
(pipeline worked)  (still healthy)      (student POV)       (exercises work)
```

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [VP Deploy Test](vp-deploy-test.html) | Full end-to-end deploy and validate — use when installing from scratch |
| [VP Refactor](vp-refactor.html) | Escalation target for ArgoCD convergence and secrets failures |
| [Student Readiness](student-readiness.html) | Next step after health checks pass — verify the student experience |
| [Workshop Tester](workshop-tester.html) | Final confidence gate — execute module exercises against the live environment |

See [ADR-015](../adrs/015-deployment-pipeline-testing.html) for the deployment pipeline testing design and [ADR-011](../adrs/011-e2e-validation-and-troubleshooting.html) for the full validation lifecycle.

## Install

```bash
./install.sh install --skill vp-deploy-validator
```
