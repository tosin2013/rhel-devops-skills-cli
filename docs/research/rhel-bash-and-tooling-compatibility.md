# RHEL Bash and Tooling Compatibility

**Date**: 2026-03-31
**Category**: platform-research
**Status**: Complete

## Research Question

What bash version and shell tooling is available on RHEL 8 and RHEL 9, and what constraints does this impose on the installer script?

## Background

The PRD specifies a bash shell script-based installer targeting RHEL. This research validates bash version availability, required tool availability, and YAML processing options on RHEL 8 and RHEL 9.

## Methodology

- Reviewed RHEL 8 and RHEL 9 package repositories for bash, git, curl versions
- Tested the current system (RHEL 9 based on `uname -r` output: 5.14.0-570.81.1.el9_6.x86_64)
- Researched YAML processing tools available on RHEL
- Reviewed RHEL compatibility with Claude Code and Cursor IDE

## Key Findings

### Finding 1: Bash Versions on RHEL
- **Description**: RHEL 8 ships bash 4.4; RHEL 9 ships bash 5.1. Both versions support associative arrays, process substitution, and other features needed for a modern installer script. The PRD's requirement of bash >= 4.0 is met by both.
- **Evidence**: RHEL 8 base repo: bash-4.4.x; RHEL 9 base repo: bash-5.1.x
- **Confidence**: High
- **Source**: [Red Hat Package Browser](https://access.redhat.com/downloads/content/package-browser)

### Finding 2: Core Tool Availability
- **Description**: Required tools are available in RHEL base repositories:
  - `git`: Available in AppStream (RHEL 8: 2.39+, RHEL 9: 2.43+)
  - `curl`: Available in BaseOS (both RHEL 8 and 9)
  - `mktemp`, `cp`, `rm`, `chmod`, `mkdir`: coreutils, always present
  - `sed`, `grep`, `awk`: Always present in base install
- **Evidence**: Standard RHEL minimal install includes these tools
- **Confidence**: High
- **Source**: RHEL system package lists

### Finding 3: YAML Processing Options
- **Description**: RHEL does not include a YAML parser in its base install. Options for the registry.yaml file:
  1. **`yq`** (Mike Farah's Go version): Available as a static binary download; not in RHEL repos but easy to fetch
  2. **`python3 -c "import yaml"`**: Python 3 is available on RHEL 8/9, but PyYAML may not be installed by default
  3. **Pure bash parsing**: Possible for simple YAML but fragile and not recommended
  4. **`jq` + JSON registry**: `jq` is available in EPEL; using JSON instead of YAML avoids the YAML parsing problem entirely
- **Evidence**: RHEL repos lack yq; Python 3.9 (RHEL 9) / 3.6 (RHEL 8) available
- **Confidence**: High
- **Source**: RHEL package availability, EPEL repository contents

### Finding 4: Claude Code and Cursor on RHEL
- **Description**: Claude Code (CLI) is installed via npm or direct download and works on Linux including RHEL. Cursor IDE is an Electron app available for Linux (AppImage/deb). Both run on RHEL 9; RHEL 8 may require additional libraries for Cursor's Electron runtime.
- **Evidence**: Claude Code requires Node.js 18+; Cursor provides Linux AppImage
- **Confidence**: Medium
- **Source**: [Claude Code docs](https://docs.claude.com/en/docs/claude-code), Cursor download page

### Finding 5: File Path Conventions
- **Description**: On Linux (RHEL), the skill directories are:
  - Claude Code: `~/.claude/skills/` (home directory hidden folder)
  - Cursor: `~/.cursor/skills/` (home directory hidden folder)
  Both follow XDG-adjacent conventions using hidden directories in $HOME.
- **Evidence**: Consistent with Linux documentation for both tools
- **Confidence**: High
- **Source**: Official documentation for both platforms

### Finding 6: SELinux Considerations
- **Description**: RHEL runs SELinux in enforcing mode by default. The installer script writes to user home directories (`~/.claude/`, `~/.cursor/`), which should be in the `user_home_t` context and not trigger SELinux denials. However, if scripts in `scripts/` need to be executed, they must have appropriate execute permissions and SELinux context.
- **Evidence**: Standard home directory operations are permitted under default SELinux policy
- **Confidence**: Medium
- **Source**: RHEL SELinux documentation

## Implications

### Architectural Impact
- The installer can safely target bash 4.4+ (lowest common denominator: RHEL 8)
- YAML registry parsing requires either bundling yq or switching to JSON format
- SELinux should not be a concern for basic file installation to home directories

### Technology Choices
- Bash 4.4+ as minimum requirement
- Consider JSON registry instead of YAML to avoid yq dependency
- Use `curl` for HTTP fetches; `git` for repository operations
- Avoid Python dependencies for the installer itself

### Risk Assessment
- **Low risk**: Bash and core tools are universally available on RHEL
- **Medium risk**: YAML parsing requires external tool (yq) or format change (JSON)
- **Low risk**: SELinux unlikely to interfere with home directory writes
- **Medium risk**: Cursor IDE availability on RHEL 8 may be limited

## Recommendations

1. Target bash 4.4+ as minimum version (covers RHEL 8+)
2. Use JSON format for the registry file to avoid yq/PyYAML dependency
3. Check for git and curl at runtime and provide clear error messages if missing
4. Include `--check-prereqs` flag to validate the environment
5. Test on both RHEL 8 and RHEL 9 in CI
6. Document SELinux considerations for scripts/ directory execution

## Related ADRs

- ADR-006: Shell Installer Architecture on RHEL

## References

- [Red Hat Enterprise Linux 9 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9)
- [Red Hat Enterprise Linux 8 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8)
- [RHEL 9 Package Browser](https://access.redhat.com/downloads/content/package-browser)
- [yq - Command-line YAML processor](https://github.com/mikefarah/yq)
- [Claude Code Installation](https://docs.claude.com/en/docs/claude-code)
- [Cursor IDE Downloads](https://www.cursor.com/downloads)
