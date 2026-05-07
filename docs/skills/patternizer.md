---
title: Patternizer
parent: Skills
nav_order: 3
---

# Patternizer Skill

**Source Repository**: [tosin2013/patternizer](https://github.com/tosin2013/patternizer) (fork of [validatedpatterns/patternizer](https://github.com/validatedpatterns/patternizer))
{: .fs-5 }

## Overview

Patternizer is a CLI tool that bootstraps Git repositories containing Helm charts into ready-to-use [Validated Patterns](https://validatedpatterns.io/) for OpenShift. It runs as a container via Podman and generates the scaffolding needed for pattern deployment.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Initializing a new Validated Pattern
- Upgrading existing patterns to latest common structure
- Working with generated files (values-global.yaml, pattern.sh, Makefile)
- Configuring secrets management
- Deploying patterns to OpenShift
- Generating independent `deploy.sh` / `teardown.sh` scripts for your pattern repo

## Key Commands

```bash
# Initialize a new pattern
podman run --pull=newer -v "$PWD:$PWD:z" -w "$PWD" \
  quay.io/validatedpatterns/patternizer init

# Initialize with secrets (Vault + External Secrets Operator)
podman run --pull=newer -v "$PWD:$PWD:z" -w "$PWD" \
  quay.io/validatedpatterns/patternizer init --with-secrets

# Upgrade pattern to latest common structure
podman run --pull=newer -v "$PWD:$PWD:z" -w "$PWD" \
  quay.io/validatedpatterns/patternizer upgrade
```

## Generated Files

| File | Purpose |
|------|---------|
| `values-global.yaml` | Global pattern configuration |
| `values-<cluster>.yaml` | Cluster group-specific values |
| `pattern.sh` | Utility script for install/upgrade |
| `Makefile` / `Makefile-common` | Build targets |
| `ansible.cfg` | Ansible configuration |

## Independent Deployment Scripts

The skill guides you to create two standalone scripts in your pattern repo root (committed to git — they contain no secrets):

| Script | Wraps | Notes |
|--------|-------|-------|
| `deploy.sh` | `pattern.sh make install` | Pre-checks for `values-secret.yaml` before running (submission-blocking requirement) |
| `teardown.sh` | `pattern.sh make uninstall` | Prompts for confirmation before uninstalling |

Both scripts are safe to commit. `values-secret.yaml` must **never** be committed — add it to `.gitignore`.

## Reference Documentation

| Document | Description |
|----------|-------------|
| `README.md` | Usage, container commands, generated files |

## Install

```bash
./install.sh install --skill patternizer
```
