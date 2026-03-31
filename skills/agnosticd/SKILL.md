---
name: agnosticd
description: AI assistance for AgnosticD v2 — the Ansible Agnostic Deployer for provisioning infrastructure and deploying workloads on AWS, Azure, OpenStack, and OpenShift. Use when working with the agd CLI, catalog items, configs, or deployment workflows.
related_skills: [field-sourced-content, showroom]
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

## Platform Prerequisites

### RHEL 9.5+
```bash
sudo subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms
sudo dnf -y install git python3.12 python3.12-devel gcc oniguruma-devel podman
```

### RHEL 10.0+
```bash
sudo subscription-manager repos --enable codeready-builder-for-rhel-10-$(arch)-rpms
sudo dnf -y install git python3 python3-devel gcc oniguruma-devel podman
```

### macOS
```bash
brew install python@3.13 podman
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

## Best Practices

- Always run `agd` from within the `agnosticd-v2` directory
- Use execution environments for reproducible deployments
- Keep secrets in `agnosticd-v2-secrets/`, never commit them to git
- Tag all resources with `guid` and `env_type` for cleanup
- Use `agnosticd_user_info` to output deployment information
- Follow the git style guide in `references/` for branch naming and PR titles
- Test configs locally before pushing
