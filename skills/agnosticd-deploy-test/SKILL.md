---
name: agnosticd-deploy-test
description: AI assistance for validating an AgnosticD v2 deployment end-to-end — verifying provisioning completed cleanly, all workloads are running, agnosticd_user_info data is flowing, and the stop/start/status lifecycle works. Use after agd provision completes, before running student-readiness checks.
related_skills: [agnosticd, agnosticd-refactor, student-readiness, workshop-tester]
---

# AgnosticD Deployment Tester Skill

## When to Use

- After `agd provision` completes and you want to verify the deployment is fully healthy
- Workloads appear to have deployed but you're not sure all are running correctly
- `agnosticd_user_info` data is missing from the RHDP catalog or Showroom
- The stop/start lifecycle has never been tested for this config
- Before running student-readiness or handing the environment to students
- After fixing an `agnosticd-refactor` audit finding and re-deploying

Do NOT use this skill to set up AgnosticD v2 from scratch — use the **agnosticd** skill instead. Do NOT use this skill to audit config files without a live deployment — use the **agnosticd-refactor** skill instead.

## Instructions

This skill defines a four-phase process. Work through the phases in order. Do not proceed to the next phase if the current phase has unresolved failures.

## Required Input

Before starting, collect:

| Input | Required | Example |
|-------|----------|---------|
| GUID of the deployed instance | Yes | `abc12` |
| Config name | Yes | `my-workshop` |
| Cloud provider | Yes | `aws`, `azure`, `openstack` |
| Path to vars file | Yes | `agnosticd-v2-vars/my-workshop.yaml` |
| AgnosticD v2 root directory | Yes | `~/Development/agnosticd-v2/` |
| Whether to run lifecycle test | No — defaults to yes | `yes`, `no` |

---

## Phase 1 — Pre-flight

Verify the local environment is ready before running any `agd` commands.

| Check | Command | Pass condition |
|-------|---------|---------------|
| Python version | `python3 --version` | Returns 3.12 or higher |
| Podman available | `podman --version` | Exits 0 |
| Virtualenv present | `ls agnosticd-v2-virtualenv/` | Directory exists |
| agd CLI reachable | `./bin/agd --help` | Exits 0 (from within `agnosticd-v2/`) |
| Vars file exists | `ls <vars-file-path>` | File exists |
| Secrets file exists | `ls agnosticd-v2-secrets/secrets.yml` | File exists |

If any pre-flight check fails, stop and provide the corrective action. Do not proceed to Phase 2.

---

## Phase 2 — Provision

Run `agd provision` and capture the result.

```bash
cd ~/Development/agnosticd-v2
./bin/agd provision --config <config-name> --vars <vars-file>
```

Capture:
- Exit code (0 = success, non-zero = failure)
- The GUID assigned to this deployment
- Any ERROR or FAILED lines in the Ansible output

**If provisioning fails:**

```
Deployment Test — Phase 2: Provision FAILED
  Config:    <config-name>
  GUID:      <guid>
  Exit code: <N>
  Error:     <last ERROR line from output>

Next step: activate agnosticd-refactor to audit the config structure.
  Common causes:
  - Missing required variables in the vars file
  - Workload role not found (check workloads: list in vars)
  - Cloud credentials not present or expired in secrets.yml
  - Playbook file missing from ansible/configs/<config-name>/
```

Stop and report. Do not proceed until the user has resolved the failure and re-provisioned.

**If provisioning succeeds:** proceed to Phase 3.

---

## Phase 3 — Post-deploy Validation

With the GUID confirmed, verify that the deployment is functionally complete.

### 3a. Workload completion check

Scan the provision output for each workload role listed in the vars file. Confirm each role completed with no FAILED tasks:

```bash
grep -E "(FAILED|ERROR|fatal)" agnosticd-v2-output/<guid>/*/ansible.log
```

Report any failed workloads:

