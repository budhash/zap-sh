#!/usr/bin/env bash
##( header
#
# Test Suite for the Advanced Bash Script Template  
#
# This script tests the template.sh advanced template structure and functionality.
# It should be run from the same directory as template.sh.
#
# USAGE: ./test-template.sh
##) header

##( configuration
# Use the same strict mode as the main script
set -e
set -u
set -o pipefail
##) configuration

##( setup
# Source the common test framework
source test/.common/test-common

# Configure for advanced template
readonly TEMPLATE_FILE="templates/enhanced.sh"
readonly TEMPLATE_NAME="Enhanced"

# Override tool settings for the common framework
NAME="enhanced"
TOOL="$TEMPLATE_FILE"

# Section markers for template validation
readonly SECTION_MARKERS=(
  "##(" "##)"    # Major section start/end
  "##[" "##]"    # Subsection start/end  
  "##{" "##}"    # Documentation block start/end
)

# Extract markers for easy reference
readonly SEC_START="${SECTION_MARKERS[0]}"
readonly SEC_END="${SECTION_MARKERS[1]}"
readonly SUB_START="${SECTION_MARKERS[2]}"
readonly SUB_END="${SECTION_MARKERS[3]}"
readonly DOC_START="${SECTION_MARKERS[4]}"
readonly DOC_END="${SECTION_MARKERS[5]}"

# Expected major sections for advanced template
readonly EXPECTED_SECTIONS=(
  "header"
  "configuration"
  "metadata" 
  "globals"
  "helpers"
  "app"
  "core"
)
##) setup

##( test helpers
# Test environment variables
ORIGINAL_PWD=""
TEST_WORKSPACE=""
TEMPLATE_PATH=""

# Pre-flight check: ensure template file exists
template_preflight_check() {
  if [[ ! -f "$ORIGINAL_PWD/$TEMPLATE_FILE" ]]; then
    echo "ERROR: Template file '$TEMPLATE_FILE' not found in original directory" >&2
    exit 1
  fi
}

# Source the template script to get access to its functions and variables
source_template() {
  set +e
  source "$ORIGINAL_PWD/$TEMPLATE_FILE"
  set -e
}

# Helper for counting occurrences
count_pattern() {
  local file="$1" pattern="$2"
  grep -c "$pattern" "$file" 2>/dev/null || echo 0
}

# Helper function for file contains assertion (since test-common doesn't have this)
assert_file_contains() {
  local file="$1" pattern="$2" desc="$3"
  if grep -q "$pattern" "$file" 2>/dev/null; then
    printf "  ${_GRN}✓${_RST} %s\n" "$desc"
    return 0
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s\n" "$desc"
    printf "    - Pattern '%s' not found in file: %s\n" "$pattern" "$file"
    return 1
  fi
}

# Create isolated test workspace for a test group
setup_test_workspace() {
  local test_name="${1:-test}"
  local workspace="$TEST_WORKSPACE/$test_name"
  mkdir -p "$workspace"
  cd "$workspace"
  echo "$workspace"
}

# Return to original directory
cleanup_test_workspace() {
  cd "$ORIGINAL_PWD"
}

# Setup function - create main test workspace
setup_tests() {
  ORIGINAL_PWD="$(pwd)"
  TEMPLATE_PATH="$(realpath "$ORIGINAL_PWD/$TEMPLATE_FILE")"
  TEST_WORKSPACE=$(mktemp -d "${TMPDIR:-/tmp}/template-test-XXXXXX")
}

# Teardown function - remove entire test workspace
teardown_tests() {
  cd "$ORIGINAL_PWD"
  [[ -n "$TEST_WORKSPACE" && -d "$TEST_WORKSPACE" ]] && rm -rf "$TEST_WORKSPACE"
}
##) template helpers

