---
name: rhel-devops-auditor
description: >-
  Audit projects against RHEL DevOps standards — AgnosticD configs,
  onboard.yml manifests, deployed environments, and project structure.
  Produces structured PASS/WARN/FAIL reports with prioritized remediation
  plans containing executable commands. A meta-auditor that dispatches to
  specific check modules and aggregates findings.
related_skills:
  - agnosticd-refactor
  - onboard
  - student-readiness
  - agnosticd-deploy-test
  - agnosticd-hub-student
---

# RHEL DevOps Auditor

## When to Use

- User says "audit this project", "check compliance", "run an audit"
- User asks "how does this project compare to standards"
- After scaffolding a project, to validate completeness
- User wants to identify gaps before submitting for review
- User asks "what's missing" or "what do I need to fix"
- User asks to verify project structure against best practices

Do NOT use this skill for:
- Refactoring AgnosticD configs directly — use **agnosticd-refactor** (this skill audits and recommends, that skill executes)
- Validating a live running deployment — use **agnosticd-deploy-test** or **student-readiness** (this skill can dispatch to those)
- Creating a new project from scratch — use `./install.sh scaffold` first, then audit

## Instructions

This skill defines a four-module audit process. Each module checks a specific domain against documented standards. Run all modules by default (full audit) or individual modules on request.

**Key behaviors:**
- Always produce a structured report with PASS/WARN/FAIL per check
- Always produce a prioritized remediation plan when failures exist
- Remediation actions must include executable commands, not just descriptions
- Reference specific file paths and line numbers in findings
- Distinguish between BLOCKING (must fix), HIGH (should fix), and MEDIUM (nice to fix)
- If a module cannot run (e.g. no cluster credentials for deployment audit), mark it SKIP with a reason

## Audit Modes

| Mode | Modules Run | When to Use |
|------|-------------|-------------|
| `full` | All 4 modules | Default; comprehensive project audit |
| `config` | Module 1 only | Audit AgnosticD configs/roles |
| `manifest` | Module 2 only | Audit onboard.yml against schema |
| `deployment` | Module 3 only | Audit live deployed environment |
| `structure` | Module 4 only | Audit project file structure |

Ask the user which mode they want if not specified. Default to `full`.

## Required Input

| Input | Required | Default | Notes |
|-------|----------|---------|-------|
| Project directory | Yes | Current working directory | Must contain project files |
| Audit mode | No | `full` | Can be narrowed to single module |
| Cluster credentials | Only for Module 3 | — | kubeconfig or API URL + token |
| Project type | No | Auto-detected from Makefile | hub-student, demo, or agnosticd-infra |

## Module 1 — AgnosticD Config Audit

**Standards source:** `agnosticd-refactor` skill (Audit Areas 1-7)

### Checks

| ID | Check | Severity | Standard |
|----|-------|----------|----------|
| M1-01 | Config directory exists (ansible/configs/) | BLOCKING | AgnosticD v2 structure |
| M1-02 | At least one config with required vars (cloud_provider, env_type) | BLOCKING | AgnosticD config contract |
| M1-03 | Workload roles follow ocp4_workload_* naming | HIGH | AgnosticD role conventions |
| M1-04 | Roles have defaults/main.yml with documented variables | HIGH | Ansible best practices |
| M1-05 | Roles have meta/main.yml with role metadata | MEDIUM | Ansible Galaxy compatibility |
| M1-06 | Pre/post hooks exist if config uses workloads | MEDIUM | AgnosticD lifecycle hooks |
| M1-07 | No hardcoded secrets in vars files | BLOCKING | Security |
| M1-08 | Vars files reference secrets via vault/external mechanism | HIGH | Secret management |

### How to check

- Scan `ansible/configs/`, `ansible/roles/`, and vars directories
- Verify file presence and YAML structure
- grep for hardcoded patterns: passwords, tokens, keys in plain text
- Validate variable naming conventions

