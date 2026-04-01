---
title: Skills
nav_order: 3
has_children: true
---

# Skills

Each skill teaches your AI assistant (Claude Code or Cursor) how to work with a specific DevOps tool. Skills include a `SKILL.md` definition and reference documentation fetched from the tool's upstream repository.

## Available Skills

| Skill | Description | Source Repository |
|-------|-------------|-------------------|
| [AgnosticD v2](agnosticd.html) | Ansible Agnostic Deployer for cloud provisioning via the `agd` CLI | [agnosticd/agnosticd-v2](https://github.com/agnosticd/agnosticd-v2) |
| [Field-Sourced Content](field-sourced-content.html) | RHDP self-service catalog items via GitOps (Helm and Ansible patterns) | [rhpds/field-sourced-content-template](https://github.com/rhpds/field-sourced-content-template) |
| [Patternizer](patternizer.html) | Bootstrap Git repos into Validated Patterns for OpenShift | [tosin2013/patternizer](https://github.com/tosin2013/patternizer) |
| [Showroom](showroom.html) | RHDP lab guide and terminal system (Antora/AsciiDoc content + Helm deployment) | [rhpds/showroom-deployer](https://github.com/rhpds/showroom-deployer) |
| [Student Readiness](student-readiness.html) | Workshop environment readiness checker — verifies the student experience end-to-end | Self-contained |

## Cross-Skill Relationships

Some skills work together. The installer and AI assistants recognize these relationships via the `related_skills` field in each SKILL.md. Currently:

| Skill A | Skill B | Integration |
|---------|---------|-------------|
| AgnosticD v2 | Field-Sourced Content | AgnosticD provisions the OpenShift cluster; Field Content deploys onto it via the `ocp4_workload_field_content` workload role |
| AgnosticD v2 | Showroom | AgnosticD deploys Showroom as an `infra_workload` to serve lab guides on the cluster |
| Field-Sourced Content | Showroom | Field Content's Helm example includes a `components/showroom/` directory to deploy Showroom alongside the demo |
| AgnosticD v2 | Student Readiness | After `agd provision`, run student-readiness checks to verify the environment before handing to students |
| Showroom | Student Readiness | Verify Showroom lab guide accessibility, terminal functionality, and content-environment match |

See [ADR-010](../adrs/010-cross-skill-dependencies.html) for cross-skill dependencies and [ADR-011](../adrs/011-e2e-validation-and-troubleshooting.html) for validation and troubleshooting.

## Complementary: RHDP Skills Marketplace

The [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/) provides additional validation skills that complement this project:

| Tool | Purpose |
|------|---------|
| `/showroom:verify-content` | Content quality validation (AsciiDoc, Red Hat standards) |
| `/health:deployment-validator` | Infrastructure health checks (pods, routes, operators) |
| `/agnosticv:validator` | Catalog configuration validation |
| `/ftl:rhdp-lab-validator` | Lab grading automation (Solve/Validate buttons) |

## Install a Skill

```bash
./install.sh install --skill agnosticd          # one skill
./install.sh install --all                       # all skills
./install.sh install --skill patternizer --ide cursor  # specific IDE
```

## How Skills Are Structured

```
~/.claude/skills/agnosticd/     # or ~/.cursor/skills/agnosticd/
  SKILL.md                      # Instructions and "When to Use" triggers
  references/
    REFERENCE.md                # Index of fetched docs
    setup.adoc                  # Actual upstream documentation
    contributing.adoc
    ...
```

The AI assistant reads `SKILL.md` to understand when and how to help, then consults `references/` for detailed documentation.
