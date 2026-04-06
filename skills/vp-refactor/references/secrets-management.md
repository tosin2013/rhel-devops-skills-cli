# Secrets Management — Validated Patterns

> Source: [Secrets Management in VP](https://validatedpatterns.io/learn/secrets-management-in-the-validated-patterns-framework/)
> Research question: RQ-4

---

## The Architectural Decision: `--with-secrets`

Running `patternizer init` without any flags generates scaffolding with **no secrets infrastructure**. To enable enterprise-grade secrets management, append `--with-secrets` at initialization:

```bash
patternizer init --with-secrets
```

This flag alters the generated configuration files to:
1. Add HashiCorp Vault as the primary backend secret store
2. Inject ESO (External Secrets Operator) subscription requirements into the deployment pipeline
3. Wire the `make load-secrets` target to push local secrets into Vault

**Why Vault over alternatives:**
- Sealed Secrets risk cryptographic lock-in; disaster recovery is complex if the decryption key is lost
- AWS Secrets Manager / Azure Key Vault are cloud-provider-specific; Validated Patterns targets multicloud and hybrid environments
- Vault is cloud-agnostic, independently highly available, and not tied to the cluster itself

---

## The Secrets Flow: Vault + External Secrets Operator

```
Developer workstation
  values-secret.yaml (local, never committed)
    │
    └─ make load-secrets
         │
         └─→ HashiCorp Vault (deployed on cluster)
                │
                └─→ External Secrets Operator
                       reads ExternalSecret CRs from Git (safe — no payload in Git)
                       authenticates to Vault via service account
                       projects native Kubernetes Secrets into app namespaces
```

The Git repository safely houses only the **configuration** of secrets (ExternalSecret CRs pointing to Vault paths) — never the secret payload itself.

---

## `values-secret.yaml` — Mandatory File Location

The `make load-secrets` target searches for the populated secrets file in a strict priority order on the local filesystem:

1. `~/.config/validatedpatterns/values-secret-<pattern_name>.yaml` ← **preferred**
2. `~/.config/hybrid-cloud-patterns/values-secret-<pattern_name>.yaml`

**This file must never be committed to any Git repository — public or private.** Moving it to one of the above paths is a mandatory, non-negotiable operational requirement.

### Safe Workflow

```bash
# patternizer generates a template — do not populate in place
ls values-secret.yaml.template

# Copy to the secure location and populate there
mkdir -p ~/.config/validatedpatterns
cp values-secret.yaml.template \
   ~/.config/validatedpatterns/values-secret-<pattern_name>.yaml

# Edit the copy — never the in-repo template
$EDITOR ~/.config/validatedpatterns/values-secret-<pattern_name>.yaml

# Verify no secret file is committed
git status   # values-secret.yaml should NOT appear
```

---

## Loading Secrets into Vault

```bash
./pattern.sh make load-secrets
```

This command:
1. Searches the local filesystem for the populated `values-secret-<pattern_name>.yaml`
2. Parses the file
3. Pushes the cryptographic material directly into the Vault instance on the cluster via the Vault API
4. ESO then detects the Vault data and projects Kubernetes Secrets into application namespaces

---

## Automated Secrets Loading During Install

If `global.secretLoader.disabled` is set to `false` in `values-global.yaml`, running `./pattern.sh make install` automatically triggers `make load-secrets` as part of the install sequence — infrastructure provisioning and cryptographic seeding happen in a single workflow.

```yaml
# values-global.yaml
global:
  secretLoader:
    disabled: false   # default; set true only to skip secrets loading
```

---

## Secrets and the VP Operator

The VP Operator (deployed via OperatorHub) **cannot** run `make load-secrets` — it has no access to the developer's local filesystem. Patterns with secrets that are deployed via the Operator require a two-step process:

1. Deploy the pattern components via the Operator UI
2. Authenticate to the cluster locally and run `make load-secrets` out-of-band to complete the installation

This is a known limitation. If your pattern requires secrets, the CLI deployment path (`./pattern.sh make install`) provides a seamless single-step workflow.
