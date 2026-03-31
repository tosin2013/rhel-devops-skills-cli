---
title: CLI Reference
parent: Reference
nav_order: 1
---

# CLI Reference

## Synopsis

```
./install.sh [OPTIONS] COMMAND [ARGS]
```

## Commands

### `install`

Install skill(s) to detected IDEs.

```bash
./install.sh install --skill <name>    # Install one skill
./install.sh install --all             # Install all skills
```

### `uninstall`

Remove skill(s) from IDEs and registry.

```bash
./install.sh uninstall --skill <name>
./install.sh uninstall --all
```

### `update`

Update skill documentation from upstream repositories.

```bash
./install.sh update --skill <name>
./install.sh update --all
```

### `check-updates`

Check if any installed skills have upstream changes.

```bash
./install.sh check-updates
```

### `verify`

Validate skill installation integrity.

```bash
./install.sh verify --skill <name>
./install.sh verify --all
./install.sh verify                    # same as --all
```

### `list`

Show installed skills with commit hash, date, and target IDEs.

```bash
./install.sh list
```

### `available`

Show all available skills with repository URLs.

```bash
./install.sh available
```

### `upgrade-installer`

Check for and install updates to the installer itself.

```bash
./install.sh upgrade-installer
```

### `help`

Show the help message.

```bash
./install.sh help
```

## Options

| Option | Description |
|--------|-------------|
| `--ide <claude\|cursor\|both>` | Target specific IDE (default: auto-detect) |
| `--verbose`, `-v` | Enable verbose debug output |
| `--dry-run` | Show what would be done without changes |
| `--force`, `-f` | Force operation even if already up to date |
| `--no-auto-check` | Disable automatic update checks on install |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 2 | Invalid arguments |
| 3 | Missing prerequisites |
| 4 | Network / fetch error |
| 6 | IDE not detected or skill not found |
| 10 | Validation failure |
| 11 | Corrupted registry |
| 12 | Upgrade failure |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RHEL_DEVOPS_SKILLS_HOME` | Data directory path | `~/.rhel-devops-skills` |
| `RHEL_DEVOPS_SKILLS_VERBOSE` | Enable verbose output | `false` |
| `GITHUB_TOKEN` | GitHub API token for private repos / rate limits | unset |
