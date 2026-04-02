---
name: workshop-tester
description: AI-as-student module testing — reads a workshop module (AsciiDoc or markdown), executes each student step against a live environment, verifies expected outcomes, classifies failures, and produces a step-by-step pass/fail report. Use when a developer asks to run through, test, or validate workshop exercises.
related_skills: [student-readiness, showroom, agnosticd]
---

# Workshop Module Tester Skill

## When to Use

- Developer asks "run through this module against the environment"
- Testing or validating workshop exercises on a live deployment
- Verifying that module steps work before handing a lab to students
- Running a specific sub-module to check for instruction or infrastructure issues
- Re-testing after fixes to confirm issues are resolved
- Comparing test results across multiple test runs to track progress

## Instructions

This skill defines a diagnostic process, not a tool wrapper. When activated, gather the required input, parse the target module for executable steps, run each step against the live environment, classify any failures, and produce a structured report.

## Required Input

Before running tests, collect the following from the user:

| Input | Required | Example |
|-------|----------|---------|
| Module file path or Showroom content repo | Yes | `content/modules/ROOT/pages/module-02.adoc` |
| Access credentials | Yes | OCP token, SSH key, or AAP token |
| Workshop GUID | Yes | `abc123` |
| Which module(s) to test | Yes | `module-02` or `all` |
| OpenShift API URL | Yes (OCP) | `https://api.cluster.example.com:6443` |
| Bastion hostname | If RHEL VM or dedicated OCP | `bastion.abc123.example.com` |

## Step Parsing

### Showroom AsciiDoc (primary format)

Showroom labs use AsciiDoc with special role attributes to distinguish executable steps from informational content.

**Executable steps** — extract these and run them:
```asciidoc
[source,bash,role="execute"]
----
oc new-project myapp
----
```

**Copy-paste text** — do NOT execute, but note for context:
```asciidoc
[source,yaml,role="copypaste"]
----
apiVersion: v1
kind: ConfigMap
...
----
```

**Verification sections** — execute after the preceding step and compare output:
```asciidoc
.Expected output
[source,text]
----
NAME    READY   STATUS    RESTARTS   AGE
myapp   1/1     Running   0          30s
----
```

### Standard Markdown

- Extract fenced code blocks tagged as `bash` or `shell` — these are executable
- Skip blocks tagged as `yaml`, `json`, `text`, or `output` — informational only
- Identify sections titled "Verify", "Expected output", or "Check" as verification steps

### Parsing Rules

1. Process the module top-to-bottom in document order
2. Track state: which project/namespace is active, what variables have been set
3. Substitute AsciiDoc attributes from `antora.yml` (e.g., `{openshift_cluster_ingress_domain}`) with actual values from the environment
4. If a step references a file from the `examples/` directory, verify the file exists before executing

## Execution Process

### 1. Pre-flight: Run Student Readiness Checks

Before testing any module steps, run the **student-readiness** skill to verify the environment is functional. If readiness checks fail, stop and report — there's no point testing module steps on a broken environment.

```
student-readiness PASS → proceed to module testing
student-readiness FAIL → stop, report readiness failure, suggest fixes
```

### 2. Execute Each Step

For each parsed executable step:

1. **Show** the step number, description, and command to the user
2. **Execute** the command against the live environment (via `oc`, `curl`, `ssh`, etc.)
3. **Capture** stdout, stderr, and exit code
4. **Verify** — if a verification section follows, execute it and compare actual vs. expected output
5. **Record** the result: PASS, FAIL, or SKIP

### 3. Handle Failures

When a step fails:

