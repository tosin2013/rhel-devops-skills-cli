---
title: "ADR-016: AgnosticD Hub-Student Topology Skill"
nav_order: 16
parent: Architecture Decision Records
---

# ADR-016: AgnosticD Hub-Student Topology Skill

* Status: accepted
* Date: 2026-04-06
* Deciders: Architecture Team

## Context and Problem Statement

The existing AgnosticD skill set covers the standard single-cluster deployment pattern where Showroom (lab guide + terminal) runs on the same OpenShift cluster that students work on. This pattern has a hard ceiling: as the number of students grows, resource contention on a single cluster degrades the student experience, and a single cluster failure takes down both the lab guide and all student workloads simultaneously.

A second topology is increasingly common for Red Hat workshops:

```
Hub cluster        — runs Showroom (lab guide, terminal proxy)
Student clusters   — one SNO or compact OCP cluster per student or per team,
                     provisioned independently on AWS, GCP, or Azure
```

In this topology, Showroom's terminal points to the student cluster API, not to the cluster it runs on. Per-student credentials (API URL, kubeconfig, admin password, console URL) must be passed from the student cluster provisioning back to Showroom via `agnosticd_user_info`. The hub and student clusters have independent stop/start lifecycles, and sizing calculations must account for N student clusters rather than one shared cluster.

No existing skill covers this topology. The `agnosticd` skill covers single-cluster provisioning. The `showroom` skill covers Showroom deployment but not cross-cluster terminal targeting. The `agnosticd-deploy-test` skill validates a single-cluster deployment pipeline.

Five specific questions have no existing skill to answer them:

1. "What AgnosticD config pattern provisions a Showroom-only hub while N student clusters are provisioned separately?"
2. "How do I configure Showroom's terminal to point to a different cluster API per student?"
3. "Which `agnosticd_user_info` keys carry per-student cluster credentials when the student cluster is separate?"
4. "What instance types and cloud quotas do I need for 10 student clusters on AWS, GCP, or Azure?"
5. "How do I stop only the student clusters without stopping the hub?"

## Decision Drivers

* The hub+student topology is structurally different from single-cluster deployments — it requires a different provisioning approach, a different data pipeline, and different sizing logic
* Showroom cross-cluster terminal targeting is not documented in any existing skill
* Sizing and quota pre-flight checks must scale with the number of students and vary by cloud provider (AWS, GCP, Azure)
* The failure modes (hub provision failed, one student cluster failed, credentials not flowing) are distinct from single-cluster failure modes and require their own diagnostic guidance
* Consistent with the process-oriented skill pattern from ADR-011, ADR-012, ADR-013, and ADR-015 — new topology = new skill

## Considered Options

1. **Extend the `agnosticd` skill** with hub+student sections — add new subsections to the existing operational skill
2. **Extend `agnosticd-deploy-test`** with multi-cluster awareness — detect hub+student pattern and branch the test process
3. **New standalone process-oriented skill** — `agnosticd-hub-student`, covering only the hub+student topology from planning to deployment and lifecycle

## Decision Outcome

Chosen option: **"New standalone process-oriented skill"** (option 3), because:

* Option 1 would mix provisioning guidance (how to run `agd`) with topology-specific deployment guidance (how to wire two separate clusters together). The `agnosticd` skill already covers single-cluster; adding multi-cluster topology would make it too broad.
* Option 2 would conflate deployment pipeline testing with topology architecture guidance. `agnosticd-deploy-test` is a test execution skill — it validates an existing deployment rather than explaining how to architect a new one.
* The hub+student topology has a distinct planning phase (student count, sizing, quota pre-flight) that has no equivalent in single-cluster deployments. This planning phase alone justifies a standalone skill.

### Skill Description

**`agnosticd-hub-student`**: A process-oriented skill that guides an AI assistant and developer through architecting, sizing, provisioning, and validating an AgnosticD deployment where Showroom runs on a dedicated hub cluster and students work on separate SNO or compact OpenShift clusters. Covers student count input (default 2), cloud provider quota pre-flight checks for AWS, GCP, and Azure, cross-cluster Showroom terminal configuration, per-student credential data pipeline, and independent hub/student lifecycle operations.

