# Static Validation — Reference Index

This directory contains reference documentation for the static-validation skill.

## Documents

| Document | Description |
|----------|-------------|
| [crd-schema-sources.md](crd-schema-sources.md) | OpenShift and operator CRD schema sources for kubeconform, with pinned versions and refresh instructions |

## Tool Versions

The static-validation skill uses the following tools. These are the tested/recommended versions — newer patch releases should also work.

| Tool | Recommended Version | Purpose | Install (RHEL) | Install (macOS) |
|------|-------------------|---------|----------------|-----------------|
| [helm](https://helm.sh/) | 3.14+ | Chart rendering and linting | `sudo dnf install helm` | `brew install helm` |
| [kustomize](https://kustomize.io/) | 5.3+ | Overlay rendering | [GitHub releases](https://github.com/kubernetes-sigs/kustomize/releases) | `brew install kustomize` |
| [kubeconform](https://github.com/yannh/kubeconform) | 0.6+ | Kubernetes manifest schema validation | [GitHub releases](https://github.com/yannh/kubeconform/releases) | `brew install kubeconform` |
| [conftest](https://www.conftest.dev/) | 0.50+ | OPA Rego policy testing | [GitHub releases](https://github.com/open-policy-agent/conftest/releases) | `brew install conftest` |
| [gitleaks](https://github.com/gitleaks/gitleaks) | 8.18+ | Git secret scanning | [GitHub releases](https://github.com/gitleaks/gitleaks/releases) | `brew install gitleaks` |
| [yamllint](https://github.com/adrienverge/yamllint) | 1.35+ | YAML linting | `sudo dnf install yamllint` or `pip install yamllint` | `brew install yamllint` |
| [ansible-lint](https://ansible.readthedocs.io/projects/lint/) | 24.2+ | Ansible playbook and role linting | `pip install ansible-lint` (in venv) | `brew install ansible-lint` |
| [ansible-playbook](https://docs.ansible.com/) | 2.15+ (ansible-core) | Ansible syntax checking | `sudo dnf install ansible-core` | `brew install ansible` |

## Schema Sources

See [crd-schema-sources.md](crd-schema-sources.md) for the full schema source documentation.

### Quick Reference

- **Kubernetes core:** Built-in to kubeconform, or from [yannh/kubernetes-json-schema](https://github.com/yannh/kubernetes-json-schema)
- **OpenShift + operator CRDs:** [datreeio/CRDs-catalog](https://github.com/datreeio/CRDs-catalog)

## Sample Conftest Policies

A minimal baseline policy set for infrastructure repos. Place these in `policy/` at the repo root.

### `policy/base.rego`

```rego
package main

deny[msg] {
  input.kind == "Pod"
  input.spec.containers[_].securityContext.privileged == true
  msg := sprintf("Privileged container not allowed: %s", [input.metadata.name])
}

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits
  msg := sprintf("Resource limits required for container %s in %s", [container.name, input.metadata.name])
}

warn[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  endswith(container.image, ":latest")
  msg := sprintf("Image tag :latest is not recommended: %s in %s", [container.image, input.metadata.name])
}

warn[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not contains(container.image, ":")
  msg := sprintf("Image has no tag (defaults to :latest): %s in %s", [container.image, input.metadata.name])
}

deny[msg] {
  input.kind == "Pod"
  input.spec.hostNetwork == true
  msg := sprintf("Host network not allowed: %s", [input.metadata.name])
}

deny[msg] {
  input.kind == "Pod"
  input.spec.hostPID == true
  msg := sprintf("Host PID not allowed: %s", [input.metadata.name])
}
```

These policies can be extended per project. See the [conftest documentation](https://www.conftest.dev/) for advanced policy patterns.
