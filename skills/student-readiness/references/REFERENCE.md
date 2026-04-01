# Student Readiness — Reference Documentation

This skill is self-contained (no upstream repository). The checklist and diagnostic process are defined in `SKILL.md`.

## Complementary RHDP Skills Marketplace Tools

For deeper validation beyond the student readiness checklist, use these tools from the [RHDP Skills Marketplace](https://rhpds.github.io/rhdp-skills-marketplace/):

| Tool | Purpose | Setup Guide |
|------|---------|-------------|
| `/health:deployment-validator` | Create Ansible validation roles for infrastructure health checks | [Deployment Validator](https://rhpds.github.io/rhdp-skills-marketplace/skills/deployment-health-checker.html) |
| `/showroom:verify-content` | Validate Showroom content quality and Red Hat standards | [Verify Content](https://rhpds.github.io/rhdp-skills-marketplace/skills/verify-content.html) |
| `/agnosticv:validator` | Validate AgnosticV catalog configurations | [AgnosticV Validator](https://rhpds.github.io/rhdp-skills-marketplace/skills/agnosticv-validator.html) |
| `/ftl:rhdp-lab-validator` | Generate Solve/Validate button automation for labs | [Lab Validator](https://rhpds.github.io/rhdp-skills-marketplace/skills/rhdp-lab-validator.html) |

## Marketplace Setup

To install the RHDP Skills Marketplace in Claude Code:

```bash
# In Claude Code chat
/plugin marketplace add rhpds/rhdp-skills-marketplace
/plugin install showroom@rhdp-marketplace
/plugin install health@rhdp-marketplace
```

See the [full setup guide](https://rhpds.github.io/rhdp-skills-marketplace/setup/claude-code.html) for details.
