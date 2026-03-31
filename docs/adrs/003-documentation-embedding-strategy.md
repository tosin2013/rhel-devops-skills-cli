---
title: "ADR-003: Documentation Embedding Strategy"
nav_order: 3
parent: Architecture Decision Records
---

# ADR-003: Documentation Embedding Strategy Using references/ Directory

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team
* Research: [Agent Skills Open Standard](../research/agent-skills-open-standard.html), [Cursor IDE Skill and Rules System](../research/cursor-ide-skill-and-rules-system.html)

## Context and Problem Statement

The PRD stores fetched documentation in a `docs/` directory alongside `skill.json` within each skill. Per ADR-001, we are adopting the Agent Skills open standard (SKILL.md). The standard defines a specific directory layout including `references/` for supplementary documentation that agents load on demand.

The Cursor documentation explicitly advises: *"Keep your main SKILL.md focused and move detailed reference material to separate files. This keeps context usage efficient since agents load resources progressively -- only when needed."*

How should fetched documentation (setup.adoc, README.md, examples, etc.) from source repositories be stored within each skill?

## Decision Drivers

* The Agent Skills standard defines `references/` as the location for additional documentation
* SKILL.md should be concise instructions, not a documentation dump
* Progressive disclosure means agents only load references when needed, conserving context
* Fetched docs can be large (AsciiDoc, Markdown with examples)
* Agents in both Claude Code and Cursor understand the `references/` convention
* Documentation must be accessible without network requests (offline-capable)

## Considered Options

1. **`references/` directory per Agent Skills standard** -- Store all fetched docs in `references/`
2. **`docs/` directory as proposed in PRD** -- Store in a custom `docs/` directory
3. **Inline in SKILL.md** -- Embed documentation directly in the SKILL.md file
4. **`assets/` directory** -- Store documentation as static assets

## Decision Outcome

Chosen option: **"`references/` directory per Agent Skills standard"**, because it follows the established standard, enables progressive disclosure for context efficiency, and is recognized by both Claude Code and Cursor.

### Skill Directory Structure

```
skills/agnosticd/
  SKILL.md                          # Concise instructions and guidance
  references/
    REFERENCE.md                    # Index of available documentation
    setup.adoc                      # Fetched from agnosticd-v2 repo
    catalog-items.adoc              # Fetched from agnosticd-v2 repo
    ...
  scripts/                          # Optional helper scripts
    validate-catalog-item.sh
  assets/                           # Optional templates
    catalog-item-template/
      defaults/main.yml
      tasks/main.yml
```

### SKILL.md Content Strategy

The SKILL.md file will contain:
- **When to Use** section -- triggers for agent activation
- **Instructions** -- step-by-step guidance referencing files in `references/`
- **Best Practices** -- concise, actionable guidance
- **Common Tasks** -- patterns the agent should follow

The SKILL.md will NOT contain:
- Full documentation text (goes in `references/`)
- Large code examples (go in `assets/`)
- Executable scripts (go in `scripts/`)

### Positive Consequences

* Follows the Agent Skills standard directory convention
* Progressive disclosure -- agents load references only when needed, saving context tokens
* SKILL.md stays focused and under recommended size limits
* Large documentation files don't bloat the primary skill file
* Clear separation of concerns: instructions (SKILL.md) vs reference material (references/) vs templates (assets/)

### Negative Consequences

* Agents may not always load references automatically; SKILL.md must explicitly direct agents to reference files
* AsciiDoc (.adoc) files may not be natively rendered by all agents; may need Markdown conversion
* More files to manage per skill compared to a single `skill.json` with embedded paths
* Agent context window limits may still constrain how much reference material can be used at once

## Links

* [Agent Skills Specification](https://agentskills.io/specification) -- Defines `references/` as standard directory for additional documentation
* [Cursor Skills Documentation](https://www.cursor.com/docs/context/skills) -- "Keep SKILL.md focused; move detailed reference material to separate files"
* [Agent Skills Overview](https://agentskills.io/) -- Describes progressive disclosure model
* Related: [ADR-001](001-adopt-agent-skills-standard.html), [ADR-004](004-installation-target-paths.html)
* Supersedes: PRD Section 5.2 `docs/` directory layout within skills
