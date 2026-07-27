---
title: "ADR-020: RHDP Workload Bootstrap Scaffold Type"
nav_order: 20
parent: Architecture Decision Records
---

# ADR-020: RHDP Pre-Provisioned Cluster Workload Bootstrap Scaffold Type

* Status: accepted
* Date: 2026-07-27
* Deciders: Architecture Team

## Context and Problem Statement

OpenShift workshops and demos increasingly use RHDP (Red Hat Demo Platform) pre-provisioned clusters rather than provisioning clusters from scratch via AgnosticD's `agd` CLI. In this model, a facilitator orders a cluster from the RHDP catalog item (`agd-v2.ocp-cluster-aws.prod`), and the cluster arrives with Red Hat Build of Keycloak (RHBK), pre-created users (`user1`, `user2`, ..., `userN`), OpenID identity provider, and cert-manager already configured. The workshop's bootstrap then applies workloads (operators, applications, pipelines) on top.

The existing `shared-cluster` scaffold type assumes AgnosticD provisions the cluster and creates users via `oc create`. This does not match the RHDP workflow in several structural ways:

* No `agd` binary or cloud credentials are needed (the cluster already exists)
* Users are pre-created by Keycloak, not by deploy scripts
* User naming follows `userN` (no dash), not `user-N`
* Each user has a unique password in the KeycloakRealmImport CR, not a shared password
* The `keycloak` namespace is already occupied by RHDP's RHBK instance
* Validation checks target Keycloak realm state, not cloud provider quotas

Attempting to add RHDP-specific flags or modes to `shared-cluster` would create conditional branches in every template file and complicate an already clear topology.

## Decision Drivers

* Growing number of workshops use RHDP pre-provisioned clusters for workload deployment
* RHDP user format (`userN`, no dash) differs from AgnosticD conventions (`user-N`)
* Workshop bootstraps that target RHDP clusters must detect and adapt to Keycloak-managed users
* Deploy scripts should focus on workload application, not cluster provisioning
* The reference implementation (tosin2013/zero-cve-hummingbird-showroom) demonstrates the pattern

## Considered Options

### Option A: New scaffold type (`rhdp-workload`)

Add a fifth scaffold type with its own templates, skipping AgnosticD provisioning and adding Keycloak user detection.

### Option B: Flags on `shared-cluster`

Add `--rhdp` or `--preprovisioned` flags to the existing `shared-cluster` type, with conditionals in each template.

### Option C: Documentation-only pattern

Document the RHDP workflow as a pattern guide without scaffold support.

## Decision Outcome

**Option A: New scaffold type (`rhdp-workload`)**

### Rationale

The differences between AgnosticD-provisioned and RHDP-provisioned clusters are structural, not configuration-level:

| Aspect | `shared-cluster` | `rhdp-workload` |
|--------|-------------------|------------------|
| Cluster provisioning | `agd provision` | Already exists (RHDP catalog) |
| User creation | `oc create` in deploy script | Pre-created via Keycloak |
| User format | `user-N` (with dash) | `userN` (no dash) |
| Identity provider | Created by workshop | Already configured (OpenID via RHBK) |
| Passwords | Generated or static | Unique per-user, in KeycloakRealmImport CR |
| Prerequisites | `agd`, AWS creds, secrets file | `oc` logged in, Keycloak accessible |
| Deploy focus | Cluster + workloads | Workloads only |
| Teardown | Destroy cluster + namespaces | Remove workloads + namespaces (cluster stays) |

Option B would require conditionals in `onboard.yml.tpl`, `deploy.sh.tpl`, `teardown.sh.tpl`, `bootstrap.sh.tpl`, and `check-quota.sh.tpl`, making both code paths harder to maintain.

### Implementation

* New template directory: `templates/rhdp-workload/` with 6 `.tpl` files
* New scaffold variable collection: `collect_rhdp_workload_vars()` in `lib/scaffold.sh`
* RHDP helper functions in `lib/workshop-common.sh`: Keycloak detection, user enumeration, password resolution, IdP verification
* Skill updates: `student-readiness`, `showroom`, and `project-onboard` gain RHDP-aware guidance
* Custom common variable collection (no AgnosticD-specific prompts like `AGD_ROOT` or `CLOUD_PROVIDER`)

### Field-Sourced Content Integration

The `rhdp-workload` scaffold type integrates with Field-Sourced Content as the primary workload deployment mechanism. When enabled at scaffold time (`USE_FIELD_CONTENT=y`), the generated deploy script creates an ArgoCD Application pointing to the user's field content Git repository. This replaces the generic placeholder with a working GitOps pipeline:

1. User scaffolds with `--type rhdp-workload` and provides their content repo URL
2. Deploy script detects RHDP users, creates namespaces, then creates an ArgoCD Application
3. ArgoCD syncs Helm charts or Ansible playbooks from the content repo onto the cluster
4. Teardown script deletes the ArgoCD Application (which prunes managed resources) and namespaces

The same `demo.redhat.com/userinfo` label mechanism works for data passback on RHDP clusters.

### Positive Consequences

* Clean separation of concerns — each scaffold type has a clear, self-contained topology
* RHDP-specific validation catches common mistakes (wrong user format, conflicting IdPs, missing Keycloak realm)
* Workshops can scaffold directly for the RHDP catalog flow without adapting AgnosticD templates
* Helper functions in `workshop-common.sh` are reusable by any project targeting RHDP clusters
* Field-Sourced Content integration provides a working GitOps deployment pipeline out of the box

### Negative Consequences

* Fifth scaffold type increases the total number of templates to maintain
* Some structural overlap with `shared-cluster` (Makefile, bootstrap.sh patterns)
* Shared library grows with RHDP-specific functions that are unused by other scaffold types

## Links

* Related: [ADR-018](018-scaffold-command.html) (scaffold command architecture)
* Issue: [GitHub #3](https://github.com/tosin2013/rhel-devops-skills-cli/issues/3)
* Reference: tosin2013/zero-cve-hummingbird-showroom (RHDP workload bootstrap example)
