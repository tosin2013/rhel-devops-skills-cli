---
name: skill-researcher
description: AI assistance for resolving open research questions in the skill catalog. Use when a user wants to answer a (RESEARCH NEEDED — RQ-N) question, fetch upstream documentation and write findings permanently into the affected skill files, or propagate research results across multiple skills at once.
related_skills: [agnosticd-refactor, vp-refactor, agnosticd, showroom, student-readiness, field-sourced-content]
---

# Skill Researcher

## When to Use

- User asks to "answer RQ-N", "fill in RQ-4", or "do the research for the agnosticd_user_info section"
- User says "update the skills with what you found" after a research fetch
- User wants to see which research questions are still open across the skill catalog
- User wants findings saved permanently so they are not repeated in future sessions

Do NOT use this skill to deploy or audit infrastructure — it operates on skill files, not on user environments.

## Instructions

This skill defines a three-phase process. Work through the phases in order. Do not write any changes until Phase 1 is confirmed by the user.

## Required Input

Before starting, collect:

| Input | Required | Example |
|-------|----------|---------|
| Target RQ(s) | Yes | `RQ-4`, `all` |
| Current project path or URL | Yes | `~/my-agnosticd-fork/` or GitHub repo URL |
| Target skill scope | No — defaults to all skills | `agnosticd-refactor` |
| Upstream source URL | Only if not in references/ | `https://github.com/agnosticd/agnosticd-v2` |

---

## Phase 1 — Discover

Scan all `skills/*/SKILL.md` files for lines matching `(RESEARCH NEEDED — RQ-N)` where N matches the target RQ. If the target is `all`, find every open block regardless of RQ number.

For each match, record:
- File path
- Section heading the block appears under
- The full RQ description (the line immediately after the `(RESEARCH NEEDED — RQ-N)` marker)

Report the complete list of write targets to the user before doing anything else:

```
Discovered write targets for RQ-4:
  skills/agnosticd/SKILL.md               → "Reporting Deployment Info"
  skills/agnosticd-refactor/SKILL.md      → "Audit Area 4: agnosticd_user_info Completeness"
  skills/showroom/SKILL.md                → "AgnosticD Data Integration"
  skills/student-readiness/SKILL.md       → "Check #7: Content-Environment Match"

Proceed with research? (y/n)
```

Wait for confirmation before proceeding to Phase 2.

---

## Phase 2 — Research

### 2a. Find the upstream source

Read `references/REFERENCE.md` in the primary skill for this RQ (usually the refactor skill — `agnosticd-refactor` for AgnosticD RQs, `vp-refactor` for Validated Patterns RQs). Identify the most relevant upstream URL for the research question.

If no relevant URL is listed and the user did not provide one, stop and ask:
> "No upstream source found in references/ for this RQ. Please provide the upstream URL to fetch, or confirm which existing reference document to consult."

### 2b. Fetch and extract

Fetch the upstream source. Extract **only verified, exact content**:
- Exact variable names (not approximations like "something like `user_count`")
- Exact module signatures, required parameters, and return values
- Exact file names and their required contents
- Exact playbook names and the Ansible tasks they must contain

Do not paraphrase or approximate. If the upstream source uses a specific term, use that term exactly.

### 2c. Compare against the user's project

Using the upstream guidance extracted in 2b as the requirements baseline, inspect the user's current project files (provided as the "Current project path or URL" input). For each requirement, determine:

- **Matches** — the project already implements this correctly
- **Gaps** — the project is missing this requirement or implements it incorrectly
- **Unclear** — the project has a file or variable that may be related but cannot be confirmed without more context

Record this comparison separately from the general finding. The skill file receives the general guidance (what upstream requires); the user receives the project-specific diagnosis (how their project measures up and what to fix).

### 2d. Verify sufficiency

Before proceeding to Phase 3, confirm that the extracted content is sufficient to replace every write target found in Phase 1. If any target requires information that was not found:

```
Research incomplete for RQ-N:
  Found: [what was found]
  Missing: [what is still needed — be specific]
  Suggested next source: [URL or repo path to check]
```

Stop and report. Do not write partial findings into the skill files — partial replacements are harder to identify as incomplete than explicit `(RESEARCH NEEDED)` blocks.

---

## Phase 3 — Write Back

### 3a. Save the reference document

Before editing any SKILL.md file, save the research findings as a new Markdown file in the relevant skill's `references/` directory:

- For AgnosticD RQs: `skills/agnosticd/references/<topic>.md`
- For Validated Patterns RQs: `skills/vp-refactor/references/<topic>.md`

The reference document should contain the raw extracted content — module signatures, variable tables, code examples — with a link to the upstream source at the top.

Then update the `references/REFERENCE.md` index in that directory to list the new file.

### 3b. Replace the placeholder blocks

For each write target confirmed in Phase 1, replace the entire `(RESEARCH NEEDED — RQ-N)` block — from the opening `>` blockquote line to the closing blank line — with the verified content.

