#!/usr/bin/env bash
# test-scaffold.sh — Tests for the scaffold command
# Run: bash tests/test-scaffold.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_TMPDIR=""
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ─── Helpers ─────────────────────────────────────────────────────────────────

setup() {
    TEST_TMPDIR="$(mktemp -d)"
    export RHEL_DEVOPS_SKILLS_HOME="$TEST_TMPDIR/data"
    export XDG_DATA_HOME="$TEST_TMPDIR/share"
    export SHARED_LIB_DIR="$TEST_TMPDIR/share/rhel-devops-skills"
    mkdir -p "$TEST_TMPDIR/project"
}

teardown() {
    [[ -n "$TEST_TMPDIR" ]] && rm -rf "$TEST_TMPDIR"
}

assert_file_exists() {
    local file="$1"
    local msg="${2:-File should exist: $file}"
    if [[ -f "$file" ]]; then
        ((TESTS_PASSED++))
    else
        echo "  FAIL: $msg"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

assert_file_executable() {
    local file="$1"
    local msg="${2:-File should be executable: $file}"
    if [[ -x "$file" ]]; then
        ((TESTS_PASSED++))
    else
        echo "  FAIL: $msg"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local msg="${3:-File $file should contain: $pattern}"
    if grep -q "$pattern" "$file" 2>/dev/null; then
        ((TESTS_PASSED++))
    else
        echo "  FAIL: $msg"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local msg="${3:-File $file should NOT contain: $pattern}"
    if ! grep -q "$pattern" "$file" 2>/dev/null; then
        ((TESTS_PASSED++))
    else
        echo "  FAIL: $msg"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

assert_dir_exists() {
    local dir="$1"
    local msg="${2:-Directory should exist: $dir}"
    if [[ -d "$dir" ]]; then
        ((TESTS_PASSED++))
    else
        echo "  FAIL: $msg"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

# ─── Source installer modules ─────────────────────────────────────────────────

source "$REPO_ROOT/lib/common.sh"
source "$REPO_ROOT/lib/scaffold.sh"

# Disable errexit for test assertions (grep returns 1 for no match)
set +e

# Override NON_INTERACTIVE for all tests
NON_INTERACTIVE=true
DRY_RUN=false
VERBOSE=false

# ─── Test: Hub-Student Scaffold ──────────────────────────────────────────────

test_scaffold_hub_student() {
    echo "TEST: Scaffold hub-student type"
    setup

    do_scaffold --type hub-student --output "$TEST_TMPDIR/project" --non-interactive

    assert_file_exists "$TEST_TMPDIR/project/Makefile" "Makefile generated"
    assert_file_exists "$TEST_TMPDIR/project/bootstrap.sh" "bootstrap.sh generated"
    assert_file_exists "$TEST_TMPDIR/project/onboard.yml" "onboard.yml generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/deploy-workshop.sh" "deploy script generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/teardown-workshop.sh" "teardown script generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/check-quota.sh" "quota script generated"

    assert_file_executable "$TEST_TMPDIR/project/bootstrap.sh" "bootstrap.sh is executable"
    assert_file_executable "$TEST_TMPDIR/project/scripts/deploy-workshop.sh" "deploy is executable"
    assert_file_executable "$TEST_TMPDIR/project/scripts/teardown-workshop.sh" "teardown is executable"

    assert_file_contains "$TEST_TMPDIR/project/Makefile" "hub-student" "Makefile has correct type"
    assert_file_contains "$TEST_TMPDIR/project/.gitignore" "deploy/config.yml" ".gitignore has config"
    assert_file_contains "$TEST_TMPDIR/project/.gitignore" "student_info.txt" ".gitignore has student_info"
    assert_file_contains "$TEST_TMPDIR/project/.gitignore" ".workshop-state" ".gitignore has state"
    assert_file_contains "$TEST_TMPDIR/project/.gitignore" "logs/" ".gitignore has logs"

    # Check template substitution happened
    assert_file_not_contains "$TEST_TMPDIR/project/Makefile" "{{" "No unsubstituted placeholders in Makefile"

    teardown
}

# ─── Test: Demo Scaffold ─────────────────────────────────────────────────────

test_scaffold_demo() {
    echo "TEST: Scaffold demo type"
    setup

    do_scaffold --type demo --output "$TEST_TMPDIR/project" --non-interactive

    assert_file_exists "$TEST_TMPDIR/project/Makefile" "Makefile generated"
    assert_file_exists "$TEST_TMPDIR/project/bootstrap.sh" "bootstrap.sh generated"
    assert_file_exists "$TEST_TMPDIR/project/onboard.yml" "onboard.yml generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/deploy-demo.sh" "deploy script generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/teardown-demo.sh" "teardown script generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/check-quota.sh" "quota script generated"

    assert_file_contains "$TEST_TMPDIR/project/Makefile" "demo" "Makefile has correct type"
    assert_file_contains "$TEST_TMPDIR/project/.gitignore" "deployment_info.txt" ".gitignore has deployment_info"

    teardown
}

# ─── Test: AgnosticD-Infra Scaffold ──────────────────────────────────────────

test_scaffold_infra() {
    echo "TEST: Scaffold agnosticd-infra type"
    setup

    do_scaffold --type agnosticd-infra --output "$TEST_TMPDIR/project" --non-interactive

    assert_file_exists "$TEST_TMPDIR/project/Makefile" "Makefile generated"
    assert_file_exists "$TEST_TMPDIR/project/bootstrap.sh" "bootstrap.sh generated"
    assert_file_exists "$TEST_TMPDIR/project/onboard.yml" "onboard.yml generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/deploy.sh" "deploy script generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/teardown.sh" "teardown script generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/check-quota.sh" "quota script generated"

    assert_file_contains "$TEST_TMPDIR/project/Makefile" "agnosticd-infra" "Makefile has correct type"

    teardown
}

# ─── Test: Shared-Cluster Scaffold ───────────────────────────────────────────

test_scaffold_shared_cluster() {
    echo "TEST: Scaffold shared-cluster type"
    setup

    do_scaffold --type shared-cluster --output "$TEST_TMPDIR/project" --non-interactive

    assert_file_exists "$TEST_TMPDIR/project/Makefile" "Makefile generated"
    assert_file_exists "$TEST_TMPDIR/project/bootstrap.sh" "bootstrap.sh generated"
    assert_file_exists "$TEST_TMPDIR/project/onboard.yml" "onboard.yml generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/deploy-shared.sh" "deploy script generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/teardown-shared.sh" "teardown script generated"
    assert_file_exists "$TEST_TMPDIR/project/scripts/check-quota.sh" "quota script generated"

    assert_file_executable "$TEST_TMPDIR/project/bootstrap.sh" "bootstrap.sh is executable"
    assert_file_executable "$TEST_TMPDIR/project/scripts/deploy-shared.sh" "deploy is executable"
    assert_file_executable "$TEST_TMPDIR/project/scripts/teardown-shared.sh" "teardown is executable"

    assert_file_contains "$TEST_TMPDIR/project/Makefile" "shared-cluster" "Makefile has correct type"
    assert_file_contains "$TEST_TMPDIR/project/onboard.yml" "oc" "onboard.yml requires oc CLI"
    assert_file_contains "$TEST_TMPDIR/project/onboard.yml" "namespace" "onboard.yml mentions namespaces"
    assert_file_contains "$TEST_TMPDIR/project/.gitignore" "student_info.txt" ".gitignore has student_info"

    # Verify template substitution defaults
    assert_file_contains "$TEST_TMPDIR/project/scripts/deploy-shared.sh" "user" "Namespace prefix substituted"
    assert_file_not_contains "$TEST_TMPDIR/project/Makefile" "{{" "No unsubstituted placeholders in Makefile"

    teardown
}

# ─── Test: Shared Library Installation ────────────────────────────────────────

test_shared_lib_install() {
    echo "TEST: Shared libraries installed"
    setup

    do_scaffold --type demo --output "$TEST_TMPDIR/project" --non-interactive

    local lib_dir="$TEST_TMPDIR/share/rhel-devops-skills"
    assert_file_exists "$lib_dir/workshop-common.sh" "workshop-common.sh installed"
    assert_file_exists "$lib_dir/workshop.mk" "workshop.mk installed"
    assert_file_exists "$lib_dir/quota-check.sh" "quota-check.sh installed"

    teardown
}

# ─── Test: Invalid Type ──────────────────────────────────────────────────────

test_scaffold_invalid_type() {
    echo "TEST: Invalid scaffold type fails"
    setup

    local result=0
    do_scaffold --type invalid --output "$TEST_TMPDIR/project" --non-interactive 2>/dev/null || result=$?

    if (( result != 0 )); then
        ((TESTS_PASSED++))
    else
        echo "  FAIL: Invalid type should fail"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))

    teardown
}

# ─── Test: Idempotent Re-run ─────────────────────────────────────────────────

test_scaffold_idempotent() {
    echo "TEST: Scaffold is idempotent (re-run safe)"
    setup

    do_scaffold --type demo --output "$TEST_TMPDIR/project" --non-interactive
    do_scaffold --type demo --output "$TEST_TMPDIR/project" --non-interactive

    assert_file_exists "$TEST_TMPDIR/project/Makefile" "Makefile still exists after re-run"
    # .gitignore should not have duplicate entries
    local count
    count=$(grep -c "deploy/config.yml" "$TEST_TMPDIR/project/.gitignore" 2>/dev/null || echo "0")
    if (( count <= 1 )); then
        ((TESTS_PASSED++))
    else
        echo "  FAIL: .gitignore has duplicate entries after re-run"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))

    teardown
}

