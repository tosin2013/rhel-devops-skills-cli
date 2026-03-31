---
title: "ADR-010: Cross-Skill Dependencies"
nav_order: 10
parent: Architecture Decision Records
---

# ADR-010: Cross-Skill Dependencies

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team

## Context and Problem Statement

Some DevOps tools in the skill catalog have tight integration relationships. For example, AgnosticD v2 provisions OpenShift clusters and manages post-deployment workloads, while Field-Sourced Content Template provides a self-service pattern for deploying demos and labs onto those clusters. The field-sourced-content repository even ships an AgnosticD workload role (`roles/ocp4_workload_field_content/`) that bridges the two tools.

When skills are treated as fully independent, AI assistants miss opportunities to guide users through combined workflows. A user building field content may not realize they need AgnosticD to provision the cluster, and a user configuring AgnosticD workloads may not know about the field content deployment pattern.

How should the skill system represent and surface cross-skill relationships?

## Decision Drivers

* Skills should remain self-contained and independently installable (ADR-001)
* AI assistants need enough context to suggest related skills during multi-tool workflows
* The metadata format must be backward-compatible -- existing skills without relationships must continue to work
* Relationships should be based on verifiable upstream integration, not speculation
* The SKILL.md format should stay close to the [Agent Skills Open Standard](https://agentskills.io)

## Considered Options

1. **No formal mechanism** -- Document relationships only in prose within each SKILL.md
2. **Front matter `related_skills` field** -- Add an optional list of related skill names to the YAML front matter, plus a dedicated section in the body
3. **Separate relationship manifest** -- A top-level `relationships.json` file mapping skill pairs
4. **Dependency field with install-time enforcement** -- Skills declare hard dependencies that the installer resolves

## Decision Outcome

Chosen option: **"Front matter `related_skills` field with dedicated integration section"**, because it keeps the relationship metadata co-located with the skill definition, is backward-compatible (the field is optional), and gives the AI assistant structured data to act on without requiring installer changes.

### Specification

#### Front Matter

Skills MAY include a `related_skills` list in their YAML front matter:

```yaml
---
name: agnosticd
description: ...
related_skills: [field-sourced-content]
---
```

The list contains skill names (matching the `name` field of other skills). The relationship is informational, not a hard dependency -- skills install and function independently.

#### Integration Section

When a skill has related skills, the SKILL.md body SHOULD include a dedicated section (e.g., "Integration with Field-Sourced Content") that explains:

* What the integration enables
* Which upstream components bridge the tools (roles, labels, APIs)
* A concrete configuration or usage example
* A pointer to the related skill for the other half of the workflow

#### AI Assistant Behavior

When a user's task touches functionality described in a related skill:

* The assistant SHOULD mention the related skill and its relevance
* The assistant SHOULD NOT require the related skill to be installed -- it should provide inline guidance if the related skill is absent
* The assistant SHOULD use the integration section to provide accurate cross-tool configuration

### First Instance: AgnosticD + Field-Sourced Content

The AgnosticD and Field-Sourced Content skills are the first pair to use this mechanism. Their integration is documented based on verified upstream sources:

```
AgnosticD v2                          Field-Sourced Content
┌──────────────────┐                  ┌──────────────────────────┐
│ agd provision     │  provisions     │ Git repo with Helm/      │
│ (OpenShift cluster│ ──────────────► │ Ansible content          │
│  + workloads)     │                 └────────────┬─────────────┘
│                   │                              │
│ workloads:        │                    ArgoCD deploys onto cluster
│ - ocp4_workload_  │                              │
│   field_content   │◄──── workload role ──────────┘
│                   │
│ Picks up userinfo │◄──── demo.redhat.com/userinfo ConfigMap
└──────────────────┘
```

**Evidence:**

* The [field-sourced-content-template README](https://github.com/rhpds/field-sourced-content-template) flow diagram shows "AgnosticD picks up user info"
* The [ocp4_workload_field_content role](https://github.com/rhpds/field-sourced-content-template/tree/main/roles/ocp4_workload_field_content) is an AgnosticD workload that creates an ArgoCD Application from a field content Git repository
* The workload role requires `ocp4_workload_field_content_gitops_repo_url` and uses `openshift_cluster_ingress_domain` / `openshift_api_url` from the AgnosticD provisioned cluster
* AgnosticD v2 [setup.adoc](https://github.com/agnosticd/agnosticd-v2/blob/main/docs/setup.adoc) documents the `workloads:` configuration list where field content would be added

### Positive Consequences

* AI assistants can guide users through end-to-end RHDP workflows spanning both tools
* The relationship is discoverable from the SKILL.md front matter without parsing prose
* No installer changes required -- the field is purely informational
* Backward-compatible -- skills without `related_skills` continue to work

### Negative Consequences

* Relationships must be maintained in both skills (bidirectional)
* The `related_skills` field is not part of the upstream Agent Skills Open Standard (may diverge)
* AI assistants need to handle the case where a related skill is not installed

## Links

* [Field-Sourced Content Template](https://github.com/rhpds/field-sourced-content-template) -- upstream repository with AgnosticD workload role
* [AgnosticD v2](https://github.com/agnosticd/agnosticd-v2) -- upstream repository with workload deployment model
* [ocp4_workload_field_content workload.yml](https://github.com/rhpds/field-sourced-content-template/blob/main/roles/ocp4_workload_field_content/tasks/workload.yml) -- the bridge role
* [Agent Skills Open Standard](https://agentskills.io) -- SKILL.md specification
* Related: [ADR-001](001-adopt-agent-skills-standard.html) (SKILL.md format), [ADR-005](005-dual-mode-skills-and-rules.html) (dual-mode installation), [ADR-009](009-community-skill-contributions.html) (contribution process)
