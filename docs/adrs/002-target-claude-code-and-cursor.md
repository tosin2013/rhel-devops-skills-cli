---
title: "ADR-002: Target Claude Code and Cursor"
nav_order: 2
parent: Architecture Decision Records
---

# ADR-002: Target Claude Code and Cursor IDE (Not Claude Desktop App)

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team
* Research: [Claude Code Skill System](../research/claude-code-skill-system.html), [Model Context Protocol (MCP)](../research/model-context-protocol-mcp.html)

## Context and Problem Statement

The PRD generically references "Claude Desktop" as a target platform for skill installation alongside Cursor IDE. Research reveals that "Claude Desktop" (the standalone Electron app) and "Claude Code" (the CLI/IDE agent) are **separate products** with fundamentally different extension mechanisms:

| Product | Extension Mechanism | Skill Format |
|---------|-------------------|-------------|
| Claude Desktop (app) | MCP servers via `claude_desktop_config.json` | No native skills directory |
| Claude Code (CLI/IDE) | `.claude/skills/SKILL.md` + MCP servers | Agent Skills standard |
| Cursor IDE | `.cursor/skills/SKILL.md` + `.cursor/rules/*.mdc` | Agent Skills standard |

For the use case of providing documentation and workflow guidance (not live tool execution), Agent Skills (SKILL.md) are the appropriate mechanism. This means Claude Code and Cursor are the correct target platforms.

Which Claude product(s) and IDE(s) should the installer target?

## Decision Drivers

* Claude Desktop uses MCP servers exclusively -- no skills directory mechanism
* Claude Code and Cursor both support the same SKILL.md format (ADR-001)
* Cursor automatically loads skills from `.claude/skills/` for cross-compatibility
* MCP server packaging adds runtime complexity (requires a running process)
* The primary use case is static documentation and workflow guidance, not live tool execution
* Simplicity of the initial release is a priority

## Considered Options

1. **Claude Code + Cursor IDE** -- Target both SKILL.md-supporting platforms
2. **Claude Desktop via MCP servers** -- Package skills as MCP servers for the standalone app
3. **All three (Claude Desktop + Claude Code + Cursor)** -- Support all platforms
4. **Cursor only** -- Target only Cursor IDE

## Decision Outcome

Chosen option: **"Claude Code + Cursor IDE"**, because both support the Agent Skills standard (SKILL.md), enabling a single skill format to serve both platforms. Claude Desktop support via MCP server packaging is deferred to a future release.

The installer will:
- Detect Claude Code by checking for `~/.claude/` directory
- Detect Cursor by checking for `~/.cursor/` directory
- Install SKILL.md-based skills to the appropriate directories
- Report which platforms were detected and configured

### Positive Consequences

* Both platforms support the same SKILL.md format, simplifying the installer
* Skills installed to `~/.claude/skills/` are automatically visible to both Claude Code AND Cursor (Cursor's compatibility loading)
* No MCP server runtime needed for initial release
* Simpler installer with fewer failure modes
* Clear, well-documented platform support matrix

### Negative Consequences

* Claude Desktop (standalone app) users cannot use skills without Claude Code also being installed
* Some users may not distinguish between Claude Desktop and Claude Code; clear documentation is critical
* MCP-based features (live tools, dynamic resources) are deferred
* Users who only have Claude Desktop will need guidance on installing Claude Code

## Links

* [Claude Code MCP Documentation](https://docs.claude.com/en/docs/claude-code/mcp) -- MCP is for both Code and Desktop, but skills are Code-only
* [Claude Desktop MCP Config Guide](https://www.claudeskillshq.com/blog/mcp-installation-deep-dive-claude-code-desktop) -- Desktop uses `claude_desktop_config.json`, not skills directories
* [Claude Skills Overview](https://claude.com/docs/skills) -- Describes skills as part of Claude Code
* [Cursor Skills Documentation](https://www.cursor.com/docs/context/skills) -- Cursor loads from `.claude/skills/` for cross-compatibility
* [MCP Specification](https://modelcontextprotocol.io/specification/latest) -- MCP is for dynamic tool integration, not static documentation
* Related: [ADR-001](001-adopt-agent-skills-standard.html), [ADR-004](004-installation-target-paths.html)
