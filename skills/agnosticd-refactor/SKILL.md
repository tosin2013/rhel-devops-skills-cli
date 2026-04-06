---
name: agnosticd-refactor
description: AI assistance for auditing and improving existing AgnosticD v2 configs and workload roles against RHDP best practices. Use when a developer has an existing deployment and wants to improve it, fix validation failures, or prepare it for RHDP submission — not when setting up from scratch.
related_skills: [agnosticd, student-readiness, workshop-tester]
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

> (RESEARCH NEEDED — RQ-1: What environment checks should the LLM run before any `agd` command, and what is the per-platform corrective action when requirements are not met?)
>
> This section will be completed once research into AgnosticD v2 pre-flight requirements is done.
> Pending items: Python 3.12+ detection per OS, podman presence check, virtualenv existence check, per-platform corrective commands.

**Current partial guidance:**

Check that the developer's local environment meets minimum requirements before attempting any `agd` commands:

- `python3 --version` must return 3.12 or higher
- `podman --version` must succeed
- `agnosticd-v2-virtualenv/` must exist (created by `./bin/agd setup`)
- All `agd` commands must be run from within the `agnosticd-v2/` directory

---

### 2. Config File Structure

> (RESEARCH NEEDED — RQ-2: What is the required file structure and playbook set for an AgnosticD v2 config, what does each playbook do, and what are the minimum required variables?)
>
> This section will be completed once research into AgnosticD v2 config anatomy is done.
> Pending items: required playbook list (provision, destroy, stop, start, status), mandatory variables, default_vars file conventions, directory layout requirements.

**Current partial guidance:**

Verify the config directory exists under `ansible/configs/<config-name>/` in the forked repository and contains at minimum a variables defaults file.

---

### 3. Workload Role Structure

> (RESEARCH NEEDED — RQ-3: What files are required in a new `ocp4_workload_*` role, what is the purpose of each task file, and how does the `ocp4_workload_example` template demonstrate the correct structure?)
>
> This section will be completed once research into AgnosticD v2 workload role anatomy is done.
> Pending items: required files (tasks/workload.yml, tasks/main.yml, defaults/main.yml, meta/main.yml), variable naming prefix conventions, ocp4_workload_example reference implementation walkthrough.

**Current partial guidance:**

Verify all custom workload roles follow the `ocp4_workload_*` naming convention and all role variables are prefixed with the role name to avoid collisions.

---

### 4. `agnosticd_user_info` Completeness

> (RESEARCH NEEDED — RQ-4: How does the `agnosticd_user_info` Ansible module work, what format does it expect, how does data flow to RHDP and students, and how does it connect to Showroom Antora attributes?)
>
> This section will be completed once research into the agnosticd_user_info module is done.
> Pending items: module signature and required keys, RHDP-expected output fields, student credential patterns, connection to openshift_cluster_ingress_domain and Showroom antora.yml attributes.

**Current partial guidance:**

Every config that deploys to RHDP must use `agnosticd_user_info` to surface deployment outputs. Check that the vars file or a post-provision task calls this module and passes the cluster URL, student credentials, and any workload-specific access information.

---

### 5. Stop / Start / Status Implementation

> (RESEARCH NEEDED — RQ-5: What Ansible playbooks and variables does a config need to support `agd stop`, `agd start`, and `agd status`, and what does RHDP expect these lifecycle operations to do for an AWS-based OpenShift cluster?)
>
> This section will be completed once research into AgnosticD v2 lifecycle playbook requirements is done.
> Pending items: playbook names and locations for stop/start/status, AWS EC2 instance stop vs cluster stop semantics, variables that control lifecycle behavior, RHDP cost-management requirements.

**Current partial guidance:**

Check whether the config implements stop, start, and status operations. These are required for RHDP cost management. Configs that do not implement them cannot be cost-controlled on the platform.

---

### 6. Execution Environment Compliance

> (RESEARCH NEEDED — RQ-6: What execution environment container images does AgnosticD v2 ship, what Ansible collections and Python libraries are included in each, and when would a developer need to build a custom EE?)
>
> This section will be completed once research into AgnosticD v2 execution environments is done.
> Pending items: available EE images and their contents, how to specify an EE in a config, when to build a custom EE, where custom EE definitions should live.

**Current partial guidance:**

Verify the config uses the execution environment rather than calling `ansible-playbook` directly. The `agd` CLI wraps `ansible-navigator`, which enforces EE usage for reproducible deployments.

---

### 7. Multi-User Configuration

> (RESEARCH NEEDED — RQ-7: How does AgnosticD v2 provision per-student namespaces, RBAC, and credentials for multi-user workshop environments, and what variables control the number of users and their access?)
>
> This section will be completed once research into AgnosticD v2 multi-user deployment patterns is done.
> Pending items: per-student namespace creation variables, RBAC configuration, credential generation patterns, number-of-users variable conventions.

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
- Fix audit items in order — items 1 and 8 (pre-flight and hygiene) are prerequisites for everything else
- After fixing Workload Role Structure issues (area 3), re-run `agd provision` to confirm the fix before proceeding
- Use `(RESEARCH NEEDED)` SKIP results as a tracking list — revisit when the corresponding research question is answered
