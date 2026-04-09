---
name: vp-deploy-test
description: AI assistance for validating a Validated Pattern deployment end-to-end — verifying VP Operator installation, ArgoCD Application convergence, secrets delivery via Vault and ESO, and imperative job completion. Use after pattern.sh make install or VP Operator install, before running student-readiness checks.
related_skills: [patternizer, vp-refactor, student-readiness, workshop-tester, vp-deploy-validator]
---

# Validated Pattern Deployment Tester Skill

## When to Use

**Purpose:** Use this skill to build confidence that the Validated Pattern deployment is sound — that installation succeeded, all Applications converged, secrets are flowing, and jobs completed — before handing the environment to students or running `workshop-tester`. Passing all phases means an operator can run this pattern with limited or no issues.

- After `pattern.sh make install` or VP Operator installation completes and you want to verify the pattern is fully deployed
- ArgoCD Applications were created but you're not sure all are Healthy/Synced
- Secrets are not reaching application pods (ESO or Vault issues)
- Imperative jobs in the `jobs/` directory have not run or are failing
- Before running student-readiness or handing the environment to students
- After fixing a `vp-refactor` audit finding and re-deploying

Do NOT use this skill to initialize a new pattern from scratch — use the **patternizer** skill instead. Do NOT use this skill to audit pattern files without a live deployment — use the **vp-refactor** skill instead. To check an already-running deployment without re-installing, use the **vp-deploy-validator** skill instead.

## Instructions

This skill defines a four-phase process. Work through the phases in order. Do not proceed to the next phase if the current phase has unresolved failures.

## Required Input

Before starting, collect:

| Input | Required | Example |
|-------|----------|---------|
| Pattern repository path or URL | Yes | `~/my-pattern/` or GitHub URL |
| Cluster group name | Yes | `hub`, `datacenter` |
| OpenShift cluster access | Yes | `oc login` token or kubeconfig path |
| Installation method | Yes | `operator` or `cli` (`pattern.sh`) |
| Operators the pattern installs | Yes | ACM, OpenShift GitOps, cert-manager |
| Whether the pattern has a workshop | No — defaults to no | `yes`, `no` |

---

## Phase 1 — Pre-flight

Verify the cluster and pattern repo are ready before installing.

| Check | Command | Pass condition |
|-------|---------|---------------|
| OCP login | `oc whoami` | Returns a username |
| Cluster version | `oc version` | 4.12 or higher (VP minimum) |
| OpenShift GitOps installed | `oc get csv -n openshift-operators \| grep gitops` | CSV in Succeeded state |
| VP Operator installed | `oc get csv -n openshift-operators \| grep patterns` | CSV in Succeeded state (operator install method) |
| values-global.yaml present | `ls values-global.yaml` | File exists |
| values-<cluster>.yaml present | `ls values-<cluster-group>.yaml` | File exists |
| values-secret.yaml NOT in git | `git status values-secret.yaml` | Not tracked / in .gitignore |
| values-secret.yaml present locally | `ls values-secret.yaml` | File exists (outside git) |

If `values-secret.yaml` is tracked by git, stop immediately:

```
CRITICAL: values-secret.yaml is committed to git.
This file contains secrets and must never be committed.
→ Remove it from git history before proceeding:
  git rm --cached values-secret.yaml
  echo "values-secret.yaml" >> .gitignore
  git commit -m "remove secrets from git"
```

If any other pre-flight check fails, stop and provide the corrective action. Do not proceed to Phase 2.

---

## Phase 2 — Install

Run the pattern installation and capture the result.

**CLI install:**
```bash
cd ~/my-pattern
./pattern.sh make install
```

**VP Operator install:**

Confirm the operator has picked up the GitOps repo:
```bash
oc get pattern -n openshift-operators
```

Expected: a Pattern CR exists and shows the target GitOps repo URL.

Capture:
- Exit code for CLI install (0 = success, non-zero = failure)
- Whether the ArgoCD ApplicationSet was created

```bash
oc get applicationset -n openshift-gitops
```

**If install fails:**

```
Deployment Test — Phase 2: Install FAILED
  Pattern:   <pattern-name>
  Method:    <cli|operator>
  Exit code: <N>
  Error:     <last error line>

Next step: activate vp-refactor to audit the pattern structure.
  Common causes:
  - main.clusterGroupName in values-global.yaml does not match a values-<name>.yaml filename
  - values-<cluster>.yaml missing clusterGroup.applications or namespaces blocks
  - pattern-metadata.yaml missing or malformed
  - OpenShift GitOps not installed before pattern.sh make install
```

Stop and report. Do not proceed until the user has resolved the failure and re-installed.

---

## Phase 3 — ArgoCD Convergence

After the ApplicationSet is created, poll until all ArgoCD Applications reach `Healthy/Synced`. VP deployments are async — convergence may take several minutes.

