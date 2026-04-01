---
title: Showroom
parent: Skills
nav_order: 4
---

# Showroom Skill

**Source Repository**: [rhpds/showroom-deployer](https://github.com/rhpds/showroom-deployer)
{: .fs-5 }

## Overview

Showroom is the RHDP lab guide and terminal system. It deploys Antora-based AsciiDoc documentation alongside an embedded terminal (Wetty, ttyd, or pod-based) onto OpenShift. This skill teaches your AI assistant how to author Showroom content, configure deployment options, and integrate Showroom with AgnosticD and Field-Sourced Content.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Creating or editing Showroom lab content (Antora/AsciiDoc)
- Configuring terminal types (showroom, wetty, content-only)
- Deploying Showroom as an AgnosticD infra_workload
- Adding Showroom as a component in Field-Sourced Content
- Previewing lab content locally with Podman
- Selecting terminal container images (OCP, ROSA, ARO)

## Key Concepts

### Content Authoring

Showroom content uses the [Antora](https://docs.antora.org/) static site generator with AsciiDoc. Start from the [default template](https://github.com/rhpds/showroom_template_default):

```bash
git clone https://github.com/rhpds/showroom_template_default.git my-lab
cd my-lab
podman run --rm -v $PWD:/antora:z -p 8080:8080 ghcr.io/juliaaano/antora-viewer
```

### Deployment

Showroom can be deployed three ways:

| Method | When to Use |
|--------|-------------|
| AgnosticD `infra_workload` | Standard RHDP demos with a provisioned cluster |
| Field Content Helm component | Self-service field content with embedded lab guide |
| Standalone Helm | Testing or non-RHDP deployments |

### Terminal Types

| Type | Description |
|------|-------------|
| `showroom` | Pod-based terminal on OpenShift (default) |
| `wetty` | SSH to bastion via browser terminal |
| Content-only | Lab instructions without any terminal |

## Related Skills

| Skill | Integration |
|-------|-------------|
| [AgnosticD v2](agnosticd.html) | Deploys Showroom as an `infra_workload` on provisioned clusters |
| [Field-Sourced Content](field-sourced-content.html) | Includes Showroom as a Helm component for self-service demos |
| [Student Readiness](student-readiness.html) | Verifies Showroom accessibility, terminal, and content-environment match |

See [ADR-011](../adrs/011-e2e-validation-and-troubleshooting.html) for validation and troubleshooting strategy.

## Reference Documentation

When installed, the `references/` directory includes:

| Document | Description |
|----------|-------------|
| `showroom-deployer-README.adoc` | Helm chart deployment guide |
| `showroom-template-README.adoc` | Content authoring and Antora structure |
| `ocp4-workload-showroom-README.adoc` | AgnosticD workload role configuration |

## Install

```bash
./install.sh install --skill showroom
```
