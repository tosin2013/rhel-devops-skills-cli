#!/usr/bin/env bash
# JSON registry management with jq/python3 fallback (ADR-006)

# --- JSON Helpers ---

_json_query() {
    if command -v jq &>/dev/null; then
        jq "$@"
    else
        python3 -c "
import json, sys
data = json.load(sys.stdin)
# Simple jq-compatible queries
query = sys.argv[1] if len(sys.argv) > 1 else '.'
if query == '.':
    json.dump(data, sys.stdout, indent=2)
elif query.startswith('.'):
    parts = query.lstrip('.').split('.')
    result = data
    for p in parts:
        if p:
            result = result.get(p) if isinstance(result, dict) else None
    if result is not None:
        if isinstance(result, (dict, list)):
            json.dump(result, sys.stdout, indent=2)
        else:
            print(result)
" "$@"
    fi
}

_json_set() {
    local file="$1" filter="$2"
    if command -v jq &>/dev/null; then
        local tmp="${file}.tmp.$$"
        jq "$filter" "$file" > "$tmp" && mv "$tmp" "$file"
    else
        python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
# Apply filter via eval (trusted internal use only)
exec(sys.argv[2])
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2)
" "$file" "$filter"
    fi
}

# --- Registry Init ---

registry_init() {
    ensure_data_dir
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        cat > "$REGISTRY_FILE" << 'REGISTRY_EOF'
{
  "version": "1.0",
  "installer_version": "1.0.0",
  "last_updated": "",
  "auto_check_updates": true,
  "installed_skills": []
}
REGISTRY_EOF
        debug "Registry initialized at $REGISTRY_FILE"
    fi
}

# --- Registry Backup ---

registry_backup() {
    if [[ -f "$REGISTRY_FILE" ]]; then
        local backup_name
        backup_name="registry-$(date +%Y%m%d-%H%M%S).json"
        cp "$REGISTRY_FILE" "$BACKUP_DIR/$backup_name"
        debug "Registry backed up to $BACKUP_DIR/$backup_name"
    fi
}

# --- Registry Read ---

registry_get_all() {
    [[ -f "$REGISTRY_FILE" ]] || { echo "{}"; return; }
    cat "$REGISTRY_FILE"
}

registry_get_skill() {
    local name="$1" field="${2:-}"
    [[ -f "$REGISTRY_FILE" ]] || return 1

    if command -v jq &>/dev/null; then
        local skill_json
        skill_json="$(jq -r --arg n "$name" '.installed_skills[] | select(.name == $n)' "$REGISTRY_FILE" 2>/dev/null)"
        [[ -z "$skill_json" || "$skill_json" == "null" ]] && return 1
        if [[ -n "$field" ]]; then
            echo "$skill_json" | jq -r ".$field // empty"
        else
            echo "$skill_json"
        fi
    else
        python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
name = sys.argv[2]
field = sys.argv[3] if len(sys.argv) > 3 else ''
for s in data.get('installed_skills', []):
    if s.get('name') == name:
        if field:
            val = s.get(field)
            if val is not None:
                print(val if not isinstance(val, (dict, list)) else json.dumps(val))
        else:
            print(json.dumps(s, indent=2))
        sys.exit(0)
sys.exit(1)
" "$REGISTRY_FILE" "$name" "$field"
    fi
}

registry_is_installed() {
    local name="$1"
    registry_get_skill "$name" "name" &>/dev/null
}

registry_list_installed() {
    [[ -f "$REGISTRY_FILE" ]] || { echo "[]"; return; }
    if command -v jq &>/dev/null; then
        jq -r '.installed_skills[].name' "$REGISTRY_FILE" 2>/dev/null
    else
        python3 -c "
import json
with open('$REGISTRY_FILE') as f:
    data = json.load(f)
for s in data.get('installed_skills', []):
    print(s.get('name', ''))
"
    fi
}

# --- Registry Write ---

registry_add_skill() {
    local name="$1" version="$2" source_repo="$3" commit_hash="$4"
    shift 4
    local installed_to_json="$*"

    registry_backup

    local now
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    if command -v jq &>/dev/null; then
        local tmp="${REGISTRY_FILE}.tmp.$$"
        jq --arg n "$name" \
           --arg v "$version" \
           --arg sr "$source_repo" \
           --arg ch "$commit_hash" \
           --arg now "$now" \
           --argjson ito "$installed_to_json" \
           '
           (.installed_skills |= map(select(.name != $n))) |
           .installed_skills += [{
               name: $n,
               version: $v,
               source_repo: $sr,
               docs_commit_hash: $ch,
               docs_fetched_date: $now,
               installed_date: $now,
               installed_to: $ito
           }] |
           .last_updated = $now
           ' "$REGISTRY_FILE" > "$tmp" && mv "$tmp" "$REGISTRY_FILE"
    else
        python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
name, version, source_repo, commit_hash, now = sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
installed_to = json.loads(sys.argv[7])
data['installed_skills'] = [s for s in data.get('installed_skills', []) if s.get('name') != name]
data['installed_skills'].append({
    'name': name, 'version': version, 'source_repo': source_repo,
    'docs_commit_hash': commit_hash, 'docs_fetched_date': now,
    'installed_date': now, 'installed_to': installed_to
})
data['last_updated'] = now
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2)
" "$REGISTRY_FILE" "$name" "$version" "$source_repo" "$commit_hash" "$now" "$installed_to_json"
    fi

    debug "Registry: added/updated skill '$name'"
}

registry_remove_skill() {
    local name="$1"
    registry_backup

    local now
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    if command -v jq &>/dev/null; then
        local tmp="${REGISTRY_FILE}.tmp.$$"
        jq --arg n "$name" --arg now "$now" \
           '.installed_skills |= map(select(.name != $n)) | .last_updated = $now' \
           "$REGISTRY_FILE" > "$tmp" && mv "$tmp" "$REGISTRY_FILE"
    else
        python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
data['installed_skills'] = [s for s in data.get('installed_skills', []) if s.get('name') != sys.argv[2]]
data['last_updated'] = sys.argv[3]
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2)
" "$REGISTRY_FILE" "$name" "$now"
    fi

    debug "Registry: removed skill '$name'"
}

registry_update_skill_field() {
    local name="$1" field="$2" value="$3"
    registry_backup

    if command -v jq &>/dev/null; then
        local tmp="${REGISTRY_FILE}.tmp.$$"
        jq --arg n "$name" --arg f "$field" --arg v "$value" \
           '(.installed_skills[] | select(.name == $n))[$f] = $v' \
           "$REGISTRY_FILE" > "$tmp" && mv "$tmp" "$REGISTRY_FILE"
    else
        python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for s in data.get('installed_skills', []):
    if s.get('name') == sys.argv[2]:
        s[sys.argv[3]] = sys.argv[4]
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2)
" "$REGISTRY_FILE" "$name" "$field" "$value"
    fi
}

registry_get_auto_check() {
    [[ -f "$REGISTRY_FILE" ]] || { echo "true"; return; }
    if command -v jq &>/dev/null; then
        jq -r '.auto_check_updates // true' "$REGISTRY_FILE"
    else
        python3 -c "
import json
with open('$REGISTRY_FILE') as f:
    data = json.load(f)
print(str(data.get('auto_check_updates', True)).lower())
"
    fi
}
