---
title: Installation
parent: Getting Started
nav_order: 1
---

# Installation

## Prerequisites

- **Bash 4.4+** (RHEL 8/9/10 included; macOS requires `brew install bash`)
- **Git** — for cloning skill documentation from source repositories
- **curl** — for checking updates and installer upgrades
- **jq** or **python3** — for JSON registry management

### RHEL

```bash
sudo dnf install git curl jq
```

### macOS

```bash
brew install bash git curl jq
```

{: .important }
macOS ships bash 3.2.57 by default. You must install a newer version via Homebrew and invoke the installer with the Homebrew bash: `/opt/homebrew/bin/bash install.sh install --all`

## Install the CLI

```bash
git clone https://github.com/tosin2013/rhel-devops-skills-cli.git
cd rhel-devops-skills-cli
```

## Install All Skills

```bash
./install.sh install --all
```

This auto-detects installed IDEs (Claude Code, Cursor) and installs skills to each.

## Install a Single Skill

```bash
./install.sh install --skill agnosticd
```

## Target a Specific IDE

```bash
./install.sh install --all --ide cursor
./install.sh install --skill patternizer --ide claude
```

## Verify Installation

```bash
./install.sh verify --all
```

## What Gets Installed

For each skill, the installer:

1. Clones the source repository (shallow, depth 1)
2. Copies the `SKILL.md` file to the IDE's skills directory
3. Copies documentation files to `references/` within the skill
4. Records the installation in `~/.rhel-devops-skills/registry.json`
5. For Cursor: optionally installs `.mdc` rules to `.cursor/rules/`

### File Layout

```
~/.claude/skills/          # or ~/.cursor/skills-cursor/
  agnosticd/
    SKILL.md               # Agent skill definition
    references/
      REFERENCE.md          # Documentation index
      setup.adoc            # Fetched from upstream
      contributing.adoc
      ...
```