##( tests
test_section_markers() {
  _section_header "Section Markers"
  
  local template_file="$ORIGINAL_PWD/$TEMPLATE_FILE"
  
  # Test that major sections exist and are properly paired
  local section
  for section in "${EXPECTED_SECTIONS[@]}"; do
    local start_count end_count
    start_count=$(count_pattern "$template_file" "^${SEC_START} ${section}$")
    end_count=$(count_pattern "$template_file" "^${SEC_END} ${section}$")
    
    assert_eq "1" "$start_count" "Section '${section}' has exactly one start marker"
    assert_eq "1" "$end_count" "Section '${section}' has exactly one end marker"
    
    # If we have exactly one of each, verify they exist where expected
    if [[ "$start_count" -eq 1 && "$end_count" -eq 1 ]]; then
      local start_line end_line
      start_line=$(grep -n "^${SEC_START} ${section}$" "$template_file" | cut -d: -f1 | head -n1)
      end_line=$(grep -n "^${SEC_END} ${section}$" "$template_file" | cut -d: -f1 | head -n1)
      
      if [[ -n "$start_line" && -n "$end_line" ]]; then
        assert_ok test "$start_line" -lt "$end_line" "Section '${section}' start comes before end (line $start_line < $end_line)"
      fi
    fi
  done
  
  # Test that all section markers are properly paired globally
  local total_starts total_ends
  total_starts=$(count_pattern "$template_file" "^${SEC_START} ")
  total_ends=$(count_pattern "$template_file" "^${SEC_END} ")
  assert_eq "$total_starts" "$total_ends" "All major section markers are paired ($total_starts starts, $total_ends ends)"
  
  # Test subsection markers are paired
  local sub_starts sub_ends
  sub_starts=$(count_pattern "$template_file" "^##\\[ ")
  sub_ends=$(count_pattern "$template_file" "^##\\] ")
  assert_eq "$sub_starts" "$sub_ends" "All subsection markers are paired ($sub_starts starts, $sub_ends ends)"
  
  # Show found subsections for debugging
  echo "  Found subsections:"
  grep '^##\[ ' "$template_file" 2>/dev/null | sed 's/^##\[ \(.*\)/    - \1/' || echo "    - None found"
  
  # Test for key subsections that should exist in enhanced template
  assert_file_contains "$template_file" '^##\[ system$' "Subsection 'system' exists"
  assert_file_contains "$template_file" '^##\[ logging$' "Subsection 'logging' exists"
  assert_file_contains "$template_file" '^##\[ string$' "Subsection 'string' exists (enhanced feature)"
  assert_file_contains "$template_file" '^##\[ array$' "Subsection 'array' exists (enhanced feature)"
  assert_file_contains "$template_file" '^##\[ network$' "Subsection 'network' exists (enhanced feature)"
  
  # Test documentation block markers (if any exist) - fix escaping for enhanced template
  local doc_starts doc_ends
  doc_starts=$(count_pattern "$template_file" "^##{")
  doc_ends=$(count_pattern "$template_file" "^##}")

  # Ensure we got single values
  doc_starts=$(echo "$doc_starts" | head -n1)
  doc_ends=$(echo "$doc_ends" | head -n1)

  if [[ "$doc_starts" -gt 0 ]] || [[ "$doc_ends" -gt 0 ]]; then
    assert_eq "$doc_starts" "$doc_ends" "All documentation block markers are paired ($doc_starts starts, $doc_ends ends)"
    
    # Additional validation for enhanced template
    if [[ "$doc_starts" -gt 0 ]]; then
      echo "  Found $doc_starts documentation blocks (enhanced template feature)"
    fi
  else
    echo "  No documentation blocks found"
  fi
  
  # Test section order - configuration should come first, core should come last
  local config_count core_count
  config_count=$(count_pattern "$template_file" "^${SEC_START} configuration$")
  core_count=$(count_pattern "$template_file" "^${SEC_START} core$")
  
  if [[ "$config_count" -eq 1 && "$core_count" -eq 1 ]]; then
    local config_line core_line
    config_line=$(grep -n "^${SEC_START} configuration$" "$template_file" | cut -d: -f1 | head -n1)
    core_line=$(grep -n "^${SEC_START} core$" "$template_file" | cut -d: -f1 | head -n1)
    
    if [[ -n "$config_line" && -n "$core_line" ]]; then
      assert_ok test "$config_line" -lt "$core_line" "Section 'configuration' (line $config_line) comes before 'core' (line $core_line)"
    fi
  fi
  
  # Test template variable placeholders exist
  assert_file_contains "$template_file" '{{app}}' "Template contains {{app}} placeholder"
  assert_file_contains "$template_file" '{{version}}' "Template contains {{version}} placeholder"
  assert_file_contains "$template_file" '{{author}}' "Template contains {{author}} placeholder"
  assert_file_contains "$template_file" '{{email}}' "Template contains {{email}} placeholder"
  assert_file_contains "$template_file" '{{description}}' "Template contains {{description}} placeholder"
  assert_file_contains "$template_file" '{{year}}' "Template contains {{year}} placeholder"
  assert_file_contains "$template_file" '{{license_name}}' "Template contains {{license_name}} placeholder"
  assert_file_contains "$template_file" '{{license_content}}' "Template contains {{license_content}} placeholder"
  
  # Test for common template issues (fix the patterns to escape parentheses)
  local malformed_starts malformed_ends
  malformed_starts=$(grep -c "^##\([^[:space:]]" "$template_file" 2>/dev/null || echo 0)
  malformed_ends=$(grep -c "^##\)[^[:space:]]" "$template_file" 2>/dev/null || echo 0)
  
  # Ensure we got single values
  malformed_starts=$(echo "$malformed_starts" | head -n1)
  malformed_ends=$(echo "$malformed_ends" | head -n1)
  
  assert_eq "0" "$malformed_starts" "No malformed section start markers (missing space)"
  assert_eq "0" "$malformed_ends" "No malformed section end markers (missing space)"
  
  # Test for proper shebang
  assert_file_contains "$template_file" '^#!/usr/bin/env bash' "Template has proper bash shebang"
  
  # Test that the template is syntactically valid bash
  assert_ok bash -n "$template_file" "Template passes bash syntax check"
  
  echo
}