```bash
# List all Applications created by this pattern
oc get applications -n openshift-gitops

# Check for any not Healthy/Synced
oc get applications -n openshift-gitops \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.health.status}{"\t"}{.status.sync.status}{"\n"}{end}'
```

Poll every 30 seconds, up to 10 minutes. Report status at each interval.

**Convergence success criteria:**
- All Applications show `health: Healthy` and `sync: Synced`

**If convergence fails (timeout or Degraded/OutOfSync):**

For each failing Application, collect:
```bash
oc describe application <app-name> -n openshift-gitops
```

Classify the failure:

| Symptom | Likely cause | Action |
|---------|-------------|--------|
| `SyncFailed: ComparedTo error` | Helm values rendering error | Check values file structure → escalate to **vp-refactor** |
| `OutOfSync: Unknown` | ArgoCD can't reach Git repo | Check repo credentials in ArgoCD → verify GitOps repo URL |
| `Degraded: Missing resource` | Chart missing a required CRD or operator | Check `clusterGroup.subscriptions` in values file |
| `Degraded: OperatorNotInstalled` | OLM subscription not resolving | Verify catalog source and package name → escalate to **vp-refactor** |
| `Progressing` (stuck) | Resource creation timing issue | Check sync wave ordering in charts |

```
Deployment Test — Phase 3: ArgoCD Convergence FAILED
  Application:  <app-name>
  Health:       Degraded
  Sync:         OutOfSync
  Reason:       <ArgoCD error message>

Next step: activate vp-refactor to audit values files and chart structure.
```

### Phase 3 Convergence Report

```
Deployment Test — Phase 3: ArgoCD Convergence
──────────────────────────────────────────────────────
 Application                  Health      Sync        Notes
 <pattern>-hub                Healthy     Synced      —
 <pattern>-acm                Healthy     Synced      —
 <pattern>-app1               Degraded    OutOfSync   Helm render error: missing ingress.host
──────────────────────────────────────────────────────
 Converged: <N>/<N> Applications
```

---

## Phase 4 — Secrets and Jobs Verification

After convergence, verify that secrets are flowing and imperative jobs have run.

### 4a. Secrets delivery (Vault + ESO)

Check ExternalSecret resources are in `Ready` state:

```bash
oc get externalsecrets -A
```

Expected: all ExternalSecrets show `READY=True` and `STATUS=SecretSynced`.

If any ExternalSecret shows `SecretSyncedError`:
```bash
oc describe externalsecret <name> -n <namespace>
```

Common causes:
- Vault is not initialized or unsealed
- ESO SecretStore credentials are incorrect
- The secret path in Vault does not match the ExternalSecret spec

### 4b. Imperative jobs

If the pattern has a `jobs/` directory, check that CronJobs have completed at least one successful run:

```bash
oc get cronjobs -n <imperative-namespace>
oc get jobs -n <imperative-namespace>
```

Expected: at least one Job per CronJob with `COMPLETIONS: 1/1`.

If jobs are not running or failing:
- Verify the CronJob schedule is not `never` (patterns sometimes use `@once` for bootstrap jobs)
- Check job logs: `oc logs job/<job-name> -n <namespace>`

### 4c. Student-readiness hand-off

After secrets and jobs checks pass, activate the **student-readiness** skill:

```
Phase 4 checks passed. Activating student-readiness for environment validation.
→ Use the student-readiness skill with cluster: <api-url>
```

If student-readiness fails:
```
student-readiness reported failures. Likely causes:
  - An Application converged but its workload pods are CrashLooping
  - A secret was not delivered to the expected namespace
  → Escalate to vp-refactor to audit the values files and chart structure
```

### Phase 4 Report

```
Deployment Test — Phase 4: Secrets and Jobs
──────────────────────────────────────────────────────
 Check                        Status   Notes
 ExternalSecret: <name>       PASS     SecretSynced
 ExternalSecret: <name>       FAIL     SecretSyncedError: Vault path not found
 CronJob: <name>              PASS     1/1 completed
 student-readiness            PASS     —
──────────────────────────────────────────────────────
```

**After all Phase 4 checks pass:** the deployment is confirmed sound. The next step in the confidence chain is `workshop-tester`:

```
All deployment tests passed.
→ Activate workshop-tester to validate module exercises against this environment.
  This is the next step in building operator confidence before going live.
```

---

## Final Summary Report

```
Validated Pattern Deployment Test — Complete
══════════════════════════════════════════════════════
 Pattern:  <pattern-name>
 Cluster:  <api-url>
 Method:   <cli|operator>

 Phase 1 — Pre-flight          PASS
 Phase 2 — Install             PASS
 Phase 3 — ArgoCD Convergence  PASS / FAIL
   Applications converged      <N>/<N>
 Phase 4 — Secrets and Jobs    PASS / FAIL
   ExternalSecrets             <N>/<N> Ready
   CronJobs                    <N>/<N> completed
   student-readiness           PASS / FAIL
══════════════════════════════════════════════════════
 Overall: READY FOR STUDENTS / NEEDS ATTENTION

 Confidence: HIGH — all phases passed. An operator can run this pattern
             with limited or no issues.
             Next step: run workshop-tester to validate module exercises.
```