```
Workload failures found:
  ocp4_workload_showroom    FAILED  — task: Deploy Showroom Helm release
  ocp4_workload_cert_manager PASS
```

### 3b. agnosticd_user_info verification

Check that `agnosticd_user_info` data was written to the output:

```bash
grep -r "agnosticd_user_info" agnosticd-v2-output/<guid>/
```

Expected: at least one entry showing the user data keys (e.g., `openshift_console_url`, `openshift_cluster_admin_password`, Showroom URL if deployed).

If no `agnosticd_user_info` output is found, note it as a finding but do not stop — record it in the Phase 3 report.

> (RESEARCH NEEDED — RQ-4: What exact output format and keys does agnosticd_user_info produce, and where in the output directory is it written?)

### 3c. Student-readiness hand-off

After workload and data checks, activate the **student-readiness** skill to verify the deployed environment from the student's perspective:

```
Phase 3 checks passed. Activating student-readiness for environment validation.
→ Use the student-readiness skill with GUID: <guid>
```

If student-readiness fails:

```
student-readiness reported failures. Likely causes:
  - A workload role partially deployed (check 3a findings)
  - agnosticd_user_info is missing required keys for Showroom attribute injection
  → Escalate to agnosticd-refactor: use the agnosticd-refactor skill to audit the config
```

### Phase 3 Report

```
Deployment Test — Phase 3: Post-deploy Validation
──────────────────────────────────────────────────────
 Config:    <config-name>
 GUID:      <guid>
 Provider:  <cloud-provider>

 Check                        Status   Notes
 Provision exit code          PASS     —
 Workload: <role-1>           PASS     —
 Workload: <role-2>           FAIL     FAILED task: Deploy Showroom Helm release
 agnosticd_user_info output   PASS     Keys: console_url, admin_password, showroom_url
 student-readiness            PASS     —
──────────────────────────────────────────────────────
 Overall: PASS / FAIL
```

---

## Phase 4 — Lifecycle Test

> (RESEARCH NEEDED — RQ-5: What are the exact playbook names and locations for stop/start/status lifecycle operations, and what does each return for AWS EC2 environments?)

Test the stop/start/status lifecycle operations. This phase is optional — skip if the user confirmed `lifecycle test: no` in Required Input, or if Phase 3 failed.

```bash
# Stop
./bin/agd stop --config <config-name> --vars <vars-file>
# Verify: cluster/VMs are stopped, no running EC2 instances for this GUID

# Start
./bin/agd start --config <config-name> --vars <vars-file>
# Verify: cluster/VMs restart successfully, routes accessible again

# Status
./bin/agd status --config <config-name> --vars <vars-file>
# Verify: reports correct state
```

For each operation, capture exit code and any ERROR lines.

**Current partial guidance:**

The stop/start lifecycle is required for RHDP cost management — environments that cannot be stopped and resumed will not pass RHDP review. Stop should power down all cloud VMs without destroying the cluster state. Start should bring everything back to a running state. Status should report the current power state.

### Phase 4 Report

```
Deployment Test — Phase 4: Lifecycle Test
──────────────────────────────────────────────────────
 Operation   Exit Code   Status   Notes
 agd stop    0           PASS     —
 agd start   0           PASS     —
 agd status  0           PASS     Reported: running
──────────────────────────────────────────────────────
 Lifecycle: PASS / FAIL
```

**After lifecycle passes:** optionally activate workshop-tester:

```
All deployment tests passed.
→ Optionally activate workshop-tester to run module exercises against this environment.
```

---

## Final Summary Report

```
AgnosticD Deployment Test — Complete
══════════════════════════════════════════════════════
 Config:    <config-name>    GUID: <guid>
 Provider:  <cloud-provider>

 Phase 1 — Pre-flight          PASS
 Phase 2 — Provision           PASS
 Phase 3 — Post-deploy         PASS / FAIL
   Workloads                   <N>/<N> passed
   agnosticd_user_info         PASS / MISSING
   student-readiness           PASS / FAIL
 Phase 4 — Lifecycle           PASS / FAIL / SKIPPED
══════════════════════════════════════════════════════
 Overall: READY FOR STUDENTS / NEEDS ATTENTION
```

