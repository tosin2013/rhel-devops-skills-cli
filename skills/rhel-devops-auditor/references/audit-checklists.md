# Audit Checklists — Machine-Readable

This document defines the exact checks for each audit module. The auditor skill
uses these checklists to produce consistent reports across projects.

## Module 1: AgnosticD Config Audit

```yaml
module: 1
name: "AgnosticD Config Audit"
standards_source: "agnosticd-refactor SKILL.md"
checks:
  - id: M1-01
    description: "Config directory exists (ansible/configs/)"
    severity: BLOCKING
    check_type: file_exists
    target: "ansible/configs/"

  - id: M1-02
    description: "Config has required vars (cloud_provider, env_type)"
    severity: BLOCKING
    check_type: yaml_keys_present
    target: "ansible/configs/*/default_vars*.yml"
    required_keys: ["cloud_provider", "env_type"]

  - id: M1-03
    description: "Workload roles follow ocp4_workload_* naming"
    severity: HIGH
    check_type: naming_convention
    target: "ansible/roles/"
    pattern: "^ocp4_workload_"

  - id: M1-04
    description: "Roles have defaults/main.yml with documented variables"
    severity: HIGH
    check_type: file_exists_per_role
    target: "ansible/roles/*/defaults/main.yml"

  - id: M1-05
    description: "Roles have meta/main.yml with role metadata"
    severity: MEDIUM
    check_type: file_exists_per_role
    target: "ansible/roles/*/meta/main.yml"

  - id: M1-06
    description: "Pre/post hooks exist if config uses workloads"
    severity: MEDIUM
    check_type: conditional_file_exists
    condition: "workloads defined in config"
    target: "ansible/configs/*/pre_infra.yml OR post_infra.yml"

  - id: M1-07
    description: "No hardcoded secrets in vars files"
    severity: BLOCKING
    check_type: pattern_absent
    target: "**/*.yml"
    patterns:
      - "password:\\s*['\"][^{]"
      - "token:\\s*['\"][^{]"
      - "secret:\\s*['\"][^{]"
      - "AKIA[A-Z0-9]{16}"

  - id: M1-08
    description: "Vars reference secrets via vault/external mechanism"
    severity: HIGH
    check_type: pattern_present
    target: "ansible/configs/*/secret_vars.yml OR vault reference"
    patterns:
      - "!vault"
      - "lookup('env'"
      - "secrets/"
```

## Module 2: Onboard Manifest Audit

```yaml
module: 2
name: "Onboard Manifest Audit"
standards_source: "onboard skill references/manifest-spec.md"
checks:
  - id: M2-01
    description: "onboard.yml exists"
    severity: BLOCKING
    check_type: file_exists
    target: "onboard.yml"

  - id: M2-02
    description: "Required fields present (name, description, prerequisites)"
    severity: BLOCKING
    check_type: yaml_keys_present
    target: "onboard.yml"
    required_keys: ["name", "description", "prerequisites"]

  - id: M2-03
    description: "All prerequisites have check_command"
    severity: HIGH
    check_type: yaml_array_field_present
    target: "onboard.yml"
    array_path: "prerequisites"
    required_field: "check_command"

  - id: M2-04
    description: "Prerequisites have install commands for rhel9"
    severity: BLOCKING
    check_type: yaml_nested_key
    target: "onboard.yml"
    array_path: "prerequisites"
    nested_key: "install.rhel9"

  - id: M2-05
    description: "Prerequisites have install commands for macos"
    severity: MEDIUM
    check_type: yaml_nested_key
    target: "onboard.yml"
    array_path: "prerequisites"
    nested_key: "install.macos"

  - id: M2-06
    description: "Config prompts have defaults"
    severity: HIGH
    check_type: yaml_array_field_present
    target: "onboard.yml"
    array_path: "config.prompts"
    required_field: "default"

  - id: M2-07
    description: "Validation section has at least 1 required check"
    severity: HIGH
    check_type: yaml_array_condition
    target: "onboard.yml"
    array_path: "validation"
    condition: "required: true exists in at least 1 entry"

  - id: M2-08
    description: "config.output_file path is in .gitignore"
    severity: HIGH
    check_type: gitignore_contains
    target: ".gitignore"
    value_from: "onboard.yml -> config.output_file"

  - id: M2-09
    description: "post_setup.message exists with next steps"
    severity: MEDIUM
    check_type: yaml_key_present
    target: "onboard.yml"
    key: "post_setup.message"
```

## Module 3: Live Deployment Audit

