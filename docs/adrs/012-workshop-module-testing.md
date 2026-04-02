---
title: "ADR-012: Workshop Module Testing Strategy"
nav_order: 12
parent: Architecture Decision Records
---

# ADR-012: Workshop Module Testing Strategy

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team

## Context and Problem Statement

Workshop developers repeatedly use the AI assistant to "run through module X against this machine" — executing each student exercise step on a live environment to verify it works before handing the workshop to real students. This is currently a manual, ad-hoc process with no structured guidance.

Existing tools cover adjacent needs but not this specific one:

| Tool | What It Does | Gap |
|------|-------------|-----|
| `student-readiness` skill | Checks "is the environment ready?" (access, services, RBAC) | Does not execute student steps |
| `/showroom:verify-content` | Validates AsciiDoc quality and Red Hat standards | Content quality, not functional correctness |
| `/ftl:rhdp-lab-validator` | Generates Solve/Validate button playbooks for ZT grading | Grading automation, does not run steps itself |

There is a clear gap between environment readiness (is the infra up?) and grading automation (can we score the student?). Nobody is answering: **"Do the exercise steps in the module actually work against this deployed environment?"**

## Decision Drivers

* Workshop developers need a repeatable way to verify module exercises work on live environments
* The AI already has the capability to run shell commands — it just needs structured guidance on how to parse modules, execute steps, and report results
* Failure reports should be actionable: developers need to know whether to fix the instructions, fix the infrastructure/deployment pipeline, or rethink the exercise design
* The solution must work with Showroom AsciiDoc content (the primary format) and standard markdown
* It should integrate with the existing validation lifecycle: readiness -> testing -> grading

## Considered Options

1. **Ad-hoc testing** — Continue letting developers manually ask the AI to run steps with no structured process
2. **Shell script test runner** — Build a bash script that parses modules and runs commands programmatically
3. **Process-oriented skill** — Create a skill that teaches the AI how to parse modules, execute steps, classify failures, and report results (like `student-readiness`)
4. **Extend student-readiness** — Add module step execution to the existing student-readiness skill

## Decision Outcome

Chosen option: **"Process-oriented skill"** (option 3), because:

* A separate skill keeps concerns cleanly separated: environment readiness vs. module functional testing
* The AI can leverage its understanding of context (error messages, documentation, code patterns) to classify failures in ways a shell script cannot
* The skill naturally integrates with the validation lifecycle as a middle step
* It can be activated with natural language triggers ("test module 3 against this environment")

### Validation Lifecycle

The workshop-tester fills the gap between readiness and grading:

```
student-readiness          workshop-tester             ftl:rhdp-lab-validator
(env ready?)         →     (steps work?)          →    (grade automation)
────────────────          ────────────────             ────────────────
Cluster access             Parse module steps           Generate Solve/Validate
Showroom accessible        Execute each command         playbooks for ZT grading
Operators ready            Verify expected output       automation
RBAC correct               Classify failures
```

### Failure Classification

When a step fails, the AI categorizes the failure to make the report actionable:

| Category | Meaning | Examples | Action |
|----------|---------|----------|--------|
| **Instruction Fix** | The module text is wrong but the env is fine | Typo in command, wrong path, outdated CLI flag, missing `--namespace`, copy-paste error in expected output | Update the .adoc/.md file |
| **Infra / Deployment Fix** | The environment or deployment pipeline is misconfigured | Operator not installed, RBAC missing, route not created, resource quota hit, image pull error, Helm values wrong, ArgoCD Application stuck in OutOfSync/Degraded, ArgoCD can't reach Git repo, Helm template rendering error, sync wave ordering issue | Fix the AgnosticD config, workload variables, Helm values, or ArgoCD Application spec |
| **Rethink** | The exercise design itself is flawed | Step depends on output of a skipped step, assumes prior knowledge not covered, timing issue (resource not ready yet), concept doesn't work as described | Redesign the module flow or add prerequisites |

Classification heuristics for the AI:

- Command not found / syntax error → **Instruction Fix**
- Permission denied / forbidden / unauthorized → **Infra / Deployment Fix** (RBAC)
- Resource not found but command is valid → **Infra / Deployment Fix** (missing workload) or **Rethink** (wrong step order)
- Timeout / not ready → **Rethink** (add wait/retry) or **Infra / Deployment Fix** (resource not deployed)
- Output doesn't match expected → **Instruction Fix** (outdated expected output) or **Rethink** (exercise assumption wrong)
- ArgoCD Application Degraded/OutOfSync → **Infra / Deployment Fix** (check ArgoCD app spec, Helm values, Git repo access)
- Helm render error / values mismatch → **Infra / Deployment Fix** (wrong values.yaml, missing chart dependency)
- GitOps repo auth failure / branch not found → **Infra / Deployment Fix** (ArgoCD repo credentials or target revision)

### Step Parsing

The skill teaches the AI to identify executable student steps in two content formats:

**Showroom AsciiDoc** (primary):
- Extract code blocks with `[source,role="execute"]` attribute — these are the commands students are told to run
- Identify `[source,role="copypaste"]` blocks as non-executable (students copy the text but don't run it)
- Recognize verification sections (typically following an exercise block with expected output)

**Standard Markdown**:
- Extract fenced code blocks tagged as `bash` or `shell`
- Skip blocks tagged as `yaml`, `json`, `text` (these are typically output examples or configs to read)

### Output Format

The skill produces a structured report:

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

### Positive Consequences

* Workshop developers get a repeatable, structured process for verifying module exercises
* Failure categorization makes reports actionable — developers know exactly what kind of fix is needed
* The AI can compare successive test runs to show progress after fixes
* Natural integration with student-readiness (pre-check) and ftl:rhdp-lab-validator (post-check)

### Negative Consequences

* Another self-contained skill to maintain with no upstream repo
* The AI must execute commands on live environments, which requires appropriate access credentials
* Failure classification heuristics may miscategorize edge cases — the AI should flag uncertain classifications
* Step parsing depends on consistent use of AsciiDoc attributes (`[source,role="execute"]`); non-standard formatting may cause missed steps

## Links

* [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/) — complementary validation tools
* [Showroom Content Authoring](https://github.com/rhpds/showroom_template_default) — default template for Showroom lab content
* [AsciiDoc source blocks](https://docs.asciidoctor.org/asciidoc/latest/verbatim/source-blocks/) — syntax reference for executable code blocks
* Related: [ADR-011](011-e2e-validation-and-troubleshooting.html) (validation and troubleshooting), [ADR-010](010-cross-skill-dependencies.html) (cross-skill dependencies)