test_system_helpers() {
  _section_header "System Helpers"
  
  assert_ok test -n "$(u.os)" "u.os returns a non-empty string"
  assert_ok test -n "$(u.arch)" "u.arch returns a non-empty string"
  assert_ok u.require 'ls' "u.require succeeds for existing command"
  
  # For commands that must run in a subshell to not exit the test, we wrap them
  test_require_fail() { (u.require 'non_existent_command_xyz' 2>/dev/null); }
  assert_fail test_require_fail "u.require fails for missing command"
  
  test_die_fail() { (u.die 'test die' 2>/dev/null); }
  assert_fail test_die_fail "u.die exits with a failure code"
  
  # Test OS detection returns valid values
  local detected_os
  detected_os=$(u.os)
  case "$detected_os" in
    mac|linux|unknown) 
      assert_eq "$detected_os" "$detected_os" "u.os returns valid OS: $detected_os"
      ;;
    *)
      assert_eq "valid_os" "$detected_os" "u.os returns invalid OS: $detected_os"
      ;;
  esac
  
  echo
}

test_logging_helpers() {
  _section_header "Logging Helpers"

  # Save original colors and temporarily disable them
  local old_RST="$_RST" old_GRN="$_GRN" old_YLW="$_YLW" old_RED="$_RED" old_BLU="$_BLU"
  _RST="" _GRN="" _YLW="" _RED="" _BLU=""

  # Test debug logging behavior
  local old_dbg="${__DBG:-false}"
  __DBG=true
  assert_eq "[debug] debug test" "$(u.debug "debug test" 2>&1)" "u.debug logs when __DBG is true"
  __DBG=false
  assert_eq "" "$(u.debug "debug test" 2>&1)" "u.debug does not log when __DBG is false"
  __DBG="$old_dbg"
  
  # Test standard logging functions
  assert_eq "[info ] info test" "$(u.info "info test" 2>&1)" "u.info logs correctly"
  assert_eq "[warn ] warn test" "$(u.warn "warn test" 2>&1)" "u.warn logs correctly"
  assert_eq "[error] error test" "$(u.error "error test" 2>&1)" "u.error logs correctly"

  # Test log level formatting consistency
  local info_output warn_output error_output
  info_output=$(u.info "test" 2>&1)
  warn_output=$(u.warn "test" 2>&1)
  error_output=$(u.error "test" 2>&1)
  
  # Helper functions for pipeline tests
  test_info_format() { echo "$info_output" | grep -q '^\[info \]'; }
  test_warn_format() { echo "$warn_output" | grep -q '^\[warn \]'; }
  test_error_format() { echo "$error_output" | grep -q '^\[error\]'; }
  
  # All should have consistent bracket format
  assert_ok test_info_format "u.info uses consistent log format"
  assert_ok test_warn_format "u.warn uses consistent log format"
  assert_ok test_error_format "u.error uses consistent log format"

  # Restore original colors
  _RST="$old_RST" _GRN="$old_GRN" _YLW="$old_YLW" _RED="$old_RED" _BLU="$old_BLU"
  
  echo
}

