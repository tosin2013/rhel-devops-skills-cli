# ADR-005: Dual-Mode Installation (Skills + Optional Cursor Rules)

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team
* Research: [Cursor IDE Skill and Rules System](../research/cursor-ide-skill-and-rules-system.md), [Agent Skills Open Standard](../research/agent-skills-open-standard.md)

## Context and Problem Statement

Cursor IDE has two complementary extension mechanisms: **skills** (`.cursor/skills/SKILL.md`) and **rules** (`.cursor/rules/*.mdc`). These serve different purposes:

- **Skills**: On-demand capabilities triggered by context relevance or explicit `/command` invocation. Progressive disclosure model.
- **Rules**: Persistent instructions included at the start of every (or matching) prompt. Always-on context with glob-based file scoping.

For DevOps skills that provide documentation and workflow guidance, should we install as skills, rules, or both?

## Decision Drivers

* Skills follow the Agent Skills standard and work cross-platform (Claude Code + Cursor)
* Rules are Cursor-specific (`.mdc` format) and don't work with Claude Code
* Rules with `alwaysApply: true` provide persistent context in every conversation
* Skills activate on-demand, conserving context tokens when not needed
* Some guidance (e.g., "always use ansible-navigator instead of ansible-playbook") benefits from always-on rules
* Other guidance (e.g., "generate a catalog item structure") is better as an on-demand skill
* Rules precedence: Team Rules > Project Rules > User Rules > AGENTS.md

## Considered Options

1. **Skills only** -- Install only SKILL.md files for both platforms
2. **Skills + optional Cursor rules** -- Install SKILL.md for both, optionally generate .mdc rules for Cursor
3. **Rules only** -- Install only .mdc rules for Cursor (abandon Claude Code support)
4. **AGENTS.md only** -- Use simple markdown files in project root

## Decision Outcome

Chosen option: **"Skills + optional Cursor rules"**, because skills provide the cross-platform foundation (Claude Code + Cursor), while optional Cursor rules can provide always-on conventions for Cursor users who want persistent guidance.

### Primary Mode: Agent Skills (SKILL.md)

Installed for both Claude Code and Cursor (per ADR-001, ADR-004):
- On-demand activation when user asks about tool-specific tasks
- Progressive disclosure loads references only when needed
- Cross-platform compatible

### Optional Mode: Cursor Rules (.mdc)

Generated on request via `--with-rules` flag for Cursor users:
- Always-on conventions and best practices
- Glob-scoped to relevant file types
- Complementary to skills, not a replacement

### Example Optional Rule

```markdown
---
description: AgnosticD v2 conventions and best practices for catalog item development
globs: ["**/ansible/**/*.yml", "**/catalog_items/**/*"]
alwaysApply: false
---

When working with AgnosticD v2 catalog items:

- Always use ansible-navigator instead of ansible-playbook
- Follow the standard directory structure: defaults/, tasks/, meta/, README.adoc
- Use execution environments for testing
- Validate with pre-commit hooks before committing
```

### Installer Behavior

```bash
# Default: install skills only (cross-platform)
./install.sh --skill agnosticd

# With Cursor rules: install skills + generate .mdc rules
./install.sh --skill agnosticd --with-rules

# Rules are installed to project-level by default
# Location: .cursor/rules/agnosticd.mdc
```

### Positive Consequences

* Cross-platform skills work with both Claude Code and Cursor
* Cursor users get optional always-on conventions via rules
* Clear separation: skills for on-demand workflows, rules for persistent conventions
* No additional dependency or format for Claude Code users
* Rules are optional and non-intrusive

### Negative Consequences

* Two artifacts to maintain per skill (SKILL.md + optional .mdc rule)
* Rules are Cursor-specific, creating a platform-dependent feature
* Users may be confused about when to use `--with-rules`
* Project-level rules (`.cursor/rules/`) require being in a project directory

## Links

* [Cursor Rules Documentation](https://www.cursor.com/docs/context/rules) -- Rules format, types, and precedence
* [Cursor Skills Documentation](https://www.cursor.com/docs/context/skills) -- Skills format and behavior
* [Agent Skills Specification](https://agentskills.io/specification) -- Cross-platform skill format
* [Cursor Rules Guide (design.dev)](https://design.dev/guides/cursor-rules/) -- Best practices for Cursor rules
* [Cursor Rules Guide (techsy.io)](https://techsy.io/blog/cursor-rules-guide) -- .mdc format details
* Related: [ADR-001](001-adopt-agent-skills-standard.md), [ADR-004](004-installation-target-paths.md)