Use consistent formatting across all files:
- Use a Markdown table for variable/parameter lists
- Use fenced code blocks with language tags for code examples
- Keep the section heading unchanged
- Remove the `(RESEARCH NEEDED)` marker and the "Current partial guidance:" label — replace both with the full verified content

### 3c. Report the write-back

Present a summary table when all writes are complete:

```
Research Write-Back — RQ-N: <topic>
──────────────────────────────────────────────────────
 File                              Section            Status
 agnosticd/SKILL.md               <section>          UPDATED
 agnosticd-refactor/SKILL.md      <section>          UPDATED
 showroom/SKILL.md                <section>          UPDATED
 student-readiness/SKILL.md       <section>          UPDATED
──────────────────────────────────────────────────────
 Reference saved: skills/agnosticd/references/<topic>.md
 REFERENCE.md updated: skills/agnosticd/references/REFERENCE.md
```

---

## Phase 4 — Upstream Contribution (Optional)

This phase is optional. Activate it after Phase 3 write-back is complete when research reveals a gap, missing documentation, or undocumented behavior in the upstream project itself.

### When to Activate Phase 4

Activate Phase 4 when: the user's project correctly implements what the upstream guidance specifies, and the upstream tool still does not behave as documented. This is the key distinction:

- **Missing or unclear upstream documentation** → update the skill files locally (Phase 3). Do not open an upstream issue just because documentation is sparse.
- **Project correctly follows the guidance; tool doesn't behave as documented** → this is an upstream bug or documentation inaccuracy worth reporting. Activate Phase 4.

If the project has gaps (found in Phase 2c), address those gaps with the user first. Phase 4 is only warranted when the project is correct and the tool is wrong.

If none of these conditions apply, skip Phase 4.

### Upstream Issue Tracker Lookup

Use this table to identify the correct upstream repository for an issue or PR:

| Skill | Upstream issue tracker |
|-------|----------------------|
| `vp-refactor` / `patternizer` | https://github.com/validatedpatterns/validatedpatterns.io/issues |
| `patternizer` (tool itself) | https://github.com/validatedpatterns/patternizer/issues |
| `agnosticd-refactor` / `agnosticd` | https://github.com/agnosticd/agnosticd-v2/issues |
| `showroom` | https://github.com/rhpds/showroom-deployer/issues |
| `field-sourced-content` | https://github.com/rhpds/field-sourced-content-template/issues |

### Phase 4a — Draft the Contribution

Offer the user a choice before doing anything:

```
The user's project correctly implements the upstream guidance, but the tool does not behave as documented:
  [describe the specific discrepancy — what the docs say vs. what the tool does]

Would you like to:
  (A) Create a GitHub issue to report the discrepancy
  (B) Create a GitHub PR with a documentation or code fix (doc-only changes unless user is a contributor)
  (C) Skip — keep the finding in the skill file only
```

Wait for the user's choice before drafting anything.

**For GitHub Issues (option A):**

Draft the issue for user review before any `gh` command is run:

```
Proposed issue for: <upstream repo>

Title: [Concise description of the missing documentation]

Body:
## Summary
[One paragraph describing what is missing]

## Expected documentation
[What should be documented and where]

## Why this matters
[Impact on users — what goes wrong without this doc]

## Suggested content
[Draft of the missing documentation or schema]

Approve this draft? (y/n)
```

**For GitHub PRs (option B — doc-only changes only):**

Only offer this path if:
- The fix is documentation only (Markdown, YAML schema docs, README updates)
- The user has a fork of the upstream repository or is willing to create one

Draft the corrected content for user review first. Never run `gh pr create` without explicit user approval of both the content and the target branch.

### Phase 4b — Create the Contribution

Only after the user approves the draft:

```bash
# GitHub Issue
gh issue create \
  --repo <owner>/<repo> \
  --title "<approved title>" \
  --body "<approved body>"

# GitHub PR (user must have fork set up)
gh pr create \
  --repo <owner>/<repo> \
  --title "<approved title>" \
  --body "<approved body>" \
  --base main
```

### Phase 4 Output

Report the result:

```
Phase 4 — Upstream Contribution
──────────────────────────────────────
 Type:       GitHub Issue
 Repo:       validatedpatterns/validatedpatterns.io
 Title:      Document pattern-metadata.yaml required fields
 URL:        https://github.com/validatedpatterns/validatedpatterns.io/issues/NNN
──────────────────────────────────────
 The issue has been filed. The (SCHEMA PENDING) marker in
 skills/vp-refactor/references/pattern-metadata.md will be
 resolved once the upstream docs are updated and re-fetched.
```

---

## RQ Registry

Current open research questions and the skills they affect:

