---
title: VP Refactor
parent: Skills
nav_order: 8
---

# VP Refactor Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The VP Refactor skill guides the AI assistant through auditing an existing Validated Pattern repository — including repos initialized with `patternizer init` — against the requirements for the VP Operator and the Sandbox/Tested/Maintained tier progression.

`patternizer init` generates the structural scaffolding (Makefiles, utility scripts, values file templates) but deliberately leaves the payload empty. Developers frequently stall during the "Day 2" phase — after initialization but before a functional deployment — because the generated configuration files require contextual data that the tool cannot infer: `main.clusterGroupName`, operator subscription fields, Helm chart paths, and secrets file locations. This skill bridges that gap with a structured 8-area audit.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "what do I fill in after `patternizer init`?"
- Asking "why won't `./pattern.sh make install` work?"
- Preparing a pattern for Sandbox tier submission to [validatedpatterns.io](https://validatedpatterns.io)
- Fixing values files where operators are not deploying correctly
- Verifying the pattern works with the VP Operator (not just the CLI)
- Finding that `pattern-metadata.yaml` is missing or incorrectly structured
- Removing secrets that were accidentally committed to the repository

Do NOT use this skill when initializing a new pattern from scratch — use the [Patternizer](patternizer.html) skill instead.

## The 8-Area Audit

| # | Audit Area | What It Checks |
|---|-----------|----------------|
| 1 | Values file completeness | `main.clusterGroupName` routing, three mandatory blocks (namespaces, subscriptions, applications) |
| 2 | Operator subscription correctness | Catalog source, channel, and `startingCSV` via cluster query workflow |
| 3 | Charts directory structure | Minimum Helm chart anatomy at every `path:` in `applications:` |
| 4 | Secrets model compliance | `--with-secrets`, Vault+ESO setup, `values-secret.yaml` at `~/.config/validatedpatterns/` |
| 5 | VP Operator compatibility | CLI vs Operator differences, three required Operator form fields, fork URL requirement |
| 6 | `pattern-metadata.yaml` presence | Required for VP catalog visibility and tier submission |
| 7 | Sandbox tier checklist | Deployability, README, architecture diagram, support policy, open contribution |
| 8 | Imperative jobs assessment | CronJob structure, YAML list requirement, idempotency, 10-min schedule |

## Key Architectural Concepts

### Values File Routing

`main.clusterGroupName` in `values-global.yaml` acts as the topological router — ArgoCD uses this string to find the matching `values-<string>.yaml` file. A mismatch causes a silent deployment failure with no workloads deployed.

### Dependency Chain

The three mandatory blocks in `values-<cluster>.yaml` must be populated in dependency order:

```
namespaces: → subscriptions: → applications:
     ↑               ↑               ↑
Must exist       Must target     Must target
before           defined         defined
operators        namespaces      namespaces
deploy
```

### Secrets File Location

`values-secret.yaml` must never be committed to git. The `make load-secrets` target searches for it at:

```
~/.config/validatedpatterns/values-secret-<pattern_name>.yaml
```

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [Patternizer](patternizer.html) | Initialization skill — use for `patternizer init` and `upgrade`; vp-refactor audits what patternizer generates |
| [Skill Researcher](skill-researcher.html) | Resolves open `(RESEARCH NEEDED)` placeholders in this skill's audit areas |

See [ADR-013](../adrs/013-refactor-skills.html) for the design rationale and [ADR-014](../adrs/014-skill-researcher.html) for how open research questions are resolved.

## Install

```bash
./install.sh install --skill vp-refactor
```