## Module 2 — Onboard Manifest Audit

**Standards source:** `onboard` skill's `references/manifest-spec.md`

### Checks

| ID | Check | Severity | Standard |
|----|-------|----------|----------|
| M2-01 | onboard.yml exists | BLOCKING | Project must be onboardable |
| M2-02 | Required fields present (name, description, prerequisites) | BLOCKING | Manifest schema |
| M2-03 | All prerequisites have check_command | HIGH | Idempotent detection |
| M2-04 | Prerequisites have install commands for rhel9 | BLOCKING | Primary platform |
| M2-05 | Prerequisites have install commands for macos | MEDIUM | Cross-platform |
| M2-06 | Config prompts have defaults | HIGH | Non-interactive mode support |
| M2-07 | Validation section has at least 1 required check | HIGH | Readiness gate |
| M2-08 | config.output_file path is in .gitignore | HIGH | No secrets in git |
| M2-09 | post_setup.message exists with next steps | MEDIUM | User guidance |

### How to check

- Parse onboard.yml with python3 + PyYAML
- Validate against schema fields
- Cross-reference .gitignore entries
- Check each prerequisite entry for completeness

## Module 3 — Live Deployment Audit

**Standards source:** `student-readiness` + `agnosticd-deploy-test` skills

### Checks

| ID | Check | Severity | Standard |
|----|-------|----------|----------|
| M3-01 | Cluster API is reachable | BLOCKING | Basic connectivity |
| M3-02 | kubeconfig or credentials are valid (oc whoami succeeds) | BLOCKING | Authentication |
| M3-03 | Hub cluster accessible (if hub-student type) | BLOCKING | Hub-student topology |
| M3-04 | Showroom deployed and route accessible (if applicable) | HIGH | Showroom requirement |
| M3-05 | Student clusters provisioned (N/N) | BLOCKING | Hub-student completeness |
| M3-06 | agnosticd_user_info present with per-student credentials | HIGH | Credential pipeline |
| M3-07 | Stop/start lifecycle works independently | MEDIUM | RHDP requirement |
| M3-08 | Cross-cluster wiring: Showroom terminal targets student API | HIGH | Hub-student topology |

### How to check

- Requires cluster credentials (kubeconfig path or API URL + token)
- Run `oc` / `kubectl` commands against target clusters
- Check route/ingress for Showroom accessibility
- Verify ConfigMaps/Secrets for credential injection
- If no credentials provided: mark entire module as SKIP

## Module 4 — Project Structure Audit

**Standards source:** `./install.sh scaffold` output (standard project pattern)

### Checks

| ID | Check | Severity | Standard |
|----|-------|----------|----------|
| M4-01 | Makefile exists | BLOCKING | Standard entry point |
| M4-02 | Makefile has 'deploy' target | BLOCKING | Deploy capability |
| M4-03 | Makefile has 'destroy' target | BLOCKING | Teardown capability |
| M4-04 | Makefile has 'dry-run' target | HIGH | Safe preview |
| M4-05 | Makefile has 'status' target | HIGH | Environment awareness |
| M4-06 | Makefile has 'check-quota' target | HIGH | Quota pre-flight |
| M4-07 | Deploy script exists and is executable | BLOCKING | Provisioning |
| M4-08 | Teardown script exists and is executable | BLOCKING | Cleanup |
| M4-09 | bootstrap.sh or onboard.yml exists | HIGH | Onboarding path |
| M4-10 | deploy/config.yml in .gitignore | BLOCKING | No secrets in git |
| M4-11 | student_info.txt or deployment_info.txt in .gitignore | HIGH | No credentials in git |
| M4-12 | logs/ in .gitignore | MEDIUM | No logs in git |
| M4-13 | .workshop-state in .gitignore | MEDIUM | No state in git |
| M4-14 | Deploy script has --dry-run flag | HIGH | Safe operations |
| M4-15 | Deploy script has --confirm or --yes flag | HIGH | Explicit confirmation |
| M4-16 | Teardown script destroys in correct order (students-first for hub-student) | HIGH | Data safety |
| M4-17 | Scripts source workshop-common.sh from shared lib path | MEDIUM | DRY pattern |
| M4-18 | GUID tracking present (.workshop-state with guid=) | MEDIUM | Environment identity |
| M4-19 | State lock pattern present (.workshop-lock) | MEDIUM | Concurrency safety |
| M4-20 | Scripts pass ShellCheck (no errors) | MEDIUM | Code quality |