| RQ | Description | Primary source | Affected skills |
|----|-------------|----------------|-----------------|
| RQ-1 | Pre-flight checks: Python 3.12+, podman, subuid/subgid detection and per-platform corrective actions | agnosticd-v2 README / setup scripts | `agnosticd`, `agnosticd-refactor` |
| RQ-2 | Config 5-stage anatomy: required playbook filenames, mandatory variables, default_vars conventions | agnosticd-v2 `ansible/configs/` examples | `agnosticd`, `agnosticd-refactor` |
| RQ-3 | Workload role structure: required files, task file purposes, ocp4_workload_example walkthrough | agnosticd-v2 `ansible/roles/ocp4_workload_example/` | `agnosticd`, `agnosticd-refactor` |
| RQ-4 | agnosticd_user_info pipeline: module signature, required keys, data flow to RHDP and Showroom antora.yml | agnosticd-v2 action_plugins or library | `agnosticd`, `agnosticd-refactor`, `showroom`, `student-readiness`, `field-sourced-content` |
| RQ-5 | Stop/start/status lifecycle: playbook names and locations, AWS EC2 stop semantics, RHDP cost-management requirements | agnosticd-v2 `ansible/configs/` stop/start examples | `agnosticd`, `agnosticd-refactor`, `student-readiness` |
| RQ-6 | Execution Environments: available EE images, their Ansible collection contents, when to build custom | agnosticd-v2 `execution-environments/` | `agnosticd`, `agnosticd-refactor` |
| RQ-7 | Multi-user configuration: per-student namespace variables, RBAC loop patterns, expected student count variable | agnosticd-v2 `ansible/roles/ocp4_idm_*/` or similar | `agnosticd`, `agnosticd-refactor`, `showroom`, `student-readiness` |
| VP RQ-1 | Values file completeness: `main.clusterGroupName` routing, three mandatory blocks | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| VP RQ-2 | Operator subscription discovery: catalog sources, `oc get packagemanifests` workflow | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| VP RQ-3 | Charts directory structure: Helm minimum anatomy, ArgoCD Application CR mapping | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| VP RQ-4 | Secrets model: `--with-secrets`, Vault+ESO flow, `values-secret.yaml` location | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| VP RQ-5 | VP Operator compatibility: CLI vs Operator comparison, three Operator form fields | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| VP RQ-6 | `pattern-metadata.yaml` schema: exact field names (purpose and location known) | upstream reference patterns — **PARTIAL** | `vp-refactor` |
| VP RQ-8 | Imperative jobs: CronJob model, YAML list requirement, idempotency, scheduling | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| RQ-HUB-1 | Hub cluster config: what AgnosticD config pattern provisions a Showroom-only hub while N student clusters are provisioned separately | agnosticd-v2 `ansible/configs/` — look for `ocp4-hub`, `ocp4-shared`, or similar | `agnosticd-hub-student` |
| RQ-HUB-2 | Showroom cross-cluster terminal: how `ocp4_workload_showroom` or its Helm chart targets a different cluster API URL per student | agnosticd-v2 `ansible/roles/ocp4_workload_showroom/` and Showroom Helm chart | `agnosticd-hub-student`, `showroom` |
| RQ-HUB-3 | Student cluster credentials in `agnosticd_user_info`: which keys carry per-student API URL, kubeconfig, admin password, console URL when the student cluster is separate from the hub | agnosticd-v2 action_plugins — extends RQ-4 | `agnosticd-hub-student`, `agnosticd`, `showroom` |
| RQ-HUB-4 | SNO and compact cluster sizing across AWS, GCP, and Azure: instance types per provider, resource minimums, cost model per student, hub cluster minimum sizing, existing AgnosticD configs (e.g., `ocp4-sno`) | agnosticd-v2 `ansible/configs/ocp4-sno/` or similar; AWS EC2 / GCP Compute / Azure VM sizing docs | `agnosticd-hub-student` |
| RQ-HUB-5 | Hub+student lifecycle: how stop/start/status operates when hub and student clusters are provisioned independently — can student clusters be stopped without stopping the hub? | agnosticd-v2 stop/start playbook patterns — extends RQ-5 | `agnosticd-hub-student` |
| RQ-HUB-6 | Student count variable: what AgnosticD variable controls how many student clusters are provisioned (`num_students`, `student_count`), how the provisioning loop iterates over it, and what the maximum supported count is | agnosticd-v2 `ansible/configs/` student-count examples | `agnosticd-hub-student` |
| RQ-HUB-7 | Cloud provider quota requirements for N student clusters across AWS, GCP, and Azure: exact per-cluster public IP / EIP count, vCPU count, VPC/VNet count, load balancer count, and NAT gateway count for both SNO and compact cluster types; default quota values per provider; and the correct Console / CLI path to request increases on each platform | AWS OCP IPI docs; GCP OCP IPI docs; Azure OCP IPI docs; agnosticd-v2 provider-specific pre-check scripts if present | `agnosticd-hub-student` |

To check which RQs are still open at any time, run a scan:
```bash
grep -r "RESEARCH NEEDED" skills/*/SKILL.md
```

---

## Escalation

- **Upstream source has changed significantly** from what the skill describes → flag for a full skill review via the **agnosticd-refactor** or **vp-refactor** skill, not just a placeholder fill
- **RQ spans both AgnosticD and Validated Patterns** → run two separate research sessions, one per ecosystem, using the appropriate refactor skill as the primary reference
- **Upstream source requires authentication or is behind a VPN** → stop and ask the user to provide the content directly as a paste, then proceed with Phase 3 using the pasted content as the source
