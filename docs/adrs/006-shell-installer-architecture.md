# ADR-006: Shell Installer Architecture on RHEL

* Status: accepted
* Date: 2026-03-31
* Deciders: Architecture Team
* Research: [RHEL Bash and Tooling Compatibility](../research/rhel-bash-and-tooling-compatibility.md)

## Context and Problem Statement

The PRD specifies a bash shell script-based installer targeting RHEL systems. Several technical decisions need to be made regarding bash version requirements, YAML/JSON tooling for the registry, dependency management, and RHEL-specific considerations (SELinux, package availability).

The current system is RHEL 9 (kernel 5.14.0-570.81.1.el9_6.x86_64). RHEL 8 ships bash 4.4; RHEL 9 ships bash 5.1. The PRD proposes a YAML registry file, but RHEL does not include a YAML parser in its base install.

What bash version, tooling, and registry format should the installer use?

## Decision Drivers

* RHEL 8 ships bash 4.4; RHEL 9 ships bash 5.1 (both >= 4.0 requirement in PRD)
* RHEL base install includes git, curl, coreutils, sed, grep, awk
* RHEL does NOT include a YAML parser (no yq, PyYAML may not be installed)
* Minimizing external dependencies improves portability and user experience
* The registry tracks installed skills, versions, paths, and metadata
* JSON can be parsed with `jq` (available in EPEL) or Python's built-in `json` module
* SELinux enforcing mode is default on RHEL; home directory writes are permitted

## Considered Options

### Registry Format
1. **JSON registry with jq** -- JSON format, parse with jq (EPEL) or Python json
2. **YAML registry with yq** -- YAML format as PRD proposes, requires yq download
3. **YAML registry with Python** -- YAML format, parse with python3 + PyYAML
4. **Plain text/ini registry** -- Simple key-value format, no external parser

### Bash Version
1. **Bash 4.4+** -- Minimum for RHEL 8 (lowest common denominator)
2. **Bash 5.0+** -- Requires RHEL 9+ only
3. **POSIX sh** -- Maximum portability but fewer features

## Decision Outcome

### Registry Format

Chosen option: **"JSON registry with jq fallback to Python json"**, because JSON avoids the YAML parser dependency, `jq` is widely available, and Python 3's built-in `json` module provides a zero-install fallback on RHEL.

```bash
# Primary: use jq if available
if command -v jq &>/dev/null; then
    parse_registry() { jq "$@" "$REGISTRY_FILE"; }
# Fallback: use Python 3 json module (always available on RHEL 8/9)
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

Chosen option: **"Bash 4.4+"**, because it covers both RHEL 8 and RHEL 9, supports associative arrays and other modern features needed for the installer.

### Dependency Strategy

Required dependencies (checked at startup):
- `bash` >= 4.4
- `git` (for repository cloning/fetching)
- `curl` (for HTTP API calls and downloads)

Optional dependencies (with fallbacks):
- `jq` (JSON parsing; falls back to `python3 -c "import json"`)
- `python3` (fallback JSON parsing; available on RHEL 8/9 base install)

### Error Handling

```bash
check_prerequisites() {
    local missing=()
    command -v git &>/dev/null || missing+=("git")
    command -v curl &>/dev/null || missing+=("curl")
    
    if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
        missing+=("jq or python3 (for JSON parsing)")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing required tools: ${missing[*]}"
        echo "Install with: sudo dnf install ${missing[*]}"
        exit 3
    fi
}
```

### Positive Consequences

* JSON registry avoids external YAML parser dependency
* `jq` + `python3` fallback covers virtually all RHEL installations
* Bash 4.4+ covers both RHEL 8 and RHEL 9
* Minimal dependency footprint (git, curl are almost always installed)
* SELinux does not interfere with home directory skill installation
* Registry format is easily parseable by other tools (web dashboards, CI scripts)

### Negative Consequences

* JSON is less human-readable than YAML for the registry file (mitigated by `jq` pretty-printing)
* Deviates from PRD's YAML registry proposal
* `jq` may need installation from EPEL (`sudo dnf install jq`)
* Python 3 fallback is slower than native `jq` for large registries

## Links

* [Red Hat Enterprise Linux 9 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9)
* [Red Hat Enterprise Linux 8 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8)
* [jq - Command-line JSON processor](https://jqlang.github.io/jq/)
* [yq - Command-line YAML processor](https://github.com/mikefarah/yq)
* [ShellCheck - Shell script analysis](https://www.shellcheck.net/)
* Related: [ADR-001](001-adopt-agent-skills-standard.md), [ADR-004](004-installation-target-paths.md)
* Supersedes: PRD Section 5.3 "Registry File Format" (YAML proposal)
