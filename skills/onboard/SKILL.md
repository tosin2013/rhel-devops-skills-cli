---
name: onboard
description: >-
  Project onboarding assistant that reads onboard.yml manifests to install
  prerequisites, configure environments, and validate deployment readiness
  for AgnosticD workshops, demos, and validated patterns. Use when a user
  clones a project and asks for help setting up, getting started, or
  deploying for the first time.
related_skills:
  - agnosticd
  - agnosticd-hub-student
  - field-sourced-content
  - student-readiness
  - showroom
  - patternizer
---

# Project Onboarding Assistant

## When to Use

- User clones a project repository and asks for help setting it up
- User asks "how do I get started" or "help me deploy" in a project directory
- User asks about prerequisites, environment setup, or first-time configuration
- A project directory contains an `onboard.yml`, `onboard.json`, or `.onboard.yml` manifest
- User says "onboard me" or "run onboard"
- User runs `make setup` and the Makefile delegates to this skill
- User asks to generate a setup script or bootstrap script for their project
- User asks about dev vs prod mode for a project setup

Do NOT use this skill for:
- Environments that are already deployed — use **student-readiness** to verify them
- Refactoring existing AgnosticD configs — use **agnosticd-refactor**
- Validating a running deployment — use **agnosticd-deploy-test** or **vp-deploy-test**
- Building a new skill — use the create-skill workflow

## Instructions

This skill defines a six-phase onboarding process driven by a declarative manifest
(`onboard.yml`) shipped by the consuming project. The manifest declares what needs to
be installed, configured, and validated — this skill interprets the manifest and
walks the user through each phase interactively.

The skill also generates runtime `bootstrap.sh` scripts that read `onboard.yml`
at execution time, so humans without AI agents can run the same onboarding process
from the command line (see Phase 7). The generated script uses python3 + PyYAML
to parse the manifest — no values are baked into the bash code.

**Key behaviors:**

- Read the manifest first; do not improvise steps that are not declared in it
- Complete each phase before moving to the next; do not skip phases
- Always confirm with the user before running `sudo` commands or installing packages
- The process is idempotent — safe to re-run; skip prerequisites already installed
- If the user says "use all defaults" or asks for non-interactive mode, accept all
  default values from the manifest without prompting
- Always run validation (Phase 5) even if the user asks to skip other phases
- Always show the post-setup message (Phase 6)
- Substitute `${variable}` references in commands, messages, and paths using the
  configuration values collected in Phase 4

**Dev vs prod modes:**

If the manifest defines a `modes` section, ask the user which mode they want at the
start of Phase 0:

- **dev** — For repo maintainers and contributors. Installs dev-only extra prerequisites
  (linters, test frameworks, pre-commit hooks) in addition to the base prerequisites.
  Does not deploy.
- **prod** — For end users who want to deploy and use the project. Installs runtime
  prerequisites, configures deployment, runs validation, and optionally executes the
  deploy script after validation passes. This is the default if the user does not specify.

If the manifest has no `modes` section, run all phases without a deploy step (original
behavior).

See `references/manifest-spec.md` for the complete `onboard.yml` schema.

## Required Input

Before starting, confirm:

| Input | Required | Default | Notes |
|-------|----------|---------|-------|
| Project directory | Yes | Current working directory | Must contain or be able to locate a manifest |
| User consent for installs | Yes | Ask per package | `sudo` required for system packages |

## Phase 0 — Manifest Discovery

Search for the manifest in this order:

1. If the user provides an explicit path, use it
2. `./onboard.yml`
3. `./onboard.json`
4. `./agnosticd/onboard.yml`
5. `./agnosticd/onboard.json`
6. `./.onboard.yml`
7. `./.onboard.json`

Read and parse the manifest. Display the project name and description to the user:

```
=== <name> Onboarding ===
<description>
```

**Mode selection:** If the manifest defines a `modes` section, ask the user:

- "Are you a maintainer/contributor (dev) or an end user looking to deploy (prod)?"
- Default to `prod` if the user does not specify
- In dev mode, include `modes.dev.extra_prerequisites` during Phase 2
- In prod mode, run `modes.prod.post_validation_command` after Phase 5

**If no manifest is found:** Explain what `onboard.yml` is and offer to help the user
create one. Refer them to `references/manifest-spec.md` for the schema and
`references/example-manifest.yml` for a working example.

## Phase 1 — Platform Detection

Detect the user's operating system and map it to a manifest platform key.

**On Linux**, read `/etc/os-release`:

```bash
cat /etc/os-release
```

Map `ID` and `VERSION_ID` to platform keys:

| `/etc/os-release` ID | VERSION_ID | Manifest Platform Key |
|----------------------|------------|----------------------|
| `rhel` or `redhat` | 8.x | `rhel8` |
| `rhel` or `redhat` | 9.x | `rhel9` |
| `rhel` or `redhat` | 10.x | `rhel10` |
| `centos` | 8.x | `rhel8` |
| `centos` | 9.x | `rhel9` |
| `fedora` | any | `fedora` |
| `debian` or `ubuntu` | any | `debian` |

