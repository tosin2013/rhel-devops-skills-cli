#!/usr/bin/env bash
# Upgrade management for installer and skills

# --- Check for Installer Updates ---

check_installer_update() {
    local api_url="https://api.github.com/repos/tosin2013/rhel-devops-skills-cli/releases/latest"
    local auth_args=()
    [[ -n "${GITHUB_TOKEN:-}" ]] && auth_args=(-H "Authorization: token $GITHUB_TOKEN")

    local response
    response="$(curl -s "${auth_args[@]}" "$api_url" 2>/dev/null)" || return 1

    local remote_version
    if command -v jq &>/dev/null; then
        remote_version="$(echo "$response" | jq -r '.tag_name // empty' 2>/dev/null)"
    else
        remote_version="$(echo "$response" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tag_name',''))" 2>/dev/null)"
    fi

    remote_version="${remote_version#v}"

    if [[ -z "$remote_version" ]]; then
        debug "Could not determine remote installer version"
        return 1
    fi

    if [[ "$remote_version" != "$INSTALLER_VERSION" ]]; then
        echo "$remote_version"
        return 0
    fi

    return 1
}

# --- Upgrade Installer ---

upgrade_installer() {
    info "Checking for installer updates..."

    local remote_version
    if remote_version="$(check_installer_update)"; then
        info "New version available: v$remote_version (current: v$INSTALLER_VERSION)"
    else
        success "Installer is up to date (v$INSTALLER_VERSION)"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY-RUN] Would upgrade installer from v$INSTALLER_VERSION to v$remote_version"
        return 0
    fi

    local script_root
    script_root="$(get_script_dir)"
    local install_dir="$script_root/.."

    local backup_path
    backup_path="$BACKUP_DIR/installer-v${INSTALLER_VERSION}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_path"
    cp -r "$install_dir/install.sh" "$install_dir/lib" "$backup_path/" 2>/dev/null
    info "Current installer backed up to $backup_path"

    local tmpdir
    tmpdir="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmpdir'" RETURN

    if git clone --depth 1 "$INSTALLER_REPO" "$tmpdir/repo" 2>/dev/null; then
        cp "$tmpdir/repo/install.sh" "$install_dir/install.sh"
        cp -r "$tmpdir/repo/lib/"* "$install_dir/lib/"
        cp -r "$tmpdir/repo/skills/"* "$install_dir/skills/" 2>/dev/null || true
        chmod +x "$install_dir/install.sh"
        success "Installer upgraded to v$remote_version"
        info "Restart the installer to use the new version"
    else
        error "Failed to download new installer version"
        warn "Restoring from backup..."
        cp "$backup_path/install.sh" "$install_dir/install.sh"
        cp -r "$backup_path/lib/"* "$install_dir/lib/"
        error "Upgrade failed. Previous version restored."
        return 12
    fi
}

# --- Upgrade Skill ---

upgrade_skill() {
    local skill_name="$1"
    validate_skill_name "$skill_name"

    if ! registry_is_installed "$skill_name"; then
        error "Skill '$skill_name' is not installed. Install first with: ./install.sh --skill $skill_name"
        return 6
    fi

    info "Checking for updates to '$skill_name'..."

    local source_repo branch
    source_repo="$(get_skill_config "$skill_name" "source_repo")"
    branch="$(get_skill_config "$skill_name" "branch")"

    local stored_hash
    stored_hash="$(registry_get_skill "$skill_name" "docs_commit_hash" 2>/dev/null)" || stored_hash=""

    local remote_hash
    remote_hash="$(get_remote_commit_hash "$source_repo" "$branch")"

    if [[ -z "$remote_hash" ]]; then
        error "Could not reach $source_repo"
        return 4
    fi

    if [[ "$remote_hash" == "$stored_hash" ]] && [[ "$FORCE" != "true" ]]; then
        success "Skill '$skill_name' is already up to date (${stored_hash:0:8})"
        return 0
    fi

    info "Updating '$skill_name': ${stored_hash:0:8} -> ${remote_hash:0:8}"

    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY-RUN] Would update '$skill_name' documentation"
        return 0
    fi

    local installed_to
    installed_to="$(registry_get_skill "$skill_name" "installed_to")"
    local ide_dirs=()

    if command -v jq &>/dev/null; then
        while IFS= read -r path; do
            path="${path/#\~/$HOME}"
            ide_dirs+=("$path")
        done < <(echo "$installed_to" | jq -r '.[].path' 2>/dev/null)
    fi

    for ide_dir_parent in "${ide_dirs[@]}"; do
        backup_skill_references "$skill_name" "$(dirname "$ide_dir_parent")"
    done

    local tmpdir
    tmpdir="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmpdir'" RETURN

    local commit_hash
    commit_hash="$(fetch_skill_docs "$skill_name" "$tmpdir/skill")" || return $?

    for ide_path in "${ide_dirs[@]}"; do
        ide_path="${ide_path/#\~/$HOME}"
        if [[ -d "$tmpdir/skill/references" ]]; then
            rm -rf "$ide_path/references"
            cp -r "$tmpdir/skill/references" "$ide_path/references"
        fi
        if [[ -f "$tmpdir/skill/SKILL.md" ]]; then
            cp "$tmpdir/skill/SKILL.md" "$ide_path/SKILL.md"
        fi
    done

    local now
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    registry_update_skill_field "$skill_name" "docs_commit_hash" "$commit_hash"
    registry_update_skill_field "$skill_name" "docs_fetched_date" "$now"

    success "Skill '$skill_name' updated to ${commit_hash:0:8}"
}

# --- Upgrade All ---

upgrade_all_skills() {
    local installed_skills
    installed_skills="$(registry_list_installed)"
    if [[ -z "$installed_skills" ]]; then
        info "No skills installed"
        return 0
    fi

    local total=0 updated=0 failed=0
    while IFS= read -r skill_name; do
        [[ -z "$skill_name" ]] && continue
        total=$((total + 1))
        if upgrade_skill "$skill_name"; then
            updated=$((updated + 1))
        else
            failed=$((failed + 1))
        fi
    done <<< "$installed_skills"

    echo ""
    info "Upgrade complete: $updated/$total updated, $failed failed"
}
