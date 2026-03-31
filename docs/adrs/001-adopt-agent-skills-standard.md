---
title: "ADR-001: Adopt Agent Skills Standard"
nav_order: 1
parent: Architecture Decision Records
---

# ADR-001: Adopt Agent Skills Open Standard (SKILL.md) Over Custom skill.json

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team
* Research: [Agent Skills Open Standard](../research/agent-skills-open-standard.md), [Claude Code Skill System](../research/claude-code-skill-system.md), [Cursor IDE Skill and Rules System](../research/cursor-ide-skill-and-rules-system.md)

## Context and Problem Statement

The PRD (PRD.md) proposes a custom `skill.json` format for defining AI assistant skills for Claude and Cursor. However, research shows that neither Claude Code nor Cursor IDE uses JSON-based skill definitions. Both platforms follow the **Agent Skills open standard** ([agentskills.io](https://agentskills.io/specification)), which uses `SKILL.md` files with YAML frontmatter and markdown content.

The Agent Skills standard was originally developed by Anthropic and is now an Apache 2.0 community-maintained open standard. It defines a portable, version-controlled package format with required `name` and `description` frontmatter fields, plus optional `scripts/`, `references/`, and `assets/` directories.

What format should we use for skill definitions in rhel-devops-skills-cli?

## Decision Drivers

* Both target platforms (Claude Code and Cursor) natively support the Agent Skills standard
* Cursor explicitly loads SKILL.md from `.cursor/skills/`, `.claude/skills/`, and `.agents/skills/`
* Claude Code loads SKILL.md from `.claude/skills/`
* The standard uses progressive disclosure (discovery -> activation -> execution) to manage LLM context efficiently
* No AI agent natively supports a `skill.json` format
* A community-maintained open standard reduces long-term maintenance burden

## Considered Options

1. **Agent Skills open standard (SKILL.md)** -- Use the standard supported by both platforms
2. **Custom skill.json format** -- As proposed in the PRD
3. **MCP server per skill** -- Package each skill as an MCP server
4. **Cursor .mdc rules only** -- Use Cursor-specific rule files
5. **AGENTS.md only** -- Use plain markdown agent instructions

## Decision Outcome

Chosen option: **"Agent Skills open standard (SKILL.md)"**, because it is natively supported by both Claude Code and Cursor IDE, eliminates the need for adaptation layers, and follows an established open standard backed by Anthropic and the community.

Each skill (agnosticd, field-sourced-content, patternizer) will be a directory containing:
- `SKILL.md` with `name` and `description` YAML frontmatter plus markdown instructions
- `references/` directory for fetched documentation files
- `scripts/` directory for helper scripts (optional)
- `assets/` directory for templates and config files (optional)

### Example SKILL.md Structure

```markdown
---
name: agnosticd
description: AI assistance for AgnosticD v2 catalog item development and deployment automation. Use when working with AgnosticD v2, catalog items, ansible-navigator, or execution environments.
---

# AgnosticD v2 Skill

## When to Use
- Setting up AgnosticD v2 development environment
- Creating or modifying catalog items
- ...

## Instructions
- Reference the documentation in references/ for detailed guidance
- ...
```

### Positive Consequences

* Native compatibility with both Claude Code and Cursor IDE without adaptation layers
* Cross-platform portability -- skills work with any agent supporting the Agent Skills standard
* Progressive disclosure keeps LLM context efficient (only loads what's needed)
* Community-maintained standard reduces our maintenance burden
* Cursor loads `.claude/skills/` for compatibility, enabling single-install for both platforms
* Skills become invocable slash commands (e.g., `/agnosticd`) in both Claude Code and Cursor

### Negative Consequences

* Requires rewriting the PRD's skill definition approach (skill.json -> SKILL.md)
* YAML frontmatter has limited fields compared to a custom JSON schema
* Cannot define executable MCP tools directly in SKILL.md (would need separate MCP server for live tool integration)
* The Agent Skills standard is still evolving (e.g., experimental `allowed-tools` field)

## Links

* [Agent Skills Specification](https://agentskills.io/specification) -- Defines SKILL.md format with YAML frontmatter
* [Agent Skills Overview](https://agentskills.io/) -- Describes progressive disclosure model and standard overview
* [Agent Skills GitHub Repository](https://github.com/agentskills/agentskills) -- Apache 2.0 licensed, originated from Anthropic
* [Agent Skills Guide](https://agentskills.so/skills) -- Detailed format explanation and examples
* [Cursor Agent Skills Documentation](https://www.cursor.com/docs/context/skills) -- Confirms SKILL.md loading from multiple directories
* [Claude Code Skills Documentation](https://docs.claude.com/en/docs/claude-code/slash-commands.md) -- Confirms `.claude/skills/SKILL.md` format
* Supersedes: PRD Section 5.3 "Skill Definition Format" (skill.json proposal)
* Related: [ADR-002](002-target-claude-code-and-cursor.md), [ADR-003](003-documentation-embedding-strategy.md), [ADR-004](004-installation-target-paths.md)
