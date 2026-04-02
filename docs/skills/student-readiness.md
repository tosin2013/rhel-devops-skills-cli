---
title: Student Readiness
parent: Skills
nav_order: 5
---

# Student Readiness Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The Student Readiness skill verifies that a deployed workshop or demo environment is ready for students to use. It teaches the AI assistant to run a structured checklist against a live deployment, checking cluster access, lab guide accessibility, terminal functionality, operator readiness, RBAC, and multi-user isolation.

This skill fills a gap not covered by existing tools: while the [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/) provides content validation (`/showroom:verify-content`), infrastructure health checks (`/health:deployment-validator`), and lab grading automation (`/ftl:rhdp-lab-validator`), none of them verify the complete student experience end-to-end.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "is my environment ready for students?"
- Running a pre-training or pre-demo readiness check
- Validating a multi-user environment after provisioning
- Smoke-testing any AgnosticD-deployed environment before handing off to participants

## Supported Environment Types

The checklist adapts based on what was deployed:

| Type | Description | Primary Access |
|------|-------------|---------------|
| OCP Shared Tenant | Students get scoped namespaces on a shared cluster | `oc login` |
| OCP Dedicated | Students have cluster-admin, lab has a bastion VM | `oc login` + SSH |
| RHEL VM + Bastion | Bastion + node VMs, no OpenShift | SSH |
| AAP | Ansible Automation Platform controller + execution environments | AAP API + SSH |
| Hybrid | Combination (e.g., OCP cluster + bastion + AAP) | Multiple |

## Readiness Checklist

1. **Cluster / Host Access** -- Can the student authenticate?
2. **Showroom Accessibility** -- Is the lab guide accessible and rendering?
3. **Terminal Functionality** -- Does the terminal work with expected CLI tools?
4. **Operators Ready** -- Are all required operators in Succeeded phase?
5. **Namespaces & RBAC** -- Do student namespaces exist with correct permissions?
6. **Workload Resources** -- Are expected deployments, pods, and routes running?
7. **Content-Environment Match** -- Do lab content URLs match actual cluster routes?
8. **AAP Readiness** -- Is the controller API reachable with expected projects?
9. **Multi-User Isolation** -- Are all N student environments provisioned?

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [AgnosticD v2](agnosticd.html) | Provisions the environment being validated; troubleshooting trees for deployment failures |
| [Showroom](showroom.html) | Deploys the lab guide and terminal being checked; troubleshooting trees for content/terminal issues |
| [Field-Sourced Content](field-sourced-content.html) | Deploys workloads onto the cluster being validated |
| [Workshop Tester](workshop-tester.html) | Next step after readiness — executes module exercises and classifies failures as Instruction Fix, Infra / Deployment Fix, or Rethink |

## Complementary Marketplace Tools

| Tool | Purpose |
|------|---------|
| `/health:deployment-validator` | Infrastructure health (pods, routes, operators) |
| `/showroom:verify-content` | Content quality (AsciiDoc, Red Hat standards) |
| `/agnosticv:validator` | Catalog configuration validation |
| `/ftl:rhdp-lab-validator` | Lab grading automation (Solve/Validate buttons) |

See [ADR-011](../adrs/011-e2e-validation-and-troubleshooting.html) for the full design rationale.

## Install

```bash
./install.sh install --skill student-readiness
```
