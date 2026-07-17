---
title: RHEL DevOps Auditor
parent: Skills
nav_order: 16
---

# RHEL DevOps Auditor Skill

**Type**: Meta-auditor (no upstream repository)
{: .fs-5 }

## Overview

The RHEL DevOps Auditor skill audits projects against established standards in the rhel-devops-skills-cli ecosystem. It produces structured PASS/WARN/FAIL reports with prioritized remediation plans containing executable commands.

This is a meta-auditor that dispatches to specific check modules and aggregates findings across four domains: AgnosticD configuration, onboard.yml manifests, deployed environments, and project file structure.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "audit this project" or "check compliance"
- Asking "how does this project compare to standards"
- Validating a project after scaffolding
- Asking "what's missing" or "what do I need to fix"
- Requesting a pre-review gap analysis

## Audit Modules

| Module | Domain | Checks |
|--------|--------|--------|
| Module 1 | AgnosticD Config | Config structure, role references, variable definitions, secrets handling |
| Module 2 | Onboard Manifest | `onboard.yml` schema compliance, prerequisite completeness, validation coverage |
| Module 3 | Deployment | Live environment health, workload completion, credential flow |
| Module 4 | Project Structure | File layout, Makefile targets, script conventions, `.gitignore` |

## Audit Modes

| Mode | Modules Run | When to Use |
|------|-------------|-------------|
| `full` | All 4 modules | Default; comprehensive project audit |
| `config` | Module 1 only | Audit AgnosticD configs/roles |
| `manifest` | Module 2 only | Audit onboard.yml against schema |
| `deployment` | Module 3 only | Audit live deployed environment |
| `structure` | Module 4 only | Audit project file structure |

## Report Format

The auditor produces a structured report:

```
RHEL DevOps Auditor Report
Project: <name>
Date: <timestamp>
Mode: <full|config|manifest|deployment|structure>

Module 1: AgnosticD Configuration
  [PASS] Config file structure valid
  [WARN] Missing optional: quota_formula
  [FAIL] Role reference not found: ocp4_workload_missing

Remediation Plan (prioritized):
  BLOCKING:
    1. Fix role reference (command: ...)
  HIGH:
    2. Add quota formula (command: ...)
```

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [AgnosticD Refactor](agnosticd-refactor.html) | Auditor identifies issues; refactor skill executes fixes |
| [Onboard](onboard.html) | Auditor validates onboard.yml; onboard skill interprets it |
| [AgnosticD Deploy Test](agnosticd-deploy-test.html) | Auditor dispatches to deploy-test for live environment checks |
| [Student Readiness](student-readiness.html) | Auditor dispatches to student-readiness for student POV validation |

See [ADR-019](../adrs/019-rhel-devops-auditor.html) for the full design rationale.

## Install

```bash
./install.sh install --skill rhel-devops-auditor
```
