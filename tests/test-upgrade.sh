#!/usr/bin/env bash
# Tests for upgrade.sh functions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

setup_test_env
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/registry.sh"
source "$PROJECT_DIR/lib/fetch-docs.sh"
source "$PROJECT_DIR/lib/upgrade.sh"

# ─── Tests ───────────────────────────────────────────────────────────────────

test_upgrade_skill_not_installed() {
    registry_init
    local result=0
    upgrade_skill "agnosticd" 2>/dev/null || result=$?
    assert_eq "6" "$result" "upgrade uninstalled skill returns 6"
}

test_upgrade_all_empty() {
    registry_init
    local output
    output="$(upgrade_all_skills 2>&1)"
    assert_contains "$output" "No skills installed" "upgrade all with none installed"
}

test_check_updates_no_skills() {
    registry_init
    check_all_updates 2>/dev/null
}

test_get_remote_commit_hash_bad_url() {
    local hash
    hash="$(get_remote_commit_hash "https://invalid.example.com/repo.git" "main" 2>/dev/null)"
    assert_eq "" "$hash" "invalid URL returns empty hash"
}

# ─── Run ─────────────────────────────────────────────────────────────────────

echo "═══ Upgrade Tests ═══"
run_test "upgrade skill not installed" test_upgrade_skill_not_installed
run_test "upgrade all (empty)" test_upgrade_all_empty
run_test "check updates with no skills" test_check_updates_no_skills
run_test "remote hash bad URL" test_get_remote_commit_hash_bad_url

teardown_test_env
print_summary "Upgrade"
