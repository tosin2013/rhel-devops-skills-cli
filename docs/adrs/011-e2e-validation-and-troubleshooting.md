---
title: "ADR-011: End-to-End Validation and Troubleshooting"
nav_order: 11
parent: Architecture Decision Records
---

# ADR-011: End-to-End Validation and Troubleshooting

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team

## Context and Problem Statement

The skill catalog covers creating content (Showroom), scaffolding deployments (Field-Sourced Content), and provisioning infrastructure (AgnosticD). However, after a workshop environment is deployed there is no formalized strategy for verifying it actually works from the student's perspective, or for systematically diagnosing failures.

The [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/) provides complementary validation tools that each check a slice of the stack:

| Marketplace Tool | What It Checks | Layer |
|------------------|---------------|-------|
| `/showroom:verify-content` | AsciiDoc quality, Red Hat style, structure | Content quality (pre-deployment) |
| `/health:deployment-validator` | Pods running, routes accessible, operators installed | Infrastructure health (post-deployment) |
| `/agnosticv:validator` | AgnosticV catalog file correctness | Catalog configuration |
| `/ftl:rhdp-lab-validator` | Generates Solve/Validate button playbooks for ZT grading | Lab grading automation |

**None of these answer the question**: "Given a deployed environment and OpenShift credentials, can students actually start and complete this workshop right now?"

That requires checking the full student experience end-to-end: authentication, lab guide accessibility, terminal functionality, prerequisite resources, RBAC, and multi-user readiness. It also requires support for multiple environment types beyond OpenShift -- RHEL VM labs, AAP environments, and hybrid deployments.

Additionally, when deployments fail, the AI assistant has no structured diagnostic steps. Each skill documents how to use its tool but not how to systematically troubleshoot failures across the integrated stack.

## Decision Drivers

* Workshop developers need a single "go / no-go" check before handing environments to students
* The validation must work across all AgnosticD environment types (OCP shared, OCP dedicated, RHEL VM, AAP, hybrid)
* Existing marketplace tools cover slices but not the student-perspective end-to-end check
* Troubleshooting guidance should be embedded where the AI encounters the failure (in deployment skills)
* The solution should complement, not duplicate, RHDP Skills Marketplace tools

## Considered Options

1. **Reference marketplace tools only** -- Point users to `/health:deployment-validator` and `/showroom:verify-content` without building anything new
2. **Embed validation checklists in existing skills** -- Add readiness checks to AgnosticD and Showroom SKILL.md files
3. **Create a dedicated student-readiness skill** -- A new process-oriented skill that runs a structured checklist against a live deployment, plus troubleshooting decision trees in deployment skills
4. **Build a shell-based validation script** -- A `validate-env.sh` script that runs checks programmatically

## Decision Outcome

Chosen option: **"Dedicated student-readiness skill with troubleshooting decision trees"** (option 3), because:

* A separate skill keeps the readiness checklist focused and environment-type agnostic
* Troubleshooting trees embedded in AgnosticD and Showroom skills give the AI diagnostic steps at the point of failure
* The marketplace tools remain the canonical validation layer for their respective domains -- our skill fills the gap they don't cover
* A feature request for [rhpds/rhdp-skills-marketplace](https://github.com/rhpds/rhdp-skills-marketplace) has been drafted (see `docs/marketplace-feature-request.md`) to propose this concept upstream

### Workshop Lifecycle

The full lifecycle now has five phases:

```
Create              Deploy              Validate            Test                Troubleshoot
┌──────────┐       ┌──────────┐       ┌──────────┐       ┌──────────┐       ┌──────────┐
│ Showroom │       │AgnosticD │       │ Student  │       │ Workshop │       │ Decision │
│ content  │──────►│ + Field  │──────►│Readiness │──────►│  Tester  │──────►│  trees   │
│ authoring│       │ Content  │       │  Skill   │       │  Skill   │       │ in SKILL │
└──────────┘       └──────────┘       └──────────┘       └──────────┘       └──────────┘
      │                  │                  │                  │                  │
      ▼                  ▼                  ▼                  ▼                  ▼
 verify-content    deployment-        student-         workshop-          agnosticd/
 (marketplace)     validator          readiness        tester             showroom
                   (marketplace)      (this project)   (this project)     troubleshoot
```

The **workshop-tester** skill (see [ADR-012](012-workshop-module-testing.html)) extends the validation lifecycle by executing actual module exercises against the live environment. While student-readiness checks "is the env ready?", workshop-tester answers "do the exercises actually work?" — classifying failures as Instruction Fix, Infra / Deployment Fix, or Rethink.

### Student Readiness Skill

A new skill (`student-readiness`) that teaches the AI to verify a deployed environment is ready for students. Key characteristics:

* **Process-oriented**: No upstream repo -- this skill defines a diagnostic process, not a tool wrapper
* **Environment-type agnostic**: Adapts its checklist based on what was deployed (OCP, RHEL VM, AAP, hybrid)
* **Complements the marketplace**: References marketplace tools for deeper validation when checks fail

The readiness checklist covers:

1. Cluster/host access (oc login or SSH)
2. Showroom lab guide accessibility (if deployed)
3. Terminal functionality (if deployed)
4. Operator readiness (OCP environments)
5. Namespace and RBAC correctness (OCP environments)
6. Workload resource availability
7. Content-environment attribute match
8. AAP controller readiness (if applicable)
9. Multi-user isolation (if applicable)

### Troubleshooting Decision Trees

Each deployment skill (AgnosticD, Showroom) gets an embedded troubleshooting section with a structured decision tree. The AI follows these trees when a user reports a failure, working through diagnostic steps before escalating to marketplace tools.

### Positive Consequences

* Workshop developers get a single command ("is my environment ready?") instead of checking multiple tools
* The AI can diagnose failures systematically instead of guessing
* All AgnosticD environment types are covered, not just OpenShift + Showroom
* Clear escalation path: skill troubleshooting -> student readiness -> marketplace tools

### Negative Consequences

* A new skill to maintain that has no upstream source repo
* The readiness checklist must be updated as new environment types or deployment patterns emerge
* Overlap potential if the RHDP Skills Marketplace adds a similar capability in the future

## Links

* [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/) -- complementary validation tools
* [/health:deployment-validator](https://rhpds.github.io/rhdp-skills-marketplace/skills/deployment-health-checker.html) -- infrastructure health checks
* [/showroom:verify-content](https://rhpds.github.io/rhdp-skills-marketplace/skills/verify-content.html) -- content quality validation
* [/ftl:rhdp-lab-validator](https://rhpds.github.io/rhdp-skills-marketplace/skills/rhdp-lab-validator.html) -- lab grading automation
* Related: [ADR-010](010-cross-skill-dependencies.html) (cross-skill dependencies), [ADR-008](008-skill-update-strategy.html) (skill updates), [ADR-012](012-workshop-module-testing.html) (workshop module testing)
