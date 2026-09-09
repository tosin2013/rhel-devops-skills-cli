---
name: showroom
description: AI assistance for Showroom — the RHDP lab guide and terminal system. Use when creating Antora-based lab content, configuring Showroom deployment on OpenShift (terminal types, VNC, multi-user), or integrating Showroom with AgnosticD or Field-Sourced Content.
license: Apache-2.0
compatibility: Requires bash 4.4+, git, oc/kubectl, and Node.js for Antora. Designed for RHEL 8/9 with Cursor and Claude Code.
metadata:
  related-skills: "agnosticd, field-sourced-content, student-readiness, workshop-tester, agnosticd-hub-student"
---

# Showroom Skill

## When to Use

- Creating or editing Showroom lab content repositories (Antora/AsciiDoc)
- Configuring Showroom deployment options (terminal types, VNC, content-only)
- Deploying Showroom as an AgnosticD `infra_workload`
- Adding Showroom as a component in a Field-Sourced Content Helm chart
- Selecting terminal images (OCP, ROSA, ARO, base)
- Setting up multi-user Showroom deployments
- Previewing Showroom content locally with Podman
- Configuring bastion auto-SSH via Wetty terminal
- Deploying Showroom via Helm to OpenShift

## Instructions

- Read `references/REFERENCE.md` when looking up terminal image options or deployment variable names
- Read `references/antora-environment-variables.md` when configuring Antora playbooks or troubleshooting site generation
- Showroom content is built with Antora from AsciiDoc source files

## Gotchas

- **Showroom does NOT auto-refresh after content pushes.** Showroom pulls content from git at pod startup. Pushing changes to the content repo does NOT update a running instance. After every content push, you MUST restart the deployment:
  ```bash
  oc rollout restart deployment/showroom -n showroom-<GUID>
  oc rollout status deployment/showroom -n showroom-<GUID> --timeout=120s
  ```
  For multi-user deployments, restart each student's namespace.
- The `URL` environment variable silently overrides `site.url` in the Antora playbook — if the site URL looks wrong, check `echo $URL` first.
- Setting `CI=true` changes Antora's log format from pretty to JSON and suppresses edit-page links in the UI. Unset it for local preview.
- Do not hardcode cluster hostnames or GUIDs in AsciiDoc content — use Antora attributes from `antora.yml` (populated by `agnosticd_user_info` at provisioning time).
- AsciiDoc `[source,bash,role=execute]` blocks are executable in Showroom terminals; `[source,bash]` without `role=execute` is display-only. Missing the role means students must copy-paste manually.
- Start from `showroom_template_default` — do not build Antora structure from scratch.

## Content Authoring

