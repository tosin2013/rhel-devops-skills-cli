# onboard.yml Manifest Specification

**Spec version:** 1.0

The `onboard.yml` manifest is a declarative file shipped by a consuming project
(committed to git) that tells the onboard skill what to install, configure, and
validate for that specific project. The file may also be named `onboard.json`
(same schema, JSON format).

---

## Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Human-readable project name, displayed in the onboarding header |
| `description` | string | No | One-line project description |
| `deploy_script` | string | No | Path to the deploy script, shown in post-setup instructions |

---

## `prerequisites`

An ordered array of tools that must be installed before the project can be used.
Each entry declares how to check for the tool, the minimum version, and per-platform
install commands.

### Prerequisite Entry Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Human-readable tool name (e.g., `python3`, `podman`) |
| `check_command` | string | Yes | Shell command to check if the tool is installed. Exit 0 = present. |
| `version_regex` | string | No | Regex with one capture group to extract the version from `check_command` output. Uses standard regex syntax with `()` capture groups. |
| `min_version` | string | No | Minimum acceptable version (dot-separated numeric, e.g., `3.12`, `5.0`). Only meaningful when `version_regex` is also set. |
| `install` | map | Yes | Per-platform install commands (see Platform Keys below) |

### Platform Keys

The `install` map uses these keys to select the correct install command:

| Key | Matches |
|-----|---------|
| `macos` | macOS (any version, assumes Homebrew) |
| `rhel9` | RHEL 9.x, CentOS Stream 9 |
| `rhel8` | RHEL 8.x, CentOS Stream 8 |
| `rhel10` | RHEL 10.x |
| `fedora` | Fedora (any version) |
| `debian` | Debian, Ubuntu, and derivatives |
| `fallback` | Printed as manual instructions for unknown/unsupported distros |

Platform detection maps `/etc/os-release` values to these keys. See the Platform
Detection phase in SKILL.md for the full mapping table.

### Example

```yaml
prerequisites:
  - name: python3
    check_command: "python3 --version"
    version_regex: "Python (\\d+\\.\\d+)"
    min_version: "3.12"
    install:
      macos: "brew install python@3.12"
      rhel9: "sudo dnf install -y python3.12"
      rhel8: "sudo dnf install -y python3.12"
      fedora: "sudo dnf install -y python3.12"
      debian: "sudo apt-get install -y python3"
      fallback: "Install Python 3.12+ from https://python.org"

  - name: sshpass
    check_command: "command -v sshpass"
    install:
      macos: "brew install esolitos/ipa/sshpass"
      rhel9: "sudo dnf install -y sshpass"
      rhel8: "sudo dnf install -y sshpass"
      fedora: "sudo dnf install -y sshpass"
      debian: "sudo apt-get install -y sshpass"
      fallback: "Install sshpass from your package manager"
```

Note: entries without `version_regex`/`min_version` (like `sshpass`) only check for
presence, not version.

---

## `setup_steps`

An ordered array of steps that run after prerequisites are satisfied. Each step
has a name, an idempotency check (skip if already done), and an action to perform.

### Setup Step Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Human-readable step name |
| `check` | string | Yes | Shell command to check if step is already done. Exit 0 = skip. Supports `${variable}` substitution. |
| `action` | string | Yes | Shell command to execute if check fails. Supports `${variable}` substitution. |
| `prompt_var` | string | No | If set, prompt the user for this variable's value before running check/action |
| `prompt` | string | No | Prompt text shown to the user (used with `prompt_var`) |
| `default` | string | No | Default value for the prompt |

### Variable Substitution

Setup step `check` and `action` fields can reference `${variable}` placeholders.
These are resolved from:

1. Values collected by `prompt_var` fields in setup steps
2. Values collected by config prompts (Phase 4)
3. The resolution order is: setup step prompt values first, then config prompt values

### Example

```yaml
setup_steps:
  - name: "Clone AgnosticD v2"
    check: "test -d ${agnosticd_root}/bin/agd"
    action: "git clone https://github.com/agnosticd/agnosticd-v2.git ${agnosticd_root}"
    prompt_var: agnosticd_root
    prompt: "AgnosticD v2 install path"
    default: "~/Development/agnosticd-v2"

  - name: "Run agd setup"
    check: "test -d ${agnosticd_root}/../agnosticd-v2-vars"
    action: "cd ${agnosticd_root} && ./bin/agd setup"
```

---

## `config`

Defines interactive configuration prompts and where to write the resulting config file.

### Config Object Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `output_file` | string | Yes | Path (relative to project root) where the config file is written |
| `gitignore` | boolean | No | If `true`, ensure `output_file` is in `.gitignore`. Default: `false`. |
| `prompts` | array | Yes | Ordered array of prompt entries |

### Prompt Entry Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `key` | string | Yes | YAML key in the output file. Also used as the variable name for `${key}` substitution in validation and post-setup. |
| `prompt` | string | Yes | Human-readable question shown to the user |
| `default` | string | No | Default value shown in brackets. Empty string means no default. |
| `choices` | array of strings | No | If set, input must be one of these values |
| `required` | boolean | No | If `true`, empty input is rejected. Default: `false`. |
| `sensitive` | boolean | No | If `true`, input should be masked during entry. Default: `false`. Reserved for future use. |

### Example

```yaml
config:
  output_file: agnosticd/config.yml
  gitignore: true

  prompts:
    - key: account
      prompt: "Account name (matches secrets filename)"
      default: "sandbox3008"
      required: true

    - key: aws_region
      prompt: "AWS region"
      default: "us-east-2"

    - key: student_type
      prompt: "Student cluster type"
      choices: ["sno", "multinode"]
      default: "sno"
```

