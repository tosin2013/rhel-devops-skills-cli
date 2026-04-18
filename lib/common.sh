#!/usr/bin/env bash
# Shared utilities for rhel-devops-skills-cli
# shellcheck disable=SC2034

set -euo pipefail

readonly INSTALLER_VERSION="1.0.0"
readonly INSTALLER_REPO="https://github.com/tosin2013/rhel-devops-skills-cli"
readonly DATA_DIR="${RHEL_DEVOPS_SKILLS_HOME:-$HOME/.rhel-devops-skills}"
readonly REGISTRY_FILE="$DATA_DIR/registry.json"
readonly BACKUP_DIR="$DATA_DIR/backups"
readonly LOG_DIR="$DATA_DIR/logs"

readonly CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
readonly CURSOR_SKILLS_DIR="$HOME/.cursor/skills"
readonly CURSOR_RULES_DIR=".cursor/rules"

# Available skills -- loaded dynamically from per-skill config.sh files
readonly ALL_SKILLS=("agnosticd" "field-sourced-content" "patternizer" "showroom" "student-readiness" "workshop-tester" "agnosticd-refactor" "vp-refactor" "skill-researcher" "agnosticd-deploy-test" "vp-deploy-test" "vp-deploy-validator" "agnosticd-hub-student")

# Per-skill config is loaded from skills/<name>/config.sh at runtime.
# Each config.sh defines: SKILL_NAME, UPSTREAM_REPO, FORK_REPO, BRANCH, DOC_PATHS
declare -A SKILL_REPOS=()
declare -A SKILL_BRANCHES=()
declare -A SKILL_DOC_PATHS=()

_load_skill_configs() {
    local script_root
    script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local skills_dir="$script_root/../skills"

    for skill_name in "${ALL_SKILLS[@]}"; do
        local config_file="$skills_dir/$skill_name/config.sh"
        if [[ -f "$config_file" ]]; then
            local UPSTREAM_REPO="" FORK_REPO="" BRANCH="main" DOC_PATHS=()
            # shellcheck source=/dev/null
            source "$config_file"
            SKILL_REPOS[$skill_name]="${FORK_REPO:-$UPSTREAM_REPO}"
            SKILL_BRANCHES[$skill_name]="${BRANCH}"
            SKILL_DOC_PATHS[$skill_name]="${DOC_PATHS[*]}"
        fi
    done
}

# Load configs on source
_load_skill_configs

VERBOSE="${RHEL_DEVOPS_SKILLS_VERBOSE:-false}"
DRY_RUN=false
FORCE=false

# --- Colors & Output ---

if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly BOLD='\033[1m'
    readonly RESET='\033[0m'
else
    readonly RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

info()    { echo -e "${BLUE}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*" >&2; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
debug()   { [[ "$VERBOSE" == "true" ]] && echo -e "[DEBUG] $*" >&2 || true; }

log_to_file() {
    mkdir -p "$LOG_DIR"
    local logfile
    logfile="$LOG_DIR/install-$(date +%Y-%m-%d).log"
    echo "[$(date -Iseconds)] $*" >> "$logfile"
}

# --- Platform Detection ---

detect_platform() {
    local os_type
    os_type="$(uname -s)"
    case "$os_type" in
        Linux)  echo "linux" ;;
        Darwin) echo "macos" ;;
        *)      echo "unknown" ;;
    esac
}

platform_install_hint() {
    local platform
    platform="$(detect_platform)"
    case "$platform" in
        linux) echo "sudo dnf install" ;;
        macos) echo "brew install" ;;
        *)     echo "install" ;;
    esac
}

# --- Prerequisite Checks (ADR-006) ---

check_prerequisites() {
    local missing=()
    local platform
    platform="$(detect_platform)"

    local bash_major="${BASH_VERSINFO[0]}"
    local bash_minor="${BASH_VERSINFO[1]}"
    if (( bash_major < 4 || (bash_major == 4 && bash_minor < 4) )); then
        error "bash ${BASH_VERSION} is too old (need 4.4+)."
        if [[ "$platform" == "macos" ]]; then
            error "Install with: brew install bash"
            error "Then re-run with: /opt/homebrew/bin/bash install.sh ..."
        else
            error "Install with: sudo dnf install bash"
        fi
        exit 3
    fi

    command -v git &>/dev/null || missing+=("git")
    command -v curl &>/dev/null || missing+=("curl")

    if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
        missing+=("jq or python3")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required tools: ${missing[*]}"
        error "Install with: $(platform_install_hint) ${missing[*]}"
        exit 3
    fi

    debug "Prerequisites OK: bash ${BASH_VERSION}, git, curl, $(command -v jq &>/dev/null && echo jq || echo python3)"
}

# --- IDE Detection (ADR-004) ---

detect_claude() {
    [[ -d "$HOME/.claude" ]]
}

detect_cursor() {
    [[ -d "$HOME/.cursor" ]]
}

resolve_target_ides() {
    local ide_flag="${1:-auto}"
    local targets=()

    case "$ide_flag" in
        claude)
            if detect_claude; then
                targets+=("claude")
            else
                error "Claude Code not detected (~/.claude/ does not exist)"
                exit 6
            fi
            ;;
        cursor)
            if detect_cursor; then
                targets+=("cursor")
            else
                error "Cursor IDE not detected (~/.cursor/ does not exist)"
                exit 6
            fi
            ;;
        both)
            detect_claude && targets+=("claude")
            detect_cursor && targets+=("cursor")
            if [[ ${#targets[@]} -eq 0 ]]; then
                error "Neither Claude Code nor Cursor IDE detected"
                error "Install Claude Code: https://docs.claude.com/en/docs/claude-code"
                error "Install Cursor: https://www.cursor.com/downloads"
                exit 6
            fi
            ;;
        auto)
            detect_claude && targets+=("claude")
            detect_cursor && targets+=("cursor")
            if [[ ${#targets[@]} -eq 0 ]]; then
                error "Neither Claude Code nor Cursor IDE detected"
                error "Install Claude Code: https://docs.claude.com/en/docs/claude-code"
                error "Install Cursor: https://www.cursor.com/downloads"
                exit 6
            fi
            ;;
        *)
            error "Invalid --ide value: $ide_flag (use: claude, cursor, both)"
            exit 2
            ;;
    esac

    echo "${targets[@]}"
}

get_ide_skills_dir() {
    local ide="$1"
    case "$ide" in
        claude) echo "$CLAUDE_SKILLS_DIR" ;;
        cursor) echo "$CURSOR_SKILLS_DIR" ;;
    esac
}

# --- Skill Validation ---

is_valid_skill() {
    local name="$1"
    for skill in "${ALL_SKILLS[@]}"; do
        [[ "$skill" == "$name" ]] && return 0
    done
    return 1
}

validate_skill_name() {
    local name="$1"
    if ! is_valid_skill "$name"; then
        error "Unknown skill: $name"
        error "Available skills: ${ALL_SKILLS[*]}"
        exit 6
    fi
}

get_skill_config() {
    local name="$1" field="$2"
    case "$field" in
        source_repo) echo "${SKILL_REPOS[$name]:-}" ;;
        branch)      echo "${SKILL_BRANCHES[$name]:-main}" ;;
        doc_paths)   echo "${SKILL_DOC_PATHS[$name]:-}" ;;
    esac
}

# --- Data Directory ---

ensure_data_dir() {
    mkdir -p "$DATA_DIR" "$BACKUP_DIR" "$LOG_DIR"
    chmod 700 "$DATA_DIR"
}

# --- Script Root ---

get_script_dir() {
    local dir
    dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    echo "$dir"
}
