---
title: "ADR-018: Scaffold Command Architecture"
nav_order: 18
parent: Architecture Decision Records
---

# ADR-018: Scaffold Command for Project Generation

* Status: accepted
* Date: 2026-07-17
* Deciders: Architecture Team

## Context and Problem Statement

Users building workshops, demos, and infrastructure projects with AgnosticD consistently need the same set of project files: a Makefile with standard targets, deploy/teardown scripts with proper ordering, an onboard.yml manifest, and supporting configuration. Each project duplicates these patterns with slight variations, leading to inconsistency and missed best practices.

The rhel-devops-skills-cli already understands these patterns through its skills (agnosticd-hub-student, onboard, etc.) but has no way to generate project scaffolding.

## Decision Drivers

* Every hub-student workshop needs the same deploy/teardown ordering pattern
* Demo and infra projects need the same pattern with fewer components
* Users report hitting AWS/GCP/Azure quota limits during deploy — pre-flight checks would prevent wasted time
* Generated `student_info.txt` bridges the gap between automation and human facilitators
* A shared library avoids duplicating common bash functions across projects

## Decision Outcome

Add a `scaffold` subcommand to `install.sh` supporting four topology types, backed by a shared bash library installed to `~/.local/share/rhel-devops-skills/`.

### Scaffold Types

| Type | Topology | Use Case |
|------|----------|----------|
| `hub-student` | Hub + N student clusters | Workshops with facilitator + students |
| `demo` | Single cluster | Presenter-focused demos |
| `agnosticd-infra` | Flexible (1+ configs) | Dev/test/prod infrastructure |
| `shared-cluster` | Single cluster, N user namespaces | Multi-user workshops on one cluster |

### Architecture

```
./install.sh scaffold --type <type> [--output DIR]
  ↓
lib/scaffold.sh (template processing + substitution)
  ↓
skills/agnosticd-hub-student/templates/  (or templates/demo/, templates/agnosticd-infra/, templates/shared-cluster/)
  ↓
Generated project files + shared libs installed to ~/.local/share/rhel-devops-skills/
```

### Shared Library (`workshop-common.sh`)

Installed once to `~/.local/share/rhel-devops-skills/`, sourced by all generated scripts. Provides:
- Config loading, GUID tracking, state/lock management
- AgnosticD wrappers (provision/destroy/stop/start)
- Parallel student orchestration with serial hub ordering
- Partial failure resume
- Info file generation (student_info.txt / deployment_info.txt)
- Log capture

### Cloud Quota Pre-flight (`quota-check.sh`)

A read-only-by-default script that checks provider quotas before deploy:
- NEVER auto-increases quotas without `--increase` flag + user confirmation
- Calculates required resources dynamically from project config
- Supports AWS, GCP, Azure
- Integrated as `make check-quota` target and deploy prerequisite

### Template Substitution

Templates use `{{VAR}}` placeholders replaced by sed at scaffold time. Project-specific values are collected interactively or via `--vars` file.

### Positive Consequences

* New projects get correct patterns from day one
* Shared library provides DRY benefits while keeping projects self-contained after scaffolding
* Quota pre-flight prevents wasted deploy time
* student_info.txt gives facilitators a copy-pasteable credential sheet
* make status provides at-a-glance environment awareness

### Negative Consequences

* Shared library at `~/.local/share/rhel-devops-skills/` must be installed (not self-contained)
* Template changes don't propagate to already-scaffolded projects
* Four scaffold types adds complexity vs a single generic template

## Links

* Related: [ADR-006](006-shell-installer-architecture.html) (shell architecture)
* Related: [ADR-016](016-hub-student-skill.html) (hub-student skill)
