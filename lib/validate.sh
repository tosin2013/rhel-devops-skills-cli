#!/usr/bin/env bash
# Installation verification utilities

# --- Validate Single Skill ---

validate_skill() {
    local skill_name="$1"
    local errors=0

    info "Verifying skill '$skill_name'..."

    if ! registry_is_installed "$skill_name"; then
        error "Skill '$skill_name' is not in the registry"
        return 10
    fi

    local installed_to
    installed_to="$(registry_get_skill "$skill_name" "installed_to")"

    if command -v jq &>/dev/null; then
        while IFS= read -r entry; do
            local ide path
            ide="$(echo "$entry" | jq -r '.ide')"
            path="$(echo "$entry" | jq -r '.path')"
            path="${path/#\~/$HOME}"
            _validate_skill_at_path "$skill_name" "$ide" "$path" || errors=$((errors + 1))
        done < <(echo "$installed_to" | jq -c '.[]' 2>/dev/null)
    else
        python3 -c "
import json, sys
data = json.loads(sys.argv[1])
for entry in data:
    print(entry.get('ide', ''), entry.get('path', ''))
" "$installed_to" | while IFS=' ' read -r ide path; do
            path="${path/#\~/$HOME}"
            _validate_skill_at_path "$skill_name" "$ide" "$path" || errors=$((errors + 1))
        done
    fi

    if [[ $errors -eq 0 ]]; then
        success "Skill '$skill_name' is correctly installed"
        return 0
    else
        error "Skill '$skill_name' has $errors issue(s)"
        return 10
    fi
}

_validate_skill_at_path() {
    local skill_name="$1" ide="$2" path="$3"
    local ok=0

    debug "Checking $ide installation at $path"

    if [[ ! -d "$path" ]]; then
        error "  [$ide] Directory missing: $path"
        return 1
    fi

    if [[ ! -f "$path/SKILL.md" ]]; then
        error "  [$ide] SKILL.md missing: $path/SKILL.md"
        ok=1
    else
        # Validate YAML frontmatter exists
        if ! head -1 "$path/SKILL.md" | grep -q '^---$'; then
            warn "  [$ide] SKILL.md missing YAML frontmatter"
        else
            success "  [$ide] SKILL.md present with frontmatter"
            _validate_frontmatter "$skill_name" "$ide" "$path/SKILL.md" || ok=1
        fi
    fi

    if [[ ! -d "$path/references" ]]; then
        warn "  [$ide] references/ directory missing (docs may not be fetched yet)"
    else
        local ref_count
        ref_count="$(find "$path/references" -type f | wc -l)"
        if [[ "$ref_count" -eq 0 ]]; then
            warn "  [$ide] references/ is empty"
        else
            success "  [$ide] references/ contains $ref_count file(s)"
        fi
    fi

    local perms
    perms="$(stat -c '%a' "$path" 2>/dev/null || stat -f '%Lp' "$path" 2>/dev/null)"
    if [[ "$perms" != "700" && "$perms" != "755" && "$perms" != "750" ]]; then
        debug "  [$ide] Directory permissions: $perms"
    fi

    # Check body line count (spec recommends < 500 lines)
    local body_lines
    body_lines="$(awk 'BEGIN{c=0; past=0} /^---$/{c++; if(c==2){past=1; next}} past{n++} END{print n+0}' "$path/SKILL.md")"
    if (( body_lines > 500 )); then
        warn "  [$ide] SKILL.md body is $body_lines lines (spec recommends < 500)"
    fi

    return $ok
}

