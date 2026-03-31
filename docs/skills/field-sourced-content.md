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
- Configuring RHDP integration labels
- Setting up Showroom content

## Deployment Patterns

### Helm Pattern

For deployments expressible as Kubernetes manifests with Helm templating. ArgoCD syncs the Helm chart directly.

### Ansible Pattern

For deployments requiring wait-for-ready logic, secret generation, or API calls. ArgoCD creates a Kubernetes Job running your playbook via Ansible Runner.

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
