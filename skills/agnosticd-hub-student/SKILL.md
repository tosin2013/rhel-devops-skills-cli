---
name: agnosticd-hub-student
description: AI assistance for architecting, sizing, provisioning, and validating an AgnosticD deployment where Showroom runs on a dedicated hub cluster and students each get their own SNO or compact OpenShift cluster. Covers student count input (default 2), cloud provider quota pre-flight checks for AWS, GCP, and Azure, cross-cluster Showroom terminal configuration, per-student credential data pipeline, and independent hub/student lifecycle operations.
related_skills: [agnosticd, agnosticd-deploy-test, showroom, student-readiness, agnosticd-refactor]
---

# AgnosticD Hub-Student Topology Skill

## When to Use

**Purpose:** Use this skill when you need to run Showroom on a central hub cluster while each student (or student team) works on a dedicated SNO or compact OpenShift cluster provisioned separately. This topology separates the lab guide infrastructure from the student workload clusters, enabling independent scaling, independent stop/start, and per-student cluster credentials.

- You want Showroom to run on a hub cluster while students log into separate SNO or compact clusters
- You need to provision N student clusters (default: 2) and wire their credentials into Showroom
- You need to estimate AWS, GCP, or Azure resource requirements before provisioning
- You need a quota pre-flight check before provisioning to avoid mid-deployment failures
- You want to stop student clusters independently without stopping the hub

Do NOT use this skill for single-cluster deployments where Showroom and student workloads share one cluster — use the **agnosticd** skill instead. Do NOT use this skill to test an existing deployment — use **agnosticd-deploy-test** instead.

## Topology Overview

```
┌─────────────────────────────────┐
│  Hub Cluster (Showroom only)    │
│  ┌─────────────────────────┐   │
│  │ Showroom                │   │
│  │  lab guide + terminal   │   │
│  │  → targets student API  │   │
│  └─────────────────────────┘   │
└────────────────┬────────────────┘
                 │  terminal points to student cluster API
     ┌───────────┼───────────┐
     │           │           │
┌────▼───┐  ┌───▼────┐  ┌───▼────┐
│Student │  │Student │  │Student │
│  1     │  │  2     │  │  N     │
│SNO/OCP │  │SNO/OCP │  │SNO/OCP │
└────────┘  └────────┘  └────────┘

AgnosticD provisions all clusters.
agnosticd_user_info carries per-student credentials to Showroom.
```

## Instructions

This skill defines a five-phase process. Complete Phase 0 (quota pre-flight) before provisioning any cluster. Do not proceed to the next phase if the current phase has unresolved blockers.

## Required Input

Before starting, collect:

| Input | Required | Default | Example |
|-------|----------|---------|---------|
| Cloud provider | Yes | — | `aws`, `gcp`, `azure` |
| Number of students | No | **2** | `5`, `10`, `20` |
| Cluster type | No | `sno` | `sno`, `compact` |
| Cloud region | Yes | — | `us-east-1`, `us-east1`, `eastus` |
| AgnosticD v2 root directory | Yes | — | `~/Development/agnosticd-v2/` |
| Config name (hub) | No | TBD via RQ-HUB-1 | `ocp4-hub` |
| Config name (student) | No | TBD via RQ-HUB-4 | `ocp4-sno` |

---

## Phase 0 — Cloud Provider Quota Pre-flight

Run this phase before any provisioning. Calculate the resources required for `num_students` student clusters plus one hub, compare against provider defaults, and block if any quota increase is required.

### Quota Calculations

For **N students** with **SNO** clusters:
- Public IPs / Elastic IPs: 1 (hub) + N (student) = **N+1 total**
- vCPUs: hub vCPUs + (N × per-SNO-node vCPUs) — `(RESEARCH NEEDED — RQ-HUB-4)`
- VPCs / VNets: N+1 (one per cluster)
- Load Balancers: N+1 (one per cluster) — `(RESEARCH NEEDED — RQ-HUB-7)`
- NAT Gateways: N+1 (one per VPC/VNet) — `(RESEARCH NEEDED — RQ-HUB-7)`

For **N students** with **compact** clusters (3-node control plane):
- vCPUs: hub vCPUs + (N × 3 × per-node vCPUs) — `(RESEARCH NEEDED — RQ-HUB-4)`
- All other resources scale the same as SNO

### Provider-Specific Defaults and Increase Paths

**AWS**

| Service Quota | Typical Default | Scales with N | Required for N students |
|---------------|-----------------|---------------|------------------------|
| Elastic IP addresses per region | 5 | Yes | N+1 |
| Running On-Demand EC2 vCPUs (by family) | varies | Yes | N × per-cluster vCPUs |
| VPCs per region | 5 | Yes | N+1 |
| Application Load Balancers per region | 20 | Yes | `(RESEARCH NEEDED — RQ-HUB-7)` |
| NAT Gateways per AZ | 5 | Yes | N+1 |

Increase path: **AWS Console → Service Quotas → EC2 / VPC → Request increase**