test_string_helpers() {
  _section_header "String Helpers"
  
  assert_eq "hello world" "$(u.lower 'HELLO WORLD')" "u.lower works on arguments"
  assert_eq "hello world" "$(echo 'HELLO WORLD' | u.lower)" "u.lower works on stdin"
  assert_eq "HELLO WORLD" "$(u.upper 'hello world')" "u.upper works on arguments"
  assert_eq "hello" "$(u.trim '  hello  ')" "u.trim works on arguments"
  assert_ok u.isnum 123 "u.isnum validates positive integers"
  assert_ok u.isnum -45 "u.isnum validates negative integers"
  assert_fail u.isnum 1.5 "u.isnum rejects floats"
  assert_fail u.isnum 12a "u.isnum rejects alphanumeric strings"
  assert_ok u.isalphanum abc123 "u.isalphanum validates alphanumeric strings"
  assert_fail u.isalphanum 'abc-123' "u.isalphanum rejects special characters"
  assert_ok u.isfloat 123 "u.isfloat validates integers"
  assert_ok u.isfloat -10.55 "u.isfloat validates negative floats"
  assert_fail u.isfloat 10. "u.isfloat rejects trailing decimal point"
  
  echo
}

test_array_helpers() {
  _section_header "Array Helpers"
  
  local arr=("a" "b" "c")
  # For commands with complex arguments, a helper function is the cleanest way
  test_contains_ok() { u.array_contains 'b' "${arr[@]}"; }
  assert_ok test_contains_ok "u.array_contains finds existing element"

  test_contains_fail() { u.array_contains 'd' "${arr[@]}"; }
  assert_fail test_contains_fail "u.array_contains rejects missing element"

  assert_eq "3" "$(u.array_length "${arr[@]}")" "u.array_length returns correct count"
  assert_eq "0" "$(u.array_length)" "u.array_length handles empty array"

  test_empty_fail() { u.array_empty "${arr[@]}"; }
  assert_fail test_empty_fail "u.array_empty is false for non-empty array"
  assert_ok u.array_empty "u.array_empty is true for empty array"

  assert_eq "a,b,c" "$(u.array_join ',' "${arr[@]}")" "u.array_join works correctly"
  
  # Test map and filter functions
  double_func() { echo $(($1 * 2)); }
  is_even_func() { (( $1 % 2 == 0 )); }
  assert_eq "2 4 6" "$(u.array_map double_func 1 2 3 | tr '\n' ' ' | u.trim)" "u.array_map works correctly"
  assert_eq "2 4" "$(u.array_filter is_even_func 1 2 3 4 | tr '\n' ' ' | u.trim)" "u.array_filter works correctly"
  
  echo
}