**On macOS**, detect via:

```bash
uname -s
```

If the result is `Darwin`, use platform key `macos`.

**Unknown platform:** Use the `fallback` key from the manifest. If no `fallback` is
defined for a prerequisite, print manual installation instructions and ask the user
to install it themselves.

Display the detected platform:

```
Detected: <distro_name> <version> (<arch>)
```

## Phase 2 — Prerequisites

For each entry in the manifest's `prerequisites` array, in order:

### Step 1: Check if installed

Run the `check_command`. If it exits 0, the tool is present.

### Step 2: Check version (if applicable)

If `version_regex` and `min_version` are defined in the manifest entry:

1. Capture the output of `check_command`
2. Extract the version using the `version_regex` pattern
3. Compare against `min_version` using dot-separated numeric comparison:
   split both versions on `.`, compare each segment as an integer left-to-right

If the installed version is less than `min_version`, treat it as needing install/upgrade.

### Step 3: Install if missing or outdated

1. Look up the install command for the detected platform key
2. If no command exists for this platform, try `fallback`
3. Show the user what will be run and ask for confirmation before executing
4. Run the install command
5. Re-run `check_command` to verify the installation succeeded

### Reporting

Print status for each prerequisite:

```
--- Phase 2: Prerequisites ---

  [OK]      python3 3.12.4 (>= 3.12)
  [INSTALL] podman not found
            → Running: sudo dnf install -y podman
  [OK]      podman 5.2.1 (>= 5.0)
  [OK]      aws 2.17.0
  [INSTALL] sshpass not found
            → Running: sudo dnf install -y sshpass
  [OK]      sshpass installed
```

**Dev mode extras:** If running in dev mode and the manifest defines
`modes.dev.extra_prerequisites`, process those after the base prerequisites using
the same check/install pattern. These are tools only maintainers need (e.g., shellcheck,
pre-commit, test frameworks).

**Gate:** All prerequisites must be installed before continuing. If any install fails,
stop and help the user troubleshoot before proceeding.

## Phase 3 — Setup Steps

For each entry in the manifest's `setup_steps` array, in order:

### Step 1: Collect variables

If the step defines `prompt_var`, `prompt`, and `default`, ask the user for the value.
Store it for variable substitution in this and later phases.

### Step 2: Check if already done

Substitute variables in the `check` command and run it. If it exits 0, skip this step
(print `[SKIP]` with the step name).

### Step 3: Execute the action

Substitute variables in the `action` command and run it. Verify it succeeds.

### Reporting

```
--- Phase 3: Setup Steps ---

  [SKIP]  Clone AgnosticD v2 (already exists)
  [RUN]   Run agd setup
  [RUN]   Scaffold secrets file
```

**Gate:** All setup steps must complete before continuing.

## Phase 4 — Configuration

Read the `config.prompts` array from the manifest. For each prompt:

1. Display the `prompt` text with the `default` value in brackets
2. If `choices` is defined, show the valid options and reject invalid input
3. If `required` is true, reject empty input (keep asking)
4. If the user accepts the default (empty input), use the `default` value
5. Store the answer keyed by `key`

After all prompts are answered, write the configuration file:

### Write the config file

Write to the path specified in `config.output_file`, relative to the project root.

Format: flat YAML, one `key: value` per line, with a header comment:

```yaml
# Generated by onboard -- re-run to reconfigure
# DO NOT commit this file (contains environment-specific values)
account: mylab
aws_region: us-west-2
num_students: 2
```

### Ensure .gitignore coverage

If `config.gitignore` is true in the manifest:

1. Check if the config file path is already in `.gitignore`
2. If not, append it (create `.gitignore` if it does not exist)
3. Inform the user

### Reporting

```
--- Phase 4: Configuration ---

  Account name (matches secrets filename) [sandbox3008]: mylab
  AWS region [us-east-2]: us-west-2
  Number of student clusters [1]: 2
  ...

  Config saved to: agnosticd/config.yml (local-only, git-ignored)
```

## Phase 5 — Validation

For each entry in the manifest's `validation` array:

1. Substitute `${variable}` references in the `command` using values from Phase 4
2. Run the command
3. Determine the result:
   - Exit 0 → **PASS**
   - Exit non-zero and `required: true` → **FAIL**
   - Exit non-zero and `required: false` → **WARN**
4. On failure, display the `fail_message` (with variable substitution)

### Reporting

```
--- Phase 5: Validation ---

  [PASS] AWS credentials valid (arn:aws:iam::123456789:user/jdoe)
  [PASS] Pull secret exists and is valid JSON
  [PASS] AgnosticD agd binary found
  [PASS] Secrets file exists
  [WARN] Route53 hosted zone not verified

  4/4 required checks passed, 1 warning. Ready to deploy!
```

### Readiness Gate

After all checks run, report the readiness score:

```
  Readiness: X/Y required checks passed (N warning(s))
```

- **All required checks pass** → Proceed to Phase 6 (and deployment in prod mode)
- **Any required check fails** → Report the score and **stop**. Do not proceed to
  deployment. The user must fix all required failures before deploying. Still show
  the post-setup message (Phase 6), since it often contains remediation instructions.
