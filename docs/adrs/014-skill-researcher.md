---
title: "ADR-014: Skill Researcher Workflow"
nav_order: 14
parent: Architecture Decision Records
---

# ADR-014: Skill Researcher Workflow

* Status: accepted
* Date: 2026-04-06
* Deciders: Architecture Team

## Context and Problem Statement

The skill catalog contains `(RESEARCH NEEDED — RQ-N)` placeholder blocks in six skills — `agnosticd`, `agnosticd-refactor`, `showroom`, `student-readiness`, `field-sourced-content`, and `vp-refactor`. These blocks mark sections where upstream documentation must be fetched and verified before accurate guidance can be written.

The problem is that research findings have no structured path back into the skills. Without a defined workflow:

- Research done in one conversation is lost — it lives in browser history rather than in the skill files
- A finding relevant to RQ-4 affects five different skill files, but nothing prompts the LLM to update all five — typically one gets updated and the rest stay stale
- The upstream sources to consult are already catalogued in `references/REFERENCE.md` files, but there is no skill that tells the LLM to read those files before fetching, or how to format what it finds
- Duplicate research happens across sessions because there is no record that a question was already answered

The skills themselves are the long-term memory of this repo. `(RESEARCH NEEDED)` blocks are the explicit gaps in that memory. A workflow is needed to close those gaps systematically and persistently.

## Decision Drivers

* Research findings must propagate to all affected skills in one pass — a single RQ can touch multiple files
* The upstream sources are already listed in `references/REFERENCE.md` files — the workflow should read them rather than requiring the user to specify URLs manually
* Completed research should be saved as a reference document so future sessions can consult it rather than re-fetching
* Consistent with the process-oriented skill pattern established in ADR-011 (student-readiness), ADR-012 (workshop-tester), and ADR-013 (refactor skills) — a skill defines the process, the LLM executes it

## Considered Options

1. **Manual research with no structured guidance** — the developer or LLM finds the upstream source, writes findings into one file, and manually updates the others
2. **Add research instructions to each individual skill** — each skill that has a `(RESEARCH NEEDED)` block also contains instructions for how to answer it
3. **Standalone `skill-researcher` meta-skill** — a single process-oriented skill that guides the LLM through discovery, research, and write-back across all affected skills in one session

## Decision Outcome

Chosen option: **"Standalone `skill-researcher` meta-skill"** (option 3), because:

* Option 1 relies on the developer knowing which other files share the same RQ — this knowledge is not visible without a scan. Propagation is consistently incomplete in practice.
* Option 2 duplicates the fetch and write-back instructions across every skill that has a placeholder. If the process changes (e.g. a new reference file format), every skill must be updated.
* Option 3 centralizes the discovery scan, the upstream fetch, and the write-back loop in one skill. The same process works for any RQ in any skill without modification.

### Skill Description

**`skill-researcher`**: A meta-skill that guides an AI assistant through three phases — discovering all `(RESEARCH NEEDED — RQ-N)` write targets across the skill catalog, fetching and extracting verified content from upstream sources, and writing findings back into every affected skill while saving a reference document. Activated when a developer or LLM session wants to permanently resolve one or more open research questions.

This skill does not operate on a user's deployed environment. It operates on the skill files themselves.

### Three-Phase Workflow

```
Phase 1 — Discover
  Scan all skills/*/SKILL.md files for (RESEARCH NEEDED — RQ-N)
  Report every file and section that is a write target

Phase 2 — Research
  Read references/REFERENCE.md to find the upstream URL
  Fetch and extract verified content (exact names, signatures, required keys)
  Stop and report if upstream source is insufficient

Phase 3 — Write Back
  Save a reference document to the relevant references/ directory
  Replace every (RESEARCH NEEDED — RQ-N) block found in Phase 1
  Update references/REFERENCE.md to list the new document
```

### Relationship to Existing Skills

```
skill-researcher → agnosticd-refactor  (resolves RQ-1 through RQ-7 for AgnosticD)
skill-researcher → vp-refactor         (resolves RQ-1 through RQ-8 for Validated Patterns)
skill-researcher → agnosticd           (propagates RQ findings to operational skill)
skill-researcher → showroom            (propagates RQ-4 and RQ-7 findings)
skill-researcher → student-readiness   (propagates RQ-4, RQ-5, RQ-7 findings)
skill-researcher → field-sourced-content (propagates RQ-4 findings)
```

### Positive Consequences

* Research findings are never siloed — all affected skills are updated in a single session
* The upstream sources are already catalogued; the LLM reads them rather than guessing
* Completed research is saved as a reference document for future sessions
* `(RESEARCH NEEDED)` blocks function as a machine-readable backlog — the skill processes them in order

### Negative Consequences

* The skill requires the LLM to have write access to the skill files — it cannot be used in read-only (Ask) mode
* If upstream sources change significantly, the write-back produces stale content that looks authoritative — the skill includes a check for this, but the LLM must act on it
* A meta-skill that modifies other skills increases the risk of accidental edits — the discovery phase explicitly lists write targets for user confirmation before any changes are made

## Links

* [AgnosticD Refactor Skill](../skills/agnosticd-refactor.html) — primary target for AgnosticD RQs
* [VP Refactor Skill](../skills/vp-refactor.html) — primary target for Validated Patterns RQs
* [ADR-013](013-refactor-skills.html) — introduced the `(RESEARCH NEEDED)` placeholder pattern
* Related: [ADR-010](010-cross-skill-dependencies.html) (cross-skill dependencies), [ADR-011](011-e2e-validation-and-troubleshooting.html) (process-oriented skills), [ADR-012](012-workshop-module-testing.html) (workshop module testing)
