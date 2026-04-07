---
title: "ADR-015: Deployment Pipeline Testing Skills"
nav_order: 15
parent: Architecture Decision Records
---

# ADR-015: Deployment Pipeline Testing Skills

* Status: accepted
* Date: 2026-04-06
* Deciders: Architecture Team

## Context and Problem Statement

The workshop development lifecycle established in ADR-011 defines five phases:

```
Create → Deploy → Validate → Test → Troubleshoot
Showroom  AgnosticD  Student   Workshop  Decision
content   + Field    Readiness  Tester   trees
          Content
```

The **Validate** phase (student-readiness) checks whether a deployed environment is ready for students. However, it assumes deployment already succeeded. There is no skill that validates the **deployment pipeline itself** — whether `agd provision` completed cleanly, whether all workloads are actually running, whether the stop/start/status lifecycle works, or whether a Validated Pattern converges via the VP Operator and all ArgoCD Applications reach `Healthy/Synced`.

This gap becomes visible in practice: `workshop-tester` classifies failures as "Infra / Deployment Fix" but has no structured path to diagnose whether the provisioning pipeline — not just the environment snapshot — is the root cause.

Additionally, ADR-011 only models the AgnosticD ecosystem. Validated Patterns (introduced through ADR-013 and the `patternizer` skill) have a completely different deployment model — GitOps via ArgoCD, Helm charts, the VP Operator, and async convergence — that the existing lifecycle does not address.

Two new questions have no existing skill to answer them:

1. "I ran `agd provision` — how do I know all the workloads actually deployed correctly and the lifecycle works?"
2. "I ran `pattern.sh make install` (or installed via the VP Operator) — how do I know all the ArgoCD Applications converged, secrets are flowing, and imperative jobs completed?"

## Decision Drivers

* The deployment pipeline is distinct from environment readiness: a snapshot check (student-readiness) does not exercise the provisioning path or the lifecycle
* Provisioning failures and GitOps convergence failures have different failure modes from the student-facing environment checks that `student-readiness` covers
* The failure escalation path needs to be explicit: a deployment test failure should invoke `agnosticd-refactor` or `vp-refactor` for root-cause audit, then re-test
* ADR-011's lifecycle must be extended to cover both AgnosticD and Validated Patterns, and to include the deployment test phase
* Consistent with the process-oriented skill pattern from ADR-011 (student-readiness), ADR-012 (workshop-tester), and ADR-013 (refactor skills)

## Considered Options

1. **Add deployment validation checks to student-readiness** — extend the readiness checklist with provisioning-specific checks
2. **Add a "test deployment" section to agnosticd and patternizer** — embed pipeline testing inside the operational skills
3. **Two standalone process-oriented skills** — `agnosticd-deploy-test` and `vp-deploy-test`, each defining a structured pipeline testing process

## Decision Outcome

Chosen option: **"Two standalone process-oriented skills"** (option 3), because:

* Option 1 conflates two different concerns: "is the student environment healthy right now?" (student-readiness) vs. "did the provisioning pipeline produce a correct, fully-working deployment?" (deploy-test). They have different inputs, different failure modes, and are run at different points.
* Option 2 would mix operational guidance ("how to run commands") with diagnostic process ("how to verify the deployment worked") — the same problem ADR-013 solved by separating `agnosticd-refactor` from `agnosticd`.
* Two separate skills are required (not one) because AgnosticD is Ansible/`agd`-CLI driven and VP is GitOps/VP Operator driven. They share the structural pattern but not a single process.

### Skill Descriptions

**`agnosticd-deploy-test`**: A process-oriented skill that guides an AI assistant through validating an AgnosticD v2 deployment from end to end — verifying that provisioning completed cleanly, all workloads are running, `agnosticd_user_info` data is flowing, and the stop/start/status lifecycle operates correctly. Activated after `agd provision` completes, before running student-readiness. Escalates to `agnosticd-refactor` for structural issues found during testing.

**`vp-deploy-test`**: A process-oriented skill that guides an AI assistant through validating a Validated Pattern deployment — verifying VP Operator installation, ArgoCD Application convergence, secrets delivery via Vault and ESO, and imperative job completion. Activated after `pattern.sh make install` or VP Operator install, before running student-readiness. Escalates to `vp-refactor` for structural issues found during testing.

### Updated Lifecycle

The full workshop development lifecycle now has six phases, and explicitly covers both ecosystems:

```
Create → Deploy → Deploy Test → Validate → Test → Troubleshoot
Showroom  AgnosticD  agnosticd-    Student   Workshop  Decision
content   + VP       deploy-test   Readiness  Tester   trees in
          patterns   vp-deploy-               SKILL.md
                     test
```

### Four-Phase Process (AgnosticD)

```
Phase 1 — Pre-flight
  Verify Python 3.12+, podman, virtualenv, agd CLI reachable
  Confirm agnosticd-v2-vars/ and agnosticd-v2-secrets/ are present

Phase 2 — Provision
  Run agd provision, stream output
  Capture exit code and GUID
  Stop on non-zero exit — report error, escalate to agnosticd-refactor

Phase 3 — Post-deploy validation
  Confirm all workload roles ran without error in the provision output
  Verify agnosticd_user_info data is present in RHDP catalog or output
  → Activate student-readiness for a full environment readiness check
  → If student-readiness fails: escalate to agnosticd-refactor

Phase 4 — Lifecycle test
  Run agd stop → verify stopped
  Run agd start → verify restarted
  Run agd status → verify output
  → Optionally activate workshop-tester when lifecycle confirms healthy
```

### Four-Phase Process (Validated Patterns)

```
Phase 1 — Pre-flight
  Verify oc login succeeds, cluster version meets VP minimum
  Check VP Operator is installed (check CSV in openshift-operators)
  Confirm values-global.yaml and values-<cluster>.yaml are present
  Confirm values-secret.yaml exists but is NOT committed to git

Phase 2 — Install
  Run pattern.sh make install or verify VP Operator has picked up the GitOps repo
  Capture ArgoCD ApplicationSet creation

Phase 3 — ArgoCD convergence
  Poll until all ArgoCD Applications report Healthy/Synced (with timeout)
  Report any Applications stuck in Degraded/OutOfSync
  → If convergence fails: escalate to vp-refactor

Phase 4 — Secrets and jobs verification
  Confirm ExternalSecret resources are Ready (Vault + ESO flow)
  Confirm CronJobs in jobs/ directory have completed at least one run
  → Activate student-readiness after all checks pass
  → Optionally activate workshop-tester when complete
```

### Cross-Skill Call Chain

```
agnosticd-deploy-test ─────────────────────────────────────────────
  On provision success  → activate student-readiness
  On provision failure  → escalate to agnosticd-refactor
  On lifecycle pass     → offer to activate workshop-tester

vp-deploy-test ─────────────────────────────────────────────────────
  On convergence pass   → activate student-readiness
  On convergence fail   → escalate to vp-refactor
  On all checks pass    → offer to activate workshop-tester
```

### Relationship to Existing Skills

```
agnosticd           → related: agnosticd-deploy-test
agnosticd-refactor  → related: agnosticd-deploy-test (escalation target)
student-readiness   → related: agnosticd-deploy-test, vp-deploy-test (called after deploy test)
workshop-tester     → related: agnosticd-deploy-test, vp-deploy-test (optional hand-off)
patternizer         → related: vp-deploy-test
vp-refactor         → related: vp-deploy-test (escalation target)
```

### Positive Consequences

* The deployment pipeline is validated separately from the student environment snapshot — failures are attributed correctly
* Both ecosystems (AgnosticD and Validated Patterns) are covered by the lifecycle for the first time
* The failure escalation path is explicit: deploy-test → refactor skill → fix → re-test
* Consistent with the established pattern for process-oriented skills

### Negative Consequences

* Two more self-contained skills to maintain with no upstream source repo
* The skills require live environment access (agd CLI, oc, ArgoCD) — they cannot be used in read-only or offline sessions
* AgnosticD lifecycle testing (stop/start/status) depends on RQ-5 (lifecycle playbook names and locations) which is currently unresearched — the skill uses partial guidance until RQ-5 is resolved

## Links

* [AgnosticD Deploy Test Skill](../skills/agnosticd-deploy-test.html) — new deployment test skill
* [VP Deploy Test Skill](../skills/vp-deploy-test.html) — new deployment test skill
* [ADR-011](011-e2e-validation-and-troubleshooting.html) — original lifecycle and student-readiness decision
* [ADR-012](012-workshop-module-testing.html) — workshop module testing strategy
* [ADR-013](013-refactor-skills.html) — refactor skills (escalation targets)
* Related: [ADR-010](010-cross-skill-dependencies.html) (cross-skill dependencies)
