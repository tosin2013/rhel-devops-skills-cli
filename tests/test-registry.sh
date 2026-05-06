#!/usr/bin/env bash
# Tests for registry.sh JSON management

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

setup_test_env
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/registry.sh"

# ─── Tests ───────────────────────────────────────────────────────────────────

test_registry_init() {
    registry_init
    assert_file_exists "$REGISTRY_FILE" "registry file created"
}

test_registry_valid_json() {
    registry_init
    if command -v jq &>/dev/null; then
        jq empty "$REGISTRY_FILE"
    else
        python3 -c "import json; json.load(open('$REGISTRY_FILE'))"
    fi
}

test_registry_default_fields() {
    registry_init
    local version
    if command -v jq &>/dev/null; then
        version="$(jq -r '.version' "$REGISTRY_FILE")"
    else
        version="$(python3 -c "import json; print(json.load(open('$REGISTRY_FILE'))['version'])")"
    fi
    assert_eq "1.0" "$version" "registry version is 1.0"
}

test_registry_add_skill() {
    registry_init
    registry_add_skill "testskill" "1.0.0" "https://example.com/repo" "abc123" '[{"ide":"claude","path":"~/.claude/skills/testskill"}]'
    local result
    result="$(registry_is_installed "testskill" && echo "yes" || echo "no")"
    assert_eq "yes" "$result" "skill is installed after add"
}

test_registry_get_skill_field() {
    registry_init
    registry_add_skill "testskill2" "1.0.0" "https://example.com/repo2" "def456" '[{"ide":"cursor","path":"~/.cursor/skills-cursor/testskill2"}]'
    local hash
    hash="$(registry_get_skill "testskill2" "docs_commit_hash")"
    assert_eq "def456" "$hash" "commit hash matches"
}

test_registry_list_installed() {
    registry_init
    registry_add_skill "skill-a" "1.0.0" "https://example.com/a" "aaa" '[{"ide":"claude","path":"~/.claude/skills/skill-a"}]'
    registry_add_skill "skill-b" "1.0.0" "https://example.com/b" "bbb" '[{"ide":"claude","path":"~/.claude/skills/skill-b"}]'
    local list
    list="$(registry_list_installed)"
    assert_contains "$list" "skill-a" "list contains skill-a"
    assert_contains "$list" "skill-b" "list contains skill-b"
}

test_registry_remove_skill() {
    registry_init
    registry_add_skill "removeme" "1.0.0" "https://example.com/rm" "rm1" '[{"ide":"claude","path":"~/.claude/skills/removeme"}]'
    registry_remove_skill "removeme"
    local result
    result="$(registry_is_installed "removeme" && echo "yes" || echo "no")"
    assert_eq "no" "$result" "skill removed"
}

test_registry_update_field() {
    registry_init
    registry_add_skill "updateme" "1.0.0" "https://example.com/up" "old" '[{"ide":"claude","path":"~/.claude/skills/updateme"}]'
    registry_update_skill_field "updateme" "docs_commit_hash" "newhash"
    local hash
    hash="$(registry_get_skill "updateme" "docs_commit_hash")"
    assert_eq "newhash" "$hash" "field updated"
}

test_registry_backup() {
    registry_init
    registry_backup
    local backup_count
    backup_count="$(ls "$BACKUP_DIR"/registry-*.json 2>/dev/null | wc -l)"
    [[ "$backup_count" -ge 1 ]]
}

test_registry_auto_check_default() {
    registry_init
    local val
    val="$(registry_get_auto_check)"
    assert_eq "true" "$val" "auto-check defaults to true"
}

# ─── Run ─────────────────────────────────────────────────────────────────────

echo "═══ Registry Tests ═══"
run_test "registry init" test_registry_init
run_test "registry valid JSON" test_registry_valid_json
run_test "registry default fields" test_registry_default_fields
run_test "add skill" test_registry_add_skill
run_test "get skill field" test_registry_get_skill_field
run_test "list installed" test_registry_list_installed
run_test "remove skill" test_registry_remove_skill
run_test "update field" test_registry_update_field
run_test "backup" test_registry_backup
run_test "auto-check default" test_registry_auto_check_default

teardown_test_env
print_summary "Registry"