---

## Remediation Plan

When the overall result is **NEEDS ATTENTION**, generate an ordered, prioritized remediation plan from the actual failures found. Create each item as a session todo so progress is tracked.

Prioritize in this order:

| Priority | Condition | Action |
|----------|-----------|--------|
| BLOCKING | `values-secret.yaml` committed to git (Phase 1) | Remove from git history immediately — do not proceed until resolved |
| BLOCKING | Install failed / ApplicationSet not created (Phase 2) | Activate **vp-refactor** to audit values files, chart structure, and `pattern-metadata.yaml` |
| BLOCKING | ArgoCD Application Degraded/OutOfSync — `SyncFailed` (Phase 3) | Activate **vp-refactor**, Audit Area 1 (Values) and Area 3 (Charts) for the specific failing Application |
| HIGH | ArgoCD Application OutOfSync — Git repo unreachable (Phase 3) | Verify ArgoCD repo credentials and GitOps repo URL in the pattern CR |
| HIGH | ExternalSecret `SecretSyncedError` (Phase 4) | Activate **vp-refactor**, Audit Area 4 (Secrets Management); check Vault path and ESO SecretStore credentials |
| HIGH | student-readiness failed (Phase 4) | Work through student-readiness troubleshooting tree; escalate to **vp-refactor** if root cause is in the pattern |
| MEDIUM | Imperative CronJob not completing (Phase 4) | Activate **vp-refactor**, Audit Area 8 (Imperative Jobs); check job logs |
| LOW | ArgoCD Application stuck `Progressing` (Phase 3) | Check sync wave ordering in charts; may resolve with a manual ArgoCD sync retry |

Present the plan as an ordered list containing only the items that actually failed:

```
Deployment Remediation Plan — <pattern-name>
──────────────────────────────────────────────────────
Priority  #  Finding                                Action
BLOCKING  1  hub app SyncFailed (Helm render error) Activate vp-refactor → Audit Area 3
HIGH      2  ExternalSecret db-creds SecretSyncedError  Activate vp-refactor → Audit Area 4
MEDIUM    3  CronJob bootstrap-job not completing   Check job logs, vp-refactor Audit Area 8
──────────────────────────────────────────────────────
Created 3 todos. Resolve in order — BLOCKING items first.
```

After presenting the plan, ask:
> "Would you like to start with item 1 now? (y/n)"

If yes, activate the indicated skill immediately.

---

## Re-test After Fixes

After the developer resolves one or more items from the remediation plan, re-run only the phases that contained failures rather than a full reinstall:

```
Re-running failed phases only:
  Phase 3 (ArgoCD convergence) — re-checking Application health after Helm fix
  Phase 4 (Secrets and jobs) — re-checking ExternalSecrets and CronJobs

Skipping Phase 1 (pre-flight passed) and Phase 2 (install succeeded).
```

For ArgoCD re-checks, trigger a manual sync first rather than re-installing:

```bash
argocd app sync <app-name> --server <argocd-url>
# or
oc patch application <app-name> -n openshift-gitops \
  --type merge -p '{"operation":{"sync":{}}}'
```

Compare results against the previous run and show which items were resolved:

```
Re-test Results — <pattern-name>
──────────────────────────────────────────────────────
 Item  Finding                         Previous   Now
 1     hub app SyncFailed              FAIL    →  PASS  ✓ resolved
 2     db-creds SecretSyncedError      FAIL    →  FAIL  still failing
 3     bootstrap-job not completing    FAIL    →  PASS  ✓ resolved
──────────────────────────────────────────────────────
 Resolved: 2/3   Remaining: 1
```

Repeat until all items resolve, then present the full Final Summary Report as READY FOR STUDENTS.

---

## Escalation

- **Install failure or ApplicationSet not created** → Use the **vp-refactor** skill to audit values files, chart structure, and pattern-metadata.yaml
- **ArgoCD Application Degraded/OutOfSync** → Use the **vp-refactor** skill, Audit Area 3 (Charts Directory) and Audit Area 1 (Values File Completeness)
- **ExternalSecret errors (Vault/ESO)** → Use the **vp-refactor** skill, Audit Area 4 (Secrets Management)
- **Imperative jobs failing** → Use the **vp-refactor** skill, Audit Area 8 (Imperative Jobs)
- **student-readiness failures after successful convergence** → Use the **student-readiness** skill's troubleshooting decision tree; if the root cause is in the pattern, escalate to **vp-refactor**
