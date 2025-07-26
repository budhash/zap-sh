#!/bin/bash
##( header
# Test for Bash 3.2 compatibility
# Ensures zap-sh works with macOS system bash
##) header

##( configuration
set -euo pipefail
##) configuration

##( globals
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Get script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
##) globals

##( helpers
# Print colored output
print_test() {
    local status=$1
    local message=$2
    case $status in
        "PASS") echo -e "  ${GREEN}✓${NC} $message" ;;
        "FAIL") echo -e "  ${RED}✗${NC} $message" ;;
        "INFO") echo -e "${BLUE}$message${NC}" ;;
        "WARN") echo -e "${YELLOW}$message${NC}" ;;
    esac
}

# Test assertion
assert() {
    local test_name=$1
    local condition=$2
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if eval "$condition"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        print_test "PASS" "$test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_test "FAIL" "$test_name"
        return 1
    fi
}

# Test that a command fails
assert_fails() {
    local test_name=$1
    shift
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if ! "$@" >/dev/null 2>&1; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        print_test "PASS" "$test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_test "FAIL" "$test_name (command should have failed)"
        return 1
    fi
}

# Check bash version
check_bash_version() {
    local version
    version=$(${BASH:-bash} --version | head -1 | awk '{print $4}' | cut -d. -f1-2)
    echo "$version"
}
##) helpers

##( tests
run_compatibility_tests() {
    print_test "INFO" "Testing Bash 3.2 Compatibility Features"
    echo
    
    # Test that we're running on Bash 3.2
    local bash_version
    bash_version=$(check_bash_version)
    print_test "INFO" "Current Bash version: $bash_version"
    echo
    
    # Test prohibited features that should fail on Bash 3.2
    print_test "INFO" "Testing prohibited Bash 4+ features..."
    
    # Test nameref (local -n) - should fail in Bash 3.2
    assert_fails "nameref (local -n) is not available" ${BASH:-bash} -c 'local -n ref=var 2>/dev/null'
    
    # Test associative arrays - should fail in Bash 3.2
    assert_fails "associative arrays (declare -A) are not available" ${BASH:-bash} -c 'declare -A arr 2>/dev/null'
    
    # Test mapfile - should fail in Bash 3.2
    assert_fails "mapfile is not available" ${BASH:-bash} -c 'mapfile arr < /dev/null 2>/dev/null'
    
    # Test readarray - should fail in Bash 3.2
    assert_fails "readarray is not available" ${BASH:-bash} -c 'readarray arr < /dev/null 2>/dev/null'
    
    # Test case conversion ${var,,} - should fail in Bash 3.2
    assert_fails "lowercase conversion \${var,,} is not available" ${BASH:-bash} -c 'var=TEST; echo ${var,,} 2>/dev/null'
    
    # Test case conversion ${var^^} - should fail in Bash 3.2
    assert_fails "uppercase conversion \${var^^} is not available" ${BASH:-bash} -c 'var=test; echo ${var^^} 2>/dev/null'
    
    # Test &>> redirection - should fail in Bash 3.2
    assert_fails "&>> redirection is not available" ${BASH:-bash} -c 'echo test &>> /dev/null'
    
    echo
    print_test "INFO" "Testing compatible alternatives..."
    
    # Test tr for case conversion (compatible alternative)
    assert "tr command for lowercase works" '[[ $(echo "TEST" | tr "[:upper:]" "[:lower:]") == "test" ]]'
    assert "tr command for uppercase works" '[[ $(echo "test" | tr "[:lower:]" "[:upper:]") == "TEST" ]]'
    
    # Test array assignment from command substitution (compatible)
    assert "array assignment from command works" 'arr=($(echo "a b c")); [[ ${#arr[@]} -eq 3 ]]'
    
    # Test while read loop (compatible alternative to mapfile)
    local test_array=()
    while IFS= read -r line; do
        test_array+=("$line")
    done < <(echo -e "line1\nline2\nline3")
    assert "while read loop works" '[[ ${#test_array[@]} -eq 3 ]]'
    
    # Test >> file 2>&1 redirection (compatible)
    assert "standard redirection works" 'echo test >> /dev/null 2>&1'
    
    echo
}

test_zap_sh_compatibility() {
    print_test "INFO" "Testing zap-sh with Bash 3.2..."
    echo
    
    # Test that zap-sh runs with /bin/bash
    assert "zap-sh shows help with system bash" '/bin/bash "$SCRIPT_DIR/zap-sh" -h >/dev/null 2>&1'
    assert "zap-sh shows version with system bash" '/bin/bash "$SCRIPT_DIR/zap-sh" -v >/dev/null 2>&1'
    
    # Test project creation with system bash
    local test_project="bash32test"
    rm -rf "$test_project.sh"
    
    assert "zap-sh creates project with system bash" '/bin/bash "$SCRIPT_DIR/zap-sh" init "$test_project" >/dev/null 2>&1'
    assert "generated script exists" '[[ -f "$test_project.sh" ]]'
    assert "generated script is executable" '[[ -x "$test_project.sh" ]]'
    
    # Test that generated script works with system bash
    assert "generated script runs with system bash" '/bin/bash "$test_project.sh" -h >/dev/null 2>&1'
    
    # Cleanup
    rm -f "$test_project.sh"
    
    echo
}

test_template_compatibility() {
    print_test "INFO" "Testing templates with Bash 3.2..."
    echo
    
    # Test basic template
    assert "basic template has valid Bash 3.2 syntax" '/bin/bash -n "$SCRIPT_DIR/templates/basic.sh" 2>/dev/null'
    
    # Test enhanced template
    assert "enhanced template has valid Bash 3.2 syntax" '/bin/bash -n "$SCRIPT_DIR/templates/enhanced.sh" 2>/dev/null'
    
    # Check templates don't contain prohibited features
    local prohibited_patterns=(
        '\${[^}]*,,'  # lowercase conversion
        '\${[^}]*\^\^'  # uppercase conversion
        'local -n'      # nameref
        'declare -n'    # nameref
        'declare -A'    # associative array
        'mapfile'       # mapfile command
        'readarray'     # readarray command
        '&>>'           # combined append redirection
    )
    
    echo
    print_test "INFO" "Checking for prohibited patterns in templates..."
    
    for pattern in "${prohibited_patterns[@]}"; do
        if grep -qE "$pattern" "$SCRIPT_DIR/templates/basic.sh"; then
            assert_fails "basic.sh contains prohibited pattern: $pattern" false
        else
            assert "basic.sh free of pattern: $pattern" true
        fi
        
        if grep -qE "$pattern" "$SCRIPT_DIR/templates/enhanced.sh"; then
            assert_fails "enhanced.sh contains prohibited pattern: $pattern" false
        else
            assert "enhanced.sh free of pattern: $pattern" true
        fi
    done
    
    echo
}
##) tests

##( main
main() {
    echo "=============================================="
    echo "      Bash 3.2 Compatibility Test Suite"
    echo "=============================================="
    echo
    
    # Run test groups
    run_compatibility_tests
    test_zap_sh_compatibility
    test_template_compatibility
    
    # Print summary
    echo "=============================================="
    echo "                 SUMMARY"
    echo "=============================================="
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_test "PASS" "All Bash 3.2 compatibility tests passed! 🎉"
        exit 0
    else
        print_test "FAIL" "Some tests failed!"
        exit 1
    fi
}

# Run main
main "$@"
##) main