### Config Output Format

The generated config file is flat YAML — one `key: value` per line:

```yaml
# Generated by onboard -- re-run to reconfigure
# DO NOT commit this file (contains environment-specific values)
account: mylab
aws_region: us-west-2
student_type: sno
```

---

## `validation`

An array of checks run after configuration is written. Each check runs a command
and reports pass/fail.

### Validation Entry Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Human-readable check name |
| `command` | string | Yes | Shell command to execute. Exit 0 = pass. Supports `${variable}` substitution from config prompt answers. |
| `required` | boolean | No | If `true`, failure is reported as FAIL. If `false`, failure is reported as WARN. Default: `false`. |
| `fail_message` | string | No | Message shown on failure, with `${variable}` substitution. Should include remediation instructions. |

### Example

```yaml
validation:
  - name: "AWS credentials"
    command: "aws sts get-caller-identity"
    required: false
    fail_message: >-
      AWS credentials not configured.
      Run 'aws configure' or set AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY.

  - name: "Pull secret exists"
    command: "test -f ${pull_secret_path}"
    required: true
    fail_message: >-
      Download your pull secret from
      https://console.redhat.com/openshift/downloads

  - name: "AgnosticD agd binary"
    command: "test -x ${agnosticd_root}/bin/agd"
    required: true
    fail_message: "AgnosticD not found. Re-run the onboard process or clone manually."
```

---

## Readiness Gating

The validation phase computes a readiness score from the `validation` array. The
score determines whether deployment proceeds.

### How the score is computed

1. Count every validation entry where `required: true` → this is `required_total`
2. Run each validation command
3. Each `required: true` entry that exits 0 increments `required_passed`
4. Each `required: false` entry that exits non-zero increments `warnings`

### Gate behavior

| Condition | Result |
|-----------|--------|
| `required_passed == required_total` | **Ready** — deployment proceeds (prod mode) |
| `required_passed < required_total` | **Blocked** — deployment is refused, exit non-zero |
| Warnings only | **Ready** — warnings are informational, do not block |

### Output format

```
Readiness: 4/5 required checks passed (1 warning(s))
BLOCKED: 1 required check(s) failed. Fix the issues above before deploying.
```

The readiness gate applies both when the AI agent runs validation (Phase 5) and
when the generated `bootstrap.sh` runs `--check-only` or reaches the validation
phase. The `post_setup.message` is still shown after a failure so users can see
remediation instructions.

---

## `post_setup`

A message displayed after all phases complete.

### Post-Setup Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `message` | string | Yes | Multi-line message with `${variable}` substitution. Use YAML block scalar (`\|`) for multi-line text. |

### Example

```yaml
post_setup:
  message: |
    Setup complete! Next steps:

    1. Fill in your AWS credentials in:
       ${agnosticd_root}/../agnosticd-v2-secrets/secrets-${account}.yml

    2. Deploy:
       make deploy

    3. When finished:
       make teardown

    Full reference: agnosticd/DEPLOYMENT.md
```

---

## `modes`

Optional section that defines dev and prod onboarding modes. If omitted, the
onboard process runs all phases without a deploy step (original behavior).

- **dev** — For repo maintainers and contributors. Installs extra development tools
  on top of the base prerequisites. Does not deploy.
- **prod** — For end users. Runs the full onboarding flow and optionally executes a
  deploy command after validation passes. This is the default mode.

### Mode Object Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `description` | string | No | Human-readable description of what this mode does |
| `phases` | array of strings | No | Which phases to run. Valid values: `prerequisites`, `setup_steps`, `config`, `validation`, `deploy`. Default: all except `deploy`. |
| `extra_prerequisites` | array | No | Additional prerequisite entries (same schema as top-level `prerequisites`) installed only in this mode. Typically used in `dev` mode for linters, test tools, etc. |
| `post_validation_command` | string | No | Shell command to run after validation passes. Typically used in `prod` mode to trigger deployment. Supports `${variable}` substitution. |

### Example

```yaml
modes:
  dev:
    description: "Set up maintainer/contributor development environment"
    phases: [prerequisites, setup_steps, config, validation]
    extra_prerequisites:
      - name: shellcheck
        check_command: "command -v shellcheck"
        install:
          rhel9: "sudo dnf install -y ShellCheck"
          macos: "brew install shellcheck"
          fallback: "Install ShellCheck from https://www.shellcheck.net/"
      - name: pre-commit
        check_command: "command -v pre-commit"
        install:
          rhel9: "pip3 install pre-commit"
          macos: "brew install pre-commit"
          fallback: "Install pre-commit from https://pre-commit.com/"
  prod:
    description: "Set up and deploy for end users"
    phases: [prerequisites, setup_steps, config, validation, deploy]
    post_validation_command: "${deploy_script}"
```

---

## Complete Minimal Example

The smallest valid manifest:

```yaml
name: my-project
description: A simple project

prerequisites:
  - name: git
    check_command: "git --version"
    install:
      rhel9: "sudo dnf install -y git"
      macos: "brew install git"
      fallback: "Install git from https://git-scm.com"

config:
  output_file: config.yml
  gitignore: true
  prompts:
    - key: name
      prompt: "Your name"
      required: true

validation: []

post_setup:
  message: |
    Config written to config.yml.
    You're ready to go!
```

---

## File Discovery

The onboard skill searches for the manifest in this order:

1. Explicit path provided by the user
2. `./onboard.yml`
3. `./onboard.json`
4. `./agnosticd/onboard.yml`
5. `./agnosticd/onboard.json`
6. `./.onboard.yml`
7. `./.onboard.json`

Both YAML and JSON formats are supported. The schema is identical; only the
serialization format differs.
