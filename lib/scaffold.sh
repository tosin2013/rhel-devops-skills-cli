#!/usr/bin/env bash
# Scaffold module for rhel-devops-skills-cli
# Generates standardized project files from topology-specific templates
# shellcheck disable=SC2034

# ─── Constants ───────────────────────────────────────────────────────────────

readonly SCAFFOLD_TYPES=("hub-student" "demo" "agnosticd-infra" "shared-cluster")

# ─── Template Directory Resolution ──────────────────────────────────────────

get_template_dir() {
    local type="$1"
    local script_root
    script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local repo_root="$script_root/.."

    case "$type" in
        hub-student)
            echo "$repo_root/skills/agnosticd-hub-student/templates"
            ;;
        demo)
            echo "$repo_root/templates/demo"
            ;;
        agnosticd-infra)
            echo "$repo_root/templates/agnosticd-infra"
            ;;
        shared-cluster)
            echo "$repo_root/templates/shared-cluster"
            ;;
    esac
}

# ─── Validation ──────────────────────────────────────────────────────────────

validate_scaffold_type() {
    local type="$1"
    for t in "${SCAFFOLD_TYPES[@]}"; do
        [[ "$t" == "$type" ]] && return 0
    done
    error "Invalid scaffold type: $type"
    error "Available types: ${SCAFFOLD_TYPES[*]}"
    return 1
}

# ─── Interactive Prompts ─────────────────────────────────────────────────────

prompt_value() {
    local prompt="$1"
    local default="$2"
    local varname="$3"

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        echo "$default"
        return
    fi

    local value
    read -rp "  $prompt [$default]: " value
    echo "${value:-$default}"
}

collect_common_vars() {
    local -n vars_ref=$1
    local output_dir="$2"

    local detected_name
    detected_name="$(basename "$output_dir")"

    local detected_repo=""
    if command -v git &>/dev/null && git -C "$output_dir" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
        detected_repo="$(git -C "$output_dir" remote get-url origin 2>/dev/null)" || true
    fi

    echo ""
    info "Common configuration:"
    vars_ref[PROJECT_NAME]="$(prompt_value "Project name" "$detected_name" "PROJECT_NAME")"
    vars_ref[CLOUD_PROVIDER]="$(prompt_value "Cloud provider (aws/gcp/azure)" "aws" "CLOUD_PROVIDER")"
    vars_ref[CLOUD_REGION]="$(prompt_value "Cloud region" "us-east-2" "CLOUD_REGION")"
    vars_ref[AGD_ROOT]="$(prompt_value "AgnosticD v2 root path" "~/Development/agnosticd-v2" "AGD_ROOT")"
    vars_ref[REPO_URL]="$(prompt_value "Project git remote URL" "${detected_repo:-https://github.com/your-org/your-project}" "REPO_URL")"
}

collect_hub_student_vars() {
    local -n vars_ref=$1

    echo ""
    info "Hub-student configuration:"
    vars_ref[CONFIG_NAME_HUB]="$(prompt_value "AgnosticD hub config name" "ocp4-hub" "CONFIG_NAME_HUB")"
    vars_ref[CONFIG_NAME_STUDENT]="$(prompt_value "AgnosticD student config name" "ocp4-sno" "CONFIG_NAME_STUDENT")"
    vars_ref[NUM_STUDENTS]="$(prompt_value "Default student count" "2" "NUM_STUDENTS")"
}

collect_demo_vars() {
    local -n vars_ref=$1

    echo ""
    info "Demo configuration:"
    vars_ref[CONFIG_NAME]="$(prompt_value "AgnosticD config name" "ocp4-demo" "CONFIG_NAME")"
    vars_ref[INCLUDE_SHOWROOM]="$(prompt_value "Include Showroom? (y/n)" "y" "INCLUDE_SHOWROOM")"
}

collect_infra_vars() {
    local -n vars_ref=$1

    echo ""
    info "Infrastructure configuration:"
    vars_ref[CONFIG_NAMES]="$(prompt_value "AgnosticD config name(s), comma-separated" "ocp4-cluster" "CONFIG_NAMES")"
    vars_ref[ENVIRONMENTS]="$(prompt_value "Environment names (comma-separated)" "dev,prod" "ENVIRONMENTS")"
}

collect_shared_cluster_vars() {
    local -n vars_ref=$1

    echo ""
    info "Shared-cluster configuration:"
    vars_ref[CONFIG_NAME]="$(prompt_value "AgnosticD config name" "ocp4-workshop" "CONFIG_NAME")"
    vars_ref[NUM_USERS]="$(prompt_value "Number of workshop users" "10" "NUM_USERS")"
    vars_ref[NAMESPACE_PREFIX]="$(prompt_value "User namespace prefix" "user" "NAMESPACE_PREFIX")"
    vars_ref[INCLUDE_SHOWROOM]="$(prompt_value "Include Showroom? (y/n)" "y" "INCLUDE_SHOWROOM")"
}

# ─── Template Processing ─────────────────────────────────────────────────────

substitute_template() {
    local template_file="$1"
    local output_file="$2"
    shift 2

    local content
    content="$(cat "$template_file")"

    local key value
    for key in "$@"; do
        value="${SCAFFOLD_VARS[$key]:-}"
        content="${content//\{\{$key\}\}/$value}"
    done

    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
}

process_templates() {
    local template_dir="$1"
    local output_dir="$2"

    if [[ ! -d "$template_dir" ]]; then
        error "Template directory not found: $template_dir"
        return 1
    fi

    local var_keys=("${!SCAFFOLD_VARS[@]}")

    while IFS= read -r -d '' tpl_file; do
        local rel_path="${tpl_file#"$template_dir/"}"
        local out_path="${rel_path%.tpl}"
        local dest="$output_dir/$out_path"

        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY-RUN] Would generate: $dest"
            continue
        fi

        substitute_template "$tpl_file" "$dest" "${var_keys[@]}"

        if [[ "$out_path" == *.sh ]]; then
            chmod +x "$dest"
        fi

        debug "Generated: $dest"
    done < <(find "$template_dir" -name "*.tpl" -print0)
}

