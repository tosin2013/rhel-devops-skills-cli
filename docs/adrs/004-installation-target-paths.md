---
title: "ADR-004: Installation Target Paths"
nav_order: 4
parent: Architecture Decision Records
---

# ADR-004: Correct Installation Target Paths for Claude Code and Cursor

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team
* Research: [Claude Code Skill System](../research/claude-code-skill-system.html), [Cursor IDE Skill and Rules System](../research/cursor-ide-skill-and-rules-system.html)

## Context and Problem Statement

The PRD uses tentative installation paths (`~/.config/claude/skills/`, `~/.cursor/skills/`) that are partially incorrect. Research has identified the actual, documented paths for each platform. Additionally, Cursor explicitly loads skills from `.claude/skills/` for cross-compatibility, which creates an opportunity to install once and serve both platforms.

What are the correct installation paths, and can we optimize for cross-platform compatibility?

## Decision Drivers

* Claude Code loads skills from `~/.claude/skills/<name>/SKILL.md` (global) and `.claude/skills/` (project)
* Cursor loads skills from `~/.cursor/skills/<name>/SKILL.md` (global) and `.cursor/skills/` (project)
* Cursor ALSO loads from `~/.claude/skills/` and `.claude/skills/` for cross-compatibility
* Installing to `~/.claude/skills/` makes skills visible to both platforms
* The PRD's `~/.config/claude/skills/` path does not exist in either platform
* Global (user-level) installation is the primary use case for rhel-devops-skills-cli
* Claude Desktop config is at `~/.config/claude/claude_desktop_config.json` (MCP only, not skills)

## Considered Options

1. **Install to `~/.claude/skills/` only** -- Single location, both platforms see it
2. **Install to both `~/.claude/skills/` and `~/.cursor/skills/`** -- Explicit per-platform installation
3. **Install to `~/.config/claude/skills/`** -- As proposed in PRD (incorrect path)
4. **Install to `~/.cursor/skills/` only** -- Cursor-specific only

## Decision Outcome

Chosen option: **"Install to both `~/.claude/skills/` and `~/.cursor/skills/` with `--ide` flag control"**, because it provides explicit, per-platform installation with clear user control, while defaulting to both platforms when both are detected.

### Installation Path Matrix

| Flag | Claude Code Detected | Cursor Detected | Installs To |
|------|---------------------|-----------------|-------------|
| `--ide claude` | Yes | - | `~/.claude/skills/<name>/` |
| `--ide cursor` | - | Yes | `~/.cursor/skills/<name>/` |
| `--ide both` | Yes | Yes | Both paths |
| (no flag) | Yes | Yes | Both paths (auto-detect) |
| (no flag) | Yes | No | `~/.claude/skills/<name>/` |
| (no flag) | No | Yes | `~/.cursor/skills/<name>/` |

### Detection Logic

```bash
detect_claude() {
    # Claude Code creates ~/.claude/ on first use
    [ -d "$HOME/.claude" ]
}

detect_cursor() {
    # Cursor creates ~/.cursor/ on first use
    [ -d "$HOME/.cursor" ]
}
```

### Installed File Layout

```
~/.claude/skills/agnosticd/
  SKILL.md
  references/
    setup.adoc
    catalog-items.adoc
  scripts/
  assets/

~/.cursor/skills/agnosticd/
  SKILL.md
  references/
    setup.adoc
    catalog-items.adoc
  scripts/
  assets/
```

### macOS Path Confirmation

On macOS, both Claude Code and Cursor use the **same home-directory paths** as on Linux:
- Claude Code: `~/.claude/skills/` (global), `.claude/skills/` (project)
- Cursor: `~/.cursor/skills/` (global), `.cursor/skills/` (project)

There is **no** `~/Library/Application Support/` variant for skills. Claude Desktop's MCP config on macOS resides at `~/Library/Application Support/Claude/claude_desktop_config.json`, but that is for MCP servers (not skills) and is out of scope per [ADR-002](002-target-claude-code-and-cursor.html).

This means the installer requires **no platform-specific path logic** -- the same `$HOME/.claude/skills/` and `$HOME/.cursor/skills/` paths work on both RHEL and macOS.

### Alternative: Cross-Compatibility Shortcut

Since Cursor loads from `~/.claude/skills/`, installing ONLY to `~/.claude/skills/` would make skills visible to both platforms. However, this creates a confusing user experience where Cursor users find their skills in a Claude directory. Explicit per-platform installation is clearer.

### Positive Consequences

* Uses correct, documented paths for each platform
* Explicit per-platform installation avoids user confusion
* Auto-detection installs to all detected platforms by default
* `--ide` flag gives users full control
* Registry tracks exactly where each skill is installed
* Uninstallation is clean and complete

### Negative Consequences

* Duplicate files when both platforms are installed (disk space, minor)
* Skills in `~/.claude/skills/` are visible to both Claude Code AND Cursor (potential double-loading)
* Need to update both locations during skill updates
* Users may be confused if they see skills in one location but not the other

## Links

* [Cursor Skills Documentation](https://www.cursor.com/docs/context/skills) -- Lists all skill directory locations including cross-compatibility paths
* [Claude Code Skills Documentation](https://docs.claude.com/en/docs/claude-code/slash-commands.md) -- Confirms `~/.claude/skills/` as global location
* [Claude Code .claude directory](https://code.claude.com/docs/en/claude-directory) -- Confirms `~/.claude/` path on all platforms including macOS
* [Claude Code CLAUDE.md Guide](https://www.jdhodges.com/blog/claude-code-claudemd-project-instructions/) -- Documents Claude Code file locations
* Related: [ADR-001](001-adopt-agent-skills-standard.html), [ADR-002](002-target-claude-code-and-cursor.html), [ADR-005](005-dual-mode-skills-and-rules.html)
* Supersedes: PRD Section 5.6 "File System" paths and Appendix B "File Locations"
