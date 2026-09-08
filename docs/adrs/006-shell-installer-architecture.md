---
title: "ADR-006: Shell Installer Architecture"
nav_order: 6
parent: Architecture Decision Records
---

# ADR-006: Shell Installer Architecture on RHEL and macOS

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team
* Research: [RHEL and macOS Bash and Tooling Compatibility](../research/rhel-bash-and-tooling-compatibility.html)

## Context and Problem Statement

The PRD specifies a bash shell script-based installer targeting RHEL systems. Several technical decisions need to be made regarding bash version requirements, YAML/JSON tooling for the registry, dependency management, and platform-specific considerations (SELinux on RHEL, Homebrew on macOS).

RHEL 8 ships bash 4.4; RHEL 9 ships bash 5.1; RHEL 10 (released May 2025) ships bash 5.2.26. macOS ships bash 3.2.57 (frozen due to GPLv3 licensing) but bash 5.2+ is available via Homebrew. The PRD proposes a YAML registry file, but RHEL does not include a YAML parser in its base install.

What bash version, tooling, registry format, and platform support matrix should the installer use?

## Decision Drivers

* RHEL 8 ships bash 4.4; RHEL 9 ships bash 5.1; RHEL 10 ships bash 5.2.26
* macOS ships bash 3.2.57 (GPLv2 frozen); Homebrew provides bash 5.2+
* RHEL base install includes git, curl, coreutils, sed, grep, awk
* macOS provides git (via Xcode CLT), curl (built-in); jq and bash 5.x via Homebrew
* RHEL does NOT include a YAML parser (no yq, PyYAML may not be installed)
* Minimizing external dependencies improves portability and user experience
* The registry tracks installed skills, versions, paths, and metadata
* JSON can be parsed with `jq` (available in EPEL/Homebrew) or Python's built-in `json` module
* SELinux enforcing mode is default on RHEL; home directory writes are permitted
* Skill paths (`~/.claude/skills/`, `~/.cursor/skills/`) are identical on Linux and macOS

## Considered Options

### Registry Format
1. **JSON registry with jq** -- JSON format, parse with jq (EPEL/Homebrew) or Python json
2. **YAML registry with yq** -- YAML format as PRD proposes, requires yq download
3. **YAML registry with Python** -- YAML format, parse with python3 + PyYAML
4. **Plain text/ini registry** -- Simple key-value format, no external parser

### Bash Version
1. **Bash 4.4+** -- Minimum for RHEL 8 (lowest common denominator across supported RHEL)
2. **Bash 5.0+** -- Requires RHEL 9+ only
3. **POSIX sh** -- Maximum portability but fewer features

## Decision Outcome

### Platform Support Matrix

| Platform | Bash Version | Status |
|----------|-------------|--------|
| RHEL 8 | 4.4 | Supported (minimum) |
| RHEL 9 | 5.1 | Supported |
| RHEL 10 | 5.2.26 | Supported |
| macOS (default) | 3.2.57 | Not supported (bash too old) |
| macOS (Homebrew) | 5.2+ | Supported (`brew install bash` required) |

### Registry Format

Chosen option: **"JSON registry with jq fallback to Python json"**, because JSON avoids the YAML parser dependency, `jq` is widely available, and Python 3's built-in `json` module provides a zero-install fallback on RHEL.

```bash
# Primary: use jq if available
if command -v jq &>/dev/null; then
    parse_registry() { jq "$@" "$REGISTRY_FILE"; }
# Fallback: use Python 3 json module (always available on RHEL 8/9/10)
elif command -v python3 &>/dev/null; then
    parse_registry() { python3 -c "import json,sys; ..." "$REGISTRY_FILE"; }
fi
```

### Registry File Location and Format

```json
{
  "version": "1.0",
  "installer_version": "1.0.0",
  "last_updated": "2026-03-31T10:30:00Z",
  "auto_check_updates": true,
  "installed_skills": [
    {
      "name": "agnosticd",
      "version": "1.0.0",
      "source_repo": "https://github.com/tosin2013/agnosticd-v2",
      "docs_commit_hash": "abc123def456",
      "docs_fetched_date": "2026-03-31T10:30:00Z",
      "installed_date": "2026-03-31T10:30:00Z",
      "installed_to": [
        {"ide": "claude", "path": "~/.claude/skills/agnosticd"},
        {"ide": "cursor", "path": "~/.cursor/skills/agnosticd"}
      ]
    }
  ]
}
```

