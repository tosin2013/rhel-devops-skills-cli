# AgnosticD Refactor Documentation References

This directory will contain documentation fetched from upstream sources once the corresponding research questions are answered.

## Planned Documents

| File | Description | Source | Research Question |
|------|-------------|--------|-------------------|
| `setup.adoc` | Development environment setup — pre-flight requirements per platform | [agnosticd/agnosticd-v2](https://github.com/agnosticd/agnosticd-v2) `docs/setup.adoc` | RQ-1 |
| `conversion_guide.adoc` | Migrating configs from AgnosticD v1 to v2 — config file anatomy | [agnosticd/agnosticd-v2](https://github.com/agnosticd/agnosticd-v2) `docs/conversion_guide.adoc` | RQ-2 |
| `ocp4_workload_example.md` | Reference implementation for new workload roles — required files and structure | [agnosticd/core_workloads](https://github.com/agnosticd/core_workloads) `roles/ocp4_workload_example/` | RQ-3 |
| `agnosticd_user_info.md` | `agnosticd_user_info` module — format, required keys, RHDP data flow | To be researched from AgnosticD v2 source | RQ-4 |
| `lifecycle_playbooks.md` | Stop/start/status playbook conventions per cloud provider | To be researched from config examples | RQ-5 |
| `execution_environments.adoc` | Available EE images, contents, custom EE build guide | [agnosticd/agnosticd-v2](https://github.com/agnosticd/agnosticd-v2) `tools/execution_environments/readme.adoc` | RQ-6 |
| `multi_user_patterns.md` | Per-student namespace, RBAC, and credential conventions | To be researched from config examples | RQ-7 |

## Currently Available References

The **agnosticd** skill's `references/` directory contains fetched documents that partially cover some of these topics:

- `setup.adoc` — platform prerequisites and common setup steps (covers RQ-1 partially)
- `contributing.adoc` — YAML code quality rules, variable naming conventions (covers audit area 8)
- `git-style-guide.adoc` — branch naming and PR conventions
- `core-workloads-catalog.md` — catalog of all 35 `agnosticd.core_workloads` roles

See the **agnosticd** skill for links to these documents.

## Source Repository

- **Upstream**: https://github.com/agnosticd/agnosticd-v2
- **Core Workloads**: https://github.com/agnosticd/core_workloads
- **To be fetched**: At research completion via `./install.sh --update agnosticd-refactor`

## Updating

```bash
./install.sh --update agnosticd-refactor
```