CLI alternative:
```bash
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-0263D0A3 \
  --desired-value <N+1>
```

**GCP**

| Service Quota | Typical Default | Scales with N | Required for N students |
|---------------|-----------------|---------------|------------------------|
| Static external IP addresses per region | 8 (varies by project) | Yes | N+1 |
| CPUs per region | 24–72 (varies) | Yes | N × per-cluster vCPUs |
| VPC networks per project | 5 | Yes | N+1 |
| Backend services | varies | Yes | `(RESEARCH NEEDED — RQ-HUB-7)` |

Increase path: **GCP Console → IAM & Admin → Quotas → Filter → Request increase**

**Azure**

| Service Quota | Typical Default | Scales with N | Required for N students |
|---------------|-----------------|---------------|------------------------|
| Public IP addresses (Standard) per subscription | 10 | Yes | N+1 |
| Total Regional vCPUs | 10–20 (new subscriptions) | Yes | N × per-cluster vCPUs |
| Virtual Networks per region | 50 | Less likely | N+1 |
| Standard Load Balancers | 100 | Less likely | `(RESEARCH NEEDED — RQ-HUB-7)` |

Increase path: **Azure Portal → Subscriptions → Usage + quotas → Request increase**

### Quota Pre-flight Report

```
Quota Pre-flight — <provider>, <N> students, <cluster_type>, <region>
──────────────────────────────────────────────────────────────────────
 Quota                   Default   Required   Status
 Public IPs / EIPs       5         <N+1>      INCREASE NEEDED / OK
 vCPUs                   varies    <calculated>  CHECK REQUIRED
 VPCs / VNets            5         <N+1>      INCREASE NEEDED / OK
 Load Balancers          20        <N+1>      OK
 NAT Gateways            5         <N+1>      INCREASE NEEDED / OK
──────────────────────────────────────────────────────────────────────
 Action required: request quota increases before provisioning.
 Increase path: <provider-specific path>
```

**If any status is INCREASE NEEDED:** Stop. Provide the exact increase steps for the provider. Do not proceed to Phase 1 until the user confirms quota increases are requested.

**If all statuses are OK:** Proceed to Phase 1.

---

## Phase 1 — Sizing Estimate

Produce a pre-provisioning resource estimate so the developer knows what will be created before running any `agd` command.

```
Hub-Student Sizing Estimate
──────────────────────────────────────────────────────────────────────
 Provider:        <cloud_provider>
 Region:          <region>
 Students:        <N>
 Cluster type:    <SNO | compact>

 Hub cluster:     1 × <instance-type>  (RESEARCH NEEDED — RQ-HUB-4)
 Student clusters: <N> × <instance-type> per SNO
                   <N> × 3 × <instance-type> per compact

 Total instances: <calculated>
 Est. cost/hour:  (RESEARCH NEEDED — RQ-HUB-4)
──────────────────────────────────────────────────────────────────────
```

> (RESEARCH NEEDED — RQ-HUB-4: SNO and compact cluster instance types, minimum resource specs, and cost models per provider for AWS, GCP, and Azure)

---

## Phase 2 — Hub Cluster Provisioning

> (RESEARCH NEEDED — RQ-HUB-1: What AgnosticD config pattern provisions a Showroom-only hub while N student clusters are provisioned separately? Look for `ocp4-hub`, `ocp4-shared`, or similar in `agnosticd-v2/ansible/configs/`)

Provision the hub cluster. The hub cluster hosts Showroom as its primary infra workload. It should not host demo workloads — those belong on the student clusters.

**Current partial guidance:**

The hub cluster provisioning uses `agd provision` with a config dedicated to the hub role. The hub config should include:
- Showroom deployed as an `infra_workload` (via `ocp4_workload_showroom`)
- A Showroom Helm values override that configures the terminal target URL as a variable (to be injected per-student in Phase 3)
- No demo-specific workload roles

```bash
cd ~/Development/agnosticd-v2
./bin/agd provision \
  --config <hub-config-name> \
  --vars agnosticd-v2-vars/<hub-vars-file>.yaml
```

After hub provisioning, confirm Showroom is accessible before provisioning student clusters.

---

## Phase 3 — Student Cluster Provisioning

> (RESEARCH NEEDED — RQ-HUB-6: What AgnosticD variable controls how many student clusters are provisioned — `num_students`, `student_count`? How does the provisioning loop iterate over it?)

> (RESEARCH NEEDED — RQ-HUB-3: Which `agnosticd_user_info` keys carry per-student API URL, kubeconfig, admin password, and console URL when the student cluster is separate from the hub?)

Provision N student clusters. The student cluster config contains the demo workloads. Per-student cluster credentials must be captured via `agnosticd_user_info` for Showroom injection.

**Current partial guidance:**

```bash
# For each student cluster (or via a loop — see RQ-HUB-6):
./bin/agd provision \
  --config <student-config-name> \
  --vars agnosticd-v2-vars/<student-vars-file>.yaml
```

