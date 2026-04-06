---
title: "ADR-013: Refactor Skills for AgnosticD and Validated Patterns"
nav_order: 13
parent: Architecture Decision Records
---

# ADR-013: Refactor Skills for AgnosticD and Validated Patterns

* Status: accepted
* Date: 2026-04-06
* Deciders: Architecture Team

## Context and Problem Statement

The skill catalog contains operational skills that teach an AI assistant how to *use* tools — setting up AgnosticD v2, running `agd provision`, initializing a Validated Pattern with Patternizer. These skills serve developers starting fresh.

However, developers frequently arrive with an *existing* AgnosticD config or Validated Pattern repo and need help answering a different class of question:

- "I have a config that deploys locally — why is it failing RHDP review?"
- "My AgnosticD workload works but the team says my `agnosticd_user_info` output is wrong — what should it look like?"
- "I ran `patternizer init` — now what do I fill in to actually make this deploy?"
- "How do I know if my pattern is ready to submit for Sandbox tier?"

These are **audit and improvement** questions, not operational ones. No existing skill addresses them:

| Existing Skill | What It Answers | What It Does Not Answer |
|---|---|---|
| `agnosticd` | How to run `agd` commands | How to audit an existing config for correctness |
| `patternizer` | How to run `patternizer init/upgrade` | What the generated files must contain to deploy |
| `student-readiness` | Is the environment ready for students? | Is the *deployment definition* itself correct? |
| `workshop-tester` | Do module exercises work? | Are the AgnosticD workload roles structured correctly? |

Additionally, a set of open research questions (RQ-1 through RQ-8 for AgnosticD, RQ-1 through RQ-8 for Validated Patterns) has been identified but not yet fully answered. The refactor skills need to exist as containers for those answers, with explicit `(RESEARCH NEEDED)` markers so the gaps are visible and fillable when research returns.

## Decision Drivers

* Developers need structured AI-guided audits for existing deployments, not just setup assistance
* The audit workflow is triggered by different user intent ("improve this" vs "set up this") — mixing it into operational skills creates confusion about when each skill activates
* Precedent exists: `student-readiness` (ADR-011) and `workshop-tester` (ADR-012) are both process-oriented skills with no upstream repo that define a diagnostic process; refactor skills follow the same pattern
* Research into AgnosticD v2 config anatomy, `agnosticd_user_info` format, workload role structure, stop/start implementation, and Validated Patterns values file requirements is in progress — the skills must be structured to receive those findings cleanly

## Considered Options

1. **Add refactor sections to existing operational skills** — append audit checklists to `agnosticd/SKILL.md` and `patternizer/SKILL.md`
2. **Standalone process-oriented skills** — new `agnosticd-refactor` and `vp-refactor` skills, each with their own `SKILL.md` and `references/` directory
3. **Single combined refactor skill** — one skill covering both AgnosticD and Validated Patterns audit

## Decision Outcome

Chosen option: **"Standalone process-oriented skills"** (option 2), because:

* The trigger is distinct: an LLM activates `agnosticd` when a user asks to *run* something; it activates `agnosticd-refactor` when a user asks to *improve or audit* something. Separate skills prevent the wrong skill from activating.
* Keeping operational skills focused preserves their usefulness for the primary setup/deployment workflow
* A combined skill (option 3) would conflate two different ecosystems — AgnosticD/RHDP vs Validated Patterns/VP Operator — with different review criteria and different submission paths
* This is consistent with ADR-012's rationale for separating `workshop-tester` from `student-readiness` despite their overlap

### Skill Descriptions

**`agnosticd-refactor`**: A process-oriented skill that guides an AI assistant through auditing an existing AgnosticD v2 config or workload role against RHDP best practices. Activated when a developer asks to improve, fix, or prepare an existing deployment for submission — not when they're setting one up from scratch.

**`vp-refactor`**: A process-oriented skill that guides an AI assistant through auditing an existing Validated Pattern repo — including post-`patternizer init` values files — against the requirements for the VP Operator and the Sandbox/Tested/Maintained tier progression. Activated when a developer asks to improve an existing pattern or prepare it for tier submission.

### Research Integration

Both skills are initially scaffolded with `(RESEARCH NEEDED — RQ-N)` placeholder blocks in each audit section. When research findings are available, each placeholder is replaced with the actual checklist, commands, and pass/fail criteria. This makes gaps explicit and machine-readable rather than silently absent.

### Relationship to Existing Skills

```
agnosticd          → related: agnosticd-refactor (bidirectional)
agnosticd-refactor → related: agnosticd, student-readiness, workshop-tester
patternizer        → related: vp-refactor (bidirectional)
vp-refactor        → related: patternizer
```

### Positive Consequences

* AI assistants can answer "how do I improve this?" questions with structured audit guidance
* Research findings have a clear home — each `RESEARCH NEEDED` block is a named target
* The two submission paths (AgnosticD → RHDP, Validated Patterns → VP Operator) remain clearly separated
* Consistent with the process-oriented skill pattern established in ADR-011 and ADR-012

### Negative Consequences

* Two more self-contained skills to maintain with no upstream source repo
* Initial versions are skeletal — developers who arrive before research is complete will see placeholder blocks rather than actionable guidance
* Requires bidirectional `related_skills` updates in both `agnosticd/SKILL.md` and `patternizer/SKILL.md`

## Links

* [AgnosticD v2 Skill](../skills/agnosticd.html) — operational skill this extends
* [Patternizer Skill](../skills/patternizer.html) — operational skill this extends
* [Validated Patterns Tier Requirements](https://validatedpatterns.io/learn/about-pattern-tiers-types/) — upstream criteria for Sandbox/Tested/Maintained
* [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/) — complementary validation tools
* Related: [ADR-010](010-cross-skill-dependencies.html) (cross-skill dependencies), [ADR-011](011-e2e-validation-and-troubleshooting.html) (validation and troubleshooting), [ADR-012](012-workshop-module-testing.html) (workshop module testing strategy)
