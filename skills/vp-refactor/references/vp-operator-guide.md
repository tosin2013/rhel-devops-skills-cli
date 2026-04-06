# VP Operator Deployment Guide — Validated Patterns

> Source: [Using the VP Operator](https://validatedpatterns.io/learn/using-validated-pattern-operator/)
> Research question: RQ-5

---

## Two Deployment Pathways

| Aspect | CLI (`./pattern.sh make install`) | VP Operator (OperatorHub) |
|--------|----------------------------------|--------------------------|
| Execution environment | Utility container with all dependencies (Helm, Ansible, oc, kubectl) | Runs entirely within the cluster |
| Setup requirement | Local clone of the pattern repo | No local files required |
| Output | Verbose stdout — ideal for debugging and iterative development | UI-driven — minimal feedback |
| Secrets loading | Automatic (`make load-secrets` integrated into install sequence) | **Not possible** — cannot access local filesystem |
| Primary use case | Active development, debugging, initial deployment | Demonstrating mature patterns; production UI-driven deployments |
| Secrets patterns | Seamless single-step workflow | Two-step: deploy via UI, load secrets out-of-band separately |

---

## VP Operator Installation

The VP Operator is distributed as a **Community Operator** via OperatorHub. Install it from the OpenShift web console:

1. Navigate to **OperatorHub** in the OpenShift web console
2. Search for "Validated Patterns Operator"
3. Select the Community Operator result
4. Click **Install** and accept the defaults for namespace and update channel

---

## Creating a Pattern via the VP Operator

After the Operator installs, create a Pattern instance. Three fields are required:

| Operator Form Field | Architectural Function | Required Value |
|---|---|---|
| **Cluster Group Name** | Injects `main.clusterGroupName` — determines which `values-<cluster>.yaml` ArgoCD targets | Must match the filename of your cluster values file (e.g. `hub` for `values-hub.yaml`) |
| **Target Repo URL** | Tells the Operator where to pull GitOps configurations | Must be your **forked repository URL** (e.g. `https://github.com/<username>/<pattern-name>`) — not the upstream VP template URL |
| **Target Revision** | The specific Git branch, tag, or commit hash to deploy | Defaults to `HEAD` (tracks `main`); use a feature branch name (e.g. `my-branch`) during testing |

### Critical Limitation: Target Repo URL

The most common deployment error with the VP Operator is leaving `Target Repo URL` pointing to the upstream Validated Patterns template repository rather than the developer's own fork. This causes the Operator to deploy the reference pattern instead of the customized one.

Always change this field to your own fork:
```
# Wrong — deploys the upstream reference pattern
https://github.com/validatedpatterns/multicloud-gitops

# Correct — deploys your customized fork
https://github.com/<your-org>/<your-pattern-name>
```

---

## When to Use Each Deployment Path

**Use CLI (`./pattern.sh make install`) when:**
- Actively developing or debugging the pattern
- The pattern requires secrets (values-secret.yaml must be loaded from local filesystem)
- You need verbose output to trace deployment failures
- First-time installation on a new cluster

**Use VP Operator when:**
- Demonstrating a mature, stable pattern that requires no debugging
- Operating in environments where local scripts are restricted by policy
- Deploying patterns that have no secrets requirements (or where secrets have already been loaded via CLI)
- Testing different branches by switching `Target Revision` without cloning locally

---

## Checking Operator Status

```bash
# Verify the Pattern resource was created
oc get pattern -A

# Check the Pattern status
oc describe pattern <pattern-name> -n <namespace>

# Check ArgoCD Applications created by the Operator
oc get application -n openshift-gitops
```
