#!/usr/bin/env bash
# Tests for install.sh CLI argument parsing and basic commands

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# ─── Tests ───────────────────────────────────────────────────────────────────

test_help_command() {
    local output
    output="$(bash "$PROJECT_DIR/install.sh" help 2>&1)"
    assert_contains "$output" "USAGE:" "help shows usage"
    assert_contains "$output" "install" "help shows install command"
    assert_contains "$output" "agnosticd" "help lists agnosticd skill"
}

test_available_command() {
    local output
    output="$(bash "$PROJECT_DIR/install.sh" available 2>&1)"
    assert_contains "$output" "agnosticd" "available lists agnosticd"
    assert_contains "$output" "field-sourced-content" "available lists fsc"
    assert_contains "$output" "patternizer" "available lists patternizer"
    assert_contains "$output" "agnosticd/agnosticd-v2" "agnosticd uses upstream URL"
}

test_unknown_command_fails() {
    assert_exit_code 2 bash "$PROJECT_DIR/install.sh" nonexistent
}

test_install_no_skill_fails() {
    setup_test_env
    assert_exit_code 2 bash "$PROJECT_DIR/install.sh" install
    teardown_test_env
}

test_uninstall_no_skill_fails() {
    setup_test_env
    assert_exit_code 2 bash "$PROJECT_DIR/install.sh" uninstall
    teardown_test_env
}

test_dry_run_install() {
    setup_test_env
    local output
    output="$(bash "$PROJECT_DIR/install.sh" install --skill agnosticd --dry-run 2>&1)" || true
    assert_contains "$output" "DRY-RUN" "dry-run shows marker"
    teardown_test_env
}

test_skill_configs_loaded() {
    setup_test_env
    source "$PROJECT_DIR/lib/common.sh"
    local repo
    repo="$(get_skill_config "agnosticd" "source_repo")"
    assert_contains "$repo" "agnosticd/agnosticd-v2" "agnosticd uses upstream URL"
    teardown_test_env
}

test_all_skill_configs_exist() {
    for skill in agnosticd field-sourced-content patternizer; do
        assert_file_exists "$PROJECT_DIR/skills/$skill/config.sh" "config.sh for $skill"
    done
}

test_all_skill_md_exist() {
    for skill in agnosticd field-sourced-content patternizer; do
        assert_file_exists "$PROJECT_DIR/skills/$skill/SKILL.md" "SKILL.md for $skill"
    done
}

test_all_skill_references_exist() {
    for skill in agnosticd field-sourced-content patternizer; do
        assert_file_exists "$PROJECT_DIR/skills/$skill/references/REFERENCE.md" "REFERENCE.md for $skill"
    done
}

test_all_cursor_rules_exist() {
    for skill in agnosticd field-sourced-content patternizer; do
        assert_file_exists "$PROJECT_DIR/skills/$skill/rules/$skill.mdc" ".mdc for $skill"
    done
}

# ─── Run ─────────────────────────────────────────────────────────────────────

echo "═══ Install CLI Tests ═══"
run_test "help command" test_help_command
run_test "available command" test_available_command
run_test "unknown command fails" test_unknown_command_fails
run_test "install without --skill fails" test_install_no_skill_fails
run_test "uninstall without --skill fails" test_uninstall_no_skill_fails
run_test "dry-run install" test_dry_run_install
run_test "skill configs loaded" test_skill_configs_loaded
run_test "all config.sh files exist" test_all_skill_configs_exist
run_test "all SKILL.md files exist" test_all_skill_md_exist
run_test "all REFERENCE.md files exist" test_all_skill_references_exist
run_test "all cursor rules exist" test_all_cursor_rules_exist
print_summary "Install CLI"
