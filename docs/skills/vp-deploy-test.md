---
title: VP Deploy Test
parent: Skills
nav_order: 11
---

# Validated Pattern Deployment Tester Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The VP Deployment Tester skill guides the AI assistant through validating a Validated Pattern deployment end-to-end after `pattern.sh make install` or VP Operator installation completes. It fills the gap between running the install command and confirming that the GitOps stack has fully converged.

While `student-readiness` checks whether the *environment* is ready for students right now, this skill validates whether the *deployment pipeline* — VP Operator installation, ArgoCD Application convergence, secrets delivery via Vault and ESO, and imperative job completion — produced a correct, fully-working result.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "did my pattern install correctly?" or "why are my ArgoCD Applications not syncing?"
- Checking whether ExternalSecrets are delivering secrets to application pods
- Verifying that imperative jobs in the `jobs/` directory completed
- Preparing to hand an environment to students and want full end-to-end confidence
- Re-verifying after fixing a `vp-refactor` audit finding and re-installing

## Four-Phase Process

```
Phase 1 — Pre-flight
  Verify oc login, cluster version, VP Operator installed
  Confirm values-global.yaml and values-<cluster>.yaml present
  Verify values-secret.yaml is NOT committed to git

Phase 2 — Install
  Run pattern.sh make install or confirm VP Operator has picked up GitOps repo
  Verify ArgoCD ApplicationSet was created
  Stop and escalate to vp-refactor on failure

Phase 3 — ArgoCD Convergence
  Poll until all Applications reach Healthy/Synced (up to 10 min)
  Classify Degraded/OutOfSync failures by symptom
  → Escalate to vp-refactor for convergence failures

Phase 4 — Secrets and Jobs Verification
  Verify ExternalSecrets are Ready (Vault + ESO flow)
  Verify CronJobs in jobs/ have at least one completed run
  → Activate student-readiness after all checks pass
  → Optionally activate workshop-tester when complete
```

## Failure Escalation

When the deployment test finds failures, the skill provides a structured escalation path:

| Failure | Escalation |
|---------|-----------|
| Install fails / ApplicationSet not created | Activate **vp-refactor** to audit values files and metadata |
| ArgoCD Application Degraded/OutOfSync | Activate **vp-refactor**, Audit Area 3 (Charts) and Area 1 (Values) |
| ExternalSecret errors | Activate **vp-refactor**, Audit Area 4 (Secrets Management) |
| Imperative jobs failing | Activate **vp-refactor**, Audit Area 8 (Imperative Jobs) |
| student-readiness fails | Use student-readiness troubleshooting tree; escalate to vp-refactor |

## Convergence Failure Classification

| Symptom | Likely cause |
|---------|-------------|
| `SyncFailed: ComparedTo error` | Helm values rendering error — check values file structure |
| `OutOfSync: Unknown` | ArgoCD cannot reach Git repo — verify repo credentials |
| `Degraded: Missing resource` | CRD or operator not installed — check `clusterGroup.subscriptions` |
| `Progressing` (stuck) | Resource creation timing — check sync wave ordering in charts |

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [Patternizer](patternizer.html) | Operational skill — use patternizer to initialize the pattern before this skill |
| [VP Refactor](vp-refactor.html) | Escalation target when deployment test finds convergence or config failures |
| [Student Readiness](student-readiness.html) | Called at end of Phase 4 for full environment readiness check |
| [Workshop Tester](workshop-tester.html) | Optional hand-off after all deployment tests pass |

See [ADR-015](../adrs/015-deployment-pipeline-testing.html) for the full design rationale.

## Install

```bash
./install.sh install --skill vp-deploy-test
```
