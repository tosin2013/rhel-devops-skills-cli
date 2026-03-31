---
title: Agent Skills Open Standard
nav_order: 3
parent: Research Documents
---

# Agent Skills Open Standard

**Date**: 2026-03-31
**Category**: standards-research
**Status**: Complete

## Research Question

What is the Agent Skills open standard, what does its specification require, and which AI agents support it?

## Background

The PRD proposes a custom `skill.json` format for skill definitions. Research revealed that both Claude Code and Cursor IDE follow the Agent Skills open standard (agentskills.io). This document captures the specification details to inform architectural decisions.

## Methodology

- Reviewed the Agent Skills specification at agentskills.io/specification
- Reviewed the Agent Skills overview at agentskills.io
- Analyzed the GitHub repository at github.com/agentskills/agentskills
- Cross-referenced with Cursor and Claude documentation

## Key Findings

### Finding 1: Originally Developed by Anthropic
- **Description**: Agent Skills was originally developed by Anthropic and released as an open standard. It is now maintained by the community under the Apache 2.0 license.
- **Evidence**: GitHub repository credits Anthropic as originator; Apache 2.0 license
- **Confidence**: High
- **Source**: [Agent Skills GitHub](https://github.com/agentskills/agentskills)

### Finding 2: SKILL.md Is the Core Specification
- **Description**: Every skill is a directory containing a required `SKILL.md` file. The file uses YAML frontmatter for metadata followed by markdown content for instructions. Required fields are `name` (max 64 chars, lowercase + hyphens) and `description` (max 1024 chars).
- **Evidence**: Specification defines required and optional fields with character limits
- **Confidence**: High
- **Source**: [Agent Skills Specification](https://agentskills.io/specification)

### Finding 3: Optional Frontmatter Fields
- **Description**: Beyond required `name` and `description`, optional fields include:
  - `license`: License name or reference
  - `compatibility`: Environment requirements (max 500 chars)
  - `metadata`: Arbitrary key-value mapping
  - `allowed-tools`: Space-delimited list of pre-approved tools (experimental)
  - `disable-model-invocation`: Boolean to prevent auto-activation
- **Evidence**: Specification lists all fields with types and constraints
- **Confidence**: High
- **Source**: [Agent Skills Specification](https://agentskills.io/specification)

### Finding 4: Standard Directory Structure
- **Description**: The specification defines a standard directory layout:
  ```
  my-skill/
    SKILL.md        (required)
    scripts/        (optional - executable code)
    references/     (optional - additional documentation)
    assets/         (optional - templates, config files, data)
  ```
- **Evidence**: Both Cursor and Claude Code documentation mirror this structure
- **Confidence**: High
- **Source**: [Agent Skills Specification](https://agentskills.io/specification), [Cursor Skills](https://www.cursor.com/docs/context/skills)

### Finding 5: Progressive Disclosure Model
- **Description**: Skills use a three-stage progressive disclosure model:
  1. **Discovery**: Agent sees skill name + description (low context cost)
  2. **Activation**: Agent reads SKILL.md instructions when relevant
  3. **Execution**: Agent loads scripts/references/assets on demand
  This keeps context usage efficient by loading only what's needed.
- **Evidence**: Documented in Agent Skills overview and Cursor docs
- **Confidence**: High
- **Source**: [Agent Skills Overview](https://agentskills.io/), [Agent Skills Guide](https://agentskills.so/skills)

### Finding 6: Broad Agent Support
- **Description**: The Agent Skills standard is supported by:
  - **Claude Code** (Anthropic CLI/IDE agent)
  - **Cursor IDE** (explicitly loads from multiple skill directories)
  - **Any compliant agent** (open standard, portable by design)
  Cursor also loads from `.claude/skills/` and `.codex/skills/` for cross-compatibility.
- **Evidence**: Cursor docs list compatibility directories; Claude docs describe same format
- **Confidence**: High
- **Source**: [Cursor Skills](https://www.cursor.com/docs/context/skills), [Claude Skills](https://docs.claude.com/en/docs/claude-code/slash-commands.md)

### Finding 7: Skills vs MCP Are Complementary
- **Description**: Agent Skills (SKILL.md) provide static knowledge and workflow instructions. MCP servers provide dynamic tools, live resources, and reusable prompts. They serve different purposes and can coexist.
- **Evidence**: Claude Code supports both MCP servers and skills simultaneously
- **Confidence**: High
- **Source**: [Claude Code MCP](https://docs.claude.com/en/docs/claude-code/mcp)

## Implications

### Architectural Impact
Adopting the Agent Skills standard means:
1. Replacing `skill.json` with `SKILL.md`
2. Using `references/` for documentation instead of custom `docs/`
3. Getting automatic compatibility with Claude Code and Cursor
4. Future-proofing against other agents adopting the standard

### Technology Choices
- Markdown + YAML frontmatter (no JSON needed for skill definitions)
- Standard directory layout (SKILL.md, scripts/, references/, assets/)
- Cross-platform portability built in

### Risk Assessment
- **Very low risk**: Standard is backed by Anthropic and community
- **Very low risk**: Already supported by two major platforms (Claude Code, Cursor)
- **Low risk**: Standard is still evolving (experimental features like `allowed-tools`)

## Recommendations

1. Adopt Agent Skills open standard as the skill definition format
2. Use `SKILL.md` with YAML frontmatter for all three skills
3. Store fetched documentation in `references/` directories
4. Store helper scripts in `scripts/` directories
5. Store templates and config files in `assets/` directories
6. Keep SKILL.md instructions concise; reference separate files for detail

## Related ADRs

- ADR-001: Adopt Agent Skills Open Standard
- ADR-003: Documentation Embedding Strategy
- ADR-005: Dual-Mode Installation

## References

- [Agent Skills Overview](https://agentskills.io/)
- [Agent Skills Specification](https://agentskills.io/specification)
- [Agent Skills GitHub Repository](https://github.com/agentskills/agentskills)
- [Agent Skills Guide (agentskills.so)](https://agentskills.so/skills)
- [Cursor Agent Skills Documentation](https://www.cursor.com/docs/context/skills)
- [Claude Code Skills Documentation](https://docs.claude.com/en/docs/claude-code/slash-commands.md)
