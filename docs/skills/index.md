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
| [Workshop Tester](workshop-tester.html) | AI-as-student module tester — executes exercises and classifies failures | Self-contained |
| [AgnosticD Refactor](agnosticd-refactor.html) | Audit and improve existing AgnosticD v2 configs and workload roles against RHDP best practices | Self-contained |
| [VP Refactor](vp-refactor.html) | Audit and improve existing Validated Pattern repos toward VP Operator and tier submission | Self-contained |
| [Skill Researcher](skill-researcher.html) | Resolve open `(RESEARCH NEEDED)` questions by fetching upstream docs and writing findings back into all affected skills | Self-contained |
| [AgnosticD Deploy Test](agnosticd-deploy-test.html) | Validate an AgnosticD v2 deployment end-to-end — provisioning, workload completion, `agnosticd_user_info` data flow, and stop/start lifecycle | Self-contained |
| [VP Deploy Test](vp-deploy-test.html) | Validate a Validated Pattern deployment end-to-end — VP Operator install, ArgoCD convergence, secrets delivery, and imperative jobs | Self-contained |

## Cross-Skill Relationships

Some skills work together. The installer and AI assistants recognize these relationships via the `related_skills` field in each SKILL.md. Currently:

| Skill A | Skill B | Integration |
|---------|---------|-------------|
| AgnosticD v2 | Field-Sourced Content | AgnosticD provisions the OpenShift cluster; Field Content deploys onto it via the `ocp4_workload_field_content` workload role |
| AgnosticD v2 | Showroom | AgnosticD deploys Showroom as an `infra_workload` to serve lab guides on the cluster |
| Field-Sourced Content | Showroom | Field Content's Helm example includes a `components/showroom/` directory to deploy Showroom alongside the demo |
| AgnosticD v2 | Student Readiness | After `agd provision`, run student-readiness checks to verify the environment before handing to students |
| Showroom | Student Readiness | Verify Showroom lab guide accessibility, terminal functionality, and content-environment match |
| Student Readiness | Workshop Tester | Run readiness checks before module testing; workshop-tester depends on student-readiness passing |
| Showroom | Workshop Tester | Workshop-tester parses Showroom AsciiDoc for executable steps (`[source,role="execute"]`) |
| AgnosticD v2 | Workshop Tester | Infra / Deployment Fix failures from testing often require AgnosticD config changes |
| AgnosticD v2 | AgnosticD Refactor | Refactor skill audits existing configs built with AgnosticD; escalates to agnosticd skill for deployment failures |
| AgnosticD Refactor | Student Readiness | After fixing audit findings, use student-readiness to verify the corrected environment end-to-end |
| AgnosticD Refactor | Workshop Tester | Infra / Deployment Fix failures in workshop-tester often require agnosticd-refactor audit to find root cause |
| Patternizer | VP Refactor | Refactor skill audits patterns initialized by Patternizer; escalates to patternizer for init/upgrade operations |
| Skill Researcher | AgnosticD Refactor | skill-researcher resolves AgnosticD RQ-1 through RQ-7 by writing verified findings into agnosticd-refactor audit areas |
| Skill Researcher | VP Refactor | skill-researcher resolves Validated Patterns RQ-1 through RQ-8 by writing verified findings into vp-refactor audit areas |
| AgnosticD v2 | AgnosticD Deploy Test | agnosticd-deploy-test validates deployments produced by `agd provision`; escalates back to agnosticd for setup issues |
| AgnosticD Refactor | AgnosticD Deploy Test | agnosticd-deploy-test escalates to agnosticd-refactor when provisioning or workload failures are found |
| Student Readiness | AgnosticD Deploy Test | agnosticd-deploy-test activates student-readiness after Phase 3 validation passes |
| Patternizer | VP Deploy Test | vp-deploy-test validates patterns initialized by patternizer |
| VP Refactor | VP Deploy Test | vp-deploy-test escalates to vp-refactor when convergence or secrets failures are found |
| Student Readiness | VP Deploy Test | vp-deploy-test activates student-readiness after Phase 4 validation passes |

See [ADR-010](../adrs/010-cross-skill-dependencies.html) for cross-skill dependencies, [ADR-011](../adrs/011-e2e-validation-and-troubleshooting.html) for validation and troubleshooting, [ADR-012](../adrs/012-workshop-module-testing.html) for workshop module testing strategy, [ADR-013](../adrs/013-refactor-skills.html) for refactor skills design, [ADR-014](../adrs/014-skill-researcher.html) for the skill researcher workflow, and [ADR-015](../adrs/015-deployment-pipeline-testing.html) for deployment pipeline testing.

## Validation Lifecycle

The validation skills follow a clear progression covering both AgnosticD and Validated Patterns:

```
agnosticd-deploy-test  →  student-readiness  →  workshop-tester  →  ftl:rhdp-lab-validator
vp-deploy-test            (env ready?)           (steps work?)       (grade automation)
(pipeline healthy?)
```

1. **AgnosticD Deploy Test / VP Deploy Test** verifies the deployment pipeline produced a correct, fully-working result (provisioning, convergence, lifecycle)
2. **Student Readiness** verifies the deployed environment is accessible and ready from the student's perspective
3. **Workshop Tester** executes module exercises against the live environment and classifies failures
4. **ftl:rhdp-lab-validator** (marketplace) generates grading automation for passing modules

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
