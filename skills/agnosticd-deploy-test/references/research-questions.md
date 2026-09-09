# Research Questions — AgnosticD Deploy Test

Open questions that need upstream verification before the corresponding skill sections can be completed.

## RQ-4

**Question:** What exact output format and keys does `agnosticd_user_info` produce, and where in the output directory is it written?

**Context:** Phase 3b (Post-deploy Validation) needs to verify that `agnosticd_user_info` data was written correctly. The exact file path in `agnosticd-v2-output/<guid>/` and the expected key names (e.g., `openshift_console_url`, `openshift_cluster_admin_password`) need to be confirmed from the AgnosticD v2 source.

**Status:** Open

---

## RQ-5

**Question:** What are the exact playbook names and locations for stop/start/status lifecycle operations, and what does each return for AWS EC2 environments?

**Context:** Phase 4 (Lifecycle Test) needs to verify stop/start/status operations. The exact playbook names (`stop.yml`, `start.yml`, `status.yml`?), their location within the config directory, and the expected return codes and output format per cloud provider need to be confirmed.

**Status:** Open
