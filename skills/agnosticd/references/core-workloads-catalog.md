# AgnosticD Core Workloads Catalog

The [agnosticd.core_workloads](https://github.com/agnosticd/core_workloads) Ansible collection provides reusable roles that can be added to the `workloads:` or `infra_workloads:` lists in AgnosticD v2 configuration files.

**Source**: https://github.com/agnosticd/core_workloads (Ansible collection `agnosticd.core_workloads` v1.0.0)

## Usage

Add workloads to your config variables file:

```yaml
workloads:
  - agnosticd.core_workloads.ocp4_workload_cert_manager
  - agnosticd.core_workloads.ocp4_workload_openshift_gitops

infra_workloads:
  - ocp4_workload_showroom  # deploy last
```

## Available Workloads

### Infrastructure & Platform

| Role | Description | Key Variables |
|------|-------------|---------------|
| `ocp4_workload_authentication` | Configure OpenShift authentication (generic) | |
| `ocp4_workload_authentication_htpasswd` | htpasswd identity provider | |
| `ocp4_workload_authentication_keycloak` | Keycloak identity provider | |
| `ocp4_workload_authentication_rhsso` | Red Hat SSO identity provider | |
| `ocp4_workload_cert_manager` | Install cert-manager operator with Let's Encrypt | `ocp4_workload_cert_manager_channel`, `ocp4_workload_cert_manager_aws_region` |
| `ocp4_workload_machinesets` | Configure MachineSets for worker nodes | |
| `ocp4_workload_metallb` | Install MetalLB load balancer | |
| `ocp4_workload_nfd` | Node Feature Discovery operator | |
| `ocp4_workload_nmstate` | NMState network configuration operator | |

### Developer Tools

| Role | Description | Key Variables |
|------|-------------|---------------|
| `ocp4_workload_builds` | OpenShift Builds (Shipwright) | |
| `ocp4_workload_devspaces` | Red Hat OpenShift Dev Spaces | |
| `ocp4_workload_gitea_operator` | Gitea Git server operator | |
| `ocp4_workload_gitlab` | GitLab on OpenShift | |
| `ocp4_workload_openshift_gitops` | OpenShift GitOps (ArgoCD) operator | |
| `ocp4_workload_gitops_bootstrap` | Bootstrap ArgoCD applications | |
| `ocp4_workload_pipelines` | OpenShift Pipelines (Tekton) | |
| `ocp4_workload_web_terminal` | Web Terminal operator | |

### Middleware & Services

| Role | Description | Key Variables |
|------|-------------|---------------|
| `ocp4_workload_amq_streams` | AMQ Streams (Apache Kafka) operator | |
| `ocp4_workload_authorino` | Authorino API authorization | |
| `ocp4_workload_kiali` | Kiali service mesh observability | |
| `ocp4_workload_minio` | MinIO object storage | |
| `ocp4_workload_serverless` | OpenShift Serverless (Knative) | |
| `ocp4_workload_servicemesh2` | Service Mesh 2.x (Istio-based) | |
| `ocp4_workload_servicemesh3` | Service Mesh 3.x | |

### Storage & Virtualization

| Role | Description | Key Variables |
|------|-------------|---------------|
| `ocp4_workload_cnv_extra_disks` | Extra disks for CNV virtual machines | |
| `ocp4_workload_external_odf` | External OpenShift Data Foundation | |
| `ocp4_workload_openshift_data_foundation` | OpenShift Data Foundation (Ceph) operator | |
| `ocp4_workload_openshift_virtualization` | OpenShift Virtualization (KubeVirt) | |
| `ocp4_workload_virt_network_config` | Virtual network configuration for CNV | |
| `ocp4_workload_mtv` | Migration Toolkit for Virtualization | |

### Platform Management & Security

| Role | Description | Key Variables |
|------|-------------|---------------|
| `ocp4_workload_connectivity_link` | Connectivity Link | |
| `ocp4_workload_quay_operator` | Quay container registry operator | |
| `ocp4_workload_rhacm` | Red Hat Advanced Cluster Management | |
| `ocp4_workload_rhacs` | Red Hat Advanced Cluster Security (StackRox) | |
| `ocp4_workload_ansible_automation_platform` | Ansible Automation Platform on OpenShift | |
| `ocp4_workload_s4` | S4 workload | |

### Demo & Content

| Role | Description | Key Variables |
|------|-------------|---------------|
| `ocp4_workload_field_content` | Deploy Field-Sourced Content via ArgoCD | `ocp4_workload_field_content_gitops_repo_url` |
| `ocp4_workload_showroom` | Deploy Showroom lab guide + terminal | `ocp4_workload_showroom_content_git_repo`, `ocp4_workload_showroom_terminal_type` |

### Template

| Role | Description |
|------|-------------|
| `ocp4_workload_example` | Reference implementation for creating new workload roles |
