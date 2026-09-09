# Student Readiness — Open Research Questions

Research questions extracted from SKILL.md. Resolve these by consulting upstream AgnosticD documentation, source code, or subject-matter experts.

## RQ-4: agnosticd_user_info Attribute Key Mapping

> What are the exact `agnosticd_user_info` key names that map to Showroom antora.yml attributes, so the content-environment match check can verify all injected values — not just ingress domain?

**Pending items:**
- Full list of attribute keys written by `agnosticd_user_info`
- How they map to `antora.yml` attribute names

**Context:** Referenced in SKILL.md § Content-Environment Match (check #7).

---

## RQ-7: AgnosticD Student Count Variable

> What is the exact AgnosticD variable name that controls the number of student environments provisioned, so the multi-user verification check can verify the deployed count against the configured count?

**Pending items:**
- Variable name for student count (e.g. `ocp4_idm_htpasswd_user_count` or similar)
- How the per-student namespace naming convention is derived from the variable

**Context:** Referenced in SKILL.md § Multi-User Verification (check #9).
