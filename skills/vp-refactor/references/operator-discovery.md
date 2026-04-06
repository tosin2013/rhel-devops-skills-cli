# Operator Discovery Workflow — Validated Patterns

> Source: [ClusterGroup in Values Files](https://validatedpatterns.io/learn/clustergroup-in-values-files/)
> Research question: RQ-2

---

## Catalog Sources

Three catalog sources exist in OpenShift. The `source` field in each subscription must match one of these identifiers exactly.

| Catalog Source Identifier | Provenance | Support Model | Testing Rigor |
|---|---|---|---|
| `redhat-operators` | First-party Red Hat software | Fully supported under OpenShift entitlements or product subscriptions | Rigorous CI, security-audited, performance-tested |
| `certified-operators` | Third-party ISV software | Supported by the ISV vendor directly, not Red Hat | Must pass OCP compatibility tests before catalog inclusion |
| `community-operators` | Open-source community projects | Best-effort community support only, no SLA | No formal security auditing or performance testing |

**Rule:** Do not use OperatorHub.io or external documentation to determine channel/CSV values. The cluster's internal catalog may lag behind upstream or mirror different builds. Always query the cluster directly.

---

## Discovery Workflow

The definitive source of truth is the cluster's `openshift-marketplace` namespace.

### Step 1 — Find the exact package name

```bash
oc get packagemanifests -n openshift-marketplace | grep <keyword>
```

Example:
```bash
oc get packagemanifests -n openshift-marketplace | grep cert-manager
# cert-manager-operator   redhat-operators   15m
```

### Step 2 — Confirm catalog source

The second column in the output above is the catalog source. Verify it matches the expected source tier.

### Step 3 — Get the default channel

```bash
oc get packagemanifest <package-name> -n openshift-marketplace \
  -o jsonpath='{.status.defaultChannel}'
```

Example:
```bash
oc get packagemanifest cert-manager-operator -n openshift-marketplace \
  -o jsonpath='{.status.defaultChannel}'
# stable-v1
```

### Step 4 — Get the `startingCSV` for the channel

```bash
oc get packagemanifest <package-name> -n openshift-marketplace \
  -o jsonpath='{.status.channels[?(@.name=="<channel-name>")].currentCSV}'
```

Example:
```bash
oc get packagemanifest cert-manager-operator -n openshift-marketplace \
  -o jsonpath='{.status.channels[?(@.name=="stable-v1")].currentCSV}'
# cert-manager-operator.v1.13.1
```

### Resulting subscription entry

```yaml
subscriptions:
  - name: cert-manager-operator
    namespace: cert-manager-operator
    channel: stable-v1
    source: redhat-operators
    startingCSV: cert-manager-operator.v1.13.1
```

---

## Why `startingCSV` is Mandatory for GitOps

Omitting `startingCSV` allows OLM to select any available version. This violates GitOps immutability: the same Git commit may produce different cluster states at different points in time as new CSVs are published. It can also cause OLM's InstallPlan to fail to generate, leaving the workload perpetually in a `Pending` state.

Always pin `startingCSV` to the exact version string returned by the cluster query.

---

## Listing All Available Channels (when default is not desired)

```bash
oc get packagemanifest <package-name> -n openshift-marketplace \
  -o jsonpath='{.status.channels[*].name}'
```

Example output:
```
stable-v1 stable-v1.12 stable-v1.13
```