```yaml
module: 3
name: "Live Deployment Audit"
standards_source: "student-readiness + agnosticd-deploy-test skills"
requires: "cluster credentials (kubeconfig or API URL + token)"
checks:
  - id: M3-01
    description: "Cluster API is reachable"
    severity: BLOCKING
    check_type: command_succeeds
    command: "oc cluster-info"

  - id: M3-02
    description: "Credentials are valid (oc whoami succeeds)"
    severity: BLOCKING
    check_type: command_succeeds
    command: "oc whoami"

  - id: M3-03
    description: "Hub cluster accessible (hub-student type)"
    severity: BLOCKING
    check_type: command_succeeds
    command: "oc --kubeconfig <hub-kubeconfig> get nodes"
    condition: "project_type == hub-student"

  - id: M3-04
    description: "Showroom deployed and route accessible"
    severity: HIGH
    check_type: command_succeeds
    command: "oc get route -n showroom showroom -o jsonpath='{.spec.host}'"
    condition: "showroom enabled"

  - id: M3-05
    description: "Student clusters provisioned (N/N)"
    severity: BLOCKING
    check_type: count_matches_expected
    condition: "project_type == hub-student"

  - id: M3-06
    description: "agnosticd_user_info present with per-student credentials"
    severity: HIGH
    check_type: state_data_present
    condition: "project_type == hub-student"

  - id: M3-07
    description: "Stop/start lifecycle works independently"
    severity: MEDIUM
    check_type: lifecycle_test
    note: "Only run if user explicitly requests"

  - id: M3-08
    description: "Cross-cluster wiring: Showroom terminal targets student API"
    severity: HIGH
    check_type: config_value_matches
    condition: "project_type == hub-student"
```

## Module 4: Project Structure Audit

```yaml
module: 4
name: "Project Structure Audit"
standards_source: "./install.sh scaffold output"
checks:
  - id: M4-01
    description: "Makefile exists"
    severity: BLOCKING
    check_type: file_exists
    target: "Makefile"

  - id: M4-02
    description: "Makefile has 'deploy' target"
    severity: BLOCKING
    check_type: grep_file
    target: "Makefile"
    pattern: "^deploy:"

  - id: M4-03
    description: "Makefile has 'destroy' target"
    severity: BLOCKING
    check_type: grep_file
    target: "Makefile"
    pattern: "^destroy:"

  - id: M4-04
    description: "Makefile has 'dry-run' target"
    severity: HIGH
    check_type: grep_file
    target: "Makefile"
    pattern: "^dry-run:"

  - id: M4-05
    description: "Makefile has 'status' target"
    severity: HIGH
    check_type: grep_file
    target: "Makefile"
    pattern: "^status:"

  - id: M4-06
    description: "Makefile has 'check-quota' target"
    severity: HIGH
    check_type: grep_file
    target: "Makefile"
    pattern: "^check-quota:"

  - id: M4-07
    description: "Deploy script exists and is executable"
    severity: BLOCKING
    check_type: file_executable
    target: "scripts/deploy*.sh"

  - id: M4-08
    description: "Teardown script exists and is executable"
    severity: BLOCKING
    check_type: file_executable
    target: "scripts/teardown*.sh"

  - id: M4-09
    description: "bootstrap.sh or onboard.yml exists"
    severity: HIGH
    check_type: any_file_exists
    targets: ["bootstrap.sh", "onboard.yml"]

  - id: M4-10
    description: "deploy/config.yml in .gitignore"
    severity: BLOCKING
    check_type: gitignore_contains
    target: ".gitignore"
    value: "deploy/config.yml"

  - id: M4-11
    description: "Info files in .gitignore (student_info.txt or deployment_info.txt)"
    severity: HIGH
    check_type: gitignore_contains_any
    target: ".gitignore"
    values: ["student_info.txt", "deployment_info.txt"]

  - id: M4-12
    description: "logs/ in .gitignore"
    severity: MEDIUM
    check_type: gitignore_contains
    target: ".gitignore"
    value: "logs/"

  - id: M4-13
    description: ".workshop-state in .gitignore"
    severity: MEDIUM
    check_type: gitignore_contains
    target: ".gitignore"
    value: ".workshop-state"

  - id: M4-14
    description: "Deploy script has --dry-run flag"
    severity: HIGH
    check_type: grep_file
    target: "scripts/deploy*.sh"
    pattern: "--dry-run"

  - id: M4-15
    description: "Deploy script has --confirm or --yes flag"
    severity: HIGH
    check_type: grep_file
    target: "scripts/deploy*.sh"
    pattern: "--(confirm|yes)"

  - id: M4-16
    description: "Teardown destroys in correct order"
    severity: HIGH
    check_type: script_order
    note: "For hub-student: students before hub"

  - id: M4-17
    description: "Scripts source workshop-common.sh"
    severity: MEDIUM
    check_type: grep_file
    target: "scripts/*.sh"
    pattern: "workshop-common.sh"

  - id: M4-18
    description: "GUID tracking present"
    severity: MEDIUM
    check_type: grep_file
    target: "scripts/deploy*.sh"
    pattern: "workshop_generate_guid\\|workshop_get_guid"

  - id: M4-19
    description: "State lock pattern present"
    severity: MEDIUM
    check_type: grep_file
    target: "scripts/deploy*.sh"
    pattern: "workshop_state_lock"

  - id: M4-20
    description: "Scripts pass ShellCheck"
    severity: MEDIUM
    check_type: shellcheck
    target: "scripts/*.sh"
```