### How to check

- File existence checks (test -f, test -x)
- grep Makefile for target names
- grep .gitignore for required entries
- grep deploy/teardown scripts for flag handling patterns
- Run shellcheck if available

## Report Format

After running all applicable modules, produce this exact format:

```
=== RHEL DevOps Project Audit Report ===
Project: <name>     Date: <timestamp>
Type: <hub-student|demo|agnosticd-infra|unknown>
Mode: <full|config|manifest|deployment|structure>
Modules: <N>/4 run

Module 1: AgnosticD Config          <PASS|WARN|FAIL|SKIP> (<X>/<Y> checks)
Module 2: Onboard Manifest          <PASS|WARN|FAIL|SKIP> (<X>/<Y> checks)
Module 3: Live Deployment           <PASS|WARN|FAIL|SKIP> (<X>/<Y> checks)
Module 4: Project Structure         <PASS|WARN|FAIL|SKIP> (<X>/<Y> checks)

Overall: <READY|NEEDS ATTENTION> (<N> finding(s))
══════════════════════════════════════════════════════════════════

--- Findings ---

  [FAIL] <ID>: <description>
         File: <path>:<line> (if applicable)
  [WARN] <ID>: <description>
  ...

--- Remediation Plan (prioritized) ---

Priority 1 (BLOCKING):
  1. <finding description>
     Action: <exact command or edit to fix>

Priority 2 (HIGH):
  2. <finding description>
     Action: <exact command or edit to fix>

Priority 3 (MEDIUM):
  3. <finding description>
     Action: <exact command or edit to fix>
```

## Scoring

- **Module PASS:** All checks in that module pass (0 failures, 0 warnings)
- **Module WARN:** All required checks pass but at least 1 warning
- **Module FAIL:** At least 1 required check failed
- **Module SKIP:** Module could not run (missing input data)
- **Overall READY:** All modules are PASS or WARN (no FAIL)
- **Overall NEEDS ATTENTION:** At least 1 module has FAIL

## Remediation Plan Rules

1. Group by priority: BLOCKING first, then HIGH, then MEDIUM
2. Each item must have an **Action** field with one of:
   - An exact shell command to run
   - An exact file edit (show the content to add/change)
   - A reference to another skill to activate (e.g. "Activate agnosticd-refactor")
3. Order within priority: fix items that unblock other items first
4. If a scaffold would fix multiple items at once, recommend it:
   `Action: ./install.sh scaffold --type <type> --output .`
5. If the fix requires research: mark it as "(RESEARCH NEEDED)" and suggest activating the skill-researcher

## Re-audit After Fixes

After the user applies fixes from the remediation plan, offer to re-run only the failed modules:

```
Re-running failed modules only:
  Module 2 (Onboard Manifest) — re-checking...
  Module 4 (Project Structure) — re-checking...

Skipping Module 1 (passed), Module 3 (skipped — no credentials).
```

## Escalation

- **AgnosticD config issues found** → Recommend activating **agnosticd-refactor** to apply fixes
- **Onboard manifest missing** → Recommend `./install.sh scaffold --type <type>` or manual creation per manifest-spec.md
- **Deployment issues found** → Recommend activating **student-readiness** or **agnosticd-deploy-test**
- **Project structure gaps** → Recommend `./install.sh scaffold --type <type>` to generate missing files
- **Research needed for a finding** → Recommend activating **skill-researcher**
