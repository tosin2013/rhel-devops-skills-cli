# Feature Request: Student/Environment Readiness Skill

**Target repo**: https://github.com/rhpds/rhdp-skills-marketplace/issues/new

**Title**: Feature Request: Student/Environment Readiness Skill

**Body**:

## Summary

Proposing a new skill (or extension to `/health:deployment-validator`) that verifies a deployed workshop environment is **ready for students to use** — checking the full student experience end-to-end, not just infrastructure health.

## The Gap

The current marketplace skills each check a slice of the workshop stack:

| Tool | What It Checks |
|------|---------------|
| `/showroom:verify-content` | Content quality (AsciiDoc, Red Hat standards) — pre-deployment |
| `/health:deployment-validator` | Infrastructure health (pods, routes, operators) — post-deployment |
| `/agnosticv:validator` | Catalog configuration correctness |
| `/ftl:rhdp-lab-validator` | Lab grading automation (Solve/Validate buttons) |

**None of these answer**: "Given a deployed environment and access credentials, can students actually start and complete this workshop right now?"

That requires checking the complete student experience: authentication, lab guide accessibility, terminal functionality, prerequisite operators, RBAC, workload readiness, content-environment URL match, and multi-user isolation.

## Proposed Checklist

A student readiness check would verify:

1. **Cluster/Host Access** — `oc login` succeeds (OCP) or SSH to bastion works (RHEL VM)
2. **Showroom Accessibility** — Route exists, HTTP 200, content renders
3. **Terminal Functionality** — Terminal pod running or Wetty reachable, expected CLI tools available
4. **Operators Ready** — All required CSVs in Succeeded phase
5. **Namespaces & RBAC** — Student namespaces exist with correct permissions
6. **Workload Resources** — Expected deployments/pods/routes are running
7. **Content-Environment Match** — Showroom content attributes match actual cluster routes
8. **AAP Readiness** (if applicable) — Controller API reachable, projects/templates exist
9. **Multi-User Isolation** (if applicable) — N student environments provisioned correctly

## Environment Types

Should support all AgnosticD environment types:

- **OCP Shared Tenant** — students get scoped namespaces
- **OCP Dedicated** — cluster-admin + bastion
- **RHEL VM + Bastion** — no OpenShift
- **AAP** — Ansible Automation Platform
- **Hybrid** — combinations of the above

## Proof of Concept

We have implemented a `student-readiness` skill in [tosin2013/rhel-devops-skills-cli](https://github.com/tosin2013/rhel-devops-skills-cli) as a process-oriented skill that teaches the AI to run these checks. See:

- [ADR-011: End-to-End Validation and Troubleshooting](https://github.com/tosin2013/rhel-devops-skills-cli/blob/main/docs/adrs/011-e2e-validation-and-troubleshooting.md)
- [Student Readiness SKILL.md](https://github.com/tosin2013/rhel-devops-skills-cli/blob/main/skills/student-readiness/SKILL.md)

## Suggested Integration

This could be:
- A new namespace: `/readiness:student-check`
- An extension to `/health:deployment-validator` (adding student-perspective checks)
- A standalone skill in the `health` plugin namespace

## Why This Matters

It closes the loop on the workshop lifecycle:

```
Create -> Deploy -> Validate Infra -> Verify Student Readiness -> Deliver Training
  |                    |                      |
showroom       deployment-validator    [THIS PROPOSAL]
```

Workshop developers currently have to manually verify each component works from the student's perspective. This skill automates that final "go / no-go" check.
