# Project Onboard Skill — Reference Documentation

This skill is self-contained (no upstream repository). The onboarding workflow
is defined in `SKILL.md`. Reference files provide the manifest schema, hardening
guidance, and a working example.

## Reference Files

| File | Description |
|------|-------------|
| `manifest-spec.md` | Full `onboard.yml` schema specification — field-by-field documentation for all manifest sections (prerequisites, setup steps, config prompts, validation, post-setup, modes) |
| `deploy-hardening.md` | Best practices for consuming projects' `deploy.sh` scripts — cross-platform sed, SSH retry, config reading, error handling, and common issue reference |
| `example-manifest.yml` | Complete working `onboard.yml` for the acm-virt-management-demo project — ready to copy and adapt for new projects |
| `bootstrap-template.md` | Runtime bash script template for generating `bootstrap.sh` — reads `onboard.yml` via python3+PyYAML at execution time, with readiness gating |
| `agents-template.md` | `AGENTS.md` template for consuming projects — condensed onboard phases so any AI agent can walk users through `onboard.yml` without the skill installed |

## Usage

- When onboarding a user to an existing project, follow `SKILL.md` phases 0-6
- When helping a user create an `onboard.yml` for a new project, use `manifest-spec.md` for the schema and `example-manifest.yml` as a starting template
- When generating a `bootstrap.sh` for a project, use `bootstrap-template.md` for the runtime script template
- When generating an `AGENTS.md` for a project, use `agents-template.md` for the AI instruction template
- When reviewing or improving a project's `deploy.sh`, reference `deploy-hardening.md` for common issues and fixes
