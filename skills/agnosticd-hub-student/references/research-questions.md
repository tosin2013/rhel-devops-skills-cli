# Research Questions — AgnosticD Hub-Student Topology Skill

Open research items extracted from the skill. Resolve each question by investigating the AgnosticD v2 codebase and updating the skill accordingly.

## RQ-HUB-1: Hub Config Pattern

**Question:** What AgnosticD config pattern provisions a Showroom-only hub while N student clusters are provisioned separately? Look for `ocp4-hub`, `ocp4-shared`, or similar in `agnosticd-v2/ansible/configs/`.

**Context:** Phase 2 — Hub Cluster Provisioning requires knowing which config to use.

---

## RQ-HUB-2: Per-Student Showroom Terminal Targeting

**Question:** How does `ocp4_workload_showroom` or its Helm chart target a different cluster API URL per student? Look in `agnosticd-v2/ansible/roles/ocp4_workload_showroom/` and the Showroom Helm chart values.

**Context:** Phase 4 — Cross-Cluster Showroom Wiring requires per-student terminal configuration.

---

## RQ-HUB-3: Per-Student agnosticd_user_info Keys

**Question:** Which `agnosticd_user_info` keys carry per-student API URL, kubeconfig, admin password, and console URL when the student cluster is separate from the hub?

**Context:** Phase 3 — Student provisioning credential capture for Showroom injection.

---

## RQ-HUB-4: Instance Types, Resource Specs, and Cost Models

**Question:** What are the SNO and compact cluster instance types, minimum resource specs, and cost models per provider for AWS, GCP, and Azure?

**Pending items:**
- Per-cluster vCPU counts for SNO and compact topologies
- Hub cluster instance type and vCPU count
- Estimated cost per hour per provider
- Instance type recommendations per provider

**Context:** Phase 0 quota calculations and Phase 1 sizing estimates both depend on this.

---

## RQ-HUB-5: Independent Hub/Student Lifecycle Operations

**Question:** How does stop/start/status operate when hub and student clusters are provisioned independently? Can student clusters be stopped without stopping the hub?

**Context:** Phase 5 — Lifecycle Verification for RHDP cost-management compliance.

---

## RQ-HUB-6: Student Count Variable

**Question:** What AgnosticD variable controls how many student clusters are provisioned — `num_students`, `student_count`? How does the provisioning loop iterate over it?

**Context:** Phase 3 — Student Cluster Provisioning loop logic.

---

## RQ-HUB-7: Load Balancer and NAT Gateway Quotas

**Question:** How many load balancers and NAT gateways does each cluster type (SNO, compact) require per provider (AWS, GCP, Azure)?

**Pending items:**
- AWS Application Load Balancers per cluster
- AWS NAT Gateways per cluster
- GCP Backend services per cluster
- Azure Standard Load Balancers per cluster

**Context:** Phase 0 quota pre-flight calculations for all three providers.

---

## RQ-HUB-8: RHACM ManagedCluster CR for Spoke Registration

**Question:** What is the minimum RHACM `ManagedCluster` CR and import secret YAML for spoke registration via auto-import, and what is the Ansible `k8s` wait task for `ManagedClusterConditionAvailable = True`?

**Context:** Phase 3 — RHACM registration during student cluster provisioning.
