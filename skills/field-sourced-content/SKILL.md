---
name: field-sourced-content
description: AI assistance for building RHDP Catalog Items using the Field-Sourced Content Template — a self-service GitOps platform with Helm and Ansible deployment patterns. Use when creating demos or labs for Red Hat Demo Platform.
related_skills: [agnosticd, showroom]
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
- Adding Showroom lab guides to field content
- Scaffolding a new demo or lab project from the template
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

## Scaffolding Workflow

This template is a **bootstrap** -- clone it to start a new project, then actively customize it for the user's demo or lab. The resulting repo belongs to the user's org, not the upstream template.

### 1. Clone and initialize

```bash
git clone https://github.com/rhpds/field-sourced-content-template.git my-demo
cd my-demo
git remote set-url origin https://github.com/your-org/my-demo.git
```

### 2. Choose a pattern and remove the other

```bash
# For Helm-based deployment:
rm -rf examples/ansible
cp -r examples/helm/* .

# Or for Ansible-based deployment:
rm -rf examples/helm
cp -r examples/ansible/* .
```

### 3. Customize for the user's goal

- **Helm**: Edit `values.yaml` to enable/disable components (operator, helloWorld, showroom), add custom templates under `components/`, set image references and resource limits
- **Ansible**: Write playbooks in `site.yml` using `kubernetes.core.k8s` with auto-injected variables (`cluster_domain`, `namespace`, `cluster_api_url`)
- Set `demo.redhat.com/application` and `demo.redhat.com/userinfo` labels on resources
- Configure Showroom content in `components/showroom/` if the demo needs a lab guide

### 4. Push and deploy

```bash
git add . && git commit -m "Initialize field content for my demo"
git push -u origin main
```

Then either order **Field Content CI** from RHDP with the repo URL, or configure AgnosticD with `ocp4_workload_field_content_gitops_repo_url` pointing to the user's repo.

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
3. **Data flows back** via two additive pipelines — both can be active in the same deployment

**Pipeline A — AgnosticD direct (workload roles):**
```
agnosticd_user_info calls in workload roles
  → structured data written during provisioning
  → RHDP catalog (student display: URLs, credentials)
  → Showroom antora.yml attribute injection
```

**Pipeline B — Field Content via label (deployed resources):**
```
ConfigMaps labeled demo.redhat.com/userinfo=""
  deployed by your ArgoCD Helm chart or Ansible playbook
  → AgnosticD picks up the ConfigMap data post-deploy
  → merges into RHDP catalog alongside Pipeline A output
```

Pipeline A is the primary mechanism for core cluster data (API URL, ingress domain, admin credentials). Pipeline B is the mechanism for workload-specific data that only becomes known after the field content deploys (e.g. application URLs, generated credentials). Both pipelines write to the same RHDP catalog destination — use them together for complete student-facing output.

This repository includes `roles/ocp4_workload_field_content/` -- an AgnosticD workload role that creates an ArgoCD Application from your field content Git repo. The role requires:

- `ocp4_workload_field_content_gitops_repo_url` -- your content repository URL
- `ocp4_workload_field_content_namespace` -- target namespace for the ArgoCD Application

The role automatically receives `openshift_cluster_ingress_domain` and `openshift_api_url` from the AgnosticD provisioned cluster, which are passed to ArgoCD as deployer values.

The Helm example also includes a `components/showroom/` directory that deploys Showroom lab guides alongside your demo. See the **showroom** skill for content authoring and terminal configuration.

See the **agnosticd** skill ("Reporting Deployment Info" section) for the full `agnosticd_user_info` data flow and how Pipeline A data reaches the RHDP catalog and Showroom.

## Best Practices

- Start from `examples/helm/` or `examples/ansible/` — do not build from scratch
- Each component should be independently toggleable via `values.yaml`
- Never commit secrets to git — use OpenShift Secrets
- Label resources for RHDP integration (userinfo, application)
- Test Helm charts with `helm template` before pushing
- For Ansible, use `kubernetes.core.k8s` module and the auto-injected variables (`cluster_domain`, `namespace`)
