#!/usr/bin/env bash
# Documentation fetching from source repositories (ADR-003, ADR-008)

readonly MAX_RETRIES=3
readonly RETRY_DELAY=2

# --- Git Auth Headers ---

_github_auth_header() {
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "-H" "Authorization: token $GITHUB_TOKEN"
    fi
}

# --- Remote Commit Hash ---

get_remote_commit_hash() {
    local repo="$1" branch="$2"
    local hash
    hash="$(git ls-remote "$repo" "refs/heads/$branch" 2>/dev/null | cut -f1)"
    echo "${hash:-}"
}

# --- Fetch Skill Documentation ---

fetch_skill_docs() {
    local skill_name="$1"
    local target_dir="$2"
    local source_repo branch

    source_repo="$(get_skill_config "$skill_name" "source_repo")"
    branch="$(get_skill_config "$skill_name" "branch")"

    info "Fetching documentation for '$skill_name' from $source_repo..."
    log_to_file "FETCH: $skill_name from $source_repo ($branch)"

    local tmpdir
    tmpdir="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmpdir'" RETURN

    local attempt=0
    local clone_ok=false
    while (( attempt < MAX_RETRIES )); do
        attempt=$((attempt + 1))
        debug "Clone attempt $attempt/$MAX_RETRIES"

        if git clone --depth 1 --branch "$branch" --single-branch \
               "$source_repo" "$tmpdir/repo" 2>/dev/null; then
            clone_ok=true
            break
        fi

        warn "Clone attempt $attempt failed, retrying in ${RETRY_DELAY}s..."
        rm -rf "$tmpdir/repo"
        sleep "$RETRY_DELAY"
    done

    if [[ "$clone_ok" != "true" ]]; then
        error "Failed to fetch documentation from $source_repo after $MAX_RETRIES attempts"
        error "Check network connectivity and repository URL"
        return 4
    fi

    local commit_hash
    commit_hash="$(git -C "$tmpdir/repo" rev-parse HEAD 2>/dev/null)"

    mkdir -p "$target_dir/references"

    local script_root
    script_root="$(get_script_dir)"
    local skill_src="$script_root/../skills/$skill_name"

    if [[ -f "$skill_src/SKILL.md" ]]; then
        cp "$skill_src/SKILL.md" "$target_dir/SKILL.md"
    fi

    _copy_docs_for_skill "$skill_name" "$tmpdir/repo" "$target_dir/references"

    if [[ -f "$skill_src/references/REFERENCE.md" ]]; then
        cp "$skill_src/references/REFERENCE.md" "$target_dir/references/REFERENCE.md"
    fi

    echo "$commit_hash"
}

_copy_docs_for_skill() {
    local skill_name="$1" repo_dir="$2" refs_dir="$3"
    local doc_paths_str
    doc_paths_str="$(get_skill_config "$skill_name" "doc_paths")"

    if [[ -n "$doc_paths_str" ]]; then
        local -a doc_paths=()
        read -ra doc_paths <<< "$doc_paths_str"
        for doc_path in "${doc_paths[@]}"; do
            local src="$repo_dir/$doc_path"
            if [[ -f "$src" ]]; then
                local dest_name
                dest_name="$(basename "$doc_path")"
                local dir_prefix
                dir_prefix="$(dirname "$doc_path")"
                if [[ "$dir_prefix" != "." && "$dir_prefix" != "/" ]]; then
                    dest_name="${dir_prefix//\//-}-${dest_name}"
                fi
                cp "$src" "$refs_dir/$dest_name"
                debug "Copied $doc_path -> $refs_dir/$dest_name"
            else
                debug "Doc path not found: $src"
            fi
        done
    else
        _copy_if_exists "$repo_dir" "$refs_dir" "README.md" "README.adoc"
        [[ -d "$repo_dir/docs" ]] && cp -r "$repo_dir/docs" "$refs_dir/docs"
    fi
}

_copy_if_exists() {
    local src_dir="$1" dest_dir="$2"
    shift 2

    for pattern in "$@"; do
        local found=false
        while IFS= read -r -d '' file; do
            local basename
            basename="$(basename "$file")"
            cp "$file" "$dest_dir/$basename" 2>/dev/null && found=true
        done < <(find "$src_dir" -maxdepth 1 -name "$pattern" -print0 2>/dev/null)
        if [[ "$found" == "true" ]]; then
            debug "Copied $pattern from $src_dir to $dest_dir"
        fi
    done
}

# --- Auto-Check for Updates (ADR-008) ---

check_updates_for_skill() {
    local skill_name="$1"
    local stored_hash source_repo branch remote_hash

    stored_hash="$(registry_get_skill "$skill_name" "docs_commit_hash" 2>/dev/null)" || return 1
    source_repo="$(get_skill_config "$skill_name" "source_repo")"
    branch="$(get_skill_config "$skill_name" "branch")"

    remote_hash="$(get_remote_commit_hash "$source_repo" "$branch")"

    if [[ -n "$remote_hash" && "$remote_hash" != "$stored_hash" ]]; then
        echo "update_available"
        return 0
    fi

    echo "up_to_date"
    return 0
}

check_all_updates() {
    local auto_check
    auto_check="$(registry_get_auto_check)"
    [[ "$auto_check" == "true" ]] || return 0

    local installed_skills
    installed_skills="$(registry_list_installed)"
    [[ -z "$installed_skills" ]] && return 0

    local updates_available=0
    while IFS= read -r skill_name; do
        [[ -z "$skill_name" ]] && continue
        local status
        status="$(check_updates_for_skill "$skill_name" 2>/dev/null)" || continue
        if [[ "$status" == "update_available" ]]; then
            info "Update available for '$skill_name' (run: ./install.sh --update $skill_name)"
            updates_available=$((updates_available + 1))
        fi
    done <<< "$installed_skills"

    if [[ $updates_available -gt 0 ]]; then
        info "$updates_available skill(s) have updates available"
    fi
}

# --- Backup Skill ---

backup_skill_references() {
    local skill_name="$1" ide_dir="$2"
    local skill_path="$ide_dir/$skill_name"
    if [[ -d "$skill_path/references" ]]; then
        local backup_path
        backup_path="$BACKUP_DIR/${skill_name}-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_path"
        cp -r "$skill_path/references" "$backup_path/"
        debug "Backed up $skill_path/references to $backup_path"
        echo "$backup_path"
    fi
}
