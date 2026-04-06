---
name: patternizer
description: AI assistance for Patternizer — a CLI tool that bootstraps Git repositories containing Helm charts into ready-to-use Validated Patterns for OpenShift. Use when initializing, upgrading, or working with Validated Patterns.
related_skills: [vp-refactor]
---

# Patternizer Skill

## When to Use

- Initializing a new Validated Pattern from a Git repository with Helm charts
- Upgrading an existing Validated Pattern to the latest common structure
- Understanding the generated scaffolding files (values-global.yaml, pattern.sh, Makefile)
- Configuring secrets management for Validated Patterns
- Working with the `pattern.sh` utility script
- Troubleshooting pattern initialization or upgrade issues

## Instructions

- Reference the documentation in `references/` for detailed guidance
- See `references/REFERENCE.md` for an index of available documentation files
- Patternizer runs as a container via Podman or Docker — no local Go installation required

## Quick Start

```bash
# Navigate to your repository with Helm charts
cd my-pattern-repo

# Initialize as a Validated Pattern
podman run --pull=newer -v "$PWD:$PWD:z" -w "$PWD" \
  quay.io/validatedpatterns/patternizer init

# Initialize with secrets management
podman run --pull=newer -v "$PWD:$PWD:z" -w "$PWD" \
  quay.io/validatedpatterns/patternizer init --with-secrets
```

## Key Commands

```bash
# Initialize a new pattern (no secrets)
patternizer init

# Initialize with secrets support (adds Vault + External Secrets Operator)
patternizer init --with-secrets

# Upgrade existing pattern to latest common structure
patternizer upgrade

# Upgrade and replace Makefile
patternizer upgrade --replace-makefile
```

All commands are typically run via the container image:
```bash
podman run --pull=newer -v "$PWD:$PWD:z" -w "$PWD" \
  quay.io/validatedpatterns/patternizer <command>
```

## Generated Files

Running `patternizer init` creates:

| File | Purpose |
|------|---------|
| `values-global.yaml` | Global pattern configuration |
| `values-<cluster_group>.yaml` | Cluster group-specific values |
| `pattern.sh` | Utility script for install, upgrade operations |
| `Makefile` | Simple Makefile including Makefile-common |
| `Makefile-common` | Core Makefile with pattern-related targets |
| `ansible.cfg` | Ansible configuration for pattern.sh |

With `--with-secrets`, additionally:
- `values-secret.yaml.template` — template for defining secrets
- Updates `values-global.yaml` to enable secret loading

## Workflow

```bash
# 1. Clone or create your pattern repo
git clone https://github.com/your-org/your-pattern.git
cd your-pattern && git checkout -b initialize-pattern

# 2. Initialize with Patternizer
podman run --pull=newer -v "$PWD:$PWD:z" -w "$PWD" \
  quay.io/validatedpatterns/patternizer init

# 3. Review and commit
git add . && git commit -m 'initialize pattern using patternizer'
git push -u origin initialize-pattern

# 4. Install the pattern on OpenShift
export KUBECONFIG=/path/to/cluster/kubeconfig
./pattern.sh make install
```

## Best Practices

- Commit your work to git before running `init --with-secrets` (not easily reversible)
- Use the container image rather than building from source
- The `upgrade` command removes the `common/` directory if it exists
- After upgrade, verify `Makefile` contains `include Makefile-common`
- See [Validated Patterns documentation](https://validatedpatterns.io/) for pattern design guidance
