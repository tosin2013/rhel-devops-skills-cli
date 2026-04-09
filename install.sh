#!/usr/bin/env bash
# rhel-devops-skills-cli installer
# Installs AI agent skills for Claude Code and Cursor IDE
# https://github.com/tosin2013/rhel-devops-skills-cli

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library modules
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/registry.sh
source "$SCRIPT_DIR/lib/registry.sh"
# shellcheck source=lib/fetch-docs.sh
source "$SCRIPT_DIR/lib/fetch-docs.sh"
# shellcheck source=lib/validate.sh
source "$SCRIPT_DIR/lib/validate.sh"
# shellcheck source=lib/upgrade.sh
source "$SCRIPT_DIR/lib/upgrade.sh"

# ─── Usage ───────────────────────────────────────────────────────────────────

usage() {
    cat <<'USAGE'
rhel-devops-skills-cli — AI Agent Skills Installer for DevOps

USAGE:
  ./install.sh [OPTIONS] COMMAND [ARGS]

COMMANDS:
  install [--skill NAME|--all]     Install skill(s) to detected IDEs
  uninstall [--skill NAME|--all]   Remove skill(s) from IDEs
  update [--skill NAME|--all]      Update skill documentation from upstream
  check-updates                    Check if any installed skills have updates
  verify [--skill NAME|--all]      Validate skill installation integrity
  list                             List installed skills and status
  available                        List all available skills
  upgrade-installer                Upgrade the installer itself
  help                             Show this help message

OPTIONS:
  --ide <claude|cursor|both>       Target specific IDE (default: auto-detect)
  --verbose                        Enable verbose output
  --dry-run                        Show what would be done without making changes
  --force                          Force operation even if up to date
  --no-auto-check                  Disable automatic update checks on install

EXAMPLES:
  ./install.sh install --all                 Install all skills to detected IDEs
  ./install.sh install --skill agnosticd     Install AgnosticD v2 skill
  ./install.sh update --all                  Update all installed skills
  ./install.sh check-updates                 Check for upstream changes
  ./install.sh verify --all                  Verify all installations
  ./install.sh list                          Show installed skills

AVAILABLE SKILLS:
  agnosticd              AgnosticD v2 — Ansible Agnostic Deployer
  field-sourced-content  RHDP Field-Sourced Content Template
  patternizer            Validated Patterns bootstrapper (Patternizer)
  showroom               RHDP lab guide and terminal system (Showroom)
  student-readiness      Workshop environment readiness checker
  workshop-tester        AI-as-student module tester with failure classification
  agnosticd-refactor     Audit and improve AgnosticD v2 configs
  vp-refactor            Audit and improve Validated Pattern repos
  skill-researcher       Resolve open research questions in skills
  agnosticd-deploy-test  Validate AgnosticD deployment end-to-end
  vp-deploy-test         Validate VP deployment end-to-end
  vp-deploy-validator    Health check running VP deployment
USAGE
}

# ─── Install Skill ───────────────────────────────────────────────────────────

do_install_skill() {
    local skill_name="$1"
    local -a ide_targets
    read -ra ide_targets <<< "$2"

    validate_skill_name "$skill_name"

    if registry_is_installed "$skill_name" && [[ "$FORCE" != "true" ]]; then
        warn "Skill '$skill_name' is already installed. Use --force to reinstall."
        return 0
    fi

    info "Installing skill: $skill_name"

    local tmpdir
    tmpdir="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmpdir'" RETURN

    local commit_hash
    commit_hash="$(fetch_skill_docs "$skill_name" "$tmpdir/skill")" || return $?

    local source_repo
    source_repo="$(get_skill_config "$skill_name" "source_repo")"

    local installed_to_entries=()

    for ide in "${ide_targets[@]}"; do
        local skills_dir
        skills_dir="$(get_ide_skills_dir "$ide")"
        local dest="$skills_dir/$skill_name"

        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY-RUN] Would install $skill_name to $dest"
            continue
        fi

        mkdir -p "$dest"

        if [[ -f "$tmpdir/skill/SKILL.md" ]]; then
            cp "$tmpdir/skill/SKILL.md" "$dest/SKILL.md"
        fi

        if [[ -d "$tmpdir/skill/references" ]]; then
            mkdir -p "$dest/references"
            cp -r "$tmpdir/skill/references/"* "$dest/references/" 2>/dev/null || true
        fi

        # Install Cursor-specific rules if targeting Cursor
        if [[ "$ide" == "cursor" ]]; then
            local rules_src="$SCRIPT_DIR/skills/$skill_name/rules"
            if [[ -d "$rules_src" ]]; then
                local cursor_rules_dest="$HOME/$CURSOR_RULES_DIR"
                mkdir -p "$cursor_rules_dest"
                cp "$rules_src/"*.mdc "$cursor_rules_dest/" 2>/dev/null || true
                debug "Installed Cursor rules for $skill_name"
            fi
        fi

        installed_to_entries+=("{\"ide\":\"$ide\",\"path\":\"$dest\"}")
        success "Installed $skill_name to $dest ($ide)"
    done

    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    local installed_to_json
    installed_to_json="[$(IFS=,; echo "${installed_to_entries[*]}")]"

    registry_add_skill \
        "$skill_name" \
        "$INSTALLER_VERSION" \
        "$source_repo" \
        "$commit_hash" \
        "$installed_to_json"

    log_to_file "INSTALL: $skill_name ($source_repo) -> ${ide_targets[*]}"
    success "Skill '$skill_name' installed successfully"
}

