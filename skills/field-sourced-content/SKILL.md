---
name: field-sourced-content
description: AI assistance for building RHDP Catalog Items using the Field-Sourced Content Template — a self-service GitOps platform with Helm and Ansible deployment patterns. Use when creating demos or labs for Red Hat Demo Platform.
related_skills: [agnosticd]
---

# Field-Sourced Content Template Skill

## When to Use

- Creating a new RHDP (Red Hat Demo Platform) catalog item
- Choosing between Helm and Ansible deployment patterns
- Writing Helm charts for ArgoCD-driven deployment
- Writing Ansible playbooks for Kubernetes automation via Ansible Runner
- Configuring RHDP integration labels (`demo.redhat.com/userinfo`, `demo.redhat.com/application`)
- Setting up Showroom content for demos
- Deploying field content on an AgnosticD-provisioned cluster
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

## AgnosticD Integration

Field-Sourced Content deploys onto OpenShift clusters that are provisioned by [AgnosticD v2](https://github.com/agnosticd/agnosticd-v2). The two tools form a complete RHDP workflow:

1. **AgnosticD provisions the cluster** via `agd provision`
2. **Field content deploys onto it** via ArgoCD (triggered by the `ocp4_workload_field_content` workload role)
3. **Data flows back** through `demo.redhat.com/userinfo` ConfigMaps that AgnosticD picks up

This repository includes `roles/ocp4_workload_field_content/` -- an AgnosticD workload role that creates an ArgoCD Application from your field content Git repo. The role requires:

- `ocp4_workload_field_content_gitops_repo_url` -- your content repository URL
- `ocp4_workload_field_content_namespace` -- target namespace for the ArgoCD Application

The role automatically receives `openshift_cluster_ingress_domain` and `openshift_api_url` from the AgnosticD provisioned cluster, which are passed to ArgoCD as deployer values.

See the **agnosticd** skill for guidance on provisioning the cluster and configuring workloads.

## Best Practices

- Start from `examples/helm/` or `examples/ansible/` — do not build from scratch
- Each component should be independently toggleable via `values.yaml`
- Never commit secrets to git — use OpenShift Secrets
- Label resources for RHDP integration (userinfo, application)
- Test Helm charts with `helm template` before pushing
- For Ansible, use `kubernetes.core.k8s` module and the auto-injected variables (`cluster_domain`, `namespace`)