### Skill Phases

```
Phase 0 — Cloud Quota Pre-flight
  Collect: cloud_provider, num_students, cluster_type (SNO | compact), region
  Calculate required quotas for public IPs, vCPUs, VPCs/VNets, LBs, NAT GWs
  Compare against provider defaults; block provisioning if increases are needed
  Provider-specific increase paths: AWS Service Quotas / GCP Quotas / Azure Portal

Phase 1 — Sizing Estimate
  Hub cluster:      fixed instance size (Showroom only)
  Per-student:      SNO = 1 node × N; compact = 3 nodes × N
  Total EC2/GCP/Azure instances and estimated cost/hour

Phase 2 — Hub Cluster Provisioning
  Provision the hub cluster with Showroom as infra_workload
  (RESEARCH NEEDED — RQ-HUB-1: what AgnosticD config provisions a Showroom-only hub)

Phase 3 — Student Cluster Provisioning
  Provision N student clusters (SNO or compact)
  Pass per-student credentials via agnosticd_user_info
  (RESEARCH NEEDED — RQ-HUB-2, RQ-HUB-3, RQ-HUB-6)

Phase 4 — Cross-Cluster Showroom Wiring
  Configure Showroom terminal to target each student cluster API
  Verify per-student credential injection into Antora attributes
  (RESEARCH NEEDED — RQ-HUB-2, RQ-HUB-3)

Phase 5 — Lifecycle Verification
  Independent stop/start for hub vs. student clusters
  Verify hub can remain running while student clusters are stopped
  (RESEARCH NEEDED — RQ-HUB-5)
```

### Seven Research Questions

The skill is scaffolded with seven `(RESEARCH NEEDED)` blocks — all resolved later via `skill-researcher`:

| RQ | Description |
|----|-------------|
| RQ-HUB-1 | Hub cluster config pattern in AgnosticD |
| RQ-HUB-2 | Showroom cross-cluster terminal targeting |
| RQ-HUB-3 | Per-student `agnosticd_user_info` credential keys |
| RQ-HUB-4 | SNO/compact sizing across AWS, GCP, Azure |
| RQ-HUB-5 | Independent hub/student stop/start lifecycle |
| RQ-HUB-6 | AgnosticD student count variable and provisioning loop |
| RQ-HUB-7 | Cloud provider quota requirements and increase paths for all three providers |

### Relationship to Existing Skills

```
agnosticd             → related: agnosticd-hub-student (topology extension)
agnosticd-deploy-test → related: agnosticd-hub-student (multi-cluster variant)
showroom              → related: agnosticd-hub-student (cross-cluster terminal config)
student-readiness     → related: agnosticd-hub-student (called per student cluster)
skill-researcher      → resolves RQ-HUB-1 through RQ-HUB-7
```

### Positive Consequences

* The hub+student topology has dedicated, searchable guidance — no more stitching together single-cluster docs
* Quota pre-flight runs before provisioning, preventing mid-deployment failures due to AWS/GCP/Azure limits
* Multi-student, multi-cloud sizing is calculated explicitly rather than guessed
* All seven research questions are registered in the RQ Registry for systematic resolution via `skill-researcher`

### Negative Consequences

* Seven open `(RESEARCH NEEDED)` blocks mean the skill is initially a scaffold — useful for orientation but not operationally complete until RQ-HUB-1 through RQ-HUB-7 are resolved
* The skill requires both `agnosticd-v2` (for provisioning) and `showroom` (for cross-cluster wiring) knowledge — operators must be familiar with both ecosystems

## Links

* [AgnosticD Hub-Student Skill](../skills/agnosticd-hub-student.html) — new hub+student topology skill
* [ADR-011](011-e2e-validation-and-troubleshooting.html) — original lifecycle and student-readiness decision
* [ADR-013](013-refactor-skills.html) — refactor skills (escalation targets)
* [ADR-015](015-deployment-pipeline-testing.html) — deployment pipeline testing (single-cluster baseline)
* Related: [ADR-010](010-cross-skill-dependencies.html) (cross-skill dependencies)