# ─── Uninstall Skill ─────────────────────────────────────────────────────────

do_uninstall_skill() {
    local skill_name="$1"
    validate_skill_name "$skill_name"

    if ! registry_is_installed "$skill_name"; then
        warn "Skill '$skill_name' is not installed"
        return 0
    fi

    info "Uninstalling skill: $skill_name"

    local installed_to
    installed_to="$(registry_get_skill "$skill_name" "installed_to")"

    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY-RUN] Would remove '$skill_name' and its registry entry"
        return 0
    fi

    if command -v jq &>/dev/null; then
        while IFS= read -r entry; do
            local ide path
            ide="$(echo "$entry" | jq -r '.ide')"
            path="$(echo "$entry" | jq -r '.path')"
            path="${path/#\~/$HOME}"

            if [[ -d "$path" ]]; then
                backup_skill_references "$skill_name" "$(dirname "$path")"
                rm -rf "$path"
                success "Removed $path ($ide)"
            fi

            # Remove Cursor rules
            if [[ "$ide" == "cursor" ]]; then
                local rule_file="$HOME/$CURSOR_RULES_DIR/${skill_name}.mdc"
                [[ -f "$rule_file" ]] && rm -f "$rule_file"
            fi
        done < <(echo "$installed_to" | jq -c '.[]' 2>/dev/null)
    else
        python3 -c "
import json, sys
data = json.loads(sys.argv[1])
for entry in data:
    print(entry.get('ide', ''), entry.get('path', ''))
" "$installed_to" | while IFS=' ' read -r ide path; do
            path="${path/#\~/$HOME}"
            if [[ -d "$path" ]]; then
                rm -rf "$path"
            fi
        done
    fi

    registry_remove_skill "$skill_name"
    log_to_file "UNINSTALL: $skill_name"
    success "Skill '$skill_name' uninstalled"
}

# ─── List Skills ─────────────────────────────────────────────────────────────

do_list() {
    registry_init

    local installed_skills
    installed_skills="$(registry_list_installed)"

    if [[ -z "$installed_skills" ]]; then
        info "No skills installed"
        info "Run: ./install.sh install --all"
        return 0
    fi

    echo ""
    printf "  ${BOLD}%-25s %-12s %-10s %s${RESET}\n" "SKILL" "COMMIT" "DATE" "IDEs"
    printf "  %-25s %-12s %-10s %s\n" "─────────────────────────" "────────────" "──────────" "────"

    while IFS= read -r skill_name; do
        [[ -z "$skill_name" ]] && continue
        local hash date_str ides

        hash="$(registry_get_skill "$skill_name" "docs_commit_hash" 2>/dev/null)" || hash="unknown"
        date_str="$(registry_get_skill "$skill_name" "docs_fetched_date" 2>/dev/null)" || date_str=""
        date_str="${date_str:0:10}"

        local installed_to
        installed_to="$(registry_get_skill "$skill_name" "installed_to" 2>/dev/null)" || installed_to="[]"
        if command -v jq &>/dev/null; then
            ides="$(echo "$installed_to" | jq -r '[.[].ide] | join(", ")' 2>/dev/null)" || ides=""
        else
            ides="installed"
        fi

        printf "  %-25s %-12s %-10s %s\n" "$skill_name" "${hash:0:8}" "$date_str" "$ides"
    done <<< "$installed_skills"
    echo ""
}

