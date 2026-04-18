---
name: agnosticd
description: AI assistance for AgnosticD v2 — the Ansible Agnostic Deployer for provisioning infrastructure and deploying workloads on AWS, Azure, OpenStack, and OpenShift. Use when working with the agd CLI, catalog items, configs, or deployment workflows.
related_skills: [field-sourced-content, showroom, student-readiness, workshop-tester, agnosticd-refactor, agnosticd-deploy-test, agnosticd-hub-student]
---

# AgnosticD v2 Skill

## When to Use

- Setting up the AgnosticD v2 local development environment
- Running `agd setup`, `agd provision`, `agd destroy`, `agd stop/start/status`
- Creating or modifying configs (infrastructure definitions)
- Creating or modifying workloads (post-deployment customizations)
- Configuring secrets files, variables files, or account credentials
- Working with execution environments and ansible-navigator
- Understanding the required directory structure
- Deploying Field-Sourced Content as an AgnosticD workload
- Configuring Showroom as an infra_workload for lab guides
- Setting up a fork of AgnosticD v2 for workshop development
- Debugging deployment failures

## Instructions

- Reference the documentation in `references/` for detailed guidance
- See `references/REFERENCE.md` for an index of available documentation files
- The primary CLI is `./bin/agd` — always run it from within the `agnosticd-v2` directory

## Directory Structure

AgnosticD v2 requires this local directory layout (created by `agd setup`):

```
~/Development/              # or any root directory
  agnosticd-v2/             # the code repository
  agnosticd-v2-vars/        # configuration variables files
  agnosticd-v2-secrets/     # secrets.yml + per-account secrets
  agnosticd-v2-output/      # ansible run output (per GUID)
  agnosticd-v2-virtualenv/  # Python 3.12+ venv with ansible-navigator
```

## Fork Workflow

Users developing workshops or custom deployments should **fork** `agnosticd-v2` to their own GitHub org rather than working directly in the upstream repository.

```bash
# Fork via GitHub UI, then clone your fork
git clone https://github.com/your-org/agnosticd-v2.git
cd agnosticd-v2

# Add upstream as a remote for syncing
git remote add upstream https://github.com/agnosticd/agnosticd-v2.git

# Keep your fork in sync
git fetch upstream
git merge upstream/main
```

- **Custom configs and workloads** live in your fork under `ansible/configs/` and `ansible/roles/`
- **Workshop-specific variables** go in `agnosticd-v2-vars/` (outside the repo, never committed)
- **Secrets** go in `agnosticd-v2-secrets/` (outside the repo, never committed)
- **Only generic improvements** (bug fixes, new core features, documentation) should be submitted as PRs to the upstream `agnosticd/agnosticd-v2` repository
- **Never push** workshop-specific configs or workloads to upstream

When configuring `ocp4_workload_field_content_gitops_repo_url`, point it to the user's own content repo -- not the upstream template.

## Creating a Config

> (RESEARCH NEEDED — RQ-2: What is the required file structure and playbook set for an AgnosticD v2 config, what does each playbook do, and what are the minimum required variables?)
>
> This section will be completed once research into AgnosticD v2 config anatomy is done.
> Pending items: required playbook list (provision.yml, destroy.yml, stop.yml, start.yml, status.yml), mandatory variables, `default_vars` file conventions, directory layout requirements.

**Current partial guidance:**

Configs live under `ansible/configs/<config-name>/` in your forked repository. At minimum, a config needs a variables defaults file and playbooks that correspond to the lifecycle operations. See the **agnosticd-refactor** skill, audit area 2, for the full checklist once research is complete.

---

## Creating a Workload Role

> (RESEARCH NEEDED — RQ-3: What files are required in a new `ocp4_workload_*` role, what is the purpose of each task file, and how does the `ocp4_workload_example` template demonstrate the correct structure?)
>
> This section will be completed once research into AgnosticD v2 workload role anatomy is done.
> Pending items: required files (tasks/workload.yml, tasks/main.yml, defaults/main.yml, meta/main.yml), variable naming prefix conventions, `ocp4_workload_example` reference implementation walkthrough.

**Current partial guidance:**

- All custom workload roles must follow the `ocp4_workload_*` naming convention
- All role variables must be prefixed with the full role name to avoid variable collisions across workloads
- Roles live under `ansible/roles/` in your forked repository
- See the upstream `ocp4_workload_example` role as the canonical starting point

