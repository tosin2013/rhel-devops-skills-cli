---
title: Contributing
nav_order: 6
has_children: true
---

# Contributing

Help improve the RHEL DevOps Skills CLI by requesting new skills, reporting issues, or contributing code.

> **Quick reference**: See the root [CONTRIBUTING.md](https://github.com/tosin2013/rhel-devops-skills-cli/blob/main/CONTRIBUTING.md) for a concise getting-started guide.

## Ways to Contribute

1. **Request a new skill** -- Open a GitHub Issue using the [New Skill Request template](https://github.com/tosin2013/rhel-devops-skills-cli/issues/new?template=new-skill-request.yml)
2. **Report a bug** -- [Open an issue](https://github.com/tosin2013/rhel-devops-skills-cli/issues/new) describing the problem
3. **Improve documentation** -- Every page has an "Edit this page on GitHub" link at the bottom
4. **Submit a pull request** -- Fork the repo, make changes, and open a PR

## Cross-Tool Testing

When contributing skills or installer changes, verify that installations work across all supported targets:

| Target | Path | Command |
|--------|------|---------|
| Claude Code | `~/.claude/skills/<name>/` | `./install.sh install --skill <name> --ide claude` |
| Cursor IDE | `~/.cursor/skills/<name>/` | `./install.sh install --skill <name> --ide cursor` |
| Cross-tool portable | `~/.agents/skills/<name>/` | `./install.sh install --skill <name> --ide agents` |
| All targets | All of the above | `./install.sh install --skill <name> --ide all` |

The `agents` target uses the [Agent Skills open standard](https://agentskills.io/) portable path (`~/.agents/skills/`), which is read by Cursor, Codex, Goose, Gemini CLI, and 40+ other compatible tools.

## In This Section

- **[Requesting a New Skill](new-skill.html)** -- How the curated contribution model works: submit an issue, a maintainer builds and validates the skill
- **[Development Guide](development.html)** -- Repository structure, running tests, design decisions, and code style conventions
