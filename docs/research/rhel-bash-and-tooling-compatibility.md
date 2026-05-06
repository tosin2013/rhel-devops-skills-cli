---
title: RHEL and macOS Compatibility
nav_order: 5
parent: Research Documents
---

# RHEL and macOS Bash and Tooling Compatibility

**Date**: 2026-03-31 (updated 2026-03-31)
**Category**: platform-research
**Status**: Complete

## Research Question

What bash version and shell tooling is available on RHEL 8, RHEL 9, RHEL 10, and macOS, and what constraints does this impose on the installer script?

## Background

The PRD specifies a bash shell script-based installer targeting RHEL. This research validates bash version availability, required tool availability, and YAML processing options across RHEL 8, RHEL 9, RHEL 10, and macOS.

## Methodology

- Reviewed RHEL 8, RHEL 9, and RHEL 10 package repositories for bash, git, curl versions
- Tested the current system (RHEL 9 based on `uname -r` output: 5.14.0-570.81.1.el9_6.x86_64)
- Researched YAML processing tools available on RHEL
- Reviewed RHEL compatibility with Claude Code and Cursor IDE
- Researched macOS default bash version and Homebrew bash availability
- Verified Claude Code and Cursor skill paths on macOS

## Key Findings

### Finding 1: Bash Versions on RHEL
- **Description**: RHEL 8 ships bash 4.4; RHEL 9 ships bash 5.1; RHEL 10 ships bash 5.2.26. All versions support associative arrays, process substitution, and other features needed for a modern installer script. The PRD's requirement of bash >= 4.0 is met by all three.
- **Evidence**: RHEL 8 base repo: bash-4.4.x; RHEL 9 base repo: bash-5.1.x; RHEL 10 base repo: bash-5.2.26-4.el10
- **Confidence**: High
- **Source**: [Red Hat Package Browser](https://access.redhat.com/downloads/content/package-browser), [RHEL 10 Package Manifest](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/package_manifest/repositories)

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
  - Cursor: `~/.cursor/skills-cursor/` (home directory hidden folder)
  Both follow XDG-adjacent conventions using hidden directories in $HOME.
- **Evidence**: Consistent with Linux documentation for both tools
- **Confidence**: High
- **Source**: Official documentation for both platforms

### Finding 6: RHEL 10 Availability
- **Description**: RHEL 10.0 was released on May 20, 2025 with kernel 6.12. RHEL 10.1 followed on November 11, 2025. RHEL 10 ships bash 5.2.26, Python 3.12, and includes git and curl in the BaseOS repository. All existing RHEL 8/9 tooling assumptions hold for RHEL 10.
- **Evidence**: RHEL 10.0 GA: 2025-05-20; RHEL 10.1 GA: 2025-11-11; bash-5.2.26-4.el10 in BaseOS
- **Confidence**: High
- **Source**: [RHEL Release Dates](https://access.redhat.com/articles/3078), [RHEL 10 Release Notes](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10), [RHEL 10 Package Manifest](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/package_manifest/repositories)

### Finding 7: macOS Default Bash Version
- **Description**: macOS ships bash 3.2.57, frozen at this version since 2007 due to Apple's refusal to adopt the GPLv3 license used by bash 4.0+. Since macOS Catalina (2019), zsh is the default shell. The installer's minimum requirement of bash 4.4+ is NOT met by the default macOS bash. Users must install bash 5.x via Homebrew (`brew install bash`), which installs to `/opt/homebrew/bin/bash` (Apple Silicon) or `/usr/local/bin/bash` (Intel).
- **Evidence**: `bash --version` on macOS reports 3.2.57; Homebrew bash installs 5.2+
- **Confidence**: High
- **Source**: [macOS bash version constraints](https://thelinuxcode.com/change-default-shell-from-zsh-to-bash-mac/), [Stack Overflow: macOS bash version](https://stackoverflow.com/questions/56117918/bash-version-reports-old-version-of-bash-on-macos-is-this-a-problem-that-shoul)

### Finding 8: macOS Skill Paths Are Identical to Linux
- **Description**: On macOS, both Claude Code and Cursor IDE use the same home-directory-based skill paths as on Linux:
  - Claude Code: `~/.claude/skills/` (global), `.claude/skills/` (project)
  - Cursor: `~/.cursor/skills-cursor/` (global), `.cursor/skills/` (project)
  There is no `~/Library/Application Support/` variant for skills. Claude Desktop's MCP config on macOS is at `~/Library/Application Support/Claude/claude_desktop_config.json`, but that is unrelated to skills.
- **Evidence**: Official Claude Code and Cursor documentation confirm `~/.claude/` and `~/.cursor/` on all platforms
- **Confidence**: High
- **Source**: [Claude Code .claude directory](https://code.claude.com/docs/en/claude-directory), [Cursor Skills docs](https://www.cursor.com/docs/context/skills)

### Finding 9: macOS Tool Availability
- **Description**: On macOS, `git` is available via Xcode Command Line Tools (`xcode-select --install`) or Homebrew. `curl` ships with macOS. `jq` is available via Homebrew (`brew install jq`). Python 3 is available via Xcode or Homebrew. The installer should detect the platform and provide appropriate install instructions (dnf on RHEL, brew on macOS).
- **Evidence**: macOS includes curl and git (via Xcode CLT); Homebrew provides jq, python3, bash
- **Confidence**: High
- **Source**: [Claude Code macOS install guide](https://dev.to/xujfcn/claude-code-installation-guide-for-macos-git-environment-variables-path-and-every-common-fix-4l96)

### Finding 10: SELinux Considerations
- **Description**: RHEL runs SELinux in enforcing mode by default. The installer script writes to user home directories (`~/.claude/`, `~/.cursor/`), which should be in the `user_home_t` context and not trigger SELinux denials. However, if scripts in `scripts/` need to be executed, they must have appropriate execute permissions and SELinux context.
- **Evidence**: Standard home directory operations are permitted under default SELinux policy
- **Confidence**: Medium
- **Source**: RHEL SELinux documentation

## Implications

### Architectural Impact
- The installer can safely target bash 4.4+ (lowest common denominator: RHEL 8)
- RHEL 10 is fully compatible with no changes needed
- macOS requires Homebrew bash as a prerequisite; the installer must detect the bash version at runtime
- YAML registry parsing requires either bundling yq or switching to JSON format
- SELinux should not be a concern for basic file installation to home directories
- Skill paths (`~/.claude/skills/`, `~/.cursor/skills-cursor/`) are identical across Linux and macOS

### Technology Choices
- Bash 4.4+ as minimum requirement
- Consider JSON registry instead of YAML to avoid yq dependency
- Use `curl` for HTTP fetches; `git` for repository operations
- Avoid Python dependencies for the installer itself
- Platform-aware install instructions (`dnf` on RHEL, `brew` on macOS)

### Risk Assessment
- **Low risk**: Bash and core tools are universally available on RHEL 8/9/10
- **Medium risk**: YAML parsing requires external tool (yq) or format change (JSON)
- **Low risk**: SELinux unlikely to interfere with home directory writes
- **Medium risk**: Cursor IDE availability on RHEL 8 may be limited
- **Medium risk**: macOS users must install Homebrew bash before running the installer

## Platform Support Matrix

| Platform | Bash Version | git | curl | jq | Status |
|----------|-------------|-----|------|----|--------|
| RHEL 8 | 4.4 | AppStream | BaseOS | EPEL | Supported (minimum) |
| RHEL 9 | 5.1 | AppStream | BaseOS | EPEL | Supported |
| RHEL 10 | 5.2.26 | BaseOS | BaseOS | EPEL | Supported |
| macOS (default) | 3.2 | Xcode CLT | Built-in | - | Not supported (bash too old) |
| macOS (Homebrew) | 5.2+ | Xcode/brew | Built-in | brew | Supported |

## Recommendations

1. Target bash 4.4+ as minimum version (covers RHEL 8+ and macOS with Homebrew bash)
2. Use JSON format for the registry file to avoid yq/PyYAML dependency
3. Check for git and curl at runtime and provide clear error messages if missing
4. Include `--check-prereqs` flag to validate the environment
5. Test on RHEL 8, RHEL 9, RHEL 10, and macOS in CI
6. Document SELinux considerations for scripts/ directory execution
7. On macOS, detect bash version and provide `brew install bash` instructions if < 4.4
8. Use platform detection (`uname -s`) to tailor install instructions (dnf vs brew)

## Related ADRs

- ADR-006: Shell Installer Architecture on RHEL

## References

- [Red Hat Enterprise Linux 10 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10)
- [Red Hat Enterprise Linux 10 Release Notes](https://linuxiac.com/red-hat-enterprise-linux-10-released)
- [RHEL 10 Package Manifest](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/package_manifest/repositories)
- [RHEL Release Dates](https://access.redhat.com/articles/3078)
- [Red Hat Enterprise Linux 9 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9)
- [Red Hat Enterprise Linux 8 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8)
- [RHEL Package Browser](https://access.redhat.com/downloads/content/package-browser)
- [yq - Command-line YAML processor](https://github.com/mikefarah/yq)
- [Claude Code Installation](https://docs.claude.com/en/docs/claude-code)
- [Claude Code macOS Install Guide](https://dev.to/xujfcn/claude-code-installation-guide-for-macos-git-environment-variables-path-and-every-common-fix-4l96)
- [Claude Code .claude directory](https://code.claude.com/docs/en/claude-directory)
- [Cursor IDE Downloads](https://www.cursor.com/downloads)
- [macOS Bash Version Constraints](https://thelinuxcode.com/change-default-shell-from-zsh-to-bash-mac/)
- [Homebrew](https://brew.sh/)
