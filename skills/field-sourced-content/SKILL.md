---
name: field-sourced-content
description: AI assistance for building RHDP Catalog Items using the Field-Sourced Content Template — a self-service GitOps platform with Helm and Ansible deployment patterns. Use when creating demos or labs for Red Hat Demo Platform.
license: Apache-2.0
compatibility: Requires bash 4.4+, git, Helm, and oc/kubectl. Designed for RHEL 8/9 with Cursor and Claude Code.
metadata:
  related-skills: "agnosticd, showroom, student-readiness, project-onboard"
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
- Deploying field content onto an RHDP pre-provisioned cluster (rhdp-workload scaffold type)
- Integrating Field-Sourced Content with RHDP Keycloak-managed users

## Instructions

- **Choosing a pattern?** Default to Helm (`references/helm-README.md`); fall back to Ansible only when you need wait logic, secret injection, or API calls (`references/ansible-README.md`, `references/ansible-developer-guide.md`)
- **Setting up Showroom?** See `references/SHOWROOM-UPDATE-SPEC.md` for content maintenance
- **First time with the template?** Start with `references/README.md` for the overview and quick start
- **Project documentation?** See `references/project-documentation.md` for the full project docs index
- The template provides two deployment patterns — **Helm** (default) and **Ansible** (escape hatch)

## Gotchas

- Default to Helm deployment pattern; use Ansible only when you need wait logic, secret injection, or API calls that Helm can't handle
- The `values.yaml` in the Helm chart is the source of truth for all configurable parameters — do not hardcode values in templates
- RHDP catalog item names must match the directory name in the GitOps repo exactly (case-sensitive)
- The `deploy.sh` script must be idempotent — running it twice should not create duplicate resources
- Field-Sourced Content repos must include a `README.md` with RHDP submission metadata or the catalog submission will be rejected

## Deployment Patterns

### Helm Pattern (`examples/helm/`) — default
Use this pattern by default. Suitable whenever deployment can be expressed as Kubernetes manifests with Helm templating.

```
Your Git Repo         OpenShift Cluster
┌────────────┐       ┌─────────────────────┐
│ Helm Chart │─ArgoCD→│ Your Workload       │
│ (templates,│       │ (operators, apps)    │
│  values)   │       └─────────────────────┘
└────────────┘
```

### Ansible Pattern (`examples/ansible/`) — escape hatch
Fall back to this only when you need wait-for-ready logic, secret generation, API calls, or conditional logic that Helm cannot express.

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

## RHDP Pre-Provisioned Cluster Deployment

Field-Sourced Content integrates directly with the `rhdp-workload` scaffold type for workshops that deploy onto RHDP pre-provisioned clusters. This is the recommended path when the cluster is ordered from the RHDP catalog (`agd-v2.ocp-cluster-aws.prod`) rather than provisioned via `agd`.

### How it works

```
RHDP Catalog                     Your Git Repo                 RHDP Cluster
┌─────────────────────┐         ┌──────────────────┐         ┌────────────────────┐
│ Order OCP cluster   │─────────│ Helm/Ansible      │─ArgoCD─│ Workloads deployed │
│ (pre-provisioned,   │         │ field content     │         │ Users via Keycloak │
│  Keycloak users)    │         │ (your-org/repo)   │         │ (user1, user2, ..) │
└─────────────────────┘         └──────────────────┘         └────────────────────┘
```

### Scaffolding for RHDP

Use the `rhdp-workload` scaffold type with Field-Sourced Content enabled:

```bash
./install.sh scaffold --type rhdp-workload --output ./my-workshop
# Answer "y" to "Use Field-Sourced Content GitOps deployment?"
# Provide your content repo URL, branch, and pattern (helm/ansible)
```

The generated `deploy-workloads.sh` script will:
1. Detect RHDP pre-created users from the Keycloak SSO realm (`userN` format, no dash)
2. Create per-user namespaces and RBAC
3. Create an ArgoCD Application pointing to your field content repo
4. ArgoCD syncs your Helm chart or Ansible playbooks onto the cluster

### Key differences from AgnosticD-driven deployment

| Aspect | AgnosticD + Field Content | RHDP + Field Content |
|--------|---------------------------|----------------------|
| Cluster provisioning | `agd provision` triggers `ocp4_workload_field_content` role | RHDP catalog provides the cluster |
| ArgoCD Application creation | AgnosticD workload role | `deploy-workloads.sh` creates it directly |
| User format | `user-N` (with dash) | `userN` (no dash, Keycloak-managed) |
| Data passback (Pipeline B) | ConfigMaps labeled `demo.redhat.com/userinfo` | Same mechanism works on RHDP clusters |
| Teardown | `agd destroy` removes everything | `teardown-workloads.sh` deletes ArgoCD app + namespaces; cluster stays |

### Helm values injection

When deploying via Helm on an RHDP cluster, the deploy script passes cluster-specific values to the ArgoCD Application:

```yaml
global:
  clusterDomain: "apps.cluster-xxx.example.com"   # auto-detected
  clusterApiUrl: "https://api.cluster-xxx:6443"    # auto-detected
  namespace: "field-content"                        # configurable
  numUsers: 10                                      # from Keycloak detection
```

Your Helm chart can reference these as `{{ .Values.global.clusterDomain }}`, etc.

### RHDP integration labels

Label your deployed resources for RHDP data passback — this works the same on RHDP pre-provisioned clusters as on AgnosticD-provisioned ones:

```yaml
metadata:
  labels:
    demo.redhat.com/application: "my-workshop"
    demo.redhat.com/userinfo: ""
```

## Best Practices

- Start from `examples/helm/` (preferred) — use `examples/ansible/` only when Helm can't express the deployment logic
- Test Helm charts with `helm template` before pushing
- Label all deployed resources for RHDP integration (`demo.redhat.com/application`, `demo.redhat.com/userinfo`)
- Never commit secrets to git — use OpenShift Secrets