# ─── Shared Library Installation ─────────────────────────────────────────────

install_shared_libs() {
    local script_root
    script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local target_dir="${SHARED_LIB_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/rhel-devops-skills}"

    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY-RUN] Would install shared libs to $target_dir"
        return 0
    fi

    mkdir -p "$target_dir"

    local libs=("workshop-common.sh" "workshop.mk" "quota-check.sh")
    for lib in "${libs[@]}"; do
        if [[ -f "$script_root/$lib" ]]; then
            cp "$script_root/$lib" "$target_dir/$lib"
            debug "Installed $lib to $target_dir/"
        fi
    done

    success "Shared libraries installed to $target_dir/"
}

# ─── .gitignore Management ───────────────────────────────────────────────────

update_gitignore() {
    local output_dir="$1"
    local gitignore="$output_dir/.gitignore"

    local entries=(
        "# Generated by rhel-devops-skills scaffold"
        "deploy/config.yml"
        "student_info.txt"
        "deployment_info.txt"
        "logs/"
        ".workshop-lock"
        ".workshop-state"
    )

    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY-RUN] Would update .gitignore"
        return 0
    fi

    local needs_update=false
    for entry in "${entries[@]}"; do
        [[ "$entry" == "#"* ]] && continue
        if ! grep -qxF "$entry" "$gitignore" 2>/dev/null; then
            needs_update=true
            break
        fi
    done

    if [[ "$needs_update" == "true" ]]; then
        echo "" >> "$gitignore"
        for entry in "${entries[@]}"; do
            if [[ "$entry" == "#"* ]]; then
                echo "$entry" >> "$gitignore"
            elif ! grep -qxF "$entry" "$gitignore" 2>/dev/null; then
                echo "$entry" >> "$gitignore"
            fi
        done
        success "Updated .gitignore with scaffold entries"
    else
        debug ".gitignore already has scaffold entries"
    fi
}

# ─── Main Scaffold Function ──────────────────────────────────────────────────

do_scaffold() {
    local scaffold_type=""
    local output_dir="."
    local vars_file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type)
                scaffold_type="${2:-}"
                [[ -z "$scaffold_type" ]] && { error "--type requires a value"; return 2; }
                shift 2
                ;;
            --output)
                output_dir="${2:-}"
                [[ -z "$output_dir" ]] && { error "--output requires a directory path"; return 2; }
                shift 2
                ;;
            --vars)
                vars_file="${2:-}"
                shift 2
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            *)
                error "Unknown scaffold option: $1"
                return 2
                ;;
        esac
    done

    if [[ -z "$scaffold_type" ]]; then
        error "Scaffold type is required: --type hub-student|demo|agnosticd-infra|shared-cluster"
        return 2
    fi

    validate_scaffold_type "$scaffold_type" || return $?

    output_dir="$(cd "$output_dir" 2>/dev/null && pwd)" || {
        error "Output directory does not exist: $output_dir"
        return 1
    }

    info "Scaffolding project: type=$scaffold_type, output=$output_dir"

    # Collect variables
    declare -A SCAFFOLD_VARS
    SCAFFOLD_VARS[PROJECT_TYPE]="$scaffold_type"

    if [[ -n "$vars_file" && -f "$vars_file" ]]; then
        info "Loading variables from: $vars_file"
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" == "#"* ]] && continue
            SCAFFOLD_VARS[$key]="$value"
        done < "$vars_file"
    else
        collect_common_vars SCAFFOLD_VARS "$output_dir"

        case "$scaffold_type" in
            hub-student)  collect_hub_student_vars SCAFFOLD_VARS ;;
            demo)         collect_demo_vars SCAFFOLD_VARS ;;
            agnosticd-infra) collect_infra_vars SCAFFOLD_VARS ;;
            shared-cluster)  collect_shared_cluster_vars SCAFFOLD_VARS ;;
        esac
    fi

    # Process templates
    local template_dir
    template_dir="$(get_template_dir "$scaffold_type")"

    echo ""
    info "Generating project files from templates..."
    process_templates "$template_dir" "$output_dir"

    # Update .gitignore
    update_gitignore "$output_dir"

    # Install shared libraries
    install_shared_libs

    if [[ "$DRY_RUN" != "true" ]]; then
        echo ""
        success "Scaffold complete! Generated files for type: $scaffold_type"
        echo ""
        info "Next steps:"
        echo "  1. Review generated files and resolve any TODO: markers"
        echo "  2. Run: make setup      (install prerequisites)"
        echo "  3. Run: make check-quota (verify cloud quotas)"
        echo "  4. Run: make deploy      (provision environment)"
        echo ""
        info "Generated files:"
        find "$output_dir" -newer "$output_dir/.gitignore" -type f 2>/dev/null | sort | while read -r f; do
            echo "  $f"
        done
    fi
}
