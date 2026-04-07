---
title: AgnosticD Deploy Test
parent: Skills
nav_order: 10
---

# AgnosticD Deployment Tester Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The AgnosticD Deployment Tester skill guides the AI assistant through validating an AgnosticD v2 deployment end-to-end after `agd provision` completes. It fills the gap between running the deployment command and confirming the environment is fully operational.

While `student-readiness` checks whether the *environment* is ready for students right now, this skill validates whether the *deployment pipeline itself* — provisioning, workload completion, `agnosticd_user_info` data flow, and the stop/start lifecycle — produced a correct, fully-working result.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "did my deployment work correctly?" or "are all my workloads running?"
- Checking whether `agnosticd_user_info` data is flowing to RHDP catalog or Showroom
- Testing the stop/start lifecycle for the first time after a new config is deployed
- Preparing to hand an environment to students and want full end-to-end confidence
- Re-verifying after fixing an `agnosticd-refactor` audit finding and re-provisioning

## Four-Phase Process

```
Phase 1 — Pre-flight
  Verify Python 3.12+, podman, virtualenv, agd CLI, vars file, secrets file

Phase 2 — Provision
  Run agd provision, capture exit code and GUID
  Stop and escalate to agnosticd-refactor on failure

Phase 3 — Post-deploy Validation
  Verify all workload roles completed without FAILED tasks
  Verify agnosticd_user_info data is present in output
  → Activate student-readiness for environment check
  → Escalate to agnosticd-refactor if student-readiness fails

Phase 4 — Lifecycle Test
  agd stop → agd start → agd status
  Confirm lifecycle operations succeed
  → Optionally activate workshop-tester when complete
```

## Failure Escalation

When the deployment test finds failures, the skill provides a structured escalation path:

| Failure | Escalation |
|---------|-----------|
| Provision fails (non-zero exit) | Activate **agnosticd-refactor** to audit config structure |
| Workload role FAILED | Activate **agnosticd-refactor**, Audit Area 3 (Workload Role Structure) |
| agnosticd_user_info missing | Activate **agnosticd-refactor**, Audit Area 4 (agnosticd_user_info) |
| student-readiness fails | Use student-readiness troubleshooting tree; escalate to agnosticd-refactor |
| Lifecycle (stop/start) fails | Check stop/start playbooks exist in `ansible/configs/<name>/` |

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [AgnosticD v2](agnosticd.html) | Operational skill — use agnosticd to set up and run `agd provision` before this skill |
| [AgnosticD Refactor](agnosticd-refactor.html) | Escalation target when deployment test finds config failures |
| [Student Readiness](student-readiness.html) | Called at end of Phase 3 for full environment readiness check |
| [Workshop Tester](workshop-tester.html) | Optional hand-off after all deployment tests pass |

See [ADR-015](../adrs/015-deployment-pipeline-testing.html) for the full design rationale.

## Install

```bash
./install.sh install --skill agnosticd-deploy-test
```
