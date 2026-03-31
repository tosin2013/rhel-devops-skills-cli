---
name: field-sourced-content
description: AI assistance for building RHDP Catalog Items using the Field-Sourced Content Template — a self-service GitOps platform with Helm and Ansible deployment patterns. Use when creating demos or labs for Red Hat Demo Platform.
---

# Field-Sourced Content Template Skill

## When to Use

- Creating a new RHDP (Red Hat Demo Platform) catalog item
- Choosing between Helm and Ansible deployment patterns
- Writing Helm charts for ArgoCD-driven deployment
- Writing Ansible playbooks for Kubernetes automation via Ansible Runner
- Configuring RHDP integration labels (`demo.redhat.com/userinfo`, `demo.redhat.com/application`)
- Setting up Showroom content for demos
- Debugging ArgoCD sync or deployment issues

## Instructions

- Reference the documentation in `references/` for detailed guidance
- See `references/REFERENCE.md` for an index of available documentation files
- The template provides two deployment patterns: **Helm** and **Ansible**

## Deployment Patterns

### Helm Pattern (`examples/helm/`)
Use when deployment can be expressed as Kubernetes manifests with Helm templating.

```
Your Git Repo         OpenShift Cluster
┌────────────┐       ┌─────────────────────┐
│ Helm Chart │─ArgoCD→│ Your Workload       │
│ (templates,│       │ (operators, apps)    │
│  values)   │       └─────────────────────┘
└────────────┘
```

### Ansible Pattern (`examples/ansible/`)
Use when you need wait-for-ready, secret generation, API calls, or conditional logic.

ArgoCD creates a Kubernetes Job that runs your playbook via Ansible Runner.

## Quick Start

```bash
git clone https://github.com/rhpds/field-sourced-content-template.git my-content
cd my-content
cd examples/helm      # or examples/ansible
# Edit values.yaml and templates per each example's README
```

Then order **Field Content CI** from RHDP with your repository URL.

## RHDP Integration Labels

```yaml
# Health monitoring — ArgoCD tracks application readiness
metadata:
  labels:
    demo.redhat.com/application: "my-demo"

# Data passback — AgnosticD picks up URLs, credentials, etc.
metadata:
  labels:
    demo.redhat.com/userinfo: ""
```

## Best Practices

- Start from `examples/helm/` or `examples/ansible/` — do not build from scratch
- Each component should be independently toggleable via `values.yaml`
- Never commit secrets to git — use OpenShift Secrets
- Label resources for RHDP integration (userinfo, application)
- Test Helm charts with `helm template` before pushing
- For Ansible, use `kubernetes.core.k8s` module and the auto-injected variables (`cluster_domain`, `namespace`)
