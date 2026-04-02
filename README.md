# rhel-devops-skills-cli

A centralized installer for AI assistant skills (Claude Code and Cursor IDE) providing deep knowledge for RHEL DevOps tooling — AgnosticD v2, Field-Sourced Content Template, Showroom, and Patternizer.

## Supported Skills

| Skill | Description | Source |
|-------|-------------|--------|
| **agnosticd** | AgnosticD v2 — Ansible Agnostic Deployer for cloud provisioning via `agd` CLI | [agnosticd/agnosticd-v2](https://github.com/agnosticd/agnosticd-v2) |
| **field-sourced-content** | RHDP self-service catalog items via GitOps (Helm/Ansible patterns) | [rhpds/field-sourced-content-template](https://github.com/rhpds/field-sourced-content-template) |
| **patternizer** | Bootstrap Git repos into Validated Patterns for OpenShift | [tosin2013/patternizer](https://github.com/tosin2013/patternizer) |
| **showroom** | RHDP lab guide and terminal system (Antora/AsciiDoc + Helm) | [rhpds/showroom-deployer](https://github.com/rhpds/showroom-deployer) |
| **student-readiness** | Workshop environment readiness checker (student POV) | Self-contained |
| **workshop-tester** | AI-as-student module tester with failure classification | Self-contained |

## Supported Platforms

| Platform | Bash Version | Status |
|----------|-------------|--------|
| RHEL 8 | 4.4 | Supported (minimum) |
| RHEL 9 | 5.1 | Supported |
| RHEL 10 | 5.2.26 | Supported |
| macOS (Homebrew bash) | 5.2+ | Supported (`brew install bash` required) |

Skills use the [Agent Skills open standard](https://agentskills.io/) (`SKILL.md`) and work with both [Claude Code](https://docs.claude.com/) and [Cursor IDE](https://www.cursor.com/).

## Quick Start

```bash
git clone https://github.com/tosin2013/rhel-devops-skills-cli.git
cd rhel-devops-skills-cli
./install.sh install --all
```

## Usage

```bash
./install.sh install --skill agnosticd       # Install one skill
./install.sh install --all                    # Install all skills
./install.sh install --all --ide cursor       # Target specific IDE
./install.sh update --all                     # Update skill docs from upstream
./install.sh check-updates                    # Check for upstream changes
./install.sh verify --all                     # Verify installations
./install.sh list                             # Show installed skills
./install.sh available                        # Show all available skills
./install.sh upgrade-installer                # Self-update the installer
```

## Documentation

- [Getting Started](https://tosin2013.github.io/rhel-devops-skills-cli/getting-started/)
- [Skills Reference](https://tosin2013.github.io/rhel-devops-skills-cli/skills/)
- [CLI Reference](https://tosin2013.github.io/rhel-devops-skills-cli/reference/cli/)
- [Architecture Decision Records](docs/adrs/)
- [Research Documents](docs/research/)
- [GitHub Pages Site](https://tosin2013.github.io/rhel-devops-skills-cli/)

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
| [008](docs/adrs/008-skill-update-strategy.md) | Skill Update Strategy |
| [009](docs/adrs/009-community-skill-contributions.md) | Community Skill Contributions |
| [010](docs/adrs/010-cross-skill-dependencies.md) | Cross-Skill Dependencies |
| [011](docs/adrs/011-e2e-validation-and-troubleshooting.md) | End-to-End Validation and Troubleshooting |
| [012](docs/adrs/012-workshop-module-testing.md) | Workshop Module Testing Strategy |

## Running Tests

```bash
bash tests/run-all.sh
```

## License

See [LICENSE](LICENSE) for details.
