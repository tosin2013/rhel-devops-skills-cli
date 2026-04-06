# Values Files Guide — Validated Patterns

> Source: [VP Framework Structure](https://validatedpatterns.io/learn/vp_openshift_framework/) | [ClusterGroup in Values Files](https://validatedpatterns.io/learn/clustergroup-in-values-files/)
> Research question: RQ-1

---

## The Two Values Files and Their Roles

After `patternizer init`, two files control all deployments:

| File | Role |
|------|------|
| `values-global.yaml` | Cross-cluster registry — image refs, Git repo paths, synchronization policies, topological routing |
| `values-<cluster>.yaml` | Cluster payload — the actual namespaces, operators, and applications to deploy |

---

## `values-global.yaml` — Mandatory Field

### `main.clusterGroupName`

This is the primary topological router. ArgoCD evaluates this field to determine which cluster-specific values file applies to the current cluster.

```yaml
main:
  clusterGroupName: hub
```

**Rule:** The string provided must have a 1:1 match with a `values-<string>.yaml` filename in the pattern root.

| `main.clusterGroupName` | Targets file |
|---|---|
| `hub` | `values-hub.yaml` |
| `edge` | `values-edge.yaml` |
| `datacenter` | `values-datacenter.yaml` |

A mismatch causes a catastrophic deployment failure — ArgoCD will not inject any cluster-specific applications or subscriptions, leaving the cluster devoid of workloads.

---

## `values-<cluster>.yaml` — Three Mandatory Blocks

All three blocks must be exhaustively populated before `./pattern.sh make install` will succeed. They form an unbreakable dependency chain.

### Dependency Chain

```
namespaces → subscriptions → applications
    ↑               ↑               ↑
Must exist     Must target     Must target
before         defined         defined
operators      namespaces      namespaces
deploy
```

### 1. `namespaces:`

Defines the Kubernetes namespace isolation boundaries. The framework provisions these before any operator or workload initializes. Deploying into a non-existent namespace halts ArgoCD synchronization entirely.

```yaml
namespaces:
  - open-cluster-management
  - vault
  - golang-external-secrets
```

### 2. `subscriptions:`

Declarative interface to OLM. Installs the operators that workloads depend on. Each entry must target a namespace defined in the `namespaces:` block above.

```yaml
subscriptions:
  - name: advanced-cluster-management
    namespace: open-cluster-management
    channel: release-2.10
    source: redhat-operators
    startingCSV: advanced-cluster-management.v2.10.0
```

Required fields per subscription:

| Field | Description |
|-------|-------------|
| `name` | OLM package name (exact string from cluster catalog) |
| `namespace` | Must match a namespace in the `namespaces:` block |
| `channel` | Update channel (e.g. `stable`, `release-2.10`) |
| `source` | Catalog source: `redhat-operators`, `certified-operators`, or `community-operators` |
| `startingCSV` | Exact CSV version — required for GitOps immutability |

### 3. `applications:`

Maps to ArgoCD Application Custom Resources. Each entry creates one Application CR on the cluster.

```yaml
applications:
  - name: acm
    namespace: open-cluster-management
    project: hub
    path: charts/hub/acm
```

Required fields per application:

| Field | ArgoCD CR field | Description |
|-------|----------------|-------------|
| `name` | `metadata.name` | Unique identifier in ArgoCD namespace |
| `namespace` | `spec.destination.namespace` | Target namespace on cluster |
| `project` | `spec.project` | ArgoCD AppProject for RBAC and multi-tenant isolation |
| `path` | `spec.source.path` | Relative path from repo root to the directory containing `Chart.yaml` |

---

## Minimal Working Example

```yaml
# values-hub.yaml (minimal — extends values-global.yaml where clusterGroupName: hub)
clusterGroup:
  namespaces:
    - my-app-namespace
  subscriptions:
    - name: my-operator
      namespace: my-app-namespace
      channel: stable
      source: redhat-operators
      startingCSV: my-operator.v1.2.3
  applications:
    - name: my-app
      namespace: my-app-namespace
      project: hub
      path: charts/hub/my-app
```
