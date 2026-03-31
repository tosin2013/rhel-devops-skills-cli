---
title: Getting Started
nav_order: 2
has_children: true
---

# Getting Started

Get AI-powered DevOps skills installed in your IDE in under a minute.

## Quick Start

```bash
# 1. Clone the installer
git clone https://github.com/tosin2013/rhel-devops-skills-cli.git
cd rhel-devops-skills-cli

# 2. Install all skills to your detected IDEs
./install.sh install --all

# 3. Verify everything installed correctly
./install.sh verify --all
```

## Prerequisites

| Tool | Required | Install (RHEL) | Install (macOS) |
|------|----------|----------------|-----------------|
| Bash 4.4+ | Yes | Included in RHEL 8+ | `brew install bash` |
| Git | Yes | `sudo dnf install git` | `brew install git` |
| curl | Yes | `sudo dnf install curl` | `brew install curl` |
| jq or python3 | One of | `sudo dnf install jq` | `brew install jq` |

## What's in This Section

- **[Installation](installation.html)** -- Full setup guide with prerequisites, single-skill and multi-skill install, IDE targeting, and file layout details
- **[Updating Skills](updating.html)** -- How to check for upstream changes, update installed skills, and upgrade the installer itself
