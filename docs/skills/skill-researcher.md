---
title: Skill Researcher
parent: Skills
nav_order: 9
---

# Skill Researcher

**Type**: Meta-skill (operates on skill files, not user environments)
{: .fs-5 }

## Overview

The Skill Researcher is a meta-skill that guides the AI assistant through resolving open `(RESEARCH NEEDED — RQ-N)` placeholder blocks in the skill catalog. Research findings are saved as reference documents and written back into every skill file that shares the same research question — ensuring no finding is siloed to a single file.

This skill treats the SKILL.md files and `references/` directories as the long-term memory of the skill catalog. When a research session answers an open question, the Skill Researcher makes that answer permanent and propagates it consistently across all affected skills.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "answer RQ-4" or "fill in the agnosticd_user_info section"
- Saying "update the skills with what you found" after providing research
- Asking which research questions are still open across the skill catalog
- Wanting findings saved permanently so they are not repeated in future sessions

Do NOT use this skill to deploy or audit infrastructure — it operates exclusively on skill files.

## Three-Phase Workflow

```
Phase 1 — Discover
  Scan all skills/*/SKILL.md files for (RESEARCH NEEDED — RQ-N)
  Report every write target to the user for confirmation

Phase 2 — Research
  Read references/REFERENCE.md to find the upstream URL
  Fetch and extract verified content (exact names, signatures, keys)
  Compare upstream guidance against the user's project files
  Report matches, gaps, and unclear areas to the user

Phase 3 — Write Back
  Save a reference document to references/ directory
  Replace every matching (RESEARCH NEEDED) block across all affected skills
  Update references/REFERENCE.md index
```

## Optional Phase 4 — Upstream Contribution

After write-back, if the user's project correctly follows the upstream guidance and the tool still does not work as documented — a discrepancy between what the docs say and what the tool actually does — the skill optionally helps create a GitHub issue or PR to report the discrepancy upstream. Missing documentation alone is handled locally by updating the skill files.

The AI always drafts the issue or PR for user review before running any `gh` command.

## Open Research Questions

The skill maintains an RQ Registry covering all open questions across both the AgnosticD and Validated Patterns ecosystems. To see which questions are still open:

```bash
grep -r "RESEARCH NEEDED" skills/*/SKILL.md
```

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [AgnosticD Refactor](agnosticd-refactor.html) | Primary write target for AgnosticD RQ-1 through RQ-7 |
| [VP Refactor](vp-refactor.html) | Primary write target for Validated Patterns RQ-1 through RQ-8 |
| [AgnosticD v2](agnosticd.html) | Receives propagated findings for RQs 1–7 |
| [Showroom](showroom.html) | Receives propagated findings for RQ-4 and RQ-7 |
| [Student Readiness](student-readiness.html) | Receives propagated findings for RQ-4, RQ-5, and RQ-7 |

See [ADR-014](../adrs/014-skill-researcher.html) for the full design rationale.

## Install

```bash
./install.sh install --skill skill-researcher
```