# Validate frontmatter fields per agentskills.io specification
_validate_frontmatter() {
    local skill_name="$1" ide="$2" skill_file="$3"
    local issues=0

    # Extract frontmatter (between first and second ---)
    local frontmatter
    frontmatter="$(awk '/^---$/{c++; next} c==1{print} c>=2{exit}' "$skill_file")"

    # Check name field exists and matches directory name
    local fm_name
    fm_name="$(echo "$frontmatter" | grep '^name:' | head -1 | sed 's/^name:[[:space:]]*//')"
    if [[ -z "$fm_name" ]]; then
        error "  [$ide] Frontmatter missing required 'name' field"
        issues=1
    elif [[ "$fm_name" != "$skill_name" ]]; then
        error "  [$ide] Frontmatter name '$fm_name' does not match directory '$skill_name'"
        issues=1
    else
        # Validate name format: lowercase, hyphens, no consecutive hyphens, no edge hyphens, max 64
        if (( ${#fm_name} > 64 )); then
            error "  [$ide] name exceeds 64 characters (${#fm_name})"
            issues=1
        fi
        if [[ "$fm_name" =~ [^a-z0-9-] ]]; then
            error "  [$ide] name contains invalid characters (only lowercase a-z, 0-9, hyphens allowed)"
            issues=1
        fi
        if [[ "$fm_name" =~ ^- ]] || [[ "$fm_name" =~ -$ ]]; then
            error "  [$ide] name must not start or end with a hyphen"
            issues=1
        fi
        if [[ "$fm_name" =~ -- ]]; then
            error "  [$ide] name must not contain consecutive hyphens"
            issues=1
        fi
    fi

    # Check description field
    local has_desc
    has_desc="$(echo "$frontmatter" | grep -c '^description:')"
    if [[ "$has_desc" -eq 0 ]]; then
        error "  [$ide] Frontmatter missing required 'description' field"
        issues=1
    else
        # Extract full description (handles multi-line >- syntax)
        local desc_len
        if command -v python3 &>/dev/null; then
            desc_len="$(python3 -c "
import re
text = open('$skill_file').read()
fm = re.search(r'^---\n(.*?)\n---', text, re.DOTALL)
if fm:
    c = fm.group(1)
    m = re.search(r'description:\s*>-?\s*\n((?:\s+.*\n)*)', c)
    if m:
        d = ' '.join(l.strip() for l in m.group(1).strip().splitlines())
    else:
        m = re.search(r'description:\s*(.*)', c)
        d = m.group(1).strip() if m else ''
    print(len(d))
else:
    print(0)
" 2>/dev/null)"
        fi
        if [[ -n "$desc_len" ]] && (( desc_len > 1024 )); then
            error "  [$ide] description exceeds 1024 characters ($desc_len)"
            issues=1
        fi
    fi

    # Check license field (warn if missing, not an error)
    local has_license
    has_license="$(echo "$frontmatter" | grep -c '^license:')"
    if [[ "$has_license" -eq 0 ]]; then
        warn "  [$ide] Frontmatter missing optional 'license' field (recommended)"
    fi

    # Check for non-standard fields (warn only)
    local non_standard
    non_standard="$(echo "$frontmatter" | grep -E '^[a-z_-]+:' | sed 's/:.*//' | grep -vE '^(name|description|license|compatibility|metadata|allowed-tools)$')"
    if [[ -n "$non_standard" ]]; then
        warn "  [$ide] Non-standard frontmatter fields: $(echo "$non_standard" | tr '\n' ', ' | sed 's/,$//')"
    fi

    return $issues
}

# --- Validate Registry ---

validate_registry() {
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        warn "Registry file not found. No skills installed yet."
        return 0
    fi

    if command -v jq &>/dev/null; then
        if ! jq empty "$REGISTRY_FILE" 2>/dev/null; then
            error "Registry file is corrupted (invalid JSON)"
            warn "Attempting to restore from backup..."
            _restore_registry_from_backup
            return 11
        fi
    else
        if ! python3 -c "import json; json.load(open('$REGISTRY_FILE'))" 2>/dev/null; then
            error "Registry file is corrupted (invalid JSON)"
            warn "Attempting to restore from backup..."
            _restore_registry_from_backup
            return 11
        fi
    fi

    success "Registry file is valid"
    return 0
}

_restore_registry_from_backup() {
    local latest_backup
    latest_backup="$(ls -t "$BACKUP_DIR"/registry-*.json 2>/dev/null | head -1)"
    if [[ -n "$latest_backup" ]]; then
        cp "$latest_backup" "$REGISTRY_FILE"
        success "Registry restored from $latest_backup"
    else
        warn "No backup found. Creating fresh registry."
        rm -f "$REGISTRY_FILE"
        registry_init
    fi
}

# --- Verify All Installed Skills ---

validate_all() {
    validate_registry || return $?

    local installed_skills
    installed_skills="$(registry_list_installed)"
    if [[ -z "$installed_skills" ]]; then
        info "No skills installed"
        return 0
    fi

    local total=0 ok=0 failed=0
    while IFS= read -r skill_name; do
        [[ -z "$skill_name" ]] && continue
        total=$((total + 1))
        if validate_skill "$skill_name"; then
            ok=$((ok + 1))
        else
            failed=$((failed + 1))
        fi
    done <<< "$installed_skills"

    echo ""
    info "Verification complete: $ok/$total OK, $failed failed"
    [[ $failed -eq 0 ]]
}