---

## Key Commands

All commands take three parameters: `--guid | -g`, `--config | -c`, `--account | -a`.

```bash
# Initial setup (run once from agnosticd-v2/)
./bin/agd setup

# Provision an environment
./bin/agd provision -g myocp -c openshift-cluster -a sandbox1234

# Destroy an environment
./bin/agd destroy -g myocp -c openshift-cluster -a sandbox1234

# Stop / Start / Status
./bin/agd stop -g myocp -c openshift-cluster -a sandbox1234
./bin/agd start -g myocp -c openshift-cluster -a sandbox1234
./bin/agd status -g myocp -c openshift-cluster -a sandbox1234
```

> (RESEARCH NEEDED — RQ-5: What Ansible playbooks and variables does a config need to support `agd stop`, `agd start`, and `agd status`, and what does RHDP expect these lifecycle operations to do for an AWS-based OpenShift cluster?)
>
> Pending items: playbook names and locations for stop/start/status, AWS EC2 instance stop vs cluster stop semantics, variables that control lifecycle behavior, RHDP cost-management requirements.

**Current partial guidance:** Stop, start, and status operations are required for RHDP cost management — configs that do not implement them cannot be cost-controlled on the platform and will not be accepted for catalog submission. See the **agnosticd-refactor** skill, audit area 5, for the verification checklist.

## Platform Prerequisites

Before running any `agd` command, verify the three requirements below. If a check fails, follow the corrective action for your platform.

### 1. Python 3.12 or higher

```bash
python3 --version    # must return Python 3.12.x or higher
```

If the version is lower than 3.12, install the correct version:

**RHEL 9.5+**
```bash
sudo subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms
sudo dnf -y install git python3.12 python3.12-devel gcc oniguruma-devel
```

**RHEL 10.0+** (ships Python 3.12 as the default `python3`)
```bash
sudo subscription-manager repos --enable codeready-builder-for-rhel-10-$(arch)-rpms
sudo dnf -y install git python3 python3-devel gcc oniguruma-devel
```

**macOS**
```bash
brew install python@3.13
```

### 2. Podman

```bash
podman --version     # must succeed
```

If missing:

**RHEL 9.5+ / 10.0+**
```bash
sudo dnf -y install podman
```

**macOS**
```bash
brew install podman
podman machine init && podman machine start
```

### 3. Virtualenv (created by `agd setup`)

```bash
ls ~/Development/agnosticd-v2-virtualenv/    # must exist
```

If missing, run setup from within the `agnosticd-v2/` directory:
```bash
cd ~/Development/agnosticd-v2
./bin/agd setup
```

## Integration with Field-Sourced Content