do_available() {
    echo ""
    printf "  ${BOLD}%-25s %-50s %s${RESET}\n" "SKILL" "REPOSITORY" "BRANCH"
    printf "  %-25s %-50s %s\n" "─────────────────────────" "──────────────────────────────────────────────────" "──────"

    for skill_name in "${ALL_SKILLS[@]}"; do
        local repo branch installed_marker=""
        repo="$(get_skill_config "$skill_name" "source_repo")"
        branch="$(get_skill_config "$skill_name" "branch")"
        registry_is_installed "$skill_name" && installed_marker=" [installed]"
        printf "  %-25s %-50s %s%s\n" "$skill_name" "$repo" "$branch" "$installed_marker"
    done
    echo ""
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
    local command=""
    local skill_name=""
    local all_skills=false
    local ide_flag="auto"
    local no_auto_check=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            install|uninstall|update|check-updates|verify|list|available|upgrade-installer|help)
                command="$1"
                shift
                ;;
            --skill)
                skill_name="${2:-}"
                [[ -z "$skill_name" ]] && { error "--skill requires a skill name"; exit 2; }
                shift 2
                ;;
            --all)
                all_skills=true
                shift
                ;;
            --ide)
                ide_flag="${2:-}"
                [[ -z "$ide_flag" ]] && { error "--ide requires a value (claude, cursor, both)"; exit 2; }
                shift 2
                ;;
            --verbose|-v)
                VERBOSE="true"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force|-f)
                FORCE=true
                shift
                ;;
            --no-auto-check)
                no_auto_check=true
                shift
                ;;
            --help|-h)
                command="help"
                shift
                ;;
            *)
                error "Unknown argument: $1"
                echo ""
                usage
                exit 2
                ;;
        esac
    done

    if [[ -z "$command" ]]; then
        usage
        exit 0
    fi

    case "$command" in
        help)
            usage
            exit 0
            ;;
        install)
            check_prerequisites
            registry_init

            local ide_targets
            ide_targets="$(resolve_target_ides "$ide_flag")"

            if [[ "$all_skills" == "true" ]]; then
                for s in "${ALL_SKILLS[@]}"; do
                    do_install_skill "$s" "$ide_targets" || true
                done
            elif [[ -n "$skill_name" ]]; then
                do_install_skill "$skill_name" "$ide_targets"
            else
                error "Specify --skill NAME or --all"
                exit 2
            fi

            if [[ "$no_auto_check" != "true" ]]; then
                check_all_updates 2>/dev/null || true
            fi
            ;;
        uninstall)
            registry_init

            if [[ "$all_skills" == "true" ]]; then
                local installed
                installed="$(registry_list_installed)"
                while IFS= read -r s; do
                    [[ -z "$s" ]] && continue
                    do_uninstall_skill "$s" || true
                done <<< "$installed"
            elif [[ -n "$skill_name" ]]; then
                do_uninstall_skill "$skill_name"
            else
                error "Specify --skill NAME or --all"
                exit 2
            fi
            ;;
        update)
            check_prerequisites
            registry_init

            if [[ "$all_skills" == "true" ]]; then
                upgrade_all_skills
            elif [[ -n "$skill_name" ]]; then
                upgrade_skill "$skill_name"
            else
                error "Specify --skill NAME or --all"
                exit 2
            fi
            ;;
        check-updates)
            registry_init
            check_all_updates
            ;;
        verify)
            registry_init

            if [[ "$all_skills" == "true" ]]; then
                validate_all
            elif [[ -n "$skill_name" ]]; then
                validate_skill "$skill_name"
            else
                validate_all
            fi
            ;;
        list)
            registry_init
            do_list
            ;;
        available)
            do_available
            ;;
        upgrade-installer)
            check_prerequisites
            upgrade_installer
            ;;
        *)
            error "Unknown command: $command"
            usage
            exit 2
            ;;
    esac
}

main "$@"
