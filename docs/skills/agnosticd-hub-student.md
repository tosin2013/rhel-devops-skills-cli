---
title: AgnosticD Hub-Student
parent: Skills
nav_order: 13
---

# AgnosticD Hub-Student Topology Skill

**Type**: Process-oriented (no upstream repository)
{: .fs-5 }

## Overview

The AgnosticD Hub-Student skill guides the AI assistant through architecting, sizing, provisioning, and validating an AgnosticD deployment where Showroom runs on a dedicated hub cluster and each student (or student team) works on a separate SNO or compact OpenShift cluster.

This topology is structurally different from a single-cluster deployment:

- The hub cluster hosts Showroom (lab guide + terminal proxy) only
- Each student cluster is provisioned independently via `agd provision`
- Showroom's terminal points to each student's cluster API — not to the hub
- Per-student credentials (API URL, kubeconfig, admin password, console URL) flow through `agnosticd_user_info` from the student cluster to Showroom
- Hub and student clusters have independent stop/start lifecycles

The default student count is **2** when not specified. The skill scales sizing and quota calculations linearly with student count.

## When the AI Uses This Skill

Your AI assistant will activate this skill when you're:

- Asking "how do I run Showroom on a hub but have students work on their own SNO or compact cluster?"
- Provisioning separate student clusters in AgnosticD
- Configuring Showroom's terminal to target a different cluster API per student
- Planning resource sizing for 5, 10, or 20 students on AWS, GCP, or Azure
- Running a cloud provider quota pre-flight check before provisioning multiple clusters

## Five-Phase Process

```
Phase 0 — Cloud Provider Quota Pre-flight
  Collect: provider (aws/gcp/azure), num_students, cluster_type, region
  Calculate required quotas (public IPs, vCPUs, VPCs/VNets, LBs, NAT GWs)
  Compare against provider defaults; block if any quota increase is needed
  Provider-specific increase paths: AWS Service Quotas / GCP Quotas / Azure Portal

Phase 1 — Sizing Estimate
  Hub cluster: fixed size (Showroom only)
  Per-student: SNO = 1 node × N; compact = 3 nodes × N
  Total instances and estimated cost/hour by provider

Phase 2 — Hub Cluster Provisioning
  agd provision with hub config (Showroom as infra_workload)
  (RESEARCH NEEDED — RQ-HUB-1: hub config pattern in agnosticd-v2)

Phase 3 — Student Cluster Provisioning
  agd provision × N (or via student count loop — see RQ-HUB-6)
  Capture per-student agnosticd_user_info credentials
  (RESEARCH NEEDED — RQ-HUB-3, RQ-HUB-6)

Phase 4 — Cross-Cluster Showroom Wiring
  Configure Showroom terminal to target each student cluster API
  Verify per-student credential injection into Antora attributes
  (RESEARCH NEEDED — RQ-HUB-2)

Phase 5 — Lifecycle Verification
  Independent stop/start for hub vs. student clusters
  Verify hub remains running while student clusters are stopped
  (RESEARCH NEEDED — RQ-HUB-5)
```

## Cloud Provider Quota Pre-flight

The skill performs a quota pre-flight check before any provisioning. It calculates the resources needed for N student clusters plus the hub, and compares against provider defaults.

| Provider | Key Quota | Default | Scales with N |
|----------|-----------|---------|---------------|
| **AWS** | Elastic IPs | 5/region | Yes |
| **AWS** | vCPUs (On-Demand) | varies | Yes |
| **AWS** | VPCs | 5/region | Yes |
| **GCP** | Static External IPs | 8/region | Yes |
| **GCP** | CPUs | 24–72 | Yes |
| **GCP** | VPC Networks | 5/project | Yes |
| **Azure** | Public IPs (Standard) | 10/subscription | Yes |
| **Azure** | Regional vCPUs | 10–20 | Yes |

If any quota would be exceeded, the skill blocks provisioning and provides the exact increase steps for the provider.

## Open Research Questions

This skill is scaffolded with seven `(RESEARCH NEEDED)` blocks. Use the **skill-researcher** skill to resolve them:

| RQ | Description |
|----|-------------|
| RQ-HUB-1 | Hub cluster config pattern in `agnosticd-v2/ansible/configs/` |
| RQ-HUB-2 | How Showroom Helm chart targets a different cluster API per student |
| RQ-HUB-3 | `agnosticd_user_info` keys for per-student cluster credentials |
| RQ-HUB-4 | SNO/compact instance types, sizes, and cost across AWS, GCP, Azure |
| RQ-HUB-5 | Independent hub/student stop/start lifecycle playbook patterns |
| RQ-HUB-6 | AgnosticD student count variable and provisioning loop |
| RQ-HUB-7 | Exact per-cluster quota counts and provider increase paths |

## Related Skills

| Skill | Relationship |
|-------|-------------|
| [AgnosticD v2](agnosticd.html) | Operational skill — use agnosticd for single-cluster deployments and general `agd` setup |
| [AgnosticD Deploy Test](agnosticd-deploy-test.html) | Validate an existing single-cluster deployment; the hub-student skill extends this for multi-cluster |
| [Showroom](showroom.html) | Lab guide and terminal system — hub-student wires Showroom's terminal to student cluster APIs |
| [Student Readiness](student-readiness.html) | Run per student cluster after Phase 3 to verify each student environment |
| [AgnosticD Refactor](agnosticd-refactor.html) | Escalation target when hub or student provisioning fails |
| [Skill Researcher](skill-researcher.html) | Resolves RQ-HUB-1 through RQ-HUB-7 |

See [ADR-016](../adrs/016-hub-student-skill.html) for the full design rationale.

## Install

```bash
./install.sh install --skill agnosticd-hub-student
```
