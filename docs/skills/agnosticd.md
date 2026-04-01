---
title: AgnosticD v2
parent: Skills
nav_order: 1
---

# AgnosticD v2 Skill

**Source Repository**: [agnosticd/agnosticd-v2](https://github.com/agnosticd/agnosticd-v2)
{: .fs-5 }

## Overview

AgnosticD v2 is the Ansible Agnostic Deployer — a framework for provisioning infrastructure and deploying workloads on AWS, Azure, OpenStack, and OpenShift. This skill teaches your AI assistant how to use the `agd` CLI, configure deployments, and follow AgnosticD best practices.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Setting up the AgnosticD v2 local development environment
- Running `agd` commands (setup, provision, destroy, stop, start, status)
- Creating or modifying configs and workloads
- Configuring secrets files or account credentials
- Setting up a fork for workshop development
- Deploying Field-Sourced Content or Showroom as workloads
- Debugging deployment failures

## Key Concepts

### The `agd` CLI

All operations use `./bin/agd` from within the `agnosticd-v2` directory:

```bash
./bin/agd setup                                            # one-time setup
./bin/agd provision -g myguid -c my-config -a my-account   # deploy
./bin/agd destroy -g myguid -c my-config -a my-account     # teardown
```

### Directory Structure

AgnosticD v2 requires sibling directories (created by `agd setup`):

```
agnosticd-v2/             # code repository
agnosticd-v2-vars/        # configuration variables
agnosticd-v2-secrets/     # secrets (never committed)
agnosticd-v2-output/      # ansible run output
agnosticd-v2-virtualenv/  # Python venv with ansible-navigator
```

## Fork Workflow

Users developing workshops should **fork** `agnosticd-v2` to their own GitHub org. Custom configs and workloads live in the fork; only generic improvements (bug fixes, core features) should be submitted as PRs to upstream.

```bash
git clone https://github.com/your-org/agnosticd-v2.git
cd agnosticd-v2
git remote add upstream https://github.com/agnosticd/agnosticd-v2.git
```

Workshop-specific variables go in `agnosticd-v2-vars/` and secrets in `agnosticd-v2-secrets/` -- both outside the repo, never committed.

## Related Skills

| Skill | Integration |
|-------|-------------|
| [Field-Sourced Content](field-sourced-content.html) | AgnosticD deploys field content via the `ocp4_workload_field_content` workload role |
| [Showroom](showroom.html) | AgnosticD deploys Showroom lab guides via the `ocp4_workload_showroom` infra_workload |
| [Student Readiness](student-readiness.html) | After provisioning, verify the environment is ready for students end-to-end |

See [ADR-010](../adrs/010-cross-skill-dependencies.html) for the cross-skill dependency model and [ADR-011](../adrs/011-e2e-validation-and-troubleshooting.html) for validation and troubleshooting.

## Reference Documentation

When installed, the `references/` directory includes:

| Document | Description |
|----------|-------------|
| `setup.adoc` | Development environment setup (RHEL, macOS, Fedora) |
| `contributing.adoc` | Contribution guidelines and PR format |
| `conversion_guide.adoc` | Migrating from AgnosticD v1 to v2 |
| `git-style-guide.adoc` | Git conventions for the project |
| `core-workloads-catalog.md` | Catalog of all 35 core_workloads roles with descriptions |

## Install

```bash
./install.sh install --skill agnosticd
```
