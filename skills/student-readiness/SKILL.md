---
name: student-readiness
description: AI assistance for verifying that a deployed workshop or demo environment is ready for students. Use when a developer provides OpenShift credentials or bastion access and asks whether students can start the lab. Adapts to OCP, RHEL VM, AAP, and hybrid AgnosticD environments.
related_skills: [agnosticd, showroom, field-sourced-content, workshop-tester]
---

# Student Readiness Skill

## When to Use

- Developer asks "is my environment ready for students?"
- Pre-training or pre-demo readiness verification
- Multi-user environment provisioning validation
- Validating any AgnosticD-deployed environment for end-user consumption
- Comparing a deployed environment against expected workshop requirements
- Post-deployment smoke test before handing off to participants

## Instructions

This skill defines a diagnostic process, not a tool wrapper. When activated, gather the required input from the user, determine the environment type, then execute the applicable checks using `oc`, `curl`, and/or `ssh`.

## Required Input

Before running checks, collect the following from the user:

| Input | Required | Example |
|-------|----------|---------|
| OpenShift API URL | Yes (OCP) | `https://api.cluster.example.com:6443` |
| Login token or credentials | Yes | `sha256~abc...` or username/password |
| Workshop GUID | Yes | `abc123` |
| Expected environment type | Yes | OCP shared, OCP dedicated, RHEL VM, AAP, hybrid |
| Number of students | If multi-user | `25` |
| Bastion hostname | If RHEL VM or dedicated OCP | `bastion.abc123.example.com` |
| AAP controller URL | If AAP | `https://controller.example.com` |

## Supported Environment Types

Adapt the checklist based on the environment type:

| Type | Description | Primary Access |
|------|-------------|---------------|
| **OCP Shared Tenant** | Students get scoped namespaces on a shared cluster | `oc login` with per-student credentials |
| **OCP Dedicated** | Students have cluster-admin, lab has a bastion VM | `oc login` + SSH to bastion |
| **RHEL VM + Bastion** | Bastion + node VMs, no OpenShift | SSH to bastion |
| **AAP** | Ansible Automation Platform controller + execution environments | AAP API + SSH |
| **Hybrid** | Combination (e.g., OCP cluster + bastion + AAP) | Multiple access methods |

## Readiness Checklist

Run checks in order. Stop at the first failure and report it with the suggested fix.

### 1. Cluster / Host Access

**OCP environments:**
```bash
oc login --server=<API_URL> --token=<TOKEN> --insecure-skip-tls-verify
oc whoami
oc get nodes --no-headers | wc -l
```
- Verify: login succeeds, identity matches expected user/SA, nodes are Ready

**RHEL VM environments:**
```bash
ssh <user>@<bastion_host> whoami
ssh <user>@<bastion_host> uptime
```
- Verify: SSH succeeds, bastion is responsive

### 2. Showroom Accessibility (if deployed)

```bash
SHOWROOM_ROUTE=$(oc get route -n showroom-<GUID> -o jsonpath='{.items[0].spec.host}' 2>/dev/null)
curl -sI "https://${SHOWROOM_ROUTE}" | head -1
curl -s "https://${SHOWROOM_ROUTE}" | grep -c '<title>'
```
- Verify: route exists, HTTP 200, HTML content renders (not blank or error page)

### 3. Terminal Functionality (if deployed)

**Pod-based terminal (type=showroom):**
```bash
oc get pods -n showroom-<GUID> -l app=showroom-terminal --no-headers
```
- Verify: terminal pod is Running

**Wetty terminal (type=wetty):**
```bash
WETTY_ROUTE=$(oc get route -n showroom-<GUID> -l app=wetty -o jsonpath='{.items[0].spec.host}' 2>/dev/null)
curl -sI "https://${WETTY_ROUTE}/wetty" | head -1
```
- Verify: Wetty route exists and returns HTTP 200

### 4. Operators Ready (OCP environments)

```bash
oc get csv -A --no-headers | grep -v Succeeded
```
- Verify: all ClusterServiceVersions are in "Succeeded" phase (no failures or pending installs)

### 5. Namespaces and RBAC (OCP environments)

```bash
oc get namespaces | grep <expected_namespace_pattern>
oc auth can-i --list -n <student_namespace> --as=<student_user>
```
- Verify: expected namespaces exist, student users have expected permissions (create pods, get routes, etc.)

### 6. Workload Resources

```bash
oc get deployments -n <namespace> --no-headers
oc get pods -n <namespace> --no-headers | grep -v Running
oc get routes -n <namespace> --no-headers
```
- Verify: expected deployments exist, all pods are Running, routes resolve

### 7. Content-Environment Match

Compare Showroom content attributes against actual cluster values:
```bash
oc get ingresses.config/cluster -o jsonpath='{.spec.domain}'
```
- Verify: the `openshift_cluster_ingress_domain` in Showroom's `antora.yml` attributes matches the actual cluster ingress domain

### 8. AAP Readiness (if applicable)

```bash
curl -sk "https://<AAP_CONTROLLER>/api/v2/ping/"
curl -sk -H "Authorization: Bearer <TOKEN>" "https://<AAP_CONTROLLER>/api/v2/projects/" | python3 -c "import sys,json; print(json.load(sys.stdin)['count'])"
```
- Verify: controller API is reachable, expected projects/templates exist, execution environments are available

### 9. Multi-User Verification (if applicable)

For N students, verify isolation:
```bash
for i in $(seq 1 $N); do
  oc get namespace "student-${i}-<GUID>" --no-headers 2>/dev/null && echo "student-${i}: OK" || echo "student-${i}: MISSING"
done
```
- Verify: all N student environments are provisioned with correct namespace isolation

## Output Format

Present results as a pass/fail table:

```
Student Readiness Report — GUID: abc123
──────────────────────────────────────────────
 #  Check                       Status  Notes
 1  Cluster Access              PASS    3 nodes Ready
 2  Showroom Accessible         PASS    HTTP 200, content renders
 3  Terminal Functional         PASS    Terminal pod Running
 4  Operators Ready             FAIL    openshift-gitops CSV pending
 5  Namespaces & RBAC           PASS    25 student namespaces
 6  Workload Resources          PASS    All pods Running
 7  Content-Environment Match   PASS    Ingress domain matches
 8  Multi-User Isolation        PASS    25/25 environments ready
──────────────────────────────────────────────
 Result: NOT READY — fix check #4 before proceeding
```

## Escalation

When checks fail and the cause is not obvious:

1. **AgnosticD deployment failure** -> See the **agnosticd** skill troubleshooting section
2. **Showroom rendering/terminal issue** -> See the **showroom** skill troubleshooting section
3. **Infrastructure health** -> Use `/health:deployment-validator` from the [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/)
4. **Content quality** -> Use `/showroom:verify-content` from the RHDP Skills Marketplace

## Best Practices

- Run readiness checks after `agd provision` completes, before notifying students
- For multi-user workshops, verify at least 3 student environments (first, middle, last)
- Save the readiness report output for post-training review
- If using the RHDP catalog, readiness checks should run after the catalog item's provisioning callback completes
- Re-run checks if the environment was stopped and restarted (`agd stop` / `agd start`)
