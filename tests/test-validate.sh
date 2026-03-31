#!/usr/bin/env bash
# Tests for validate.sh verification functions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

setup_test_env
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/registry.sh"
source "$PROJECT_DIR/lib/validate.sh"

# ─── Tests ───────────────────────────────────────────────────────────────────

test_validate_no_registry() {
    local output
    output="$(validate_registry 2>&1)"
    assert_contains "$output" "No skills installed" "no registry = no skills"
}

test_validate_empty_registry() {
    registry_init
    validate_registry
}

test_validate_corrupted_registry() {
    registry_init
    echo "not json" > "$REGISTRY_FILE"
    local result=0
    validate_registry 2>/dev/null || result=$?
    assert_eq "11" "$result" "corrupted registry returns 11"
}

test_validate_skill_not_installed() {
    rm -f "$REGISTRY_FILE"
    registry_init
    local result=0
    validate_skill "agnosticd" 2>/dev/null || result=$?
    assert_eq "10" "$result" "uninstalled skill returns 10"
}

test_validate_skill_installed_correctly() {
    rm -f "$REGISTRY_FILE"
    registry_init

    local skill_dir="$HOME/.claude/skills/testvalid"
    mkdir -p "$skill_dir/references"
    cat > "$skill_dir/SKILL.md" << 'EOF'
---
name: testvalid
description: test
---
# Test
EOF
    echo "ref content" > "$skill_dir/references/README.md"

    registry_add_skill "testvalid" "1.0.0" "https://example.com" "abc" '[{"ide":"claude","path":"'"$skill_dir"'"}]'

    validate_skill "testvalid" >/dev/null 2>&1
}

test_validate_all_empty() {
    rm -f "$REGISTRY_FILE"
    registry_init
    local output
    output="$(validate_all 2>&1)"
    assert_contains "$output" "No skills installed" "validate_all with no skills"
}

# ─── Run ─────────────────────────────────────────────────────────────────────

echo "═══ Validate Tests ═══"
run_test "no registry file" test_validate_no_registry
run_test "empty registry valid" test_validate_empty_registry
run_test "corrupted registry" test_validate_corrupted_registry
run_test "skill not installed" test_validate_skill_not_installed
run_test "correctly installed skill" test_validate_skill_installed_correctly
run_test "validate all (empty)" test_validate_all_empty

teardown_test_env
print_summary "Validate"