# ─── Test: Vars File Input ────────────────────────────────────────────────────

test_scaffold_vars_file() {
    echo "TEST: Scaffold with --vars file"
    setup

    cat > "$TEST_TMPDIR/vars.env" <<'EOF'
PROJECT_NAME=my-test-workshop
CLOUD_PROVIDER=gcp
CLOUD_REGION=us-central1
AGD_ROOT=~/dev/agnosticd
REPO_URL=https://github.com/test/repo
CONFIG_NAME_HUB=ocp4-custom-hub
CONFIG_NAME_STUDENT=ocp4-custom-sno
NUM_STUDENTS=5
EOF

    do_scaffold --type hub-student --output "$TEST_TMPDIR/project" --vars "$TEST_TMPDIR/vars.env"

    assert_file_contains "$TEST_TMPDIR/project/onboard.yml" "my-test-workshop" "Project name substituted"
    assert_file_contains "$TEST_TMPDIR/project/onboard.yml" "gcp" "Cloud provider substituted"
    assert_file_contains "$TEST_TMPDIR/project/onboard.yml" "5" "Student count substituted"

    teardown
}

# ─── Run All Tests ───────────────────────────────────────────────────────────

echo ""
echo "=== Scaffold Tests ==="
echo ""

test_scaffold_hub_student
test_scaffold_demo
test_scaffold_infra
test_scaffold_shared_cluster
test_shared_lib_install
test_scaffold_invalid_type
test_scaffold_idempotent
test_scaffold_vars_file

echo ""
echo "─────────────────────────────────────────"
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed ($TESTS_RUN total)"
echo ""

if (( TESTS_FAILED > 0 )); then
    exit 1
fi
