# Imperative Jobs — Validated Patterns

> Source: [ClusterGroup in Values Files](https://validatedpatterns.io/learn/clustergroup-in-values-files/)
> Research question: RQ-8

---

## What the `imperative:` Section Is

ArgoCD synchronizes declarative state — it cannot natively execute procedural actions. The `imperative:` section in `values-<cluster>.yaml` is the Validated Patterns framework's escape hatch for tasks that cannot be expressed as static Kubernetes manifests or OLM subscriptions.

When populated, ArgoCD deploys CronJobs that execute Ansible playbooks inside the cluster.

---

## Architecture: How Imperative Jobs Run

```
values-<cluster>.yaml   →   ArgoCD   →   CronJobs (imperative namespace)
                                              │
                                              └─→ Ansible Execution Environment container
                                                    registry.redhat.io/ansible-automation-platform-22/
                                                    ee-supported-rhel8:latest
                                                    (pre-packaged: Ansible engine + kubernetes.core collection)
                                                        │
                                                        └─→ Runs ansible/playbooks/<playbook>.yaml
                                                              from the pattern Git repo
```

The default container image is:
```
registry.redhat.io/ansible-automation-platform-22/ee-supported-rhel8:latest
```

This image includes the `kubernetes.core` Ansible collection, giving playbooks full access to the Kubernetes API.

---

## Playbook Location

Ansible playbooks for imperative jobs must be placed in:

```
<pattern-root>/
└── ansible/
    └── playbooks/
        ├── bootstrap-vault.yaml
        ├── distribute-ca.yaml
        └── ...
```

---

## `values-<cluster>.yaml` Configuration

### Critical: Must be a YAML List

Imperative jobs **must** be defined as a YAML list, not a hash/dictionary. YAML hashes lose ordering when parsed by Helm. Preserving execution order is required for bootstrapping sequences where one task depends on the completion of the previous one.

```yaml
# CORRECT — YAML list (ordered)
clusterGroup:
  imperative:
    jobs:
      - name: bootstrap-vault
        playbook: ansible/playbooks/bootstrap-vault.yaml
      - name: distribute-ca
        playbook: ansible/playbooks/distribute-ca.yaml
```

```yaml
# INCORRECT — hash/dict (unordered after Helm parsing)
clusterGroup:
  imperative:
    jobs:
      bootstrap-vault:
        playbook: ansible/playbooks/bootstrap-vault.yaml
```

### Scheduling

| Job type | Default schedule | Notes |
|----------|-----------------|-------|
| Standard imperative jobs | `*/10 * * * *` | Every 10 minutes |
| Vault unsealing | `*/9 * * * *` | Every 9 minutes — ensures secrets remain rapidly accessible if Vault pod restarts |

### Idempotency Mandate

Because CronJobs execute continuously (every 10 minutes by default), **all playbooks must be strictly idempotent**. A non-idempotent playbook run on a 10-minute cycle will:
- Overwrite existing configurations on each execution
- Exhaust external API rate limits
- Destabilize cluster state

Every playbook must check desired state before acting:
```yaml
# Example idempotency pattern
- name: Check if certificate already exists
  kubernetes.core.k8s_info:
    api_version: v1
    kind: Secret
    name: my-cert
    namespace: my-namespace
  register: cert_check

- name: Generate certificate only if missing
  when: cert_check.resources | length == 0
  # ... generation tasks
```

---

## Configurable Options

| Option | Default | Description |
|--------|---------|-------------|
| `timeout` | `3600` seconds | Maximum job runtime before considered hung |
| `serviceAccountName` | Framework default | Override for jobs requiring elevated cluster privileges |
| Ansible verbosity | Standard | Add `-v` or `-vv` flags for debugging |
| Schedule | `*/10 * * * *` | Override the CronJob schedule per job |

---

## Common Use Cases

These tasks are candidates for the `imperative:` section — they fall outside the purview of declarative synchronization:

| Use case | Why imperative? |
|----------|----------------|
| HashiCorp Vault unsealing | Cryptographic API interaction; cannot be expressed as a Kubernetes manifest |
| Distributing regional Certificate Authorities | One-time cluster-wide operation that must be sequenced after cert-manager is ready |
| Red Hat ACM multi-cluster configuration | RHACM APIs require procedural calls that ArgoCD cannot express declaratively |
| Bare-metal edge node network configuration | Requires direct hardware API interaction outside Kubernetes reconciliation |
| Registering AAP execution environments | AAP controller API calls that must run after the controller pod is ready |

---

## When NOT to Use `imperative:`

If the task can be expressed as:
- An operator subscription in `subscriptions:`
- A Helm chart resource in `templates/`
- A Kubernetes Job or Init Container within a chart

…use the declarative approach. The `imperative:` section should be the last resort, not the first choice. Overuse increases operational complexity and testing burden.
