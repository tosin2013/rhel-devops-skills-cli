---
name: agnosticd
description: AI assistance for AgnosticD v2 — the Ansible Agnostic Deployer for provisioning infrastructure and deploying workloads on AWS, Azure, OpenStack, and OpenShift. Use when working with the agd CLI, catalog items, configs, or deployment workflows.
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

## Best Practices

- Always run `agd` from within the `agnosticd-v2` directory
- Use execution environments for reproducible deployments
- Keep secrets in `agnosticd-v2-secrets/`, never commit them to git
- Tag all resources with `guid` and `env_type` for cleanup
- Use `agnosticd_user_info` to output deployment information
- Follow the git style guide in `references/` for branch naming and PR titles
- Test configs locally before pushing
