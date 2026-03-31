# rhel-devops-skills-cli

A centralized repository and installation system that enables users to easily install and configure AI assistant skills (for Claude Code and Cursor IDE) providing deep knowledge and assistance for working with RHEL DevOps tooling.

## Supported Skills

| Skill | Description | Source |
|-------|-------------|--------|
| **agnosticd** | AgnosticD v2 catalog item development and deployment automation | [agnosticd-v2](https://github.com/tosin2013/agnosticd-v2) |
| **field-sourced-content** | OpenShift GitOps-based workshop/demo deployment via Field-Sourced Content Template | [field-sourced-content-template](https://github.com/rhpds/field-sourced-content-template) |
| **patternizer** | Kubernetes/OpenShift pattern generation | [patternizer](https://github.com/tosin2013/patternizer) |

## Supported Platforms

| Platform | Bash Version | Status |
|----------|-------------|--------|
| RHEL 8 | 4.4 | Supported (minimum) |
| RHEL 9 | 5.1 | Supported |
| RHEL 10 | 5.2 | Supported |
| macOS (Homebrew bash) | 5.2+ | Supported (`brew install bash` required) |

Skills are installed using the [Agent Skills open standard](https://agentskills.io/) (`SKILL.md`) and work with both [Claude Code](https://docs.claude.com/en/docs/claude-code/slash-commands.md) and [Cursor IDE](https://www.cursor.com/docs/context/skills).

## Quick Start

```bash
git clone https://github.com/tosin2013/rhel-devops-skills-cli.git
cd rhel-devops-skills-cli
./install.sh --skill agnosticd
```

## Documentation

- [Architecture Decision Records](docs/adrs/) -- Design decisions with external research references
- [Research Documents](docs/research/) -- Platform and standards research backing the ADRs
- [Product Requirements Document](PRD.md) -- Full PRD (note: some assumptions superseded by ADRs)
- [GitHub Pages Site](https://tosin2013.github.io/rhel-devops-skills-cli/) -- Online documentation

## Architecture Decisions

| ADR | Title |
|-----|-------|
| [001](docs/adrs/001-adopt-agent-skills-standard.md) | Adopt Agent Skills Open Standard (SKILL.md) |
| [002](docs/adrs/002-target-claude-code-and-cursor.md) | Target Claude Code and Cursor IDE |
| [003](docs/adrs/003-documentation-embedding-strategy.md) | Documentation Embedding via references/ |
| [004](docs/adrs/004-installation-target-paths.md) | Correct Installation Target Paths |
| [005](docs/adrs/005-dual-mode-skills-and-rules.md) | Dual-Mode Installation (Skills + Rules) |
| [006](docs/adrs/006-shell-installer-architecture.md) | Shell Installer Architecture |
| [007](docs/adrs/007-github-pages-documentation-site.md) | GitHub Pages Documentation Site |

## License

See [LICENSE](LICENSE) for details.
