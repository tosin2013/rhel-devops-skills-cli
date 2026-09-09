# Research Questions — AgnosticD Refactor

Open questions that need upstream verification before the corresponding audit areas can be completed.

## RQ-1

**Question:** What environment checks should the LLM run before any `agd` command, and what is the per-platform corrective action when requirements are not met?

**Context:** Audit Area 1 (Environment Pre-flight Compliance). Pending: Python 3.12+ detection per OS, podman presence check, virtualenv existence check, per-platform corrective commands.

**Status:** Open

---

## RQ-2

**Question:** What is the required file structure and playbook set for an AgnosticD v2 config, what does each playbook do, and what are the minimum required variables?

**Context:** Audit Area 2 (Config File Structure). Pending: required playbook list (provision, destroy, stop, start, status), mandatory variables, default_vars file conventions, directory layout requirements.

**Status:** Open

---

## RQ-3

**Question:** What files are required in a new `ocp4_workload_*` role, what is the purpose of each task file, and how does the `ocp4_workload_example` template demonstrate the correct structure?

**Context:** Audit Area 3 (Workload Role Structure). Pending: required files (tasks/workload.yml, tasks/main.yml, defaults/main.yml, meta/main.yml), variable naming prefix conventions, ocp4_workload_example reference implementation walkthrough.

**Status:** Open

---

## RQ-4

**Question:** How does the `agnosticd_user_info` Ansible module work, what format does it expect, how does data flow to RHDP and students, and how does it connect to Showroom Antora attributes?

**Context:** Audit Area 4 (agnosticd_user_info Completeness). Pending: module signature and required keys, RHDP-expected output fields, student credential patterns, connection to openshift_cluster_ingress_domain and Showroom antora.yml attributes.

**Status:** Open

---

## RQ-5

**Question:** What Ansible playbooks and variables does a config need to support `agd stop`, `agd start`, and `agd status`, and what does RHDP expect these lifecycle operations to do for an AWS-based OpenShift cluster?

**Context:** Audit Area 5 (Stop/Start/Status Implementation). Pending: playbook names and locations for stop/start/status, AWS EC2 instance stop vs cluster stop semantics, variables that control lifecycle behavior, RHDP cost-management requirements.

**Status:** Open

---

## RQ-6

**Question:** What execution environment container images does AgnosticD v2 ship, what Ansible collections and Python libraries are included in each, and when would a developer need to build a custom EE?

**Context:** Audit Area 6 (Execution Environment Compliance). Pending: available EE images and their contents, how to specify an EE in a config, when to build a custom EE, where custom EE definitions should live.

**Status:** Open

---

## RQ-7

**Question:** How does AgnosticD v2 provision per-student namespaces, RBAC, and credentials for multi-user workshop environments, and what variables control the number of users and their access?

**Context:** Audit Area 7 (Multi-User Configuration). Pending: per-student namespace creation variables, RBAC configuration, credential generation patterns, number-of-users variable conventions.

**Status:** Open
