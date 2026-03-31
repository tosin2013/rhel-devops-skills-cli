---
title: Cursor IDE Skill and Rules System
nav_order: 2
parent: Research Documents
---

# Cursor IDE Skill and Rules System

**Date**: 2026-03-31
**Category**: platform-research
**Status**: Complete

## Research Question

How does Cursor IDE support custom skills, rules, and agent instructions? What are the correct file formats, directory locations, and activation mechanisms?

## Background

The PRD for rhel-devops-skills-cli assumes skills install to `~/.cursor/skills/` using a `skill.json` format. This research validates those assumptions against the actual Cursor IDE extension systems as of March 2026.

## Methodology

- Reviewed official Cursor documentation at cursor.com/docs
- Fetched and analyzed the full Cursor Skills page and Rules page
- Reviewed the Agent Skills open standard at agentskills.io
- Reviewed community guides on Cursor rules best practices

## Key Findings

### Finding 1: Cursor Has Three Extension Systems
- **Description**: Cursor IDE supports three distinct mechanisms for providing AI agent context:
  1. **Rules** (`.cursor/rules/*.mdc`): Persistent instructions with glob-based scoping
  2. **Skills** (`.cursor/skills/<name>/SKILL.md`): Agent Skills open standard packages
  3. **AGENTS.md**: Simple markdown alternative for agent instructions
- **Evidence**: All three are documented separately in official Cursor docs
- **Confidence**: High
- **Source**: [Cursor Rules](https://www.cursor.com/docs/context/rules), [Cursor Skills](https://www.cursor.com/docs/context/skills)

### Finding 2: Skills Use SKILL.md (Not skill.json)
- **Description**: Cursor skills follow the Agent Skills open standard. Each skill is a folder containing a `SKILL.md` file with YAML frontmatter (`name`, `description` required). No JSON skill format exists.
- **Evidence**: Official docs show `SKILL.md` with `---` YAML frontmatter blocks
- **Confidence**: High
- **Source**: [Cursor Skills](https://www.cursor.com/docs/context/skills)

### Finding 3: Skill Directory Locations
- **Description**: Skills are auto-loaded from these directories:
  - `.agents/skills/` (project-level)
  - `.cursor/skills/` (project-level)
  - `~/.cursor/skills/` (user-level/global)
  - For compatibility: `.claude/skills/`, `.codex/skills/`, `~/.claude/skills/`, `~/.codex/skills/`
- **Evidence**: Explicitly listed in official documentation table
- **Confidence**: High
- **Source**: [Cursor Skills docs](https://www.cursor.com/docs/context/skills)

### Finding 4: Rules Use .mdc Format with Frontmatter
- **Description**: Cursor rules are stored in `.cursor/rules/` as `.mdc` (Markdown Cursor) or `.md` files. They use YAML frontmatter with `description`, `globs`, and `alwaysApply` fields. Four rule types exist: Always Apply, Apply Intelligently, Apply to Specific Files, Apply Manually.
- **Evidence**: Official documentation with examples showing `.mdc` format
- **Confidence**: High
- **Source**: [Cursor Rules](https://www.cursor.com/docs/context/rules)

### Finding 5: Rules vs Skills Serve Different Purposes
- **Description**: Rules provide persistent, always-on context (coding standards, conventions). Skills provide on-demand, invocable capabilities (workflows, tools). Rules are scoped by file globs; skills are triggered by context relevance or explicit `/command` invocation.
- **Evidence**: Rules are included at prompt start; skills are loaded progressively on demand
- **Confidence**: High
- **Source**: [Cursor Rules](https://www.cursor.com/docs/context/rules), [Cursor Skills](https://www.cursor.com/docs/context/skills)

### Finding 6: Skills Support Optional Directories
- **Description**: Skills can include optional subdirectories:
  - `scripts/`: Executable code the agent can run
  - `references/`: Additional documentation loaded on demand
  - `assets/`: Static resources like templates, config files
- **Evidence**: Documented in official Cursor Skills specification table
- **Confidence**: High
- **Source**: [Cursor Skills](https://www.cursor.com/docs/context/skills)

### Finding 7: Cross-Platform Compatibility
- **Description**: Cursor explicitly loads skills from `.claude/skills/` and `.codex/skills/` directories in addition to its own directories. This means a single skill installed to `.claude/skills/` works in both Claude Code and Cursor.
- **Evidence**: Documented compatibility table in Cursor Skills page
- **Confidence**: High
- **Source**: [Cursor Skills](https://www.cursor.com/docs/context/skills)

### Finding 8: AGENTS.md as Simple Alternative
- **Description**: `AGENTS.md` files placed in the project root (or subdirectories) serve as a simple markdown alternative to structured rules. They are automatically applied. Nested AGENTS.md files in subdirectories are supported with additive inheritance.
- **Evidence**: Documented as alternative to `.cursor/rules/`
- **Confidence**: High
- **Source**: [Cursor Rules](https://www.cursor.com/docs/context/rules)

### Finding 9: Rules Hierarchy
- **Description**: When rules conflict, precedence is: Team Rules > Project Rules (.cursor/rules/) > User Rules > Legacy Rules (.cursorrules) > AGENTS.md
- **Evidence**: Explicitly documented precedence order
- **Confidence**: High
- **Source**: [Cursor Rules Guide](https://design.dev/guides/cursor-rules/)

## Implications

### Architectural Impact
The PRD's `skill.json` format is incorrect. The installer should:
1. Create `SKILL.md` files for on-demand skill capabilities
2. Optionally create `.cursor/rules/*.mdc` files for always-applied conventions
3. Install global skills to `~/.cursor/skills/` or leverage `.claude/skills/` cross-compatibility

### Technology Choices
- SKILL.md with YAML frontmatter (Agent Skills standard)
- Optional .mdc files for Cursor-specific always-on rules
- references/ directory for documentation embedding

### Risk Assessment
- **Low risk**: Agent Skills standard is explicitly supported by Cursor
- **Low risk**: Cross-compatibility with `.claude/skills/` reduces installation complexity
- **Medium risk**: Rules (.mdc) require Cursor-specific formatting; skills are cross-platform

## Recommendations

1. Primary installation format: SKILL.md in skill directories
2. Install to `~/.cursor/skills/` for global Cursor skills
3. Optionally install to `~/.claude/skills/` for cross-Claude/Cursor compatibility
4. Consider generating `.cursor/rules/*.mdc` for always-on project conventions
5. Keep SKILL.md focused; use references/ for detailed documentation
6. Use AGENTS.md as a lightweight alternative for simple projects

## Related ADRs

- ADR-001: Adopt Agent Skills Open Standard
- ADR-004: Correct Installation Target Paths
- ADR-005: Dual-Mode Installation (Skills + Optional Cursor Rules)

## References

- [Cursor Agent Skills](https://www.cursor.com/docs/context/skills)
- [Cursor Rules](https://www.cursor.com/docs/context/rules)
- [Agent Skills Standard](https://agentskills.io/)
- [Agent Skills Specification](https://agentskills.io/specification)
- [Cursor Rules Guide (design.dev)](https://design.dev/guides/cursor-rules/)
- [Cursor Rules Guide (techsy.io)](https://techsy.io/blog/cursor-rules-guide)
- [Complete Guide to Cursor Rules 2026](https://localskills.sh/blog/cursor-rules-guide)
- [Cursor Plugins Reference](https://cursor.com/docs/reference/plugins)
