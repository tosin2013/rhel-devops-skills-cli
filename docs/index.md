---
title: Home
layout: home
nav_order: 1
---

# RHEL DevOps Skills CLI
{: .fs-9 }

A centralized installer for AI assistant skills — providing deep knowledge of AgnosticD v2, Field-Sourced Content, and Patternizer to Claude Code and Cursor IDE.
{: .fs-6 .fw-300 }

[Get Started](getting-started/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/tosin2013/rhel-devops-skills-cli){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Quick Start

```bash
git clone https://github.com/tosin2013/rhel-devops-skills-cli.git
cd rhel-devops-skills-cli
./install.sh install --all
```

## Available Skills

| Skill | Description | Source Repository |
|-------|-------------|-------------------|
| [agnosticd](skills/agnosticd.html) | AgnosticD v2 — Ansible Agnostic Deployer for cloud provisioning | [agnosticd/agnosticd-v2](https://github.com/agnosticd/agnosticd-v2) |
| [field-sourced-content](skills/field-sourced-content.html) | RHDP self-service catalog items via GitOps (Helm/Ansible) | [rhpds/field-sourced-content-template](https://github.com/rhpds/field-sourced-content-template) |
| [patternizer](skills/patternizer.html) | Bootstrap Git repos into Validated Patterns for OpenShift | [tosin2013/patternizer](https://github.com/tosin2013/patternizer) |

## Supported Platforms

| Platform | Bash Version | Status |
|----------|-------------|--------|
| RHEL 8 | 4.4 | Supported (minimum) |
| RHEL 9 | 5.1 | Supported |
| RHEL 10 | 5.2.26 | Supported |
| macOS (Homebrew) | 5.2+ | Supported |

## Supported IDEs

| IDE | Skill Format | Extra Features |
|-----|-------------|----------------|
| [Claude Code](https://docs.claude.com/) | `SKILL.md` + `references/` | Agent Skills standard |
| [Cursor IDE](https://www.cursor.com/) | `SKILL.md` + `references/` | Optional `.cursor/rules/*.mdc` |
