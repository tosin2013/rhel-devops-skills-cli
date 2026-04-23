---
name: vp-submission
description: AI assistance for auditing a Validated Pattern against VP tier requirements (Community/Sandbox, Tested, Maintained) and guiding submission to validatedpatterns/docs. Use after vp-deploy-validator reports HEALTHY and the pattern deploys fully without user interaction.
related_skills: [vp-deploy-validator, vp-deploy-test, vp-refactor, patternizer]
---

# Validated Pattern Submission Skill

## When to Use

**Purpose:** Use this skill after `vp-deploy-validator` reports HEALTHY to audit whether the pattern meets Validated Patterns tier requirements and guide the developer through the PR submission process to [validatedpatterns/docs](https://github.com/validatedpatterns/docs).

- `vp-deploy-validator` just passed and you want to know what it takes to get the pattern listed on validatedpatterns.io
- You want to understand which VP tier (Community, Tested, Maintained) the pattern currently qualifies for
- You are preparing a PR to [validatedpatterns/docs](https://github.com/validatedpatterns/docs) to list the pattern
- You want a gap analysis between current state and the next tier

**Prerequisite:** The pattern must deploy fully unattended (no interactive prompts in `pattern.sh make install`). This is checked by `vp-deploy-validator` Phase 1 — if a `SUBMISSION_BLOCKING` finding is present, resolve it before using this skill.

Do NOT use this skill to fix pattern structure issues — use the **vp-refactor** skill instead. Do NOT use this skill to validate a live deployment — use the **vp-deploy-validator** skill instead.

## Instructions

This skill defines a three-phase process. Work through the phases in order.

## Required Input

Before starting, collect:

| Input | Required | Example |
|-------|----------|---------|
| Pattern repository URL | Yes | `https://github.com/my-org/my-pattern` |
| Pattern name | Yes | `my-workshop-pattern` |
| Target tier | No — defaults to Community | `community`, `tested`, `maintained` |
| OCP versions the pattern has been tested on | No | `4.14`, `4.15`, `4.16` |
| CI/CD system used | No | `GitHub Actions`, `Tekton`, `none` |
| Active maintainer GitHub handles | No | `@my-handle` |

---

## Phase 1 — Tier Readiness Audit

Audit the pattern repository against all three tier criteria. Report pass/fail for each check, even if the target tier is lower than Maintained — this gives the developer a full gap analysis.

### Tier 1 — Community/Sandbox

The entry point for listing a pattern on validatedpatterns.io. All checks must pass.

| Check | How to verify | Pass condition |
|-------|---------------|---------------|
| Non-interactive deploy | Run `pattern.sh make install` without any TTY attached; `vp-deploy-validator` reports no `SUBMISSION_BLOCKING` | Exits 0 with no interactive prompts |
| `pattern-metadata.yaml` present and valid | `ls pattern-metadata.yaml` and inspect fields | File exists with `name`, `displayName`, `description`, `type` populated |
| `values-secret.yaml` excluded from git | `git log --all -- values-secret.yaml` | No commits found |
| Pattern repo is public on GitHub | Check repo visibility | Public (not private or internal) |
| README explains the use case | Review `README.md` or `README.adoc` | Covers what the pattern does, who it is for, and how to deploy it |
| `pattern-metadata.yaml` tier field | Inspect `tier:` field | Set to `community` or left unset (defaults to community) |

> (RESEARCH NEEDED — VP-SUB-1: Exact required fields for `pattern-metadata.yaml` at Community tier — field names, types, and which are mandatory vs. optional per validatedpatterns.io current schema)

### Tier 2 — Tested

Requires a working CI/CD pipeline that proves the pattern deploys automatically.

| Check | How to verify | Pass condition |
|-------|---------------|---------------|
| CI/CD pipeline exists | Check `.github/workflows/`, `.tekton/`, or equivalent | At least one pipeline file that runs `pattern.sh make install` |
| Pipeline runs on push | Inspect pipeline trigger | Triggered on `push` to `main` or equivalent |
| OCP version matrix declared | Check pipeline or `pattern-metadata.yaml` | At least one OCP version declared and tested |
| ArgoCD convergence confirmed in CI | Pipeline includes a health check step | `oc get applications` health check or equivalent in pipeline output |
| Lab or demo documentation present | Check `docs/` or `README` | Step-by-step lab or demo guide exists |
| `pattern-metadata.yaml` tier field | Inspect `tier:` field | Set to `tested` |

> (RESEARCH NEEDED — VP-SUB-2: Exact CI/CD requirements for the Tested tier — which pipeline platforms are accepted, what the convergence check must cover, and what OCP version matrix is required per the VP team's current acceptance criteria)

### Tier 3 — Maintained

Requires ongoing commitment from an active maintainer.

| Check | How to verify | Pass condition |
|-------|---------------|---------------|
| `OWNERS` file present | `ls OWNERS` | File lists at least one active maintainer with GitHub handle |
| Dependency update cadence | Check git log for Helm chart version or operator subscription bumps | At least one dependency update in the last 90 days |
| Red Hat partner or community involvement | Inspect OWNERS, CODEOWNERS, or commit history | Red Hat employee, RHPDS team, or recognized community contributor listed |
| Issue/PR response SLA | Check recent issues/PRs | No open issues/PRs older than 30 days without a response |
| `pattern-metadata.yaml` tier field | Inspect `tier:` field | Set to `maintained` |

> (RESEARCH NEEDED — VP-SUB-3: Exact Maintained tier requirements — SLA values, what qualifies as "Red Hat involvement", whether RHDP team ownership counts, and how the VP team verifies maintainer activity)

### Tier Audit Report

```
VP Tier Readiness Audit — <pattern-name>
══════════════════════════════════════════════════════
 Tier 1 — Community/Sandbox
  Non-interactive deploy           PASS / FAIL
  pattern-metadata.yaml present    PASS / FAIL
  values-secret.yaml excluded      PASS / FAIL
  Repo public on GitHub            PASS / FAIL
  README use case                  PASS / FAIL
  ─────────────────────────────────
  Tier 1 overall:                  READY / NOT READY

 Tier 2 — Tested
  CI/CD pipeline exists            PASS / FAIL / N/A
  Pipeline runs on push            PASS / FAIL / N/A
  OCP version declared             PASS / FAIL / N/A
  Convergence check in CI          PASS / FAIL / N/A
  Lab/demo documentation           PASS / FAIL / N/A
  ─────────────────────────────────
  Tier 2 overall:                  READY / NOT READY / GAPS

 Tier 3 — Maintained
  OWNERS file present              PASS / FAIL / N/A
  Dependency updates recent        PASS / FAIL / N/A
  RH/community involvement         PASS / FAIL / N/A
  Issue/PR SLA met                 PASS / FAIL / N/A
  ─────────────────────────────────
  Tier 3 overall:                  READY / NOT READY / GAPS
══════════════════════════════════════════════════════
 Highest tier achieved:  Community / Tested / Maintained / NONE
 Recommended action:     submit at <tier> / resolve gaps first
```

If any Tier 1 check fails, stop. The pattern cannot be submitted at any tier until all Tier 1 checks pass.

---

## Phase 2 — Gap Remediation Plan

For any tier the developer wants to target, produce an ordered remediation plan for checks that failed.

```
VP Submission Gap Plan — <pattern-name> → target: <tier>
──────────────────────────────────────────────────────
Priority  #  Gap                               Action
BLOCKING  1  pattern.sh requires interaction   Fix interactive prompts → vp-deploy-validator
BLOCKING  2  pattern-metadata.yaml missing     Create file with required fields (see RQ VP-SUB-1)
HIGH      3  No CI/CD pipeline                 Add GitHub Actions workflow calling pattern.sh make install
MEDIUM    4  No OCP version declared           Add tested-ocp-versions to pattern-metadata.yaml
──────────────────────────────────────────────────────
```

Present only the gaps for the chosen target tier. Ask:
> "Would you like to address item 1 now? (y/n)"

If yes for structural issues, activate **vp-refactor**. If yes for CI/CD setup, provide the GitHub Actions workflow template below.

### GitHub Actions CI Template (Tier 2 baseline)

```yaml
# .github/workflows/validate-pattern.yml
name: Validate Pattern
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up oc
        uses: redhat-actions/openshift-tools-installer@v1
        with:
          oc: latest

      - name: Login to OCP
        run: |
          oc login ${{ secrets.OCP_API_URL }} \
            --token=${{ secrets.OCP_TOKEN }} \
            --insecure-skip-tls-verify

      - name: Install pattern
        run: ./pattern.sh make install

      - name: Wait for ArgoCD convergence
        run: |
          for i in $(seq 1 30); do
            NOT_HEALTHY=$(oc get applications -n openshift-gitops \
              -o jsonpath='{range .items[*]}{.status.health.status}{"\n"}{end}' \
              | grep -v Healthy | wc -l)
            [ "$NOT_HEALTHY" -eq 0 ] && echo "All healthy" && exit 0
            echo "Waiting... ($i/30)"
            sleep 30
          done
          echo "Convergence timeout" && exit 1
```

> (RESEARCH NEEDED — VP-SUB-2: The VP team may have an official CI template or GitHub Actions reusable workflow — check validatedpatterns/docs/.github/ and validatedpatterns/common for official CI tooling)

---

## Phase 3 — Submission PR Guidance

Once the pattern passes all checks for the chosen tier, guide the developer through submitting a PR to [validatedpatterns/docs](https://github.com/validatedpatterns/docs).

### Step 1 — Fork the docs repo

```bash
gh repo fork validatedpatterns/docs --clone
cd docs
```

### Step 2 — Understand the content structure

> (RESEARCH NEEDED — VP-SUB-4: Exact content structure of validatedpatterns/docs — which directory holds pattern pages, what frontmatter fields are required, what the tier badge syntax is, and what a merged pattern page looks like in the repo)

**Current partial guidance** (verify against the live repo before filing a PR):

The docs repo uses Hugo with AsciiDoc content. Pattern pages live under `content/`. Based on the repo structure at [github.com/validatedpatterns/docs](https://github.com/validatedpatterns/docs), a pattern entry includes:
- A directory under `content/patterns/<pattern-name>/`
- An `_index.adoc` file with Hugo frontmatter
- A `getting-started.adoc` file with installation instructions

### Step 3 — Create the pattern page

```bash
mkdir -p content/patterns/<pattern-name>
```

Minimum `_index.adoc` frontmatter:

```asciidoc
---
title: <Pattern Display Name>
date: <YYYY-MM-DD>
tier: community|tested|maintained
summary: <One sentence describing what the pattern does>
rh_products:
  - <Red Hat Product Name>
industries:
  - <Industry>
---
```

> (RESEARCH NEEDED — VP-SUB-4: Exact frontmatter schema and required fields for the Hugo-based docs site — check `archetypes/` and existing pattern pages in `content/patterns/`)

### Step 4 — Submit the PR

```bash
git checkout -b add-<pattern-name>-pattern
git add content/patterns/<pattern-name>/
git commit -m "feat: add <pattern-name> at <tier> tier"
git push origin add-<pattern-name>-pattern
gh pr create \
  --repo validatedpatterns/docs \
  --title "feat: add <pattern-name> pattern (<tier> tier)" \
  --body "$(cat <<'EOF'
## Summary

- Adds pattern page for <pattern-name>
- Tier: <community|tested|maintained>
- Pattern repo: <GitHub URL>

## Checklist

- [ ] Pattern deploys without user interaction
- [ ] pattern-metadata.yaml present and valid
- [ ] values-secret.yaml excluded from git
- [ ] README explains use case

EOF
)"
```

### Step 5 — Reviewer expectations

> (RESEARCH NEEDED — VP-SUB-5: What the VP team checks during PR review — OWNERS file, CI results, tier-specific requirements, response time SLA, and whether a demo or recording is required)

**Current partial guidance:**
- The VP team reviews for tier compliance — the checklist in the PR body should match the audit from Phase 1
- A link to a recent successful CI run or a recorded demo strengthens the submission
- Expect review comments within 1–2 weeks from the validatedpatterns maintainers

### Submission Report

```
VP Submission — <pattern-name>
══════════════════════════════════════════════════════
 Target tier:    <community|tested|maintained>
 PR filed:       <PR URL>
 Pattern repo:   <GitHub URL>
 Submitted by:   <GitHub handle>

 Tier 1 audit:   PASS
 Tier 2 audit:   PASS / N/A
 Tier 3 audit:   PASS / N/A

 Status:  PR SUBMITTED — awaiting VP team review
══════════════════════════════════════════════════════
```

---

## Research Questions

The following items require upstream research via `skill-researcher`:

| RQ | Description | Primary source |
|----|-------------|----------------|
| VP-SUB-1 | Exact required fields for `pattern-metadata.yaml` at Community tier | validatedpatterns/docs `content/` and validatedpatterns/common |
| VP-SUB-2 | CI/CD requirements for Tested tier — accepted platforms, convergence check spec, OCP version matrix | validatedpatterns/docs `AGENTS.md`, `.github/workflows/`, VP team documentation |
| VP-SUB-3 | Maintained tier requirements — SLA values, Red Hat involvement criteria, maintainer verification process | validatedpatterns/docs contributor guidelines |
| VP-SUB-4 | validatedpatterns/docs content structure — directory layout, Hugo frontmatter schema, tier badge syntax | validatedpatterns/docs `archetypes/`, `content/patterns/` examples |
| VP-SUB-5 | PR reviewer expectations and merge criteria — checklist, demo requirements, review timeline | validatedpatterns/docs CONTRIBUTING.md or OWNERS file |

---

## Escalation

- **Non-interactive install failure** → Use **vp-deploy-test** to re-validate after fixing interactive prompts; confirm `vp-deploy-validator` shows no `SUBMISSION_BLOCKING` finding
- **Structural pattern issues (values, charts, secrets)** → Use **vp-refactor** to audit and fix before re-running Phase 1
- **`pattern-metadata.yaml` missing or malformed** → Use **vp-refactor** for structural audit, then resolve VP-SUB-1 via `skill-researcher`
- **PR rejected by VP team** → Review reviewer comments, address findings, and re-run Phase 1 audit before re-submitting
