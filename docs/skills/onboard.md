---
title: Onboard
parent: Skills
nav_order: 15
---

# Onboard Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The Onboard skill automates project setup for AgnosticD workshops, demos, and validated patterns. It reads a declarative manifest (`onboard.yml`) shipped by any consuming project and walks the user through installing prerequisites, configuring the environment, and validating deployment readiness.

Every AgnosticD-based project has the same onboarding pattern: prerequisites, secrets, configuration, deploy. Instead of users reading hundreds of lines of setup documentation, the AI assistant reads the manifest and handles each step interactively -- installing missing tools, asking configuration questions, writing config files, and running preflight checks.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Cloning a project and asking for help setting it up
- Asking "how do I get started" or "help me deploy" in a project that has an `onboard.yml`
- Asking about prerequisites, environment setup, or first-time configuration
- Saying "onboard me" or "run onboard"

## The Onboarding Process

The skill follows a seven-phase workflow:

| Phase | What Happens |
|-------|-------------|
| **0 -- Manifest Discovery** | Finds and reads `onboard.yml` from the project directory; asks dev or prod mode |
| **1 -- Platform Detection** | Detects the OS (RHEL 8/9/10, Fedora, macOS, Debian/Ubuntu) to select correct install commands |
| **2 -- Prerequisites** | Checks each declared tool, installs missing ones with user confirmation; dev mode adds extra tools for maintainers |
| **3 -- Setup Steps** | Runs ordered setup tasks (clone repos, run `agd setup`, scaffold files), skipping already-completed steps |
| **4 -- Configuration** | Prompts for project-specific values, writes a local config file (git-ignored) |
| **5 -- Validation** | Runs preflight checks, computes a readiness score, and blocks deployment if any required check fails |
| **6 -- Post-Setup** | Shows next steps; in prod mode, optionally runs the deploy script |
| **7 -- Generate Bootstrap** | Creates a standalone `bootstrap.sh` for humans without AI agents |

## Dev vs Prod Modes

The manifest supports two modes to serve different audiences:

| Mode | Audience | What it does |
|------|----------|-------------|
| **dev** | Repo maintainers and contributors | Installs base prerequisites plus dev-only tools (linters, test frameworks, pre-commit hooks). Does not deploy. |
| **prod** (default) | End users who want to deploy | Installs runtime prerequisites, configures deployment, validates, and optionally runs the deploy script. |

The AI agent asks which mode the user wants. The generated `bootstrap.sh` accepts `--mode dev|prod`.

## Bootstrap Script Generation

The skill generates a `bootstrap.sh` that reads `onboard.yml` at runtime using python3 + PyYAML. Because the script reads the manifest dynamically, editing `onboard.yml` changes bootstrap behavior immediately -- no regeneration needed.

```bash
./bootstrap.sh                    # prod mode (default)
./bootstrap.sh --mode dev         # maintainer setup
./bootstrap.sh --non-interactive  # use all defaults (CI)
./bootstrap.sh --check-only       # validation only
```

The generated script is committed to the consuming project's repo alongside `onboard.yml`, giving every user a one-command setup path regardless of whether they have AI tooling. The only runtime dependencies are python3 and PyYAML (both ship on RHEL).

### Readiness Gate

The bootstrap script enforces a strict readiness gate during validation. It reports a score like `Readiness: 4/5 required checks passed` and blocks deployment if any required check fails. Warnings are informational and do not block.

## The `onboard.yml` Manifest

Each consuming project ships an `onboard.yml` (committed to git) that declares what the onboard skill should do. The manifest has six sections:

| Section | Purpose |
|---------|---------|
| `prerequisites` | Tools to check/install, with per-platform commands and version requirements |
| `setup_steps` | Ordered tasks with idempotency checks (e.g., clone repo, run setup) |
| `config` | Interactive prompts and where to write the config file |
| `validation` | Preflight commands with pass/fail/warn reporting |
| `post_setup` | Message shown after setup completes |
| `modes` | Optional dev/prod mode definitions with extra prerequisites and deploy commands |

See the full schema in the skill's `references/manifest-spec.md` and a complete working example in `references/example-manifest.yml`.

## Supported Platforms

Prerequisites in the manifest declare install commands per platform:

| Platform Key | Matches |
|-------------|---------|
| `rhel8` | RHEL 8.x, CentOS Stream 8 |
| `rhel9` | RHEL 9.x, CentOS Stream 9 |
| `rhel10` | RHEL 10.x |
| `fedora` | Fedora (any version) |
| `debian` | Debian, Ubuntu, and derivatives |
| `macos` | macOS (assumes Homebrew) |
| `fallback` | Manual instructions for unknown platforms |

## Config Output

The skill writes a flat YAML config file (e.g., `agnosticd/config.yml`) that deploy scripts can source. Environment variables override config file values, maintaining backward compatibility:

```bash
make deploy                    # reads saved config
NUM_STUDENTS=5 make deploy     # overrides one value
```

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [AgnosticD v2](agnosticd.html) | Most common consumer -- onboard installs AgnosticD prerequisites and configures deployment variables |
| [AgnosticD Hub-Student](agnosticd-hub-student.html) | Hub+student topologies use onboard for initial setup, then hub-student for multi-cluster provisioning |
| [Field-Sourced Content](field-sourced-content.html) | Field content repos can ship `onboard.yml` for their simpler prerequisite set |
| [Student Readiness](student-readiness.html) | After onboard + deploy, use student-readiness to verify the environment is ready for students |
| [Showroom](showroom.html) | Showroom-based workshops benefit from onboard for cross-platform prerequisite installation |
| [Patternizer](patternizer.html) | Validated Pattern repos can ship `onboard.yml` for pattern-specific setup |

## For Project Authors

To add onboard support to your project:

1. Create an `onboard.yml` in your project root (use the example manifest as a starting template)
2. Declare prerequisites with per-platform install commands
3. Define config prompts for deployment-specific values
4. Add validation checks for secrets, credentials, and infrastructure
5. Write a post-setup message with next steps

The AI assistant can also help you create the manifest -- just ask it to generate an `onboard.yml` from your project's existing setup documentation.

After creating the manifest, ask the AI to generate a `bootstrap.sh` so users without AI agents can onboard too.

## Install

```bash
./install.sh install --skill onboard
```
