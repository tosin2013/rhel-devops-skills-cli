---
title: "ADR-019: RHEL DevOps Auditor Skill"
nav_order: 19
parent: Architecture Decision Records
---

# ADR-019: RHEL DevOps Auditor Skill

* Status: accepted
* Date: 2026-07-17
* Deciders: Architecture Team

## Context and Problem Statement

Projects built with rhel-devops-skills-cli scaffolding and patterns need a way to verify compliance with standards. Currently, checking whether a project follows best practices requires manual review or activating multiple individual skills. Users need a single entry point that audits all aspects of a project and produces an actionable report.

## Decision Drivers

* Users ask "what's missing" or "does this follow standards" frequently
* Multiple skills define standards (agnosticd-refactor, onboard, student-readiness) but none aggregate findings
* Post-scaffold validation should be automated — identify remaining TODO markers and gaps
* Remediation plans should be executable, not just descriptive
* Live deployment audits complement static project structure checks

## Decision Outcome

Create a `rhel-devops-auditor` skill that acts as a meta-auditor, dispatching checks across four modules and aggregating findings into a single structured report with prioritized remediation plans.

### Audit Modules

| Module | Domain | Standards Source |
|--------|--------|-----------------|
| 1 | AgnosticD Config | agnosticd-refactor SKILL.md |
| 2 | Onboard Manifest | onboard/references/manifest-spec.md |
| 3 | Live Deployment | student-readiness + agnosticd-deploy-test |
| 4 | Project Structure | scaffold output patterns |

### Report Format

```
=== RHEL DevOps Project Audit Report ===
Module 1: AgnosticD Config     PASS (8/8)
Module 2: Onboard Manifest     WARN (6/7, 1 warning)
Module 3: Live Deployment      SKIP (no credentials)
Module 4: Project Structure    FAIL (4/7, 3 failures)

Overall: NEEDS ATTENTION (3 findings)
--- Remediation Plan (prioritized) ---
...
```

### Key Design Decisions

1. **Self-contained skill** — no upstream repo dependency; references/audit-checklists.md provides machine-readable check definitions
2. **Module independence** — each module can run alone or as part of a full audit
3. **SKIP, not FAIL** — modules that cannot run due to missing input (e.g., no cluster credentials) are marked SKIP, not FAIL
4. **Executable remediation** — every finding includes a specific command or file edit to resolve it
5. **Severity levels** — BLOCKING, HIGH, MEDIUM distinguish must-fix from nice-to-fix
6. **Cross-skill escalation** — when a finding requires deep work, the auditor recommends activating the appropriate specialized skill

### Positive Consequences

* Single command gives users a complete project health assessment
* Standardizes quality expectations across all project types
* Remediation plans are actionable (not just "fix this")
* Naturally validates scaffold output — projects scaffolded correctly pass by default
* Supports iterative improvement (re-audit after fixes)

### Negative Consequences

* Must be kept in sync with standards defined in other skills
* Module 3 (live deployment) requires cluster access — not always available
* Checklist maintenance as standards evolve

## Links

* Related: [ADR-018](018-scaffold-command.html) (scaffold command)
* Related: [ADR-013](013-refactor-skills.html) (refactor skills)
* Related: [ADR-016](016-hub-student-skill.html) (hub-student skill)