### Bash Version

Chosen option: **"Bash 4.4+"**, because it covers RHEL 8, 9, and 10, and macOS with Homebrew bash. It supports associative arrays and other modern features needed for the installer.

### Dependency Strategy

Required dependencies (checked at startup):
- `bash` >= 4.4
- `git` (for repository cloning/fetching)
- `curl` (for HTTP API calls and downloads)

Optional dependencies (with fallbacks):
- `jq` (JSON parsing; falls back to `python3 -c "import json"`)
- `python3` (fallback JSON parsing; available on RHEL 8/9/10 base install and macOS)

### Error Handling

```bash
check_prerequisites() {
    local missing=()
    local os_type
    os_type="$(uname -s)"

    command -v git &>/dev/null || missing+=("git")
    command -v curl &>/dev/null || missing+=("curl")

    if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
        missing+=("jq or python3 (for JSON parsing)")
    fi

    local bash_major bash_minor
    bash_major="${BASH_VERSINFO[0]}"
    bash_minor="${BASH_VERSINFO[1]}"
    if (( bash_major < 4 || (bash_major == 4 && bash_minor < 4) )); then
        if [[ "$os_type" == "Darwin" ]]; then
            echo "ERROR: bash ${BASH_VERSION} is too old (need 4.4+)."
            echo "Install with: brew install bash"
            echo "Then re-run with: /opt/homebrew/bin/bash install.sh ..."
        else
            echo "ERROR: bash ${BASH_VERSION} is too old (need 4.4+)."
            echo "Install with: sudo dnf install bash"
        fi
        exit 3
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing required tools: ${missing[*]}"
        if [[ "$os_type" == "Darwin" ]]; then
            echo "Install with: brew install ${missing[*]}"
        else
            echo "Install with: sudo dnf install ${missing[*]}"
        fi
        exit 3
    fi
}
```

### Positive Consequences

* JSON registry avoids external YAML parser dependency
* `jq` + `python3` fallback covers virtually all RHEL and macOS installations
* Bash 4.4+ covers RHEL 8, 9, 10, and macOS with Homebrew bash
* Minimal dependency footprint (git, curl are almost always installed)
* SELinux does not interfere with home directory skill installation on RHEL
* Skill paths are identical across Linux and macOS -- no platform-specific path logic needed
* Registry format is easily parseable by other tools (web dashboards, CI scripts)
* Platform detection (`uname -s`) provides appropriate install instructions

### Negative Consequences

* JSON is less human-readable than YAML for the registry file (mitigated by `jq` pretty-printing)
* Deviates from PRD's YAML registry proposal
* `jq` may need installation from EPEL on RHEL (`sudo dnf install jq`) or Homebrew on macOS (`brew install jq`)
* Python 3 fallback is slower than native `jq` for large registries
* macOS users must install Homebrew bash before running the installer -- additional friction
* macOS default bash (3.2) cannot run the installer; clear error messaging is critical

## Links

* [Red Hat Enterprise Linux 10 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10)
* [RHEL 10 Release Notes](https://linuxiac.com/red-hat-enterprise-linux-10-released)
* [RHEL 10 Package Manifest](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/package_manifest/repositories)
* [RHEL Release Dates](https://access.redhat.com/articles/3078)
* [Red Hat Enterprise Linux 9 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9)
* [Red Hat Enterprise Linux 8 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8)
* [jq - Command-line JSON processor](https://jqlang.github.io/jq/)
* [yq - Command-line YAML processor](https://github.com/mikefarah/yq)
* [ShellCheck - Shell script analysis](https://www.shellcheck.net/)
* [macOS Bash Version Constraints](https://thelinuxcode.com/change-default-shell-from-zsh-to-bash-mac/)
* [Homebrew](https://brew.sh/)
* [Claude Code macOS Install Guide](https://dev.to/xujfcn/claude-code-installation-guide-for-macos-git-environment-variables-path-and-every-common-fix-4l96)
* Related: [ADR-001](001-adopt-agent-skills-standard.html), [ADR-004](004-installation-target-paths.html)
* Supersedes: PRD Section 5.3 "Registry File Format" (YAML proposal)