---

## Remediation Plan

When the overall result is **NEEDS ATTENTION**, generate an ordered, prioritized remediation plan from the actual failures found. Create each item as a session todo so progress is tracked.

Prioritize in this order:

| Priority | Condition | Action |
|----------|-----------|--------|
| BLOCKING | Provision failed (Phase 2) | Activate **agnosticd-refactor** to audit config structure and required variables before re-provisioning |
| BLOCKING | Workload role FAILED (Phase 3) | Activate **agnosticd-refactor**, Audit Area 3 (Workload Role Structure) for the specific failing role |
| HIGH | `agnosticd_user_info` missing (Phase 3) | Activate **agnosticd-refactor**, Audit Area 4 — data pipeline not wired |
| HIGH | student-readiness failed (Phase 3) | Work through student-readiness troubleshooting tree; escalate to **agnosticd-refactor** if root cause is config |
| MEDIUM | Lifecycle `agd stop` failed (Phase 4) | Verify `stop.yml` exists in `ansible/configs/<config-name>/` and cloud credentials are current |
| MEDIUM | Lifecycle `agd start` failed (Phase 4) | Verify `start.yml` exists and inspect the start playbook output for FAILED tasks |
| LOW | Lifecycle `agd status` failed (Phase 4) | Verify `status.yml` exists; status failure alone does not block student readiness |

Present the plan as an ordered list containing only the items that actually failed:

```
Deployment Remediation Plan — <config-name> / <guid>
──────────────────────────────────────────────────────
Priority  #  Finding                           Action
BLOCKING  1  ocp4_workload_showroom FAILED     Activate agnosticd-refactor → Audit Area 3
HIGH      2  agnosticd_user_info missing       Activate agnosticd-refactor → Audit Area 4
MEDIUM    3  agd stop failed (exit 1)          Check stop.yml in ansible/configs/<name>/
──────────────────────────────────────────────────────
Created 3 todos. Resolve in order — BLOCKING items first.
```

After presenting the plan, ask:
> "Would you like to start with item 1 now? (y/n)"

If yes, activate the indicated skill immediately.

---

## Re-test After Fixes

After the developer resolves one or more items from the remediation plan, re-run only the phases that contained failures rather than a full end-to-end test:

```
Re-running failed phases only:
  Phase 3 (Post-deploy validation) — re-checking workloads and agnosticd_user_info
  Phase 4 (Lifecycle) — re-testing agd stop/start/status

Skipping Phase 1 (pre-flight passed) and Phase 2 (provision succeeded).
```

Compare results against the previous run and show which items were resolved:

```
Re-test Results — <config-name> / <guid>
──────────────────────────────────────────────────────
 Item  Finding                        Previous   Now
 1     ocp4_workload_showroom         FAILED  →  PASS  ✓ resolved
 2     agnosticd_user_info            MISSING →  PASS  ✓ resolved
 3     agd stop                       FAILED  →  FAIL  still failing
──────────────────────────────────────────────────────
 Resolved: 2/3   Remaining: 1
```

Repeat until all items resolve, then present the full Final Summary Report as READY FOR STUDENTS.

---

## Escalation

- **Provision failure or workload failure** → Use the **agnosticd-refactor** skill to audit the config structure, required variables, and workload role layout
- **student-readiness failures after successful provision** → Use the **student-readiness** skill's troubleshooting decision tree; if the root cause is in the config, escalate to **agnosticd-refactor**
- **Lifecycle failures (stop/start/status)** → Check that stop/start playbooks exist in `ansible/configs/<config-name>/` and that the cloud provider credentials are current
- **agnosticd_user_info data missing** → The workload role is not calling `agnosticd_user_info` correctly; use **agnosticd-refactor** Audit Area 4 once RQ-4 is resolved
