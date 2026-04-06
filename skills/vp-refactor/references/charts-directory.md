# Charts Directory Structure — Validated Patterns

> Source: [VP Framework Structure](https://validatedpatterns.io/learn/vp_openshift_framework/) | [Structuring a Validated Pattern](https://validatedpatterns.io/learn/vp_structure_vp_pattern/)
> Research question: RQ-3

---

## Minimum Helm Chart Structure Required by ArgoCD

The `path:` field in each `applications:` entry must point to a directory containing a valid Helm chart. ArgoCD does not parse unstructured YAML directories when Helm is expected. Without the following three components, ArgoCD reports a synchronization failure.

```
charts/hub/my-app/        ← this is what path: points to
├── Chart.yaml            ← REQUIRED: chart manifest
├── values.yaml           ← REQUIRED: default variable declarations
└── templates/            ← REQUIRED: Kubernetes resource definitions
    ├── deployment.yaml
    ├── service.yaml
    └── ...
```

### `Chart.yaml` — Required Fields

```yaml
apiVersion: v2
name: my-app
description: A Helm chart for my application
type: application
version: 0.1.0
appVersion: "1.0.0"
```

| Field | Purpose |
|-------|---------|
| `apiVersion` | `v2` for Helm 3 |
| `name` | Chart identifier (matches directory name by convention) |
| `description` | Brief description |
| `type` | `application` or `library` |
| `version` | Semantic version of the chart itself |
| `appVersion` | Version of the application being packaged |

Absence of `Chart.yaml` causes ArgoCD to reject the directory as an invalid source, halting synchronization.

### `values.yaml` — Default Configuration

Contains baseline variable declarations. In Validated Patterns, these defaults are frequently overridden by `values-global.yaml` and `values-<cluster>.yaml` through Helm's deep-merge mechanism, so global parameters cascade down to individual charts.

```yaml
# values.yaml
replicaCount: 1
image:
  repository: my-registry/my-app
  tag: latest
namespace: my-app-namespace
```

### `templates/` — Kubernetes Resources

Static YAML files initially placed here. ArgoCD executes `helm template` natively, combining templates with injected values before applying manifests via the Kubernetes API.

To leverage the framework fully, replace static values with Go template directives:

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.appName }}
  namespace: {{ .Values.namespace }}
spec:
  replicas: {{ .Values.replicaCount }}
```

---

## `applications:` Block to ArgoCD Application CR Mapping

Each entry in the `applications:` block generates one ArgoCD Application Custom Resource on the cluster.

| Values file field | ArgoCD Application CR field | Description |
|---|---|---|
| `name` | `metadata.name` | Must be unique in the ArgoCD deployment namespace; shown in ArgoCD UI |
| `namespace` | `spec.destination.namespace` | Target namespace on the cluster where manifests are injected |
| `project` | `spec.project` | ArgoCD AppProject — controls RBAC, destination restrictions, and permitted resource types |
| `path` | `spec.source.path` | Relative path from the repository root to the directory containing `Chart.yaml` |

### Common Failure Modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| ArgoCD reports "missing chart" | `path:` does not resolve to a directory with `Chart.yaml` | Verify the path is relative to repo root and the directory exists |
| Application stuck in "Unknown" | `namespace:` does not exist on cluster | Add the namespace to the `namespaces:` block |
| "permission denied" sync error | `project:` does not allow the resource types being deployed | Check ArgoCD AppProject definition for cluster-scope resource restrictions |

---

## Repository Layout Convention

```
<pattern-root>/
└── charts/
    ├── hub/                  ← charts for the hub cluster group
    │   ├── acm/
    │   │   ├── Chart.yaml
    │   │   ├── values.yaml
    │   │   └── templates/
    │   └── my-app/
    │       ├── Chart.yaml
    │       ├── values.yaml
    │       └── templates/
    └── all/                  ← charts shared across all cluster groups
        └── ...
```

The `path:` in `applications:` is always relative from the repository root:
```yaml
path: charts/hub/my-app   # correct — starts from repo root
path: my-app              # incorrect — ArgoCD cannot resolve this
```
