# RQ Registry

Current open research questions and the skills they affect:

| RQ | Description | Primary source | Affected skills |
|----|-------------|----------------|-----------------|
| RQ-1 | Pre-flight checks: Python 3.12+, podman, subuid/subgid detection and per-platform corrective actions | agnosticd-v2 README / setup scripts | `agnosticd`, `agnosticd-refactor` |
| RQ-2 | Config 5-stage anatomy: required playbook filenames, mandatory variables, default_vars conventions | agnosticd-v2 `ansible/configs/` examples | `agnosticd`, `agnosticd-refactor` |
| RQ-3 | Workload role structure: required files, task file purposes, ocp4_workload_example walkthrough | agnosticd-v2 `ansible/roles/ocp4_workload_example/` | `agnosticd`, `agnosticd-refactor` |
| RQ-4 | agnosticd_user_info pipeline: module signature, required keys, data flow to RHDP and Showroom antora.yml | agnosticd-v2 action_plugins or library | `agnosticd`, `agnosticd-refactor`, `showroom`, `student-readiness`, `field-sourced-content` |
| RQ-5 | Stop/start/status lifecycle: playbook names and locations, AWS EC2 stop semantics, RHDP cost-management requirements | agnosticd-v2 `ansible/configs/` stop/start examples | `agnosticd`, `agnosticd-refactor`, `student-readiness` |
| RQ-6 | Execution Environments: available EE images, their Ansible collection contents, when to build custom | agnosticd-v2 `execution-environments/` | `agnosticd`, `agnosticd-refactor` |
| RQ-7 | Multi-user configuration: per-student namespace variables, RBAC loop patterns, expected student count variable | agnosticd-v2 `ansible/roles/ocp4_idm_*/` or similar | `agnosticd`, `agnosticd-refactor`, `showroom`, `student-readiness` |
| VP RQ-1 | Values file completeness: `main.clusterGroupName` routing, three mandatory blocks | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| VP RQ-2 | Operator subscription discovery: catalog sources, `oc get packagemanifests` workflow | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| VP RQ-3 | Charts directory structure: Helm minimum anatomy, ArgoCD Application CR mapping | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| VP RQ-4 | Secrets model: `--with-secrets`, Vault+ESO flow, `values-secret.yaml` location | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| VP RQ-5 | VP Operator compatibility: CLI vs Operator comparison, three Operator form fields | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| VP RQ-6 | `pattern-metadata.yaml` schema: exact field names (purpose and location known) | upstream reference patterns — **PARTIAL** | `vp-refactor` |
| VP RQ-8 | Imperative jobs: CronJob model, YAML list requirement, idempotency, scheduling | validatedpatterns.io — **RESOLVED** | `vp-refactor` |
| RQ-HUB-1 | Hub cluster config: what AgnosticD config pattern provisions a Showroom-only hub while N student clusters are provisioned separately | agnosticd-v2 `ansible/configs/` — look for `ocp4-hub`, `ocp4-shared`, or similar | `agnosticd-hub-student` |
| RQ-HUB-2 | Showroom cross-cluster terminal: how `ocp4_workload_showroom` or its Helm chart targets a different cluster API URL per student | agnosticd-v2 `ansible/roles/ocp4_workload_showroom/` and Showroom Helm chart | `agnosticd-hub-student`, `showroom` |
| RQ-HUB-3 | Student cluster credentials in `agnosticd_user_info`: which keys carry per-student API URL, kubeconfig, admin password, console URL when the student cluster is separate from the hub | agnosticd-v2 action_plugins — extends RQ-4 | `agnosticd-hub-student`, `agnosticd`, `showroom` |
| RQ-HUB-4 | SNO and compact cluster sizing across AWS, GCP, and Azure: instance types per provider, resource minimums, cost model per student, hub cluster minimum sizing, existing AgnosticD configs (e.g., `ocp4-sno`) | agnosticd-v2 `ansible/configs/ocp4-sno/` or similar; AWS EC2 / GCP Compute / Azure VM sizing docs | `agnosticd-hub-student` |
| RQ-HUB-5 | Hub+student lifecycle: how stop/start/status operates when hub and student clusters are provisioned independently — can student clusters be stopped without stopping the hub? | agnosticd-v2 stop/start playbook patterns — extends RQ-5 | `agnosticd-hub-student` |
| RQ-HUB-6 | Student count variable: what AgnosticD variable controls how many student clusters are provisioned (`num_students`, `student_count`), how the provisioning loop iterates over it, and what the maximum supported count is | agnosticd-v2 `ansible/configs/` student-count examples | `agnosticd-hub-student` |
| RQ-HUB-7 | Cloud provider quota requirements for N student clusters across AWS, GCP, and Azure: exact per-cluster public IP / EIP count, vCPU count, VPC/VNet count, load balancer count, and NAT gateway count for both SNO and compact cluster types; default quota values per provider; and the correct Console / CLI path to request increases on each platform | AWS OCP IPI docs; GCP OCP IPI docs; Azure OCP IPI docs; agnosticd-v2 provider-specific pre-check scripts if present | `agnosticd-hub-student` |
| RQ-HUB-8 | Minimum RHACM `ManagedCluster` CR and import secret YAML for registering a spoke OCP cluster to an ACM hub via the auto-import mechanism, and the Ansible `k8s` wait task for `ManagedClusterConditionAvailable = True` — informs `tasks/workload.yml` in the `ocp4_workload_rhacm_import` role scaffold. **Note:** no upstream RHACM import role exists in agnosticd/agnosticd-v2 (confirmed); this role must be built in the developer's own fork. | RHACM docs — ManagedCluster API; ACM GitHub examples; `open-cluster-management` API reference | `agnosticd-hub-student`, `agnosticd` |
| VP-SUB-1 | Exact required fields for `pattern-metadata.yaml` at Community tier — field names, types, and which are mandatory vs. optional per current validatedpatterns.io schema | validatedpatterns/docs `content/` and validatedpatterns/common repo | `vp-submission`, `vp-refactor` |
| VP-SUB-2 | CI/CD requirements for Tested tier — accepted pipeline platforms, what the convergence check must cover, OCP version matrix format, and whether an official VP CI template exists | validatedpatterns/docs `AGENTS.md`, `.github/workflows/`, validatedpatterns/common | `vp-submission` |
| VP-SUB-3 | Maintained tier requirements — SLA values, what qualifies as Red Hat involvement, how the VP team verifies maintainer activity, and whether RHDP team ownership counts | validatedpatterns/docs contributor guidelines, OWNERS file | `vp-submission` |
| VP-SUB-4 | validatedpatterns/docs content structure — directory layout for pattern pages, Hugo frontmatter schema, tier badge syntax, and what a merged pattern page looks like | validatedpatterns/docs `archetypes/`, `content/patterns/` examples | `vp-submission` |
| VP-SUB-5 | PR reviewer expectations and merge criteria — what the VP team checks during review, whether a demo or recording is required, and typical review timeline | validatedpatterns/docs CONTRIBUTING.md, OWNERS, recent merged PRs | `vp-submission` |

## Quick Scan

To check which RQs are still open at any time:
```bash
grep -r "RESEARCH NEEDED" skills/*/SKILL.md
```
