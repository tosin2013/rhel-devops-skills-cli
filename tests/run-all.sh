#!/usr/bin/env bash
# Run all test suites

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

total_pass=0
total_fail=0
total_run=0
suites=("test-install.sh" "test-registry.sh" "test-validate.sh" "test-upgrade.sh")

echo "═══════════════════════════════════════════"
echo "  rhel-devops-skills-cli Test Runner"
echo "═══════════════════════════════════════════"
echo ""

for suite in "${suites[@]}"; do
    echo "Running $suite..."
    if bash "$SCRIPT_DIR/$suite"; then
        total_pass=$((total_pass + 1))
    else
        total_fail=$((total_fail + 1))
    fi
    total_run=$((total_run + 1))
done

echo ""
echo "═══════════════════════════════════════════"
echo "  Overall: $total_pass/$total_run suites passed"
if [[ $total_fail -gt 0 ]]; then
    echo "  $total_fail suite(s) had failures"
    exit 1
fi
echo "  All tests passed!"
echo "═══════════════════════════════════════════"
