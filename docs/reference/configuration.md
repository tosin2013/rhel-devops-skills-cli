---
title: Configuration
parent: Reference
nav_order: 2
---

# Configuration

## Per-Skill Config Files

Each skill has a `config.sh` file in `skills/<name>/config.sh` that defines:

```bash
SKILL_NAME="agnosticd"
UPSTREAM_REPO="https://github.com/agnosticd/agnosticd-v2"
FORK_REPO=""                    # optional override
BRANCH="main"
DOC_PATHS=(
    "docs/setup.adoc"
    "docs/contributing.adoc"
    "README.adoc"
)
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `SKILL_NAME` | Yes | Identifier matching the directory name |
| `UPSTREAM_REPO` | Yes | Primary source repository URL |
| `FORK_REPO` | No | Fork URL; used instead of upstream if set |
| `BRANCH` | Yes | Git branch to fetch from |
| `DOC_PATHS` | Yes | Array of file paths to copy into `references/` |

### Using a Fork

To use a fork instead of the upstream repository, set `FORK_REPO` in the skill's `config.sh`:

```bash
FORK_REPO="https://github.com/your-username/agnosticd-v2"
```

The installer uses `FORK_REPO` when set, falling back to `UPSTREAM_REPO`.

## Registry

The registry at `~/.rhel-devops-skills/registry.json` tracks:

- Installed skills and their source repositories
- Commit hash at install/update time
- Which IDEs each skill is installed to
- Whether automatic update checking is enabled

### Registry Location

Override with the `RHEL_DEVOPS_SKILLS_HOME` environment variable:

```bash
export RHEL_DEVOPS_SKILLS_HOME=/custom/path
./install.sh install --all
```

## Cursor Rules

When installing to Cursor, `.mdc` rule files from `skills/<name>/rules/` are copied to `.cursor/rules/` in the current project. Rules use glob patterns to activate only on relevant files:

```yaml
---
description: AgnosticD v2 conventions
globs: ["**/configs/**/*", "**/roles/**/tasks/*.yml"]
alwaysApply: false
---
```
