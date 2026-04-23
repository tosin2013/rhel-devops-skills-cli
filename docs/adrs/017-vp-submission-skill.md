---
title: "ADR-017: VP Submission Skill and Validator Redeploy Gate"
nav_order: 17
parent: Architecture Decision Records
---

# ADR-017: VP Submission Skill and Validator Redeploy Gate

* Status: accepted
* Date: 2026-04-06
* Deciders: Architecture Team

## Context and Problem Statement

Two gaps exist in the current Validated Patterns skill set:

### Gap 1 — No submission path after successful deployment

The confidence chain established in ADR-015 ends at `workshop-tester`. A developer who has passed `vp-deploy-validator` has no structured guidance for the next step: submitting the pattern to be listed on [validatedpatterns.io](https://validatedpatterns.io). The VP team maintains three quality tiers (Community/Sandbox, Tested, Maintained), each with distinct criteria. No existing skill audits a pattern against these tiers or guides the PR submission process to [validatedpatterns/docs](https://github.com/validatedpatterns/docs).

### Gap 2 — `vp-deploy-validator` has no escalation path for irrecoverable failures

The current `vp-deploy-validator` has a remediation plan but no decision rule for when remediation is exhausted. In practice, two situations require escalating beyond "fix and re-check":

1. `pattern.sh make install` requires user interaction (interactive prompt, TTY wait, `y/n` confirmation). A pattern that cannot deploy fully unattended fails the Community tier requirement and cannot be submitted to validatedpatterns.io.
2. BLOCKING failures (ArgoCD never converges, secrets never sync) persist after two remediation cycles — the cluster or pattern state is irrecoverable without a full destroy-and-redeploy.

Similarly, if the OCP cluster itself is unhealthy (nodes NotReady, API unreachable), the validator has no guidance for tracking a replacement cluster.

## Decision Drivers

* The submission path to validatedpatterns.io is the natural culmination of the VP development lifecycle and should be explicitly modeled
* Non-interactive deployability is a hard requirement at every VP tier — the skill set must surface this as a blocking concern, not just a note
* Two remediation cycles is the practical threshold beyond which re-checking the same broken state wastes developer time; destroy-and-redeploy is a faster path to a clean environment
* Consistent with the process-oriented skill pattern established in ADR-011 through ADR-016

## Considered Options

### For Gap 1 (submission path)

1. **Extend `vp-refactor`** with a tier checklist — add submission readiness checks to the existing audit skill
2. **New standalone `vp-submission` skill** — focused entirely on tier auditing and PR submission guidance

### For Gap 2 (irrecoverable failures)

1. **Add a note to the escalation section** — no structural change, just text
2. **Add a "Destroy and Redeploy" decision section** to `vp-deploy-validator` with explicit triggers, cluster tracking, and hand-offs

## Decision Outcome

**Gap 1:** Chosen option 2 (new standalone skill), because:
- `vp-refactor` audits the pattern structure against VP Operator requirements. Submission readiness is a different concern: it audits against VP team acceptance criteria and guides external contribution workflows (forking docs, writing frontmatter, filing PRs).
- Separating them keeps each skill focused and makes the escalation chain explicit: `vp-deploy-validator` → `vp-submission`.

**Gap 2:** Chosen option 2 (structured decision section), because:
- A plain note has no behavioral guidance. An explicit "Destroy and Redeploy" section gives the AI assistant a clear decision rule, preventing it from cycling indefinitely on the same broken state.

### `vp-submission` Skill Description

**`vp-submission`**: A process-oriented skill that guides an AI assistant through auditing a Validated Pattern against VP tier requirements and submitting it to [validatedpatterns/docs](https://github.com/validatedpatterns/docs). Activated after `vp-deploy-validator` reports HEALTHY. Works through three tiers — Community/Sandbox, Tested, and Maintained — and produces a checklist of what the pattern passes, what it needs to achieve the next tier, and step-by-step submission instructions once the chosen tier is met.

### `vp-deploy-validator` Destroy-and-Redeploy Gate

Two triggers activate the gate:

1. **Non-interactive install failure**: `pattern.sh make install` exits non-zero or produces an interactive prompt (TTY wait, `y/n`, password request, kubeconfig selection prompt). This is a `SUBMISSION_BLOCKING` severity finding — the pattern cannot be submitted to any VP tier until it deploys fully unattended.

2. **Irrecoverable BLOCKING failures**: After two complete remediation cycles (two rounds of `vp-refactor` escalation + re-check), at least one BLOCKING failure remains. The validator stops cycling and transitions to the destroy-and-redeploy decision.

The cluster tracking extension handles the case where the OCP cluster itself is unhealthy. The validator detects whether the issue is with the pattern (redeploy to the same cluster) or the cluster (provision a replacement, then re-run). Replacement cluster provisioning is handed off to `agnosticd-deploy-test`.

### Updated Confidence Chain

```
vp-deploy-test
  → vp-deploy-validator (health check)
      → BLOCKING × 1:  vp-refactor (fix)  → vp-deploy-validator (re-check)
      → BLOCKING × 2:  Destroy-and-Redeploy gate
          → cluster broken: new cluster tracking → agnosticd-deploy-test → vp-deploy-test
          → pattern broken: vp-deploy-test (fresh install on same cluster)
      → HEALTHY:       student-readiness + vp-submission (tier audit)
```

### Positive Consequences

* The full VP lifecycle is modeled from initialization to submission — no dead end after `vp-deploy-validator` passes
* Non-interactive deployability is a first-class failure at the point it matters most: before submission
* The destroy-and-redeploy gate prevents infinite remediation loops
* `vp-submission` is independently useful for developers who want to understand VP tier requirements without being in a live deployment session

### Negative Consequences

* `vp-submission` is initially scaffolded with `(RESEARCH NEEDED)` placeholders for exact VP tier criteria — the VP team's acceptance requirements are not fully documented and require research via `skill-researcher`
* The destroy-and-redeploy gate introduces a destructive operation path; the skill requires explicit user confirmation before any cluster destruction

## Links

* [VP Submission Skill](../skills/vp-submission.html) — new tier audit and submission skill
* [VP Deploy Validator Skill](../skills/vp-deploy-validator.html) — updated with destroy-and-redeploy gate
* [validatedpatterns/docs](https://github.com/validatedpatterns/docs) — submission target
* [ADR-013](013-refactor-skills.html) — refactor skills (audit complement to submission)
* [ADR-015](015-deployment-pipeline-testing.html) — deployment pipeline testing (confidence chain base)
* Related: [ADR-010](010-cross-skill-dependencies.html) (cross-skill dependencies)
