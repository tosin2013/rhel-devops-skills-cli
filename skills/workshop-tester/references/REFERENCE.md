# Workshop Tester — Reference Documentation

This skill is self-contained (no upstream repository). The testing process, failure classification, and reporting format are defined in `SKILL.md`.

## Showroom AsciiDoc Conventions

Workshop content authored for Showroom uses AsciiDoc attributes to mark executable steps:

| Attribute | Meaning | AI Action |
|-----------|---------|-----------|
| `[source,bash,role="execute"]` | Command the student should run | Parse and execute |
| `[source,yaml,role="copypaste"]` | Text the student should copy (not run) | Skip execution, note for context |
| `[source,text]` after "Expected output" | What the student should see | Use as verification target |

See the [Showroom template](https://github.com/rhpds/showroom_template_default) for content structure conventions.

## AsciiDoc Attribute Substitution

Showroom content uses Antora attributes defined in `content/antora.yml`. Common attributes that need substitution against the live environment:

| Attribute | Source |
|-----------|--------|
| `{openshift_cluster_ingress_domain}` | `oc get ingresses.config/cluster -o jsonpath='{.spec.domain}'` |
| `{openshift_api_url}` | Provided by user or from `oc whoami --show-server` |
| `{guid}` | Workshop GUID provided by user |
| `{user}` | Student username (e.g., `user1`) |
| `{password}` | Student password (from environment provisioning output) |

## Complementary RHDP Skills Marketplace Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `/showroom:verify-content` | Content quality (AsciiDoc, Red Hat standards) | Before testing — ensures content is well-formed |
| `/health:deployment-validator` | Infrastructure health (pods, routes, operators) | When Infra / Deployment Fix failures are found |
| `/ftl:rhdp-lab-validator` | Lab grading automation (Solve/Validate buttons) | After testing — generate grading for passing modules |

See the [RHDP Skills Marketplace setup guide](https://rhpds.github.io/rhdp-skills-marketplace/setup/claude-code.html) for installation instructions.

## Related ADRs

- [ADR-012: Workshop Module Testing Strategy](../../docs/adrs/012-workshop-module-testing.md) — design rationale for this skill
- [ADR-011: End-to-End Validation and Troubleshooting](../../docs/adrs/011-e2e-validation-and-troubleshooting.md) — validation lifecycle and student-readiness
- [ADR-010: Cross-Skill Dependencies](../../docs/adrs/010-cross-skill-dependencies.md) — how skills reference each other
