# AgnosticD v2 Documentation References

This directory contains documentation fetched from the [AgnosticD v2](https://github.com/agnosticd/agnosticd-v2) repository.

## Available Documents

| File | Description | Source Path |
|------|-------------|-------------|
| `setup.adoc` | Development environment setup guide (RHEL, macOS, Fedora) | `docs/setup.adoc` |
| `contributing.adoc` | Contribution guidelines, PR format, code of conduct | `docs/contributing.adoc` |
| `conversion_guide.adoc` | Guide for converting AgnosticD v1 configs to v2 | `docs/conversion_guide.adoc` |
| `git-style-guide.adoc` | Git commit messages, branch naming, PR conventions | `docs/git-style-guide.adoc` |
| `README.adoc` | Repository overview, getting started, architecture | `README.adoc` |
| `readme.adoc` | Execution environments documentation | `tools/execution_environments/readme.adoc` |
| `core-workloads-catalog.md` | Complete catalog of all 35 core_workloads roles with descriptions and key variables | Local reference (from [agnosticd/core_workloads](https://github.com/agnosticd/core_workloads)) |

## Source Repository

- **Upstream**: https://github.com/agnosticd/agnosticd-v2
- **Fork**: https://github.com/tosin2013/agnosticd-v2
- **Branch**: main
- **Fetched**: At install time via `./install.sh --skill agnosticd`

## Updating

```bash
./install.sh --update agnosticd
```