1. **Classify** the failure (see Failure Classification below)
2. **Pause** and report the failure to the user
3. **Ask** whether to continue testing remaining steps or stop
4. If continuing, mark dependent steps as SKIP (steps that rely on the failed step's output)

## Failure Classification

When a step fails, analyze the error and categorize it:

| Category | Meaning | Examples | Action |
|----------|---------|----------|--------|
| **Instruction Fix** | The module text is wrong but the env is fine | Typo in command, wrong path, outdated CLI flag, missing `--namespace`, copy-paste error in expected output | Update the .adoc/.md file |
| **Infra / Deployment Fix** | The environment or deployment pipeline is misconfigured | Operator not installed, RBAC missing, route not created, resource quota hit, image pull error, Helm values wrong, ArgoCD Application stuck in OutOfSync/Degraded, ArgoCD can't reach Git repo, Helm template rendering error, sync wave ordering issue | Fix the AgnosticD config, workload variables, Helm values, or ArgoCD Application spec |
| **Rethink** | The exercise design itself is flawed | Step depends on output of a skipped step, assumes prior knowledge not covered, timing issue (resource not ready yet), concept doesn't work as described | Redesign the module flow or add prerequisites |

### Classification Heuristics

Use these patterns to guide classification:

- **Command not found** / syntax error → **Instruction Fix** (wrong command in the module)
- **Permission denied** / forbidden / unauthorized → **Infra / Deployment Fix** (RBAC not configured)
- **Resource not found** but command is valid → **Infra / Deployment Fix** (workload not deployed) or **Rethink** (wrong step order)
- **Timeout** / not ready → **Rethink** (add wait/retry instruction) or **Infra / Deployment Fix** (resource never deployed)
- **Output doesn't match expected** → **Instruction Fix** (outdated expected output) or **Rethink** (exercise assumption wrong)
- **ArgoCD Application Degraded/OutOfSync** → **Infra / Deployment Fix** (check ArgoCD app spec, Helm values, Git repo access)
- **Helm render error** / values mismatch → **Infra / Deployment Fix** (wrong values.yaml, missing chart dependency)
- **GitOps repo auth failure** / branch not found → **Infra / Deployment Fix** (ArgoCD repo credentials or target revision)

When classification is ambiguous, flag it with `[uncertain]` and explain the reasoning.

## Output Format

Present results as a structured report:

```
Module Test Report — module-02.adoc — GUID: abc123
──────────────────────────────────────────────────────────
 #  Step                    Status  Category              Notes
 1  oc login                PASS    —                     —
 2  oc new-project myapp    PASS    —                     —
 3  oc apply -f deploy.yml  FAIL    Instruction Fix       File path wrong: deploy.yml not in examples/
 4  curl app route          SKIP    —                     Skipped (depends on #3)
 5  oc get pods             FAIL    Infra/Deploy Fix      Operator CSV pending: openshift-gitops
 6  argocd app sync myapp   FAIL    Infra/Deploy Fix      ArgoCD app Degraded: Helm values missing ingress.host
──────────────────────────────────────────────────────────
 Result: 2 PASS, 3 FAIL, 1 SKIP
 Breakdown: 1 Instruction Fix, 2 Infra/Deployment Fix, 0 Rethink
```

## Post-Test Actions

After completing all steps:

1. **Summarize** findings: X/Y steps passed, with failure breakdown by category
2. **Suggest fixes** for each failure:
   - For **Instruction Fix**: specify the exact line and file to change (e.g., "change `deploy.yml` to `examples/deploy.yml` on line 47 of module-02.adoc")
   - For **Infra / Deployment Fix**: identify the config to change (e.g., "install the `openshift-gitops` operator" or "set `ingress.host` in Helm values for ArgoCD app `myapp`")
   - For **Rethink**: describe the design issue and suggest alternatives (e.g., "add a wait step after deployment before checking pods")
3. **Group** findings by category so the developer can tackle instruction fixes, infra/deployment fixes, and rethinks separately
4. **Optionally commit** the test report to git as a tracking artifact
5. **Compare** against previous reports if re-running after fixes, showing which issues were resolved

## Escalation

When test failures cannot be resolved through the classification heuristics:

1. **Infra / Deployment issues** → Use the **agnosticd** skill troubleshooting decision tree
2. **Showroom content/terminal issues** → Use the **showroom** skill troubleshooting decision tree
3. **Deep infrastructure validation** → Use `/health:deployment-validator` from the [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/)
4. **Content quality issues** → Use `/showroom:verify-content` from the RHDP Skills Marketplace
5. **Grading automation** → After tests pass, use `/ftl:rhdp-lab-validator` to generate Solve/Validate button automation

## Best Practices

- Always run student-readiness checks before module testing — don't debug module steps on a broken environment
- Test modules in order (module-01 before module-02) since later modules may depend on earlier state
- When re-testing after fixes, run only the failed steps first, then do a full pass
- Save test reports to git so the team can track testing progress across environments
- For multi-module workshops, test each module independently to isolate failures
- If a step has a timing dependency (waiting for a pod to start), add a reasonable retry with backoff before classifying as a failure
