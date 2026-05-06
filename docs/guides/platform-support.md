---
title: Platform Support
parent: Guides
nav_order: 2
---

# Platform Support

## Linux (RHEL)

| Version | Bash | Notes |
|---------|------|-------|
| RHEL 8 | 4.4 | Minimum supported (bash 4.4+) |
| RHEL 9 | 5.1 | Recommended |
| RHEL 10 | 5.2.26 | Fully supported |
| Fedora 41+ | 5.2+ | Supported |

### Install Prerequisites

```bash
sudo dnf install git curl jq
```

## macOS

| Version | Default Bash | Required |
|---------|-------------|----------|
| macOS (any) | 3.2.57 | Must use Homebrew bash 5.x |

macOS ships an outdated bash (3.2.57) due to licensing. The installer requires bash 4.4+.

### Install Prerequisites

```bash
brew install bash git curl jq
```

### Running the Installer

```bash
# Option 1: Invoke with Homebrew bash directly
/opt/homebrew/bin/bash install.sh install --all

# Option 2: Add Homebrew bash to your shell
echo '/opt/homebrew/bin/bash' | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/bash
```

## IDE Support

### Claude Code

- **Skill path**: `~/.claude/skills/<skill-name>/`
- **Detection**: Checks for `~/.claude/` directory
- **Format**: `SKILL.md` with `references/` subdirectory

### Cursor IDE

- **Skill path**: `~/.cursor/skills-cursor/<skill-name>/`
- **Rules path**: `.cursor/rules/<skill-name>.mdc` (project-level)
- **Detection**: Checks for `~/.cursor/` directory
- **Format**: `SKILL.md` + optional `.mdc` rule files
