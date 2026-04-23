---
name: vp-deploy-validator
description: AI assistance for validating the health of an already-running Validated Pattern deployment — checking ArgoCD Application convergence, secrets delivery, and job completion without re-installing. Use when the pattern was deployed by automation or by someone else, or for a pre-demo confidence check on a live deployment.
related_skills: [vp-deploy-test, vp-refactor, student-readiness, workshop-tester, vp-submission]
---

# Validated Pattern Deployment Validator Skill

## When to Use

**Purpose:** Use this skill to build confidence that a live Validated Pattern deployment is healthy — that all ArgoCD Applications are converged, secrets are flowing, and jobs are complete — without triggering a reinstall. Passing all phases means an operator can run this pattern with limited or no issues.

- The pattern was deployed by CI/CD, automation, or another team member — you want to validate it without re-installing
- Pre-demo confidence check: verify the live deployment is healthy before running exercises
- After a values file update, chart version bump, or cluster upgrade — spot-check convergence without reinstalling
- Regular health monitoring of a running demo or workshop pattern
- After resolving a `vp-refactor` finding — confirm the fix took effect without a full reinstall

Use **vp-deploy-test** instead when you need to run the full install process from scratch and validate the result end-to-end.

Do NOT use this skill to install or reinstall a pattern — use the **vp-deploy-test** skill instead. Do NOT use this skill to audit pattern files — use the **vp-refactor** skill instead.

## Instructions

This skill defines a three-phase health check process. None of the phases install or modify the deployment — they only inspect the current state.

## Required Input

Before starting, collect:

| Input | Required | Example |
|-------|----------|---------|
| OpenShift cluster access | Yes | `oc login` token or kubeconfig path |
| Pattern name or ArgoCD namespace | Yes | `my-pattern`, `openshift-gitops` |
| Whether to check secrets (requires Vault access) | No — defaults to yes | `yes`, `no` |
| Whether the pattern has imperative jobs | No — defaults to auto-detect | `yes`, `no` |

---

## Phase 1 — Pre-flight

Verify access and that the VP stack is present before running health checks.

| Check | Command | Pass condition |
|-------|---------|---------------|
| OCP login | `oc whoami` | Returns a username |
| Cluster nodes healthy | `oc get nodes` | All nodes in `Ready` state |
| VP Operator present | `oc get csv -n openshift-operators \| grep patterns` | CSV in Succeeded state |
| OpenShift GitOps present | `oc get csv -n openshift-operators \| grep gitops` | CSV in Succeeded state |
| ArgoCD reachable | `oc get applications -n openshift-gitops` | Returns at least one Application |
| Non-interactive install | Inspect recent `pattern.sh` output or install log for interactive prompts | No TTY waits, `y/n` prompts, password requests, or kubeconfig selection prompts found |

If the VP Operator or ArgoCD is not present, stop and report:

```
Pre-flight FAILED: VP Operator or ArgoCD not found.
This cluster does not appear to have a Validated Pattern installed.
→ If you need to install one, use the vp-deploy-test skill.
```

If cluster nodes are not all Ready, record as a **cluster health** finding — this triggers the new cluster tracking path in the Destroy and Redeploy section.

If an interactive prompt is detected in the install log:

```
Pre-flight — SUBMISSION_BLOCKING: Non-interactive install failure
  pattern.sh make install required user interaction:
  <exact prompt text found>

  A Validated Pattern must deploy fully unattended to be accepted at any VP tier.
  This is a submission-blocking issue — the pattern cannot be submitted until resolved.

  Action: Remove all interactive prompts from pattern.sh, Makefiles, and any
  called scripts. Common causes:
  - `read` calls in shell scripts without a default value
  - `oc login` prompts (credentials must be pre-configured)
  - Helm `--set` prompts for missing values
  - kubectl/oc asking to confirm destructive operations

  After fixing: re-run vp-deploy-test to validate a clean unattended install.
```

Record this as a `SUBMISSION_BLOCKING` finding and continue the health check — the pattern may still be partially healthy even if the install was not fully unattended.

---

## Phase 2 — ArgoCD Application Health Scan

Check all ArgoCD Applications associated with the pattern for `Healthy/Synced` status.

```bash
oc get applications -n openshift-gitops \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.health.status}{"\t"}{.status.sync.status}{"\n"}{end}'
```

**Pass condition:** all Applications show `health: Healthy` and `sync: Synced`.

For any Application that is not Healthy/Synced, collect details:

```bash
oc describe application <app-name> -n openshift-gitops
```

Classify each failure:

| Symptom | Likely cause | Action |
|---------|-------------|--------|
| `SyncFailed: ComparedTo error` | Helm values rendering error | Escalate to **vp-refactor**, Audit Area 3 (Charts) |
| `OutOfSync: Unknown` | ArgoCD can't reach Git repo | Verify repo credentials and GitOps repo URL |
| `Degraded: Missing resource` | Operator subscription not resolving | Escalate to **vp-refactor**, Audit Area 1 (Values) |
| `Progressing` (stuck) | Resource creation in progress or timing issue | Wait 2 minutes and re-check; if still stuck, escalate to **vp-refactor** |

### Phase 2 Report

```
Validation — Phase 2: ArgoCD Application Health
──────────────────────────────────────────────────────
 Application                  Health      Sync        Notes
 <pattern>-hub                Healthy     Synced      —
 <pattern>-app1               Degraded    OutOfSync   Helm render error: missing ingress.host
──────────────────────────────────────────────────────
 Healthy/Synced: <N>/<N> Applications
```

---

## Phase 3 — Secrets and Jobs Health Scan

### 3a. Secrets delivery (Vault + ESO)

Check ExternalSecret resources across all namespaces:

```bash
oc get externalsecrets -A \
  -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.conditions[0].status,STATUS:.status.conditions[0].reason"
```

**Pass condition:** all ExternalSecrets show `READY=True` and `STATUS=SecretSynced`.

For any `SecretSyncedError`:
```bash
oc describe externalsecret <name> -n <namespace>
```

Common causes:
- Vault is not initialized or unsealed
- ESO SecretStore credentials are incorrect or expired
- The secret path in Vault does not match the ExternalSecret spec

### 3b. Imperative jobs

If the pattern has a `jobs/` directory or CronJobs in a dedicated namespace:

```bash
oc get cronjobs -A | grep -v kube
oc get jobs -A | grep -v kube
```

**Pass condition:** at least one completed Job per CronJob with `COMPLETIONS: 1/1`.

### 3c. Confidence chain hand-off

After secrets and jobs checks pass, the deployment is confirmed healthy. The next steps in the confidence chain:

```
All health checks passed.
→ Activate student-readiness to verify the student experience end-to-end.
→ Then activate workshop-tester to validate module exercises.
→ When workshop-tester passes: activate vp-submission to audit VP tier
  readiness and prepare the pattern for submission to validatedpatterns.io.
  These are the steps in building operator confidence and reaching submission.
```

### Phase 3 Report

```
Validation — Phase 3: Secrets and Jobs
──────────────────────────────────────────────────────
 Check                        Status   Notes
 ExternalSecret: <name>       PASS     SecretSynced
 ExternalSecret: <name>       FAIL     SecretSyncedError: Vault path not found
 CronJob: <name>              PASS     1/1 completed
──────────────────────────────────────────────────────
```

---

## Final Summary Report

```
Validated Pattern Health Check — Complete
══════════════════════════════════════════════════════
 Pattern:  <pattern-name>
 Cluster:  <api-url>

 Phase 1 — Pre-flight               PASS
 Phase 2 — ArgoCD Health            PASS / FAIL
   Applications healthy             <N>/<N>
 Phase 3 — Secrets and Jobs         PASS / FAIL
   ExternalSecrets                  <N>/<N> Ready
   CronJobs                         <N>/<N> completed
══════════════════════════════════════════════════════
 Overall: HEALTHY / NEEDS ATTENTION

 Confidence: HIGH — all health checks passed. An operator can run this
             pattern with limited or no issues.
             Next steps: student-readiness → workshop-tester → vp-submission
```

---

## Remediation Plan

When the overall result is **NEEDS ATTENTION**, generate an ordered, prioritized remediation plan from the actual failures found. Create each item as a session todo so progress is tracked.

| Priority | Condition | Action |
|----------|-----------|--------|
| BLOCKING | ArgoCD Application Degraded/OutOfSync — `SyncFailed` | Activate **vp-refactor**, Audit Area 1 (Values) and Area 3 (Charts) for the specific failing Application |
| HIGH | ArgoCD Application OutOfSync — Git repo unreachable | Verify ArgoCD repo credentials and GitOps repo URL |
| HIGH | ExternalSecret `SecretSyncedError` | Activate **vp-refactor**, Audit Area 4 (Secrets Management) |
| MEDIUM | Imperative CronJob not completing | Activate **vp-refactor**, Audit Area 8 (Imperative Jobs); check job logs |
| LOW | ArgoCD Application stuck `Progressing` | Wait 2 minutes and re-check; check sync wave ordering in charts |

Present the plan as an ordered list containing only the items that actually failed:

```
Health Check Remediation Plan — <pattern-name>
──────────────────────────────────────────────────────
Priority  #  Finding                                Action
BLOCKING  1  hub app SyncFailed (Helm render error) Activate vp-refactor → Audit Area 3
HIGH      2  db-creds SecretSyncedError             Activate vp-refactor → Audit Area 4
──────────────────────────────────────────────────────
Created 2 todos. Resolve in order — BLOCKING items first.
```

