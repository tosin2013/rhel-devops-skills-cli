#!/usr/bin/env bash
# Shared test helpers

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$TEST_DIR/.." && pwd)"
TEST_TMPDIR=""
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

setup_test_env() {
    TEST_TMPDIR="$(mktemp -d)"
    export RHEL_DEVOPS_SKILLS_HOME="$TEST_TMPDIR/data"
    export HOME="$TEST_TMPDIR/fakehome"
    mkdir -p "$HOME/.claude" "$HOME/.cursor" "$HOME/.cursor/rules"
}

teardown_test_env() {
    if [[ -n "$TEST_TMPDIR" && -d "$TEST_TMPDIR" ]]; then
        rm -rf "$TEST_TMPDIR"
    fi
}

assert_eq() {
    local expected="$1" actual="$2" msg="${3:-assertion}"
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "  FAIL: $msg"
        echo "    expected: '$expected'"
        echo "    actual:   '$actual'"
        return 1
    fi
}

assert_file_exists() {
    local path="$1" msg="${2:-file exists}"
    if [[ -f "$path" ]]; then
        return 0
    else
        echo "  FAIL: $msg — file not found: $path"
        return 1
    fi
}

assert_dir_exists() {
    local path="$1" msg="${2:-directory exists}"
    if [[ -d "$path" ]]; then
        return 0
    else
        echo "  FAIL: $msg — directory not found: $path"
        return 1
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" msg="${3:-contains}"
    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "  FAIL: $msg"
        echo "    expected to contain: '$needle'"
        echo "    in: '$haystack'"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    shift
    local actual=0
    "$@" >/dev/null 2>&1 || actual=$?
    if [[ "$expected" -eq "$actual" ]]; then
        return 0
    else
        echo "  FAIL: expected exit code $expected, got $actual for: $*"
        return 1
    fi
}

run_test() {
    local test_name="$1"
    local test_func="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  $test_name... "
    if $test_func; then
        echo "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

print_summary() {
    local suite_name="${1:-Tests}"
    echo ""
    echo "━━━ $suite_name Summary ━━━"
    echo "  Total:  $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo ""
    [[ $TESTS_FAILED -eq 0 ]]
}
