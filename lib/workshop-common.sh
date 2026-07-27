#!/usr/bin/env bash
# workshop-common.sh — Shared bash library for AgnosticD workshop/demo/infra projects
# Source this file in deploy/teardown scripts:
#   source "${WORKSHOP_LIB:-$HOME/.local/share/rhel-devops-skills}/workshop-common.sh"
#
# shellcheck disable=SC2034

set -euo pipefail

# ─── Constants ───────────────────────────────────────────────────────────────

readonly WS_STATE_FILE=".workshop-state"
readonly WS_LOCK_FILE=".workshop-lock"
readonly WS_LOG_DIR="logs"
readonly WS_CONFIG_FILE="deploy/config.yml"

# ─── Colors & Logging ────────────────────────────────────────────────────────

if [[ -t 1 ]]; then
    _WS_RED='\033[0;31m'; _WS_GREEN='\033[0;32m'; _WS_YELLOW='\033[1;33m'
    _WS_BLUE='\033[0;34m'; _WS_BOLD='\033[1m'; _WS_RESET='\033[0m'
else
    _WS_RED=''; _WS_GREEN=''; _WS_YELLOW=''; _WS_BLUE=''; _WS_BOLD=''; _WS_RESET=''
fi

workshop_log() {
    local level="$1"; shift
    local timestamp
    timestamp="$(date -Iseconds)"
    local msg="[$timestamp] [$level] $*"

    case "$level" in
        INFO)  echo -e "${_WS_BLUE}[INFO]${_WS_RESET} $*" ;;
        OK)    echo -e "${_WS_GREEN}[OK]${_WS_RESET} $*" ;;
        WARN)  echo -e "${_WS_YELLOW}[WARN]${_WS_RESET} $*" >&2 ;;
        ERROR) echo -e "${_WS_RED}[ERROR]${_WS_RESET} $*" >&2 ;;
        *)     echo -e "$*" ;;
    esac

    if [[ -d "$WS_LOG_DIR" ]]; then
        echo "$msg" >> "$WS_LOG_DIR/current.log"
    fi
}

# ─── Config Loading ──────────────────────────────────────────────────────────

workshop_load_config() {
    local config_file="${1:-$WS_CONFIG_FILE}"

    if [[ ! -f "$config_file" ]]; then
        workshop_log ERROR "Config file not found: $config_file"
        workshop_log ERROR "Run 'make setup' or './bootstrap.sh' to generate it"
        return 1
    fi

    while IFS=': ' read -r key value; do
        [[ -z "$key" || "$key" == "#"* ]] && continue
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        export "WS_CFG_${key^^}"="$value"
    done < <(grep -v '^\s*#' "$config_file" | grep -v '^\s*$')
}

workshop_get_config() {
    local key="$1"
    local var="WS_CFG_${key^^}"
    echo "${!var:-}"
}

# ─── GUID / Environment ID ───────────────────────────────────────────────────

workshop_generate_guid() {
    local guid
    guid="$(head -c 6 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    echo "$guid"
}

workshop_get_guid() {
    if [[ -f "$WS_STATE_FILE" ]]; then
        grep '^guid=' "$WS_STATE_FILE" | cut -d= -f2
    fi
}

workshop_save_state() {
    local key="$1" value="$2"
    if grep -q "^${key}=" "$WS_STATE_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$WS_STATE_FILE"
    else
        echo "${key}=${value}" >> "$WS_STATE_FILE"
    fi
}

workshop_get_state() {
    local key="$1"
    if [[ -f "$WS_STATE_FILE" ]]; then
        grep "^${key}=" "$WS_STATE_FILE" 2>/dev/null | cut -d= -f2
    fi
}

# ─── State Lock ──────────────────────────────────────────────────────────────

workshop_state_lock() {
    if [[ -f "$WS_LOCK_FILE" ]]; then
        local lock_pid
        lock_pid="$(cat "$WS_LOCK_FILE")"
        if kill -0 "$lock_pid" 2>/dev/null; then
            workshop_log ERROR "Another operation is in progress (PID: $lock_pid)"
            workshop_log ERROR "If this is stale, remove $WS_LOCK_FILE manually"
            return 1
        else
            workshop_log WARN "Removing stale lock (PID $lock_pid no longer running)"
            rm -f "$WS_LOCK_FILE"
        fi
    fi
    echo "$$" > "$WS_LOCK_FILE"
}

workshop_state_unlock() {
    rm -f "$WS_LOCK_FILE"
}

# ─── Log Capture ─────────────────────────────────────────────────────────────