After presenting the plan, ask:
> "Would you like to start with item 1 now? (y/n)"

---

## Re-check After Fixes

After fixes are applied, re-run only the phases that contained failures. For ArgoCD issues, trigger a manual sync before re-checking rather than reinstalling:

```bash
oc patch application <app-name> -n openshift-gitops \
  --type merge -p '{"operation":{"sync":{}}}'
```

Show a before/after comparison:

```
Re-check Results — <pattern-name>
──────────────────────────────────────────────────────
 Item  Finding                         Previous   Now
 1     hub app SyncFailed              FAIL    →  PASS  ✓ resolved
 2     db-creds SecretSyncedError      FAIL    →  FAIL  still failing
──────────────────────────────────────────────────────
 Resolved: 1/2   Remaining: 1
```

Repeat until all items resolve, then present the final confidence statement: **HEALTHY — operator can run with high confidence.**

---

## Destroy and Redeploy Decision Gate

The remediation loop has a limit. After **two complete remediation cycles** (two rounds of `vp-refactor` escalation + re-check) with at least one BLOCKING failure still present, stop the remediation loop and activate the destroy-and-redeploy decision gate.

The gate also activates immediately if either of these is true:
- A `SUBMISSION_BLOCKING: Non-interactive install failure` finding was recorded in Phase 1
- The OCP cluster nodes are not all Ready (cluster health failure recorded in Phase 1)

### Decide: Pattern Problem or Cluster Problem?

Before destroying anything, determine the root cause:

```
Destroy-and-Redeploy Assessment — <pattern-name>
──────────────────────────────────────────────────────
 Remediation cycles completed: <N>
 Remaining BLOCKING failures:  <list>

 Is the cluster itself healthy?
   oc get nodes            → All Ready / NOT ALL READY
   oc get co               → All Available / DEGRADED

 Diagnosis:
   CLUSTER PROBLEM  — nodes not ready, operators degraded, API unstable
   PATTERN PROBLEM  — cluster healthy but pattern never converges
──────────────────────────────────────────────────────
```

Ask the user to confirm the diagnosis before proceeding.

### Path A — Pattern Problem (cluster is healthy)

The cluster is healthy but the pattern state is irrecoverable. Destroy the VP installation and redeploy from scratch on the same cluster.

**Confirm with the user before running any destructive command:**

```
Proposed action: destroy and redeploy the pattern on the existing cluster.
  This will delete all ArgoCD Applications, Helm releases, and namespaces
  created by the pattern. The cluster itself will remain.

Approve? (y/n)
```

If approved:

```bash
# Uninstall the pattern via VP Operator or pattern.sh
./pattern.sh make uninstall
# Verify ArgoCD Applications are removed
oc get applications -n openshift-gitops
# Redeploy from scratch
→ Activate vp-deploy-test to run a fresh install and validate end-to-end.
```

### Path B — Cluster Problem (nodes not ready or API unstable)

The OCP cluster itself is unhealthy and cannot host a reliable pattern deployment. Track a replacement cluster.

**Confirm with the user before any cluster action:**

```
Proposed action: provision a replacement OCP cluster and re-run vp-deploy-test on it.
  The current cluster will not be destroyed unless you explicitly request it.

Replacement cluster options:
  (A) Provision a new cluster via AgnosticD — activate agnosticd-deploy-test
  (B) Provision via ROSA/ARO/ROKS (managed OpenShift)
  (C) Use an existing cluster at a different API URL

Which path? (A/B/C)
```

**Tracking the new cluster:**

Once a replacement cluster is confirmed, record it as a session variable:

```
New cluster target:
  API URL:     <new-api-url>
  Kubeconfig:  <path>
  Status:      PROVISIONING / READY

→ When cluster is Ready: activate vp-deploy-test with the new cluster context.
→ After vp-deploy-test passes: re-run vp-deploy-validator on the new cluster.
```

---

## Escalation

- **ArgoCD Application Degraded/OutOfSync** → Use the **vp-refactor** skill to audit values files and chart structure
- **ExternalSecret errors** → Use the **vp-refactor** skill, Audit Area 4 (Secrets Management)
- **Imperative jobs failing** → Use the **vp-refactor** skill, Audit Area 8 (Imperative Jobs)
- **VP Operator not present** → The pattern is not installed — use the **vp-deploy-test** skill to install and validate
- **Health checks pass but student experience broken** → Activate the **student-readiness** skill for student-perspective checks
- **BLOCKING failures persist after two remediation cycles** → Activate the **Destroy and Redeploy** decision gate above
- **Non-interactive install failure** → Fix all interactive prompts, then use **vp-deploy-test** to validate a clean unattended install
- **All checks pass** → Activate **vp-submission** to audit VP tier readiness and guide submission to validatedpatterns.io
