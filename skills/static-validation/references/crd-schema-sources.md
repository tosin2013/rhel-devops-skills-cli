# CRD Schema Sources for kubeconform

## Problem

kubeconform's default schemas cover upstream Kubernetes resources only. OpenShift-specific resources (Route, DeploymentConfig, BuildConfig, ImageStream, etc.) and operator CRDs (ArgoCD Application, ExternalSecret, VaultSecret, etc.) are marked as `unknown` and skip validation entirely.

For infrastructure repos targeting OpenShift — especially Validated Patterns and AgnosticD workloads — this means a large portion of the manifests go unvalidated.

## Recommended Sources

### 1. Kubernetes Core Schemas

**Source:** Built-in to kubeconform (default)

**Fallback:** [yannh/kubernetes-json-schema](https://github.com/yannh/kubernetes-json-schema)

These schemas cover all upstream Kubernetes resources (Deployments, Services, ConfigMaps, etc.) across all Kubernetes versions.

kubeconform includes these by default when using `--schema-location default`.

### 2. OpenShift and Operator CRD Schemas

**Source:** [datreeio/CRDs-catalog](https://github.com/datreeio/CRDs-catalog)

This community-maintained catalog provides JSON schemas for 600+ CRDs, including:

| Category | Example CRDs |
|----------|-------------|
| OpenShift | Route, DeploymentConfig, BuildConfig, ImageStream, Project |
| ArgoCD | Application, ApplicationSet, AppProject |
| Cert-Manager | Certificate, Issuer, ClusterIssuer |
| External Secrets | ExternalSecret, SecretStore, ClusterSecretStore |
| OLM | Subscription, CatalogSource, ClusterServiceVersion |
| ACM | ManagedCluster, Policy, PlacementRule |
| Vault | VaultSecret, VaultAuth |

**Why this source over alternatives:**
- Actively maintained with automated weekly updates
- Covers the specific CRDs used by Validated Patterns (ArgoCD, ESO, Vault, ACM)
- Covers the specific CRDs used by AgnosticD workloads (OpenShift core, OLM)
- Compatible with kubeconform's `--schema-location` URL template pattern
- Can be used both online (GitHub raw URLs) and offline (local clone)

## Usage

### Online (GitHub raw URLs)

Pass the CRDs-catalog URL template as a second `--schema-location`:

```bash
kubeconform \
  -strict \
  -summary \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  <manifest.yaml>
```

kubeconform tries each schema location in order. If the resource is not found in the default Kubernetes schemas, it falls back to the CRDs-catalog.

### Offline (local clone)

For fully offline validation, clone the catalog locally:

```bash
git clone --depth 1 https://github.com/datreeio/CRDs-catalog.git \
  ~/.local/share/crd-schemas
```

Then reference the local path:

```bash
kubeconform \
  -strict \
  -summary \
  -schema-location default \
  -schema-location '~/.local/share/crd-schemas/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  <manifest.yaml>
```

**Tilde expansion:** kubeconform does not expand `~`. Use the full path (`/home/<user>/.local/share/crd-schemas/...`) or set an environment variable:

```bash
export CRD_SCHEMA_DIR="$HOME/.local/share/crd-schemas"
kubeconform \
  -schema-location default \
  -schema-location "${CRD_SCHEMA_DIR}/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json" \
  <manifest.yaml>
```

## Refresh Procedure

The CRDs-catalog is updated weekly. To refresh your local clone:

```bash
cd ~/.local/share/crd-schemas
git pull origin main
```

To pin to a specific date (for reproducible CI):

```bash
git clone --depth 1 --branch main https://github.com/datreeio/CRDs-catalog.git \
  ~/.local/share/crd-schemas

cd ~/.local/share/crd-schemas
git log -1 --format='%H %ci'
```

Record the commit hash in your CI configuration or evidence artifacts for traceability.

## Version Pinning Strategy

For reproducible validation in CI pipelines:

1. Clone the CRDs-catalog at a known commit
2. Record the commit hash in evidence artifacts
3. Refresh on a regular cadence (monthly or per-release)
4. If a CRD schema is missing from the catalog, file an issue at [datreeio/CRDs-catalog](https://github.com/datreeio/CRDs-catalog/issues)

Example CI pinning:

```bash
CRD_CATALOG_COMMIT="abc1234"
git clone https://github.com/datreeio/CRDs-catalog.git ~/.local/share/crd-schemas
cd ~/.local/share/crd-schemas
git checkout "$CRD_CATALOG_COMMIT"
```

## Adding Custom CRD Schemas

If your project uses CRDs not covered by the datreeio catalog, generate schemas from the running cluster:

```bash
# Extract CRD schema from a live cluster (one-time operation)
oc get crd <crd-name> -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema}' \
  | python3 -m json.tool > custom-schemas/<group>/<kind>_<version>.json
```

Place custom schemas in a project-local directory and add it as a third `--schema-location`:

```bash
kubeconform \
  -schema-location default \
  -schema-location '~/.local/share/crd-schemas/...' \
  -schema-location './custom-schemas/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  <manifest.yaml>
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Resource shows as `unknown` | Schema not in catalog | Check if the CRD group/kind/version match the catalog structure; add custom schema if missing |
| `HTTP 404` on schema URL | CRD not in datreeio catalog | Clone catalog locally; check if the resource API group path exists |
| Schema validation passes but resource fails on cluster | Schema version mismatch | Verify `--kubernetes-version` matches your target cluster version |
| Timeout downloading schemas | Network or rate limiting | Clone catalog locally for offline use |
