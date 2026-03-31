---
title: Field-Sourced Content
parent: Skills
nav_order: 2
---

# Field-Sourced Content Template Skill

**Source Repository**: [rhpds/field-sourced-content-template](https://github.com/rhpds/field-sourced-content-template)
{: .fs-5 }

## Overview

The Field-Sourced Content Template is a self-service platform for creating RHDP (Red Hat Demo Platform) catalog items using GitOps. It provides two deployment patterns — Helm and Ansible — deployed by ArgoCD on OpenShift.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Creating a new RHDP catalog item
- Choosing between Helm and Ansible deployment patterns
- Writing Helm charts for ArgoCD
- Writing Ansible playbooks for Kubernetes
- Scaffolding a new demo or lab project from the template
- Configuring RHDP integration labels
- Setting up Showroom content

## Deployment Patterns

### Helm Pattern

For deployments expressible as Kubernetes manifests with Helm templating. ArgoCD syncs the Helm chart directly.

### Ansible Pattern

For deployments requiring wait-for-ready logic, secret generation, or API calls. ArgoCD creates a Kubernetes Job running your playbook via Ansible Runner.

## Scaffolding Workflow

This template is a **bootstrap** — clone it to start a new project, then customize it for your demo or lab. The resulting repo belongs to the user's org, not the upstream template.

```bash
git clone https://github.com/rhpds/field-sourced-content-template.git my-demo
cd my-demo
rm -rf .git && git init
git remote add origin https://github.com/your-org/my-demo.git
```

Choose **one** deployment pattern and remove the other:

- **Helm**: Edit `values.yaml` to enable/disable components (Showroom, operators, namespaces)
- **Ansible**: Write playbooks in `site.yml` orchestrating ArgoCD job execution

## Related Skills

| Skill | Integration |
|-------|-------------|
| [AgnosticD v2](agnosticd.html) | AgnosticD provisions the cluster; field content deploys onto it via the `ocp4_workload_field_content` role |
| [Showroom](showroom.html) | Field content's Helm example includes a `components/showroom/` directory to deploy Showroom lab guides |

See [ADR-010](../adrs/010-cross-skill-dependencies.html) for the cross-skill dependency model.

## RHDP Integration

```yaml
metadata:
  labels:
    demo.redhat.com/application: "my-demo"   # health monitoring
    demo.redhat.com/userinfo: ""              # data passback
```

## Reference Documentation

| Document | Description |
|----------|-------------|
| `README.md` | Template overview and quick start |
| `ansible-developer-guide.md` | Ansible pattern details |
| `SHOWROOM-UPDATE-SPEC.md` | Showroom content specification |
| `helm-README.md` | Helm example guide |
| `ansible-README.md` | Ansible example guide |

## Install

```bash
./install.sh install --skill field-sourced-content
```
