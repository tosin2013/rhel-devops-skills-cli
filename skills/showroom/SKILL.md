---
name: showroom
description: AI assistance for Showroom — the RHDP lab guide and terminal system. Use when creating Antora-based lab content, configuring Showroom deployment on OpenShift (terminal types, VNC, multi-user), or integrating Showroom with AgnosticD or Field-Sourced Content.
related_skills: [agnosticd, field-sourced-content]
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

- Reference the documentation in `references/` for detailed guidance
- See `references/REFERENCE.md` for an index of available documentation files
- Showroom content is built with Antora from AsciiDoc source files

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

## Best Practices

- Start from `showroom_template_default` -- do not build Antora structure from scratch
- Use AsciiDoc attributes from `antora.yml` for dynamic content (hostnames, passwords)
- Keep modules focused -- one concept per page
- Use `partials/` for reusable content shared across modules
- Test locally with the Antora viewer container before pushing
- Pin the Helm chart version in AgnosticD configs for reproducibility

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

- **Content quality**: Use `/showroom:verify-content` from the [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/) to validate AsciiDoc against Red Hat standards
- **Student readiness**: Use the **student-readiness** skill to verify the full student experience (access, lab guide, terminal, operators, RBAC)
- **Lab grading** (if applicable): Use `/ftl:rhdp-lab-validator` to generate Solve/Validate button automation
