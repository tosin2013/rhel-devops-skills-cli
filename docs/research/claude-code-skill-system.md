---
title: Claude Code Skill System
nav_order: 1
parent: Research Documents
---

# Claude Code Skill System

**Date**: 2026-03-31
**Category**: platform-research
**Status**: Complete

## Research Question

How does Claude (Desktop and Code) support custom skills and extensions, and what are the correct file formats, directory locations, and activation mechanisms?

## Background

The PRD for rhel-devops-skills-cli assumes a custom `skill.json` format installed to `~/.config/claude/skills/`. This research validates those assumptions against the actual Claude product ecosystem as of March 2026.

## Methodology

- Reviewed official Claude Code documentation at docs.claude.com
- Reviewed the Agent Skills open standard at agentskills.io
- Reviewed community guides and tutorials for Claude skills (2025-2026)
- Tested directory structures against documented specifications

## Key Findings

### Finding 1: Claude Desktop vs Claude Code Are Different Products
- **Description**: Claude Desktop (the standalone app) and Claude Code (the CLI/IDE agent) are separate products with fundamentally different extension mechanisms. Claude Desktop extends via MCP servers. Claude Code extends via CLAUDE.md, SKILL.md files, and MCP servers.
- **Evidence**: Claude Desktop config is `claude_desktop_config.json`; Claude Code uses `.claude/skills/` directories
- **Confidence**: High
- **Source**: [Claude Code MCP docs](https://docs.claude.com/en/docs/claude-code/mcp), [Claude Skills overview](https://claude.com/docs/skills)

### Finding 2: Claude Code Uses SKILL.md (Not skill.json)
- **Description**: Claude Code skills are defined as directories containing a `SKILL.md` file with YAML frontmatter and markdown instructions. There is no `skill.json` format. The SKILL.md file follows the Agent Skills open standard.
- **Evidence**: Official documentation specifies `.claude/skills/<name>/SKILL.md` as the entry point
- **Confidence**: High
- **Source**: [Extend Claude with skills](https://docs.claude.com/en/docs/claude-code/slash-commands.md), [Agent Skills specification](https://agentskills.io/specification)

### Finding 3: Skill Directory Locations
- **Description**: Claude Code loads skills from two scope levels:
  - **Global/Personal**: `~/.claude/skills/<name>/SKILL.md`
  - **Project-scoped**: `.claude/skills/<name>/SKILL.md` (in the project root)
  - **Legacy format**: `~/.claude/commands/<name>.md` (older single-file commands, still supported)
- **Evidence**: Official Claude Code documentation explicitly lists these paths
- **Confidence**: High
- **Source**: [Claude Code slash commands](https://docs.claude.com/en/docs/claude-code/slash-commands.md)

### Finding 4: CLAUDE.md for Project-Level Instructions
- **Description**: Claude Code reads `CLAUDE.md` at session start for persistent project instructions. This file provides project overview, conventions, and architecture guidance. It is complementary to skills.
- **Evidence**: CLAUDE.md exists at `./CLAUDE.md`, `~/.claude/CLAUDE.md`, or `.claude/CLAUDE.local.md`
- **Confidence**: High
- **Source**: [Claude Code CLAUDE.md guide](https://www.jdhodges.com/blog/claude-code-claudemd-project-instructions/), [Claude Code Memory guide](https://skillsplayground.com/guides/claude-code-memory/)

### Finding 5: Claude Desktop Uses MCP, Not Skills Directories
- **Description**: Claude Desktop (the standalone app) does not have a native skills directory mechanism. It extends via MCP (Model Context Protocol) servers configured in `claude_desktop_config.json`. MCP servers expose Tools, Resources, and Prompts.
- **Evidence**: Claude Desktop config location on Linux is `~/.config/claude/claude_desktop_config.json`
- **Confidence**: High
- **Source**: [MCP Installation Guide](https://www.claudeskillshq.com/blog/mcp-installation-deep-dive-claude-code-desktop), [Claude Code MCP docs](https://docs.claude.com/en/docs/claude-code/mcp)

### Finding 6: Skill Invocation
- **Description**: Skills become slash commands (e.g., `/deploy-check`). They can also be auto-invoked by Claude Code when contextually relevant, unless `disable-model-invocation: true` is set in frontmatter.
- **Evidence**: Directory name becomes the command name; built-in skills like `/batch`, `/simplify`, `/debug` ship with Claude Code
- **Confidence**: High
- **Source**: [Claude Code skills tutorial](https://www.sitepoint.com/claude-agent-skills-tutorial/)

## Implications

### Architectural Impact
The PRD's proposed `skill.json` format and `~/.config/claude/skills/` path are both incorrect. The installer must:
1. Create `SKILL.md` files instead of `skill.json`
2. Install to `~/.claude/skills/` (not `~/.config/claude/skills/`)
3. Distinguish between Claude Code (skills) and Claude Desktop (MCP) support

### Technology Choices
- SKILL.md with YAML frontmatter + Markdown (not JSON)
- Optional `references/`, `scripts/`, `assets/` subdirectories
- Optional CLAUDE.md for project-level context

### Risk Assessment
- **Low risk**: Agent Skills standard is well-documented and stable
- **Medium risk**: Claude Desktop requires separate MCP server approach if targeted
- **Low risk**: Cursor also reads `.claude/skills/` for compatibility

## Recommendations

1. Use SKILL.md format following the Agent Skills open standard
2. Install global skills to `~/.claude/skills/<name>/SKILL.md`
3. Target Claude Code as the primary Claude product (not Claude Desktop app)
4. Consider optional MCP server packaging for Claude Desktop support as a future enhancement
5. Include a CLAUDE.md template for project-level context

## Related ADRs

- ADR-001: Adopt Agent Skills Open Standard
- ADR-002: Target Claude Code + Cursor
- ADR-004: Correct Installation Target Paths

## References

- [Extend Claude with skills](https://docs.claude.com/en/docs/claude-code/slash-commands.md)
- [Claude Skills Overview](https://claude.com/docs/skills)
- [Claude Code MCP](https://docs.claude.com/en/docs/claude-code/mcp)
- [MCP Installation Guide for Claude](https://www.claudeskillshq.com/blog/mcp-installation-deep-dive-claude-code-desktop)
- [Claude Code CLAUDE.md Guide](https://www.jdhodges.com/blog/claude-code-claudemd-project-instructions/)
- [Claude Code Memory Guide](https://skillsplayground.com/guides/claude-code-memory/)
- [Claude Code Best Practices](https://skillsplayground.com/guides/claude-code-best-practices/)
- [Complete Guide to Building Skills for Claude 2026](https://mcpdirectory.app/blog/complete-guide-building-skills-for-claude-mcp-2026)
- [Agent Skills Specification](https://agentskills.io/specification)