- **Warnings** are informational and do not block deployment

## Phase 6 — Post-Setup

Display the `post_setup.message` from the manifest with all `${variable}` references
substituted. Also show the `deploy_script` path if defined:

```
--- Next Steps ---

  <post_setup.message with variables substituted>
```

**Prod mode deploy:** If running in prod mode and the manifest defines
`modes.prod.post_validation_command`, ask the user if they want to deploy now.
If yes, run the command. If validation had required failures, warn before deploying.

## Phase 7 — Generate Bootstrap Script

When the user asks to generate a setup script, create a `bootstrap.sh` that reads
`onboard.yml` at runtime. This gives the project a standalone onboarding experience
for humans who do not have Claude Code or Cursor.

### When to generate

- User asks "generate a bootstrap script" or "create a setup script"
- User asks "how can someone set this up without AI?"
- After completing Phases 0-6, offer to generate the script

### How to generate

1. Read `references/bootstrap-template.md` for the complete runtime script
2. Copy the script into the project root as `bootstrap.sh`
3. Run `chmod +x bootstrap.sh`
4. Read `references/agents-template.md` for the AGENTS.md template
5. If the project already has an `AGENTS.md`, append the onboard section under a new
   `## Onboarding` heading. Otherwise create `AGENTS.md` with the template content.
6. Suggest the project add it to their Makefile: `setup: ./bootstrap.sh`
7. Remind the user to commit `onboard.yml`, `bootstrap.sh`, and `AGENTS.md`

### Key principles

- The generated script reads `onboard.yml` at runtime via python3 + PyYAML — no
  manifest values are baked into the bash code
- **Single source of truth**: changing `onboard.yml` changes bootstrap behavior
  immediately; the script itself only needs updating if a new version of the
  template adds structural improvements
- **python3 + PyYAML required**: the script exits with clear install instructions
  if either is missing. python3 ships on every RHEL system; PyYAML ships as
  `python3-pyyaml` on RHEL/Fedora
- **Strict readiness gate**: deployment is blocked unless all required validation
  checks pass. The script prints a readiness score and exits non-zero on failure.
- The script is **idempotent** — safe to re-run
- Default mode is `prod` (most users are consumers, not maintainers)
- CI-friendly: `./bootstrap.sh --non-interactive --check-only` works in pipelines

## Re-run Behavior

The onboard process is designed to be re-run safely:

- **Prerequisites:** Already-installed tools are detected and skipped
- **Setup steps:** The `check` command skips completed steps
- **Configuration:** Previous values can be re-entered or changed
- **Validation:** Always runs fresh

If the user asks to re-run only part of the process:
- "Reconfigure" → Skip to Phase 4 (config prompts), then run Phases 5-6
- "Check only" → Skip to Phase 5 (validation), then Phase 6
- "Install prerequisites only" → Run Phases 1-2 only

## Creating an onboard.yml for a New Project

When a user asks to create a manifest for their project:

1. Read `references/manifest-spec.md` for the schema
2. Read `references/example-manifest.yml` for a complete working example
3. Examine the project's existing setup documentation (README, DEPLOYMENT.md, etc.)
4. Extract prerequisites, configuration options, and validation steps
5. Generate the manifest, filling in platform-specific install commands
6. For deploy.sh hardening, refer to `references/deploy-hardening.md`

## Platform-Specific Install Command Reference

Common install commands for use when helping users author manifests:

| Tool | rhel8/rhel9 | fedora | debian | macos |
|------|-------------|--------|--------|-------|
| python3 | `sudo dnf install -y python3.12` | `sudo dnf install -y python3.12` | `sudo apt-get install -y python3` | `brew install python@3.12` |
| podman | `sudo dnf install -y podman` | `sudo dnf install -y podman` | `sudo apt-get install -y podman` | `brew install podman` |
| git | `sudo dnf install -y git` | `sudo dnf install -y git` | `sudo apt-get install -y git` | `brew install git` |
| jq | `sudo dnf install -y jq` | `sudo dnf install -y jq` | `sudo apt-get install -y jq` | `brew install jq` |
| awscli | `sudo dnf install -y awscli2` | `sudo dnf install -y awscli2` | `sudo apt-get install -y awscli` | `brew install awscli` |
| sshpass | `sudo dnf install -y sshpass` | `sudo dnf install -y sshpass` | `sudo apt-get install -y sshpass` | `brew install esolitos/ipa/sshpass` |

## Escalation

- **Prerequisites fail on unsupported platform** → Show the `fallback` message from the manifest; suggest the user install manually
- **Validation finds cluster or cloud issues** → Activate the **student-readiness** skill for deployed environment checks
- **deploy.sh has cross-platform bugs** → Refer to `references/deploy-hardening.md` for sed, SSH, and error-handling patterns
- **AgnosticD config needs improvement** → Activate the **agnosticd-refactor** skill
- **User wants to create a manifest for a new project** → Use the schema in `references/manifest-spec.md` and the example in `references/example-manifest.yml`