After each student cluster provisions, verify `agnosticd_user_info` contains:
- Per-student API URL
- Per-student kubeconfig or admin password
- Per-student console URL

---

## Phase 4 — Cross-Cluster Showroom Wiring

> (RESEARCH NEEDED — RQ-HUB-2: How does `ocp4_workload_showroom` or its Helm chart target a different cluster API URL per student? Look in `agnosticd-v2/ansible/roles/ocp4_workload_showroom/` and the Showroom Helm chart values.)

Configure Showroom's terminal to point to each student cluster API rather than the hub cluster. This is the key cross-cluster wiring step.

**Current partial guidance:**

Showroom's terminal URL is configured via Helm chart values. The hub provisioning injects the Showroom URL, but each student needs a different terminal target. The mechanism for injecting per-student terminal targets is covered by RQ-HUB-2 and RQ-HUB-3.

After wiring, verify per-student credential injection:

```bash
# Verify Showroom antora.yml has student cluster attributes
# (exact attribute names TBD — see RQ-HUB-3)
oc -n showroom get configmap showroom-config -o yaml
```

---

## Phase 5 — Lifecycle Verification

> (RESEARCH NEEDED — RQ-HUB-5: How does stop/start/status operate when hub and student clusters are provisioned independently? Can student clusters be stopped without stopping the hub?)

Verify that the hub and student clusters can be managed independently.

**Current partial guidance:**

```bash
# Stop all student clusters (hub remains running)
./bin/agd stop --config <student-config-name> --vars <student-vars-file>

# Verify hub is still accessible
oc --kubeconfig <hub-kubeconfig> get nodes

# Start student clusters back up
./bin/agd start --config <student-config-name> --vars <student-vars-file>
```

The stop/start lifecycle must be independent: stopping student clusters should not affect Showroom on the hub. This is a RHDP requirement — environments that cannot be stopped and resumed will not pass RHDP review.

---

## Final Summary Report

```
AgnosticD Hub-Student Deployment — Complete
══════════════════════════════════════════════════════
 Provider:       <cloud_provider>    Region: <region>
 Students:       <N>                 Type:   <SNO | compact>

 Phase 0 — Quota pre-flight          PASS / BLOCKED
 Phase 1 — Sizing estimate           PASS
 Phase 2 — Hub provisioning          PASS / FAIL
   Hub cluster accessible            YES / NO
   Showroom deployed                 YES / NO
 Phase 3 — Student provisioning      PASS / FAIL
   Clusters provisioned              <N>/<N>
   agnosticd_user_info present       YES / NO
 Phase 4 — Showroom wiring           PASS / FAIL
   Terminal targets injected         YES / NO
 Phase 5 — Lifecycle                 PASS / FAIL / SKIPPED
══════════════════════════════════════════════════════
 Overall: READY FOR STUDENTS / NEEDS ATTENTION

 Next step: Run student-readiness for each student cluster.
```

---

## Remediation Plan

When the overall result is **NEEDS ATTENTION**, generate an ordered, prioritized remediation plan from the actual failures found.

| Priority | Condition | Action |
|----------|-----------|--------|
| BLOCKING | Quota pre-flight failed (Phase 0) | Request quota increases before any provisioning |
| BLOCKING | Hub provisioning failed (Phase 2) | Activate **agnosticd-refactor** to audit hub config |
| BLOCKING | Student provisioning failed (Phase 3) | Activate **agnosticd-refactor** to audit student config |
| HIGH | `agnosticd_user_info` missing (Phase 3) | Activate **agnosticd-refactor**, Audit Area 4 — data pipeline not wired |
| HIGH | Showroom terminal not wired (Phase 4) | Research RQ-HUB-2 and RQ-HUB-3 — cross-cluster wiring not yet documented |
| MEDIUM | Lifecycle independent stop failed (Phase 5) | Verify stop playbooks support per-config stop; check RQ-HUB-5 |

---

## Re-test After Fixes

After resolving items from the remediation plan, re-run only the phases that failed:

```
Re-running failed phases only:
  Phase 3 (Student provisioning) — re-checking student clusters and agnosticd_user_info
  Phase 4 (Showroom wiring) — re-checking cross-cluster terminal injection

Skipping Phase 0 (quotas confirmed), Phase 1 (sizing complete), Phase 2 (hub OK).
```

---

## Escalation

- **Hub or student provisioning failure** → Use the **agnosticd-refactor** skill to audit config structure, required variables, and workload role layout
- **`agnosticd_user_info` keys missing** → Use **agnosticd-refactor** Audit Area 4; escalate RQ-HUB-3 to `skill-researcher`
- **Showroom cross-cluster terminal not working** → Escalate RQ-HUB-2 to `skill-researcher` to research the Showroom Helm chart and `ocp4_workload_showroom` role
- **Quota pre-flight blocking provisioning** → Follow provider-specific quota increase path in Phase 0; re-run pre-flight after confirmation
- **Independent stop/start not working** → Escalate RQ-HUB-5 to `skill-researcher`
