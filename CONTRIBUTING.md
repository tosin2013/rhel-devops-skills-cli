# Contributing to rhel-devops-skills-cli

Thank you for your interest in contributing! This project provides AI agent
skills for RHEL DevOps tooling, targeting Claude Code, Cursor IDE, and 40+
tools that support the [Agent Skills open standard](https://agentskills.io/).

## Ways to Contribute

- **Request a new skill** — Open a [New Skill Request](https://github.com/tosin2013/rhel-devops-skills-cli/issues/new?template=new-skill-request.yml) issue
- **Report a bug** — [Open an issue](https://github.com/tosin2013/rhel-devops-skills-cli/issues/new) describing the problem and your platform
- **Improve documentation** — Fix typos, clarify instructions, or add examples
- **Submit a pull request** — Fork the repo, make changes, and open a PR

For detailed guides see the [Contributing docs](https://tosin2013.github.io/rhel-devops-skills-cli/contributing/).

## Quick Start for Development

```bash
git clone https://github.com/tosin2013/rhel-devops-skills-cli.git
cd rhel-devops-skills-cli
bash tests/run-all.sh     # Run the test suite
```

### Prerequisites

- Bash 4.4+ (RHEL 8+, macOS via `brew install bash`)
- `git`, `curl`
- `jq` or `python3` (for JSON operations)

## Skill Contribution Process

We use a **curated contribution model**. Community members request skills via
GitHub Issues; maintainers build and validate them. This ensures every skill is
accurate, tested, and based on actual upstream repository content.

1. Open a [New Skill Request](https://github.com/tosin2013/rhel-devops-skills-cli/issues/new?template=new-skill-request.yml) with the source repo URL, documentation paths, and use-case triggers
2. A maintainer reviews the request, clones the source repo, and builds the skill
3. A PR is opened for review with the new skill under `skills/<name>/`
4. Tests must pass on both Ubuntu and macOS CI

### Skill Directory Layout

```
skills/<name>/
├── config.sh              # Source repo URL, branch, doc paths
├── SKILL.md               # Agent skill definition (YAML frontmatter + Markdown)
├── references/
│   └── REFERENCE.md       # Index of available documentation
└── rules/
    └── <name>.mdc         # Optional Cursor-specific rules
```

See the [Agent Skills specification](https://agentskills.io/specification) for
`SKILL.md` format details.

## Pull Request Guidelines

- **One concern per PR** — keep changes focused and reviewable
- **Tests must pass** — run `bash tests/run-all.sh` before submitting
- **ShellCheck clean** — the CI runs ShellCheck on `install.sh` and `lib/`
- **Document architectural changes** — add an ADR in `docs/adrs/` for design decisions
- **Cross-tool testing** — verify skills install correctly to all targets:
  - `~/.claude/skills/` (Claude Code)
  - `~/.cursor/skills/` (Cursor IDE)
  - `~/.agents/skills/` (cross-tool portable path)

## Code Style

- Bash 4.4+ features are permitted (associative arrays, `${var,,}`, etc.)
- Use `set -euo pipefail` in all scripts
- Functions are prefixed: `_private()` for internal, `public()` for API
- JSON operations use `jq` with `python3` fallback
- All tasks and variables should have descriptive names
- Use `# shellcheck source=` directives for sourced files

## License

By contributing to this project, you agree that your contributions will be
licensed under the [Apache License 2.0](LICENSE).