test_filesys_helpers() {
  _section_header "Filesys Helpers"
  
  local sandbox; sandbox=$(mktemp -d); trap 'rm -rf "$sandbox"' RETURN
  local test_file="${sandbox}/f.tmp"; local test_dir="${sandbox}/d.tmp"; 
  touch "$test_file"; mkdir "$test_dir"

  assert_ok u.exists "$test_file" "u.exists finds file"
  assert_ok u.isfile "$test_file" "u.isfile validates file"
  assert_fail u.isdir "$test_file" "u.isdir rejects file"
  assert_ok u.isdir "$test_dir" "u.isdir validates directory"
  assert_fail u.isfile "$test_dir" "u.isfile rejects directory"
  assert_fail u.exists "${sandbox}/nonexistent" "u.exists rejects missing file"
  
  local temp_dir; temp_dir=$(u.tempdir test); 
  assert_ok test -d "$temp_dir" "u.tempdir creates a directory"
  
  echo
}

test_time_helpers() {
  _section_header "Time Helpers"
  
  # Use helper functions for complex conditionals
  test_ts_unix() { [[ "$(u.timestamp unix)" =~ ^[0-9]{10,}$ ]]; }
  assert_ok test_ts_unix "u.timestamp unix returns a valid timestamp"
  test_ts_iso() { [[ "$(u.timestamp iso)" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; }
  assert_ok test_ts_iso "u.timestamp iso returns a valid date format"
  
  local random_result; random_result=$(u.random alphanum 16); 
  assert_eq "16" "${#random_result}" "u.random returns correct length string"
  
  echo
}

test_json_helpers() {
  _section_header "JSON Helpers"
  
  local test_json='{"name":"app","version":1.2,"success":true,"message":"hello world"}'
  assert_eq "app" "$(u.json_get "$test_json" name)" "u.json_get extracts simple string value"
  assert_eq "1.2" "$(u.json_get "$test_json" version)" "u.json_get extracts numeric value"
  assert_eq "true" "$(u.json_get "$test_json" success)" "u.json_get extracts boolean value"
  assert_eq "hello world" "$(u.json_get "$test_json" message)" "u.json_get extracts string with spaces"
  assert_eq "N/A" "$(u.json_get "$test_json" missing_key "N/A")" "u.json_get returns default for missing key"

  test_json_fail_1() { u.json_get "$test_json" 'another_missing_key' 2>/dev/null; }
  assert_fail test_json_fail_1 "u.json_get fails without default value"

  test_json_fail_2() { u.json_get '' key 'default' 2>/dev/null; }
  assert_fail test_json_fail_2 "u.json_get handles empty JSON string"

  # Test and document the known limitation of the simple sed parser
  local complex_json='{"a":{"b":"c"}}'
  assert_eq "c" "$(u.json_get "$complex_json" "b")" "u.json_get finds nested key (known limitation)"
  
  echo
}

test_network_helpers() {
  _section_header "Network Helpers"

  if ! u.online; then
    printf "  ${_YLW}⚠${_RST} Network offline, skipping network tests.\n"
    echo
    return 0
  fi

  local kurl_get_response
  kurl_get_response=$(u.kurl GET "https://httpbin.org/get" 2>/dev/null || echo "")
  if [[ -n "$kurl_get_response" ]]; then
    # Use a helper function for clarity and safety
    test_kurl_get() { echo "$kurl_get_response" | grep -q 'httpbin.org'; }
    assert_ok test_kurl_get "u.kurl performs a successful GET request"

    local kurl_post_response payload='{"framework":"bash-template"}'
    kurl_post_response=$(u.kurl POST "https://httpbin.org/post" "$payload" "$_H_JSON" 2>/dev/null || echo "")
    if [[ -n "$kurl_post_response" ]]; then
      test_kurl_post() { echo "$kurl_post_response" | grep -q 'bash-template'; }
      assert_ok test_kurl_post "u.kurl performs a successful POST with payload"
    fi

    local api_get_response
    api_get_response=$(u.api_get "https://httpbin.org/json" 2>/dev/null || echo "")
    if [[ -n "$api_get_response" ]]; then
      test_api_get() { u.json_get "$api_get_response" 'author' 2>/dev/null | grep -q 'Yours Truly'; }
      assert_ok test_api_get "u.api_get performs a successful JSON GET request"
    fi
  else
    printf "  ${_YLW}⚠${_RST} Network tests skipped (service unavailable)\n"
  fi
  
  echo
}

test_app_integration() {
  _section_header "App Integration"
  
  local workspace=$(setup_test_workspace "app-integration")
  
  # Test file is executable
  assert_file_exists "$TEMPLATE_PATH" "template file exists"
  assert_ok test -x "$TEMPLATE_PATH" "template file is executable"
  
  assert_ok "$TEMPLATE_PATH" -h "runs with -h (help)"
  assert_ok "$TEMPLATE_PATH" -v "runs with -v (version)"

  # Test default functionality 
  test_app_default() {
    local was_pipefail=false
    if [[ "$(set -o|grep pipefail)" == *on* ]]; then was_pipefail=true; set +o pipefail; fi

    "$TEMPLATE_PATH" 2>&1 | grep -q 'Hello, World!'
    local status=$?

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_ok test_app_default "default greeting works"

  # Test name parameter
  test_app_name() {
    local was_pipefail=false
    if [[ "$(set -o|grep pipefail)" == *on* ]]; then was_pipefail=true; set +o pipefail; fi

    "$TEMPLATE_PATH" -n TestUser 2>&1 | grep -q 'Hello, TestUser!'
    local status=$?

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_ok test_app_name "custom name greeting works"

  # Test count parameter
  test_app_count() { test "$("$TEMPLATE_PATH" -c 3 2>&1 | grep -c 'Hello, World!')" -eq 3; }
  assert_ok test_app_count "count parameter works"
  
  # Test loud mode
  test_app_loud() {
    local was_pipefail=false
    if [[ "$(set -o|grep pipefail)" == *on* ]]; then was_pipefail=true; set +o pipefail; fi

    "$TEMPLATE_PATH" -l 2>&1 | grep -q 'HELLO, WORLD!'
    local status=$?

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_ok test_app_loud "loud mode (uppercase) works"
  
  # Test version line
  test_app_version_line() {
    local was_pipefail=false
    if [[ "$(set -o|grep pipefail)" == *on* ]]; then was_pipefail=true; set +o pipefail; fi

    # Accept either processed templates or raw template variables
    local output
    output=$("$TEMPLATE_PATH" 2>&1)
    if echo "$output" | grep -q 'Template version.*running on' || echo "$output" | grep -q '{{version}}.*running on'; then
      local status=0
    else
      local status=1
    fi

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_ok test_app_version_line "shows template version and OS"

  # Test error handling for invalid options
  test_invalid_option() {
    local was_pipefail=false
    if [[ "$(set -o|grep pipefail)" == *on* ]]; then was_pipefail=true; set +o pipefail; fi

    "$TEMPLATE_PATH" -z 2>/dev/null
    local status=$?

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_fail test_invalid_option "rejects invalid options"
  
  cleanup_test_workspace
  echo
}

test_template_structure() {
  _section_header "Template Structure"
  
  local template_file="$ORIGINAL_PWD/$TEMPLATE_FILE"
  
  # Test that template has proper shebang
  assert_file_contains "$template_file" '^#!/usr/bin/env bash' "has proper bash shebang"
  
  # Test that all required template variables are present
  local required_vars=("{{app}}" "{{detail}}" "{{description}}" "{{author}}" "{{email}}" "{{version}}" "{{license_name}}" "{{year}}" "{{license_content}}")
  local var
  for var in "${required_vars[@]}"; do
    assert_file_contains "$template_file" "$var" "contains required template variable: $var"
  done
  
  echo
}
##) tests

##( init
# Initialize test environment
setup_tests
template_preflight_check
source_template
##) init

##( core
# Run all tests using the common framework
_test_runner

# Clean up after tests
teardown_tests
##) core