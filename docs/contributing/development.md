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
  lib/
    common.sh             # Shared utilities, platform detection, prerequisites
    registry.sh           # JSON registry management (jq/python3 fallback)
    fetch-docs.sh         # Clone repos and copy documentation
    validate.sh           # Verify installation integrity
    upgrade.sh            # Skill and installer upgrades
  skills/
    agnosticd/            # AgnosticD v2 skill
    field-sourced-content/ # Field-Sourced Content skill
    patternizer/          # Patternizer skill
  tests/
    test-helpers.sh       # Shared test framework
    test-install.sh       # CLI argument parsing tests
    test-registry.sh      # Registry CRUD tests
    test-validate.sh      # Validation function tests
    test-upgrade.sh       # Upgrade function tests
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
- **ADR-004**: Installation paths (`~/.claude/skills/`, `~/.cursor/skills-cursor/`)
- **ADR-005**: Dual-mode skills + optional Cursor rules
- **ADR-006**: Shell installer with JSON registry
- **ADR-007**: GitHub Pages with Just the Docs
- **ADR-008**: Skill update strategy (auto-check + manual)
- **ADR-009**: Community contributions via GitHub Issues

## Code Style

- Bash 4.4+ features are permitted (associative arrays, `${var,,}`, etc.)
- Use `set -euo pipefail` in all scripts
- Functions are prefixed: `_private()` for internal, `public()` for API
- JSON operations use `jq` with `python3` fallback
- Platform-specific logic uses `detect_platform()` from `lib/common.sh`