AgnosticD provisions the OpenShift clusters that [Field-Sourced Content](https://github.com/rhpds/field-sourced-content-template) deploys onto. The field-sourced-content-template repo ships an AgnosticD workload role (`ocp4_workload_field_content`) that creates an ArgoCD Application to deploy field content on a provisioned cluster.

To deploy field content as an AgnosticD workload, add it to the `workloads:` list in your config variables file:

```yaml
workloads:
  - agnosticd.core_workloads.ocp4_workload_cert_manager
  - ocp4_workload_field_content

ocp4_workload_field_content_gitops_repo_url: "https://github.com/your-org/your-content.git"
```

The workload role uses `openshift_cluster_ingress_domain` and `openshift_api_url` from the provisioned cluster to configure the ArgoCD Application. Field content resources labeled with `demo.redhat.com/userinfo` pass URLs and credentials back to AgnosticD and the RHDP catalog.

For lab guides, add `ocp4_workload_showroom` to `infra_workloads:` to deploy Showroom alongside the cluster. See the **showroom** skill for content authoring and terminal configuration.

See the **field-sourced-content** skill for guidance on authoring the content repository itself (Helm or Ansible patterns).

## Reporting Deployment Info

Every config that deploys to RHDP must surface structured data back to the platform so students see their credentials and URLs in the catalog item. This is done via the `agnosticd_user_info` Ansible action plugin.

**Conceptual data flow:**

```
agnosticd_user_info calls (in workload roles or post-provision tasks)
  │
  ├─→ RHDP catalog  ──────────→ student display (URLs, credentials)
  │
  └─→ Showroom antora.yml     → {openshift_cluster_ingress_domain} and
      attribute injection        other dynamic values in lab content
```

> (RESEARCH NEEDED — RQ-4: How does the `agnosticd_user_info` Ansible module work, what format does it expect, how does data flow to RHDP and students, and how does it connect to Showroom Antora attributes?)
>
> This section will be completed once research into the agnosticd_user_info module is done.
> Pending items: module signature and required keys, RHDP-expected output fields, student credential patterns, connection to openshift_cluster_ingress_domain and Showroom antora.yml attributes.

**Current partial guidance:**

- Call `agnosticd_user_info` in the post-provision phase of each workload role that produces a student-facing URL or credential
- The RHDP catalog picks up this data and displays it in the "My Services" page
- Showroom uses the same data to populate `antora.yml` attributes — so lab content that references `{openshift_cluster_ingress_domain}` gets the actual cluster domain at build time
- Every RHDP config must call this module; configs that do not surface output cannot be accepted for catalog submission
- See the **agnosticd-refactor** skill, audit area 4, for the full verification checklist

---

## Best Practices

- Always run `agd` from within the `agnosticd-v2` directory
- Use execution environments for reproducible deployments — available EE images and their collection contents are pending research (RQ-6)
- Keep secrets in `agnosticd-v2-secrets/`:
  - `secrets.yml` — pull secret and satellite/RHN credentials
  - `secrets-<account>.yml` — per-cloud-account credentials matching the `-a` flag
  - Never commit either file to git
- Tag all cloud resources via `cloud_tags` with at minimum `owner`, `guid: "{{ guid }}"`, and `config` — required for RHDP automated cleanup
- Use `agnosticd_user_info` to output deployment information (see **Reporting Deployment Info** section above)
- All tasks and plays must have `name:` fields; use YAML literal notation — no `foo=bar` inline syntax
- Follow the git style guide in `references/` for branch naming and PR titles
- Test configs locally before pushing

## Troubleshooting

When `agd provision` or `agd destroy` fails, follow this decision tree:

```
Deployment fails
├─ "agd setup" not run or broken?
│   → Run ./bin/agd setup
│   → Verify Python 3.12+ and podman are installed
│   → Check that agnosticd-v2-virtualenv/ exists
│
├─ Credential / account error?
│   → Check agnosticd-v2-secrets/ for the account file
│   → Verify cloud credentials are valid (AWS STS, Azure token, etc.)
│   → Confirm the account name in -a flag matches a secrets file
│
├─ Cluster unreachable after provisioning?
│   → Run: agd status -g <GUID> -c <CONFIG> -a <ACCOUNT>
│   → Check VPN/network connectivity
│   → Verify openshift_cluster_ingress_domain resolves
│   → Check cloud console for instance/cluster state
│
├─ Workload fails (ocp4_workload_* role)?
│   → Check output in agnosticd-v2-output/<GUID>/
│   → Look for the failing role name in the Ansible output
│   ├─ ocp4_workload_field_content?
│   │   → Verify ocp4_workload_field_content_gitops_repo_url is correct
│   │   → Check ArgoCD Application sync status: oc get app -n openshift-gitops
│   ├─ ocp4_workload_showroom?
│   │   → Verify content_git_repo URL and ref
│   │   → Check showroom pod: oc get pods -n showroom-<GUID>
│   │   → Check showroom pod logs: oc logs -n showroom-<GUID> -l app=showroom
│   └─ Other workload?
│       → Check the role's defaults/main.yml for required variables
│       → Verify operator prerequisites are met (oc get csv -A)
│
├─ Environment deployed but not working for students?
│   → Use the student-readiness skill to run end-to-end checks
│
└─ Still stuck?
    → Use /health:deployment-validator from the RHDP Skills Marketplace
      to generate Ansible validation roles
    → See: https://rhpds.github.io/rhdp-skills-marketplace/
```

## Validation

After a successful deployment, verify the environment before handing it to students:

- **Student readiness**: Use the **student-readiness** skill to verify cluster access, Showroom, terminal, operators, RBAC, and workload resources
- **Module testing**: Use the **workshop-tester** skill to execute each module's exercises against the live environment and classify any failures as Instruction Fix, Infra / Deployment Fix, or Rethink
- **Content quality**: Use `/showroom:verify-content` from the [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/) to validate lab content against Red Hat standards
- **Infrastructure health**: Use `/health:deployment-validator` to create Ansible roles that verify pods, routes, and operators
