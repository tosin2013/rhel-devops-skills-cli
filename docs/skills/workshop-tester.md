---
title: Workshop Tester
parent: Skills
nav_order: 6
---

# Workshop Tester Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The Workshop Tester skill teaches the AI assistant to act as an "AI-as-student" — reading a workshop module (AsciiDoc or markdown), executing each student step against a live environment, verifying expected outcomes, and producing a step-by-step pass/fail report with failure classification.

This skill fills the gap between environment readiness (`student-readiness`) and grading automation (`/ftl:rhdp-lab-validator`). While student-readiness checks if the environment is ready and the lab validator generates grading playbooks, neither answers: **"Do the exercise steps in this module actually work?"**

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "run through module X against this environment"
- Testing workshop exercises on a live deployment
- Verifying that module steps work before handing a lab to students
- Re-testing after fixes to confirm issues are resolved
- Comparing test results across runs to track progress

## Validation Lifecycle

The workshop-tester sits between readiness checks and grading automation:

```
student-readiness → workshop-tester → ftl:rhdp-lab-validator
(env ready?)        (steps work?)     (grade automation)
```

## Failure Classification

When a step fails, the AI classifies it into one of three categories:

| Category | Meaning | Action |
|----------|---------|--------|
| **Instruction Fix** | The module text is wrong but the env is fine | Update the .adoc/.md file |
| **Infra / Deployment Fix** | The environment or deployment pipeline is misconfigured (RBAC, operators, Helm values, ArgoCD) | Fix AgnosticD config, workload variables, Helm values, or ArgoCD Application spec |
| **Rethink** | The exercise design itself is flawed | Redesign the module flow or add prerequisites |

## Step Parsing

The skill identifies executable steps in two content formats:

- **Showroom AsciiDoc**: Extracts `[source,role="execute"]` blocks, skips `[source,role="copypaste"]` blocks, and uses "Expected output" sections for verification
- **Standard Markdown**: Extracts fenced `bash`/`shell` code blocks, skips `yaml`/`json`/`text` blocks

## Sample Report

```
Module Test Report — module-02.adoc — GUID: abc123
──────────────────────────────────────────────────────────
 #  Step                    Status  Category              Notes
 1  oc login                PASS    —                     —
 2  oc new-project myapp    PASS    —                     —
 3  oc apply -f deploy.yml  FAIL    Instruction Fix       File path wrong: deploy.yml not in examples/
 4  curl app route          SKIP    —                     Skipped (depends on #3)
 5  oc get pods             FAIL    Infra/Deploy Fix      Operator CSV pending: openshift-gitops
 6  argocd app sync myapp   FAIL    Infra/Deploy Fix      ArgoCD app Degraded: Helm values missing
──────────────────────────────────────────────────────────
 Result: 2 PASS, 3 FAIL, 1 SKIP
 Breakdown: 1 Instruction Fix, 2 Infra/Deployment Fix, 0 Rethink
```

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [Student Readiness](student-readiness.html) | Pre-flight check — run before module testing to verify environment health |
| [Showroom](showroom.html) | Content format — workshop-tester parses Showroom AsciiDoc for executable steps |
| [AgnosticD v2](agnosticd.html) | Infrastructure — Infra / Deployment Fix failures often require AgnosticD config changes |
| [Field-Sourced Content](field-sourced-content.html) | Deployment pipeline — Helm/ArgoCD failures traced back to Field Content configs |

## Complementary Marketplace Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `/showroom:verify-content` | Content quality (AsciiDoc, Red Hat standards) | Before testing — ensure content is well-formed |
| `/health:deployment-validator` | Infrastructure health (pods, routes, operators) | When Infra / Deployment Fix failures are found |
| `/ftl:rhdp-lab-validator` | Lab grading automation (Solve/Validate buttons) | After testing — generate grading for passing modules |

See [ADR-012](../adrs/012-workshop-module-testing.html) for the full design rationale.

## Install

```bash
./install.sh install --skill workshop-tester
```
