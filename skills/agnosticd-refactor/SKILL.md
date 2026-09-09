---
name: agnosticd-refactor
description: AI assistance for auditing and improving existing AgnosticD v2 configs and workload roles against RHDP best practices. Use when a developer has an existing deployment and wants to improve it, fix validation failures, or prepare it for RHDP submission — not when setting up from scratch.
license: Apache-2.0
compatibility: Requires bash 4.4+, git, and Ansible. Designed for RHEL 8/9 with Cursor and Claude Code.
metadata:
  related-skills: "agnosticd, student-readiness, workshop-tester, agnosticd-deploy-test"
---

# AgnosticD Refactor Skill

## When to Use

- Developer has an existing AgnosticD v2 config and asks "how do I improve this?"
- Config deploys locally but fails RHDP review or catalog validation
- Migrating a config from AgnosticD v1 to v2
- Workload role works in isolation but fails when combined with other workloads
- Developer asks "is my config ready to submit to RHDP?"
- `agnosticd_user_info` output is missing or incomplete
- Stop/start/status lifecycle operations are not implemented
- Secrets or resource tagging don't follow platform conventions

## Instructions

This skill defines an audit process, not a tool wrapper. When activated, collect the required input from the developer, then work through the audit areas below in order. For each area, assess the current state, identify gaps, and provide specific remediation steps.

Do NOT use this skill when a developer is setting up AgnosticD v2 from scratch — use the **agnosticd** skill instead.

> When you encounter an `[RQ-*]` tag, see [references/research-questions.md](references/research-questions.md) for the open question and its context. For fetched upstream docs, see [references/REFERENCE.md](references/REFERENCE.md).

## Gotchas

- Workload role names must start with `ocp4_workload_` — AgnosticD will not discover roles with other prefixes
- The `destroy` action in a workload role is mandatory — omitting `remove.yml` means teardown will leave resources orphaned
- Config variable files use `_vars.yml` suffix by convention, not `.yaml` — inconsistent extensions break variable loading
- AgnosticD roles run as the `ec2-user` (or equivalent), not root — `become: true` is needed for system-level changes
- `agnosticd_user_info` must be called from the workload role, not the config — the config only sets up the infrastructure

## Required Input

Before auditing, collect the following from the developer:

| Input | Required | Example |
|-------|----------|---------|
| Path to config directory | Yes | `ansible/configs/my-workshop/` |
| Path to vars file | Yes | `agnosticd-v2-vars/my-workshop.yaml` |
| Cloud provider | Yes | `aws`, `azure`, `openstack` |
| List of workload roles in use | Yes | `ocp4_workload_cert_manager`, `ocp4_workload_showroom` |
| Target RHDP environment type | If known | OCP dedicated, shared tenant, RHEL VM |
| GUID of a deployed instance | If available | `abc12` |

## Audit Areas

Work through each area in order. Report findings as a pass/fail table at the end (see Output Format).

---

### 1. Environment Pre-flight Compliance

> `[RQ-1]` — pre-flight environment checks and per-platform corrective actions are an open research question.

**Current partial guidance:**

Check that the developer's local environment meets minimum requirements before attempting any `agd` commands:

- `python3 --version` must return 3.12 or higher
- `podman --version` must succeed
- `agnosticd-v2-virtualenv/` must exist (created by `./bin/agd setup`)
- All `agd` commands must be run from within the `agnosticd-v2/` directory

---

### 2. Config File Structure

> `[RQ-2]` — required file structure, playbooks, and minimum variables for a v2 config are an open research question.

**Current partial guidance:**

Verify the config directory exists under `ansible/configs/<config-name>/` in the forked repository and contains at minimum a variables defaults file.

---

### 3. Workload Role Structure

> `[RQ-3]` — required workload role files and the `ocp4_workload_example` reference structure are an open research question.

**Current partial guidance:**

Verify all custom workload roles follow the `ocp4_workload_*` naming convention and all role variables are prefixed with the role name to avoid collisions.

---

### 4. `agnosticd_user_info` Completeness

> `[RQ-4]` — `agnosticd_user_info` module signature, data flow, and Showroom attribute connection are an open research question.

**Current partial guidance:**

Every config that deploys to RHDP must use `agnosticd_user_info` to surface deployment outputs. Check that the vars file or a post-provision task calls this module and passes the cluster URL, student credentials, and any workload-specific access information.

---

### 5. Stop / Start / Status Implementation

> `[RQ-5]` — lifecycle playbooks, variables, and RHDP cost-management expectations are an open research question.

**Current partial guidance:**

Check whether the config implements stop, start, and status operations. These are required for RHDP cost management. Configs that do not implement them cannot be cost-controlled on the platform.

---

### 6. Execution Environment Compliance

> `[RQ-6]` — available EE images, their contents, and when to build a custom EE are an open research question.

**Current partial guidance:**

Verify the config uses the execution environment rather than calling `ansible-playbook` directly. The `agd` CLI wraps `ansible-navigator`, which enforces EE usage for reproducible deployments.

---

### 7. Multi-User Configuration

> `[RQ-7]` — multi-user namespace provisioning, RBAC, and credential variables are an open research question.

**Current partial guidance:**

If the workshop is multi-user, verify the config includes variables for student count and per-student namespace isolation. Use the **student-readiness** skill to verify per-student environments after provisioning.

---

### 8. Secrets Hygiene and Resource Tagging

Check these items directly — no further research needed:

**Secrets:**
- `agnosticd-v2-secrets/` exists outside the git repository
- No credentials appear in `ansible/configs/`, `ansible/roles/`, or any committed vars file
- `secrets.yml` contains pull secret and satellite/RHN credentials
- Per-account secrets file (`secrets-<account>.yml`) exists and matches the `-a` flag used in `agd` commands

**Resource tagging:**
- `cloud_tags` in the vars file includes at minimum `owner`, `guid: "{{ guid }}"`, and `config`
- Tags are present on all provisioned cloud resources (required for RHDP automated cleanup)

**YAML code quality:**
- All tasks use YAML literal notation — no `foo=bar` inline syntax
- All tasks and plays have `name:` fields
- All role variables are prefixed with the role name
- `.yamllint` file is present in each role and config directory

---

## Output Format

Present audit results as a pass/fail table:

```
AgnosticD Refactor Audit — Config: <config-name>
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

For SKIP items where research is pending, note that the audit area cannot be fully evaluated yet and link to the research question.

## Escalation

When audit findings reveal deeper issues:

1. **Deployment still fails after fixes** → Use the **agnosticd** skill troubleshooting decision tree
2. **Environment deploys but students can't access it** → Use the **student-readiness** skill
3. **Module exercises fail on a working environment** → Use the **workshop-tester** skill
4. **Infrastructure health after deploy** → Use `/health:deployment-validator` from the [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/)

## Best Practices

- Run this audit before submitting a config to RHDP review, not after
- Fix audit items in order — pre-flight and hygiene are prerequisites for everything else
- After fixing workload role structure issues, re-run `agd provision` to confirm before proceeding
