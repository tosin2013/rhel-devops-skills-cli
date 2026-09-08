---
title: Development Guide
parent: Contributing
nav_order: 2
---

# Development Guide

## Repository Structure

```
rhel-devops-skills-cli/
  install.sh              # Main entry point
  LICENSE                 # Apache-2.0 license
  CONTRIBUTING.md         # Quick-start contributing guide
  README.md               # Project overview and usage
  lib/
    common.sh             # Shared utilities, platform detection, prerequisites
    registry.sh           # JSON registry management (jq/python3 fallback)
    fetch-docs.sh         # Clone repos and copy documentation
    validate.sh           # Verify installation integrity
    upgrade.sh            # Skill and installer upgrades
    scaffold.sh           # Project scaffolding from templates
  skills/
    agnosticd/            # AgnosticD v2 skill
    field-sourced-content/ # Field-Sourced Content skill
    patternizer/          # Patternizer skill
    showroom/             # Showroom skill
    ...                   # (16 skills total)
  templates/              # Scaffold templates (demo, infra, shared-cluster, etc.)
  tests/
    test-helpers.sh       # Shared test framework
    test-install.sh       # CLI argument parsing tests
    test-registry.sh      # Registry CRUD tests
    test-validate.sh      # Validation function tests
    test-upgrade.sh       # Upgrade function tests
    test-scaffold.sh      # Scaffold function tests
    run-all.sh            # Test runner
  docs/                   # GitHub Pages documentation
  .github/
    workflows/
      test.yml            # CI tests (Ubuntu + macOS)
      release.yml         # Release automation
      deploy-docs.yml     # GitHub Pages deployment
    ISSUE_TEMPLATE/
      new-skill-request.yml
```

## Running Tests

```bash
bash tests/run-all.sh
```

Tests create isolated temp directories and mock `$HOME` to avoid side effects.

## Design Decisions

All architectural decisions are documented in [ADRs](../adrs/):

- **ADR-001**: Agent Skills standard (`SKILL.md`) over custom formats
- **ADR-002**: Target Claude Code and Cursor IDE
- **ADR-003**: Documentation embedding via `references/`
- **ADR-004**: Installation paths (`~/.claude/skills/`, `~/.cursor/skills-cursor/`, `~/.agents/skills/`)
- **ADR-005**: Dual-mode skills + optional Cursor rules
- **ADR-006**: Shell installer with JSON registry
- **ADR-007**: GitHub Pages with Just the Docs
- **ADR-008**: Skill update strategy (auto-check + manual)
- **ADR-009**: Community contributions via GitHub Issues

## Cross-Tool Installation Targets

The installer supports three target types:

| `--ide` value | Path | Compatible tools |
|---------------|------|------------------|
| `claude` | `~/.claude/skills/` | Claude Code |
| `cursor` | `~/.cursor/skills-cursor/` | Cursor IDE |
| `agents` | `~/.agents/skills/` | Codex, Copilot, Cursor, Goose, Gemini CLI, and 40+ Agent Skills standard tools |
| `both` | Claude + Cursor | (auto-detect) |
| `all` | Claude + Cursor + agents | (all paths) |
| (default) | Auto-detect Claude + Cursor | |

When testing changes, verify at minimum:

```bash
./install.sh install --skill agnosticd --ide claude --dry-run
./install.sh install --skill agnosticd --ide cursor --dry-run
./install.sh install --skill agnosticd --ide agents --dry-run
```

## Code Style

- Bash 4.4+ features are permitted (associative arrays, `${var,,}`, etc.)
- Use `set -euo pipefail` in all scripts
- Functions are prefixed: `_private()` for internal, `public()` for API
- JSON operations use `jq` with `python3` fallback
- Platform-specific logic uses `detect_platform()` from `lib/common.sh`
