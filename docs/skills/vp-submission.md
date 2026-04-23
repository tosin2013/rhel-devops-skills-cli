---
title: VP Submission
parent: Skills
nav_order: 14
---

# Validated Pattern Submission Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The VP Submission skill guides the AI assistant through auditing a Validated Pattern against VP tier requirements and submitting it to [validatedpatterns/docs](https://github.com/validatedpatterns/docs) to be listed on [validatedpatterns.io](https://validatedpatterns.io).

This skill is the final step in the VP confidence chain — activated after `vp-deploy-validator` reports HEALTHY and the pattern is confirmed to deploy fully without user interaction.

The skill covers three quality tiers defined by the Validated Patterns team:

| Tier | Description | Key requirements |
|------|-------------|-----------------|
| **Community/Sandbox** | Entry-level listing | Non-interactive deploy, `pattern-metadata.yaml`, public repo, README |
| **Tested** | Verified automated deployment | CI/CD pipeline, OCP version matrix, convergence check in CI |
| **Maintained** | Active long-term pattern | OWNERS file, dependency updates, Red Hat/community involvement |

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "how do I get my pattern listed on validatedpatterns.io?"
- Wanting to know which VP tier your pattern qualifies for
- Preparing a PR to [validatedpatterns/docs](https://github.com/validatedpatterns/docs)
- Running a gap analysis to reach the next VP tier
- After `vp-deploy-validator` reports HEALTHY and asks about next steps

## Three-Phase Process

```
Phase 1 — Tier Readiness Audit
  Audit all three tiers regardless of target
  Report pass/fail for each check
  Identify highest tier currently achievable
  Stop if any Tier 1 (Community) check fails

Phase 2 — Gap Remediation Plan
  Ordered list of gaps for the chosen target tier
  Activate vp-refactor for structural issues
  Provide GitHub Actions CI template for Tested tier

Phase 3 — Submission PR Guidance
  Fork validatedpatterns/docs
  Create pattern page with correct Hugo frontmatter
  File PR with tier checklist
  Reviewer expectations and timeline
```

## Prerequisite: Non-Interactive Deploy

A pattern must deploy fully unattended via `pattern.sh make install` or the VP Operator. If `vp-deploy-validator` recorded a `SUBMISSION_BLOCKING: Non-interactive install failure` finding, resolve it before using this skill.

## Open Research Questions

This skill is scaffolded with five `(RESEARCH NEEDED)` blocks. Use the **skill-researcher** skill to resolve them:

| RQ | Description |
|----|-------------|
| VP-SUB-1 | Exact `pattern-metadata.yaml` required fields at Community tier |
| VP-SUB-2 | Tested tier CI/CD requirements — accepted platforms and convergence spec |
| VP-SUB-3 | Maintained tier SLA values and Red Hat involvement criteria |
| VP-SUB-4 | validatedpatterns/docs content structure and Hugo frontmatter schema |
| VP-SUB-5 | PR reviewer expectations and merge criteria |

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [VP Deploy Validator](vp-deploy-validator.html) | Must pass HEALTHY before activating this skill; surfaces `vp-submission` in its confidence chain hand-off |
| [VP Deploy Test](vp-deploy-test.html) | Must confirm non-interactive install before submission audit |
| [VP Refactor](vp-refactor.html) | Escalation target for structural pattern issues found during Phase 1 audit |
| [Patternizer](patternizer.html) | Initializes the pattern structure that this skill audits for submission |
| [Skill Researcher](skill-researcher.html) | Resolves VP-SUB-1 through VP-SUB-5 |

See [ADR-017](../adrs/017-vp-submission-skill.html) for the full design rationale.

## Install

```bash
./install.sh install --skill vp-submission
```
