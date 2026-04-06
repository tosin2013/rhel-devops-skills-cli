---
title: AgnosticD Refactor
parent: Skills
nav_order: 7
---

# AgnosticD Refactor Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The AgnosticD Refactor skill guides the AI assistant through auditing an existing AgnosticD v2 config or workload role against RHDP best practices. It produces a structured pass/fail report with prioritized remediation steps and tier readiness assessment.

This skill fills the gap between running `agd provision` and having a config that is accepted for the RHDP catalog. A config that deploys locally may still fail RHDP review due to missing lifecycle playbooks, incorrect `agnosticd_user_info` output, uncommitted-but-present secrets, or incomplete resource tagging.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "how do I improve this config?" or "why is my config failing RHDP review?"
- Migrating a config from AgnosticD v1 to v2
- Preparing a config or workload role for RHDP catalog submission
- Fixing `agnosticd_user_info` output that is missing or incomplete
- Adding stop/start/status lifecycle support to an existing config
- Auditing secrets hygiene before submitting a pull request

Do NOT use this skill when setting up AgnosticD v2 from scratch — use the [AgnosticD v2](agnosticd.html) skill instead.

## The 8-Area Audit

The skill works through each area in order and reports a pass/fail table with a priority fix list:

| # | Audit Area | What It Checks |
|---|-----------|----------------|
| 1 | Environment pre-flight | Python 3.12+, podman, virtualenv presence |
| 2 | Config file structure | Required playbooks and mandatory variables |
| 3 | Workload role structure | `ocp4_workload_*` naming, required files, variable prefix conventions |
| 4 | `agnosticd_user_info` completeness | Student credentials and cluster URLs surfaced to RHDP catalog |
| 5 | Stop/start/status lifecycle | Required for RHDP cost management |
| 6 | Execution environment compliance | `ansible-navigator` EE usage, available EE images |
| 7 | Multi-user configuration | Per-student namespace variables, RBAC loop patterns |
| 8 | Secrets hygiene and resource tagging | No committed secrets, cloud_tags with owner/guid/config |

## Sample Audit Report

```
AgnosticD Refactor Audit — Config: my-workshop
──────────────────────────────────────────────────────
 #  Area                            Status  Notes
 1  Environment pre-flight          PASS    Python 3.12.3, podman 4.9, virtualenv present
 2  Config file structure           SKIP    Research pending — RQ-2
 3  Workload role structure         FAIL    ocp4_workload_myapp missing meta/main.yml
 4  agnosticd_user_info             SKIP    Research pending — RQ-4
 5  Stop/start/status               FAIL    No stop/start playbooks found
 6  Execution environment           PASS    ansible-navigator EE in use
 7  Multi-user configuration        N/A     Single-user deployment
 8  Secrets hygiene & tagging       PASS    All checks passed
──────────────────────────────────────────────────────
 Result: 2 FAIL, 3 PASS, 2 SKIP (research pending), 1 N/A
 Priority fixes: #3 (workload meta), #5 (lifecycle playbooks)
```

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [AgnosticD v2](agnosticd.html) | Operational skill — use for setup and deployment; agnosticd-refactor audits existing configs |
| [Student Readiness](student-readiness.html) | After fixing audit findings, verify the corrected environment end-to-end |
| [Workshop Tester](workshop-tester.html) | Infra / Deployment Fix failures in module testing often require an agnosticd-refactor audit |
| [Skill Researcher](skill-researcher.html) | Resolves open `(RESEARCH NEEDED)` placeholders in this skill's audit areas |

See [ADR-013](../adrs/013-refactor-skills.html) for the design rationale and [ADR-014](../adrs/014-skill-researcher.html) for how open research questions are resolved.

## Install

```bash
./install.sh install --skill agnosticd-refactor
```