Showroom lab guides use Antora with AsciiDoc. Start from the [showroom_template_default](https://github.com/rhpds/showroom_template_default) template:

```bash
git clone https://github.com/rhpds/showroom_template_default.git my-lab
cd my-lab
```

### Content Structure

```
content/modules/ROOT/
├── assets/images/         # Images for your content
├── examples/              # Downloadable assets (scripts, configs)
├── nav.adoc               # Navigation sidebar
├── pages/
│   ├── index.adoc         # First page (overview)
│   ├── module-01.adoc     # Lab modules
│   └── module-02.adoc
└── partials/              # Reusable AsciiDoc fragments
```

### Local Preview

```bash
podman run --rm --name antora -v $PWD:/antora:z -p 8080:8080 -i -t \
  ghcr.io/juliaaano/antora-viewer
# Open http://localhost:8080
```

### Antora CLI Validation

Optionally install the Antora CLI for native local validation without containers:

```bash
npm i -g @antora/cli @antora/site-generator
antora antora-playbook.yml
```

This validates the full site build (broken xrefs, missing includes, attribute errors) and produces the same output as the container approach. Use the CLI when you need faster iteration or CI integration.

Key environment variables that affect site generation:

| Variable | Effect |
|----------|--------|
| `URL` | Overrides `site.url` in playbook |
| `CI=true` | JSON log format, suppresses edit links |
| `GIT_CREDENTIALS` | Auth for private content repos |
| `ANTORA_CACHE_DIR` | Custom cache location |
| `ANTORA_LOG_LEVEL` | `warn` (default), `error`, `info`, `debug` |

### Adding Links to the UI

```yaml
# content/antora.yml
asciidoc:
  attributes:
    page-links:
    - url: https://redhat.com
      text: Red Hat
```

## Deployment Options

Showroom can be deployed in three ways:

### 1. AgnosticD infra_workload (recommended for RHDP)

Add `ocp4_workload_showroom` to your AgnosticD config:

```yaml
infra_workloads:
  - ocp4_workload_showroom  # deploy last

ocp4_workload_showroom_content_git_repo: "https://github.com/your-org/your-lab.git"
ocp4_workload_showroom_content_git_repo_ref: main
```

**Multi-user deployments:** For workshops where each student gets their own Showroom instance, AgnosticD provisions a separate Showroom namespace per student. The number of student instances is controlled by AgnosticD multi-user variables in the config's vars file.

**RHDP pre-provisioned clusters:** When deploying Showroom on a cluster ordered from the RHDP catalog with "Create users on cluster" enabled:
- Users follow the `userN` format (no dash separator): `user1`, `user2`, `user3`, etc.
- Per-user Showroom instances must use this naming convention for namespace derivation and RBAC
- Each user has a unique password stored in the `KeycloakRealmImport` CR in the `keycloak` namespace — resolve passwords from this CR rather than generating or assuming shared passwords
- The `keycloak` namespace is already occupied by RHDP's Red Hat Build of Keycloak (RHBK) — if the workshop deploys components that need their own Keycloak instance (e.g., RHTAS), deploy to a different namespace to avoid conflicts
- Do NOT create additional identity providers (htpasswd, etc.); RHDP has already configured OpenID via RHBK

> (RESEARCH NEEDED — RQ-7: What AgnosticD variables control per-student Showroom provisioning, and how does the multi-user loop work for `ocp4_workload_showroom`?)
>
> Pending items: the variable name that sets the number of students (e.g. `ocp4_idm_htpasswd_user_count` or similar), how the per-student namespace naming is derived, and any Showroom-specific multi-user configuration options.

See the **agnosticd-refactor** skill, audit area 7, for the full multi-user configuration checklist.

### 2. Field-Sourced Content component

The Helm example includes a `components/showroom/` directory that deploys Showroom alongside your demo via ArgoCD. Enable it in `values.yaml`:

```yaml
components:
  showroom:
    enabled: true
    content:
      repoUrl: https://github.com/your-org/your-lab.git
```

### 3. Standalone via Helm

```bash
helm template showroom showroom-single-pod \
  --set deployer.domain=apps.cluster.example.com \
  --set general.guid=my-test \
  --set documentation.repoUrl=https://github.com/your-org/your-lab.git \
  | oc apply -f -
```

## Terminal Types

| Type | Use Case | Variable |
|------|----------|----------|
| `showroom` | Pod-based terminal on OpenShift (default) | `ocp4_workload_showroom_terminal_type: showroom` |
| `wetty` | SSH to bastion via browser | `ocp4_workload_showroom_terminal_type: wetty` |
| (empty) | Content only, no terminal | `ocp4_workload_showroom_content_only: true` |

### Terminal Images

| Image | Tools |
|-------|-------|
| `quay.io/rhpds/openshift-showroom-terminal-baseimage:latest` | Bare Linux |
| `quay.io/rhpds/openshift-showroom-terminal-ocp:latest` | oc, tkn, kn (default) |
| `quay.io/rhpds/openshift-showroom-terminal-rosa:latest` | OCP tools + rosa, aws |
| `quay.io/rhpds/openshift-showroom-terminal-aro:latest` | OCP tools + az |

## Key Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ocp4_workload_showroom_content_git_repo` | template default | Git repo with Antora content |
| `ocp4_workload_showroom_content_git_repo_ref` | `main` | Branch/tag to use |
| `ocp4_workload_showroom_terminal_type` | `showroom` | Terminal: `showroom`, `wetty`, or empty |
| `ocp4_workload_showroom_terminal_image` | OCP image | Container image for terminal pod |
| `ocp4_workload_showroom_content_only` | `false` | Show only lab instructions, no terminal |
| `ocp4_workload_showroom_namespace` | `showroom-{guid}` | Target namespace |
| `ocp4_workload_showroom_wetty_ssh_bastion_login` | `false` | Auto-SSH to bastion (Wetty only) |
| `ocp4_workload_showroom_novnc_enable` | `false` | Enable VNC client tab |
| `ocp4_workload_showroom_deployer_chart_version` | `1.3.4` | Helm chart version |

## AgnosticD Data Integration

When Showroom is deployed as an `ocp4_workload_showroom` infra_workload, AgnosticD automatically populates `antora.yml` attributes with live cluster data. This means AsciiDoc content like `{openshift_cluster_ingress_domain}` renders the real cluster domain — not a placeholder — when the lab guide loads.

**How the data flows:**

```
AgnosticD provisioning
  │
  └─ agnosticd_user_info calls (in workload roles)
       │
       └─→ Antora attribute injection into antora.yml
               │
               └─→ {openshift_cluster_ingress_domain}
                   {student credentials}
                   {workload-specific URLs}
                   rendered in AsciiDoc content at build time
```

This connection is why lab content should reference `{openshift_cluster_ingress_domain}` as an attribute rather than hardcoding a URL — the attribute value will be accurate for every student's environment, regardless of GUID.

> (RESEARCH NEEDED — RQ-4: What exact Antora attribute names does AgnosticD inject, how are they written into antora.yml, and what is the full list of attributes that workload roles can populate?)
>
> Pending items: canonical list of injected attribute names, the mechanism by which agnosticd_user_info output becomes antora.yml attributes, which attributes are populated by the core provisioning vs individual workload roles.

**Current partial guidance:**

- Use `{openshift_cluster_ingress_domain}` in content for cluster URLs that must resolve per-student
- Do not hardcode cluster hostnames or GUIDs — they will be wrong for other students' environments
- If an attribute renders as `{attribute-name}` literally in the deployed guide, the source is missing: either the workload role did not call `agnosticd_user_info` with the expected key, or the attribute name in the AsciiDoc does not match what `agnosticd_user_info` wrote
- See the **agnosticd** skill, "Reporting Deployment Info" section, for the full data flow

---

## Best Practices

- Keep modules focused — one concept per page
- Use `partials/` for reusable content shared across modules
- Test locally with the Antora viewer container before pushing
- Pin the Helm chart version in AgnosticD configs for reproducibility

## Live Cluster Validation

After generating Showroom content, prove it works on a real cluster and feed real evidence back into the content.

### Validation loop

1. **Deploy** — Hand off to AgnosticD (`agd provision`) or Helm to deploy Showroom on the cluster
2. **Restart after content changes** — After every `git push` to the content repo:
   ```bash
   oc rollout restart deployment/showroom -n showroom-<GUID>
   oc rollout status deployment/showroom -n showroom-<GUID> --timeout=120s
   ```
3. **Validate environment** — Activate the **student-readiness** skill to confirm the cluster is ready for students
4. **Test exercises** — Activate the **workshop-tester** skill to execute each module's exercises against the live environment
5. **Capture evidence** — Collect real outputs to replace generic placeholders. Evidence types depend on the demo/workshop context:
   - **Command outputs** — Run commands (`oc get pods`, `oc get routes`, `curl`) and capture into `[source,bash]` / `[source,text]` blocks
   - **Screenshots** — Ask the user: "This step shows the OpenShift console. Can you paste a screenshot of what you see at [URL]? I'll reference it in the lab content." Use `image::` macro to embed
   - **API/route responses** — Capture HTTP status codes and JSON payloads as `[source,json]` blocks
   - **Pod/container logs** — Capture log snippets as `[source,text]` blocks
   - **Context-dependent** — AAP job output for Ansible demos, ArgoCD sync status for GitOps patterns, Vault status for VP demos, etc.
6. **Update content** — Replace placeholder outputs in AsciiDoc modules with captured evidence. Mark any step still using generic placeholders
7. **Re-validate** — Run **workshop-tester** again to confirm the enriched content matches what students will see

### Evidence comparison

When encountering a step that shows example output:
1. Run the actual command on the live cluster
2. Compare real output to what the content shows
3. If they differ, update the content (or flag for user review if the difference is significant)
4. If visual proof is needed, ask the user for a screenshot

## Troubleshooting

When Showroom is not accessible or behaving unexpectedly, follow this decision tree:

```
Showroom not accessible
├─ Pod not running?
│   → oc get pods -n showroom-<GUID>
│   → Check events: oc describe pod -n showroom-<GUID> <pod-name>
│   → Image pull error? Verify terminal image URL in variables
│   → CrashLoopBackOff? Check logs: oc logs -n showroom-<GUID> <pod-name>
│
├─ Route not created?
│   → oc get routes -n showroom-<GUID>
│   → Verify namespace exists: oc get ns showroom-<GUID>
│   → Check Helm release: helm list -n showroom-<GUID>
│
├─ Content blank or shows error?
│   → Verify ocp4_workload_showroom_content_git_repo URL is correct
│   → Verify ocp4_workload_showroom_content_git_repo_ref branch/tag exists
│   → Check Antora build logs in the showroom pod:
│     oc logs -n showroom-<GUID> -c showroom-content
│   → Test the content repo locally with the Antora viewer container
│
├─ Terminal not connecting?
│   ├─ Type = showroom (pod-based)?
│   │   → Check terminal pod: oc get pods -n showroom-<GUID> -l app=showroom-terminal
│   │   → Verify terminal image is correct for the lab (OCP, ROSA, ARO, base)
│   │   → Check terminal pod logs: oc logs -n showroom-<GUID> -l app=showroom-terminal
│   └─ Type = wetty (SSH)?
│       → Verify bastion is reachable: ssh <user>@<bastion_host>
│       → Check wetty_ssh_bastion_login variable
│       → Check Wetty route: oc get route -n showroom-<GUID> -l app=wetty
│
├─ VNC not working?
│   → Verify ocp4_workload_showroom_novnc_enable is true
│   → Check noVNC pod status
│
├─ Environment deployed but not ready for students?
│   → Use the student-readiness skill to run end-to-end checks
│
└─ Still stuck?
    → Run /showroom:verify-content to validate content quality
    → Run /health:deployment-validator for infrastructure checks
    → See: https://rhpds.github.io/rhdp-skills-marketplace/
```

## Validation

Before handing a Showroom environment to students:
- **Environment readiness**: Activate the **student-readiness** skill for cluster-level verification
- **Content verification**: Run the **Live Cluster Validation** loop above to prove exercises work and capture real evidence
- **Module testing**: Use the **workshop-tester** skill to execute each module's exercises against the live environment and classify any failures as Instruction Fix, Infra / Deployment Fix, or Rethink
