# Research Questions — AgnosticD Skill

Open research items extracted from the skill. Resolve each question by investigating the AgnosticD v2 codebase and updating the skill accordingly.

## RQ-2: Config File Structure and Required Playbooks

**Question:** What is the required file structure and playbook set for an AgnosticD v2 config, what does each playbook do, and what are the minimum required variables?

**Pending items:**
- Required playbook list (provision.yml, destroy.yml, stop.yml, start.yml, status.yml)
- Mandatory variables
- `default_vars` file conventions
- Directory layout requirements

**Context:** This will complete the "Creating a Config" section of the skill.

---

## RQ-3: Workload Role Anatomy

**Question:** What files are required in a new `ocp4_workload_*` role, what is the purpose of each task file, and how does the `ocp4_workload_example` template demonstrate the correct structure?

**Pending items:**
- Required files (tasks/workload.yml, tasks/main.yml, defaults/main.yml, meta/main.yml)
- Variable naming prefix conventions
- `ocp4_workload_example` reference implementation walkthrough

**Context:** This will complete the "Creating a Workload Role" section of the skill.

---

## RQ-4: agnosticd_user_info Module

**Question:** How does the `agnosticd_user_info` Ansible module work, what format does it expect, how does data flow to RHDP and students, and how does it connect to Showroom Antora attributes?

**Pending items:**
- Module signature and required keys
- RHDP-expected output fields
- Student credential patterns
- Connection to openshift_cluster_ingress_domain and Showroom antora.yml attributes

**Context:** This will complete the "Reporting Deployment Info" section of the skill.

---

## RQ-5: Stop/Start/Status Lifecycle Playbooks

**Question:** What Ansible playbooks and variables does a config need to support `agd stop`, `agd start`, and `agd status`, and what does RHDP expect these lifecycle operations to do for an AWS-based OpenShift cluster?

**Pending items:**
- Playbook names and locations for stop/start/status
- AWS EC2 instance stop vs cluster stop semantics
- Variables that control lifecycle behavior
- RHDP cost-management requirements

**Context:** This will complete the lifecycle commands section of the skill.

---

## RQ-6: Execution Environment Images

**Question:** What execution environment images are available for AgnosticD v2, and what Ansible collections do they include?

**Pending items:**
- Available EE image names and registry locations
- Collection contents per EE image
- Recommended EE for different deployment scenarios

**Context:** Referenced in the Best Practices section regarding reproducible deployments.