workshop_init_logging() {
    local guid="${1:-$(workshop_get_guid)}"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$WS_LOG_DIR"
    local logfile="$WS_LOG_DIR/${guid:-noid}-${timestamp}.log"
    ln -sf "$(basename "$logfile")" "$WS_LOG_DIR/current.log"
    workshop_save_state "logfile" "$logfile"
    echo "$logfile"
}

# ─── Dry-Run Guard ───────────────────────────────────────────────────────────

workshop_dry_run_guard() {
    if [[ "${WS_DRY_RUN:-false}" == "true" ]]; then
        workshop_log INFO "[DRY-RUN] Would run: $*"
        return 0
    fi
    return 1
}

# ─── Confirmation Prompt ─────────────────────────────────────────────────────

workshop_confirm() {
    local prompt="${1:-Continue?}"

    if [[ "${WS_YES:-false}" == "true" ]]; then
        return 0
    fi

    if [[ ! -t 0 ]]; then
        workshop_log ERROR "Cannot prompt for confirmation in non-interactive mode"
        workshop_log ERROR "Use --yes to skip confirmations"
        return 1
    fi

    local response
    read -rp "  $prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

# ─── Idempotency Check ───────────────────────────────────────────────────────

workshop_idempotency_check() {
    local target="$1"
    local state_key="$2"
    local current_state
    current_state="$(workshop_get_state "$state_key")"

    if [[ "$current_state" == "deployed" ]]; then
        workshop_log WARN "$target is already deployed"
        if ! workshop_confirm "Re-provision $target?"; then
            workshop_log INFO "Skipping $target (already deployed)"
            return 1
        fi
    fi
    return 0
}

# ─── AgnosticD Wrappers ──────────────────────────────────────────────────────

workshop_agd_provision() {
    local config="$1"
    local vars_file="$2"
    local guid="${3:-$(workshop_get_guid)}"
    local agd_root="${WS_CFG_AGD_ROOT:-$HOME/Development/agnosticd-v2}"

    local cmd="$agd_root/bin/agd provision --config $config --vars $vars_file"
    [[ -n "$guid" ]] && cmd+=" --guid $guid"

    if workshop_dry_run_guard "$cmd"; then
        return 0
    fi

    workshop_log INFO "Provisioning: $config (GUID: $guid)"
    eval "$cmd"
}

workshop_agd_destroy() {
    local config="$1"
    local vars_file="$2"
    local guid="${3:-$(workshop_get_guid)}"
    local agd_root="${WS_CFG_AGD_ROOT:-$HOME/Development/agnosticd-v2}"

    local cmd="$agd_root/bin/agd destroy --config $config --vars $vars_file"
    [[ -n "$guid" ]] && cmd+=" --guid $guid"

    if workshop_dry_run_guard "$cmd"; then
        return 0
    fi

    workshop_log INFO "Destroying: $config (GUID: $guid)"
    eval "$cmd"
}

workshop_agd_stop() {
    local config="$1"
    local vars_file="$2"
    local guid="${3:-$(workshop_get_guid)}"
    local agd_root="${WS_CFG_AGD_ROOT:-$HOME/Development/agnosticd-v2}"

    local cmd="$agd_root/bin/agd stop --config $config --vars $vars_file"
    [[ -n "$guid" ]] && cmd+=" --guid $guid"

    if workshop_dry_run_guard "$cmd"; then
        return 0
    fi

    workshop_log INFO "Stopping: $config (GUID: $guid)"
    eval "$cmd"
}

workshop_agd_start() {
    local config="$1"
    local vars_file="$2"
    local guid="${3:-$(workshop_get_guid)}"
    local agd_root="${WS_CFG_AGD_ROOT:-$HOME/Development/agnosticd-v2}"

    local cmd="$agd_root/bin/agd start --config $config --vars $vars_file"
    [[ -n "$guid" ]] && cmd+=" --guid $guid"

    if workshop_dry_run_guard "$cmd"; then
        return 0
    fi

    workshop_log INFO "Starting: $config (GUID: $guid)"
    eval "$cmd"
}

workshop_agd_status() {
    local config="$1"
    local vars_file="$2"
    local guid="${3:-$(workshop_get_guid)}"
    local agd_root="${WS_CFG_AGD_ROOT:-$HOME/Development/agnosticd-v2}"

    "$agd_root/bin/agd" status --config "$config" --vars "$vars_file" ${guid:+--guid "$guid"} 2>/dev/null || echo "UNKNOWN"
}

# ─── Orchestration ───────────────────────────────────────────────────────────

workshop_parallel_students() {
    local action="$1"
    local config="$2"
    local vars_base="$3"
    local num_students="${4:-$(workshop_get_config num_students)}"
    local max_parallel="${5:-$num_students}"

    local pids=()
    local failed=()
    local running=0

    for ((i=1; i<=num_students; i++)); do
        local vars_file="${vars_base/\{N\}/$i}"

        (
            workshop_log INFO "Student $i: $action"
            if "workshop_agd_$action" "$config" "$vars_file" "$(workshop_get_guid)" 2>&1; then
                workshop_save_state "student_${i}_status" "success"
            else
                workshop_save_state "student_${i}_status" "failed"
                exit 1
            fi
        ) &
        pids+=($!)
        ((running++))

        if ((running >= max_parallel)); then
            wait "${pids[0]}" || failed+=("${pids[0]}")
            pids=("${pids[@]:1}")
            ((running--))
        fi
    done

    for pid in "${pids[@]}"; do
        wait "$pid" || failed+=("$pid")
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        workshop_log ERROR "${#failed[@]} student operation(s) failed"
        return 1
    fi

    workshop_log OK "All $num_students student operations completed successfully"
}

workshop_serial_hub() {
    local action="$1"
    local config="$2"
    local vars_file="$3"

    workshop_log INFO "Hub: $action"
    if "workshop_agd_$action" "$config" "$vars_file" "$(workshop_get_guid)"; then
        workshop_save_state "hub_status" "success"
        workshop_log OK "Hub $action completed"
    else
        workshop_save_state "hub_status" "failed"
        workshop_log ERROR "Hub $action failed"
        return 1
    fi
}

# ─── Partial Resume ──────────────────────────────────────────────────────────

workshop_resume_partial() {
    local num_students="${1:-$(workshop_get_config num_students)}"
    local failed_students=()

    for ((i=1; i<=num_students; i++)); do
        local status
        status="$(workshop_get_state "student_${i}_status")"
        if [[ "$status" == "failed" || -z "$status" ]]; then
            failed_students+=("$i")
        fi
    done

    if [[ ${#failed_students[@]} -eq 0 ]]; then
        workshop_log OK "No failed students to resume"
        return 0
    fi

    workshop_log INFO "Resuming ${#failed_students[@]} failed student(s): ${failed_students[*]}"
    echo "${failed_students[@]}"
}

# ─── Info File Generation ────────────────────────────────────────────────────

workshop_generate_student_info() {
    local project_name="${1:-$(workshop_get_config project_name)}"
    local guid="${2:-$(workshop_get_guid)}"
    local num_students="${3:-$(workshop_get_config num_students)}"
    local output_file="student_info.txt"

    workshop_log INFO "Generating $output_file"

    {
        echo "Workshop: $project_name"
        echo "Date: $(date +%Y-%m-%d)"
        echo "GUID: $guid"
        echo "Hub Console: $(workshop_get_state hub_console_url)"
        echo "Showroom URL: $(workshop_get_state hub_showroom_url)"
        echo ""

        for ((i=1; i<=num_students; i++)); do
            echo "Student $i:"
            echo "  Console: $(workshop_get_state "student_${i}_console_url")"
            echo "  API: $(workshop_get_state "student_${i}_api_url")"
            echo "  Username: $(workshop_get_state "student_${i}_username")"
            echo "  Password: $(workshop_get_state "student_${i}_password")"
            echo ""
        done
    } > "$output_file"

    workshop_log OK "Student info written to $output_file"
}

workshop_generate_deployment_info() {
    local project_name="${1:-$(workshop_get_config project_name)}"
    local guid="${2:-$(workshop_get_guid)}"
    local project_type="${3:-$(workshop_get_config project_type)}"
    local output_file="deployment_info.txt"

    workshop_log INFO "Generating $output_file"

    {
        case "$project_type" in
            demo)
                echo "Demo: $project_name"
                ;;
            *)
                echo "Infrastructure: $project_name"
                ;;
        esac
        echo "Date: $(date +%Y-%m-%d)"
        echo "GUID: $guid"
        echo "Provider: $(workshop_get_config cloud_provider) / $(workshop_get_config cloud_region)"
        if [[ -n "$(workshop_get_state active_env)" ]]; then
            echo "Environment: $(workshop_get_state active_env)"
        fi
        echo ""
        echo "Cluster:"
        echo "  Console: $(workshop_get_state cluster_console_url)"
        echo "  API: $(workshop_get_state cluster_api_url)"
        if [[ -n "$(workshop_get_state cluster_showroom_url)" ]]; then
            echo "  Showroom: $(workshop_get_state cluster_showroom_url)"
        fi
        echo "  Username: $(workshop_get_state cluster_username)"
        echo "  Password: $(workshop_get_state cluster_password)"
    } > "$output_file"

    workshop_log OK "Deployment info written to $output_file"
}

# ─── Quota Check (sources lib/quota-check.sh) ────────────────────────────────

workshop_check_quota() {
    local quota_script="${WORKSHOP_LIB:-$HOME/.local/share/rhel-devops-skills}/quota-check.sh"
    if [[ -f "$quota_script" ]]; then
        # shellcheck source=/dev/null
        source "$quota_script"
        quota_check "$@"
    else
        workshop_log WARN "Quota check script not found: $quota_script"
        workshop_log WARN "Skipping quota pre-flight (install shared libs with: ./install.sh scaffold --type ...)"
        return 0
    fi
}

# ─── RHDP Pre-Provisioned Cluster Helpers ─────────────────────────────────────
#
# These functions support the rhdp-workload scaffold type, where the OpenShift
# cluster is ordered from the RHDP catalog (agd-v2.ocp-cluster-aws.prod) and
# users are pre-created via Red Hat Build of Keycloak (RHBK).

workshop_rhdp_detect_keycloak() {
    if ! oc get namespace keycloak &>/dev/null 2>&1; then
        workshop_log ERROR "Namespace 'keycloak' not found on cluster"
        return 1
    fi

    if ! oc get csv -n keycloak --no-headers 2>/dev/null | grep -q Succeeded; then
        workshop_log WARN "RHBK operator CSV not in Succeeded state in keycloak namespace"
        return 1
    fi

    local kc_pods
    kc_pods="$(oc get pods -n keycloak --no-headers 2>/dev/null | grep -c Running || echo 0)"
    if (( kc_pods == 0 )); then
        workshop_log WARN "No running Keycloak pods found in keycloak namespace"
        return 1
    fi

    return 0
}

workshop_rhdp_detect_users() {
    local realm_cr="sso"
    local namespace="keycloak"

    if ! oc get keycloakrealmimport "$realm_cr" -n "$namespace" &>/dev/null 2>&1; then
        workshop_log ERROR "KeycloakRealmImport '$realm_cr' not found in '$namespace' namespace"
        return 1
    fi

    local users
    users="$(oc get keycloakrealmimport "$realm_cr" -n "$namespace" \
        -o jsonpath='{range .spec.realm.users[*]}{.username}{"\n"}{end}' 2>/dev/null)"

    if [[ -z "$users" ]]; then
        workshop_log ERROR "No users found in KeycloakRealmImport '$realm_cr'"
        return 1
    fi

    echo "$users"
}

workshop_rhdp_resolve_passwords() {
    local num_users="${1:-0}"
    local realm_cr="sso"
    local namespace="keycloak"

    if ! oc get keycloakrealmimport "$realm_cr" -n "$namespace" &>/dev/null 2>&1; then
        workshop_log ERROR "KeycloakRealmImport '$realm_cr' not found — cannot resolve passwords"
        return 1
    fi

    local user_json
    user_json="$(oc get keycloakrealmimport "$realm_cr" -n "$namespace" \
        -o jsonpath='{.spec.realm.users}' 2>/dev/null)"

    if [[ -z "$user_json" ]]; then
        workshop_log ERROR "No user data in KeycloakRealmImport '$realm_cr'"
        return 1
    fi

    python3 -c "
import json, sys

users = json.loads('''$user_json''')
num = int('$num_users') if '$num_users' != '0' else len(users)

for u in users[:num]:
    username = u.get('username', '')
    creds = u.get('credentials', [])
    password = creds[0].get('value', '') if creds else ''
    if username and password:
        print(f'{username}={password}')
" 2>/dev/null | while IFS='=' read -r user password; do
        idx="${user#user}"
        if [[ "$idx" =~ ^[0-9]+$ ]]; then
            workshop_save_state "user_${idx}_password" "$password"
        fi
    done

    workshop_log OK "Resolved per-user passwords from KeycloakRealmImport"
}

workshop_rhdp_verify_idp() {
    local oauth_providers
    oauth_providers="$(oc get oauth cluster -o jsonpath='{.spec.identityProviders[*].type}' 2>/dev/null || echo '')"

    if [[ -z "$oauth_providers" ]]; then
        workshop_log WARN "No identity providers configured on cluster OAuth"
        return 1
    fi

    if echo "$oauth_providers" | grep -qi "openid"; then
        workshop_log OK "OpenID identity provider detected (RHDP Keycloak)"
    else
        workshop_log WARN "OpenID identity provider not found — detected: $oauth_providers"
        workshop_log WARN "RHDP clusters should have OpenID configured via RHBK. Users may not be able to log in."
    fi

    if echo "$oauth_providers" | grep -qi "htpasswd"; then
        workshop_log WARN "htpasswd identity provider also detected — avoid creating conflicting IdPs"
    fi

    return 0
}
