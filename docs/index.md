---
title: Home
layout: home
nav_order: 1
---

# RHEL DevOps Skills CLI

A centralized installation system for AI assistant skills (Claude Code and Cursor IDE) that provide deep knowledge for RHEL DevOps tooling.
{: .fs-6 .fw-300 }

[Get Started](#quick-start){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/tosin2013/rhel-devops-skills-cli){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Quick Start

```bash
git clone https://github.com/tosin2013/rhel-devops-skills-cli.git
cd rhel-devops-skills-cli
./install.sh --skill agnosticd
```

## Available Skills

| Skill | Description |
|-------|-------------|
| **agnosticd** | AgnosticD v2 catalog item development and deployment automation |
| **field-sourced-content** | OpenShift GitOps-based workshop/demo deployment |
| **patternizer** | Kubernetes/OpenShift pattern generation |

## Supported Platforms

| Platform | Bash | Status |
|----------|------|--------|
| RHEL 8 | 4.4 | Supported (minimum) |
| RHEL 9 | 5.1 | Supported |
| RHEL 10 | 5.2 | Supported |
| macOS (Homebrew) | 5.2+ | Supported |

## Architecture Decision Records

Research-backed decisions that correct the PRD's assumptions about Claude and Cursor skill systems.

| ADR | Decision |
|-----|----------|
| [001](adrs/001-adopt-agent-skills-standard.md) | Adopt Agent Skills Open Standard (SKILL.md) |
| [002](adrs/002-target-claude-code-and-cursor.md) | Target Claude Code and Cursor IDE |
| [003](adrs/003-documentation-embedding-strategy.md) | Documentation Embedding via references/ |
| [004](adrs/004-installation-target-paths.md) | Correct Installation Target Paths |
| [005](adrs/005-dual-mode-skills-and-rules.md) | Dual-Mode Installation (Skills + Rules) |
| [006](adrs/006-shell-installer-architecture.md) | Shell Installer Architecture |
| [007](adrs/007-github-pages-documentation-site.md) | GitHub Pages Documentation Site |

## Research Documents

External research with authoritative source links backing the ADRs.

| Topic | Key Sources |
|-------|------------|
| [Agent Skills Open Standard](research/agent-skills-open-standard.md) | [agentskills.io](https://agentskills.io/specification), [GitHub](https://github.com/agentskills/agentskills) |
| [Claude Code Skill System](research/claude-code-skill-system.md) | [docs.claude.com](https://docs.claude.com/en/docs/claude-code/slash-commands.md), [claude.com/docs/skills](https://claude.com/docs/skills) |
| [Cursor IDE Skill and Rules System](research/cursor-ide-skill-and-rules-system.md) | [cursor.com/docs/skills](https://www.cursor.com/docs/context/skills), [cursor.com/docs/rules](https://www.cursor.com/docs/context/rules) |
| [Model Context Protocol (MCP)](research/model-context-protocol-mcp.md) | [modelcontextprotocol.io](https://modelcontextprotocol.io/specification/latest) |
| [RHEL and macOS Compatibility](research/rhel-bash-and-tooling-compatibility.md) | [RHEL 10 docs](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10), [Homebrew](https://brew.sh/) |
