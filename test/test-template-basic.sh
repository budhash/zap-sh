#!/usr/bin/env bash
##( header
#
# Test Suite for the Basic Bash Script Template
#
# This script tests the basic.sh template structure and functionality.
# It should be run from the same directory as basic.sh.
#
# USAGE: ./test-basic.sh
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

# Configure for basic template
readonly TEMPLATE_FILE="templates/basic.sh"
readonly TEMPLATE_NAME="Basic"

# Override tool settings for the common framework
NAME="basic-template"
TOOL="./$TEMPLATE_FILE"

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

# Expected major sections for basic template
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

##( template helpers
# Pre-flight check: ensure template file exists
template_preflight_check() {
  if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "ERROR: Template file '$TEMPLATE_FILE' not found in current directory" >&2
    exit 1
  fi
}

# Source the template script to get access to its functions and variables
source_template() {
  # We disable 'exit on error' temporarily in case the sourced script has initial checks
  set +e
  source "./$TEMPLATE_FILE"
  set -e
}

# Helper for counting occurrences
count_pattern() {
  local file="$1" pattern="$2"
  grep -c "$pattern" "$file" 2>/dev/null || echo 0
}
##) template helpers

##( tests
test_section_markers() {
  _section_header "Section Markers"
  
  # Test that major sections exist and are properly paired
  local section
  for section in "${EXPECTED_SECTIONS[@]}"; do
    local start_count end_count
    start_count=$(count_pattern "$TEMPLATE_FILE" "^${SEC_START} ${section}$")
    end_count=$(count_pattern "$TEMPLATE_FILE" "^${SEC_END} ${section}$")
    
    assert_eq "1" "$start_count" "Section '${section}' has exactly one start marker"
    assert_eq "1" "$end_count" "Section '${section}' has exactly one end marker"
    
    # If we have exactly one of each, verify they exist where expected
    if [[ "$start_count" -eq 1 && "$end_count" -eq 1 ]]; then
      local start_line end_line
      start_line=$(grep -n "^${SEC_START} ${section}$" "$TEMPLATE_FILE" | cut -d: -f1 | head -n1)
      end_line=$(grep -n "^${SEC_END} ${section}$" "$TEMPLATE_FILE" | cut -d: -f1 | head -n1)
      
      if [[ -n "$start_line" && -n "$end_line" ]]; then
        assert_ok test "$start_line" -lt "$end_line" "Section '${section}' start comes before end (line $start_line < $end_line)"
      fi
    fi
  done
  
  # Test that all section markers are properly paired globally
  local total_starts total_ends
  total_starts=$(count_pattern "$TEMPLATE_FILE" "^${SEC_START} ")
  total_ends=$(count_pattern "$TEMPLATE_FILE" "^${SEC_END} ")
  assert_eq "$total_starts" "$total_ends" "All major section markers are paired ($total_starts starts, $total_ends ends)"
  
  # Test subsection markers are paired
  local sub_starts sub_ends
  sub_starts=$(count_pattern "$TEMPLATE_FILE" "^##\\[ ")
  sub_ends=$(count_pattern "$TEMPLATE_FILE" "^##\\] ")
  assert_eq "$sub_starts" "$sub_ends" "All subsection markers are paired ($sub_starts starts, $sub_ends ends)"
  
  # Test for key subsections that should exist in basic template
  assert_ok grep -q "^##\\[ system$" "$TEMPLATE_FILE" "Subsection 'system' exists"
  assert_ok grep -q "^##\\[ logging$" "$TEMPLATE_FILE" "Subsection 'logging' exists"
  
  # Test documentation block markers (if any exist)
  local doc_starts doc_ends
  doc_starts=$(count_pattern "$TEMPLATE_FILE" "^##\\{")
  doc_ends=$(count_pattern "$TEMPLATE_FILE" "^##\\}")

  # Ensure we got single values
  doc_starts=$(echo "$doc_starts" | head -n1)
  doc_ends=$(echo "$doc_ends" | head -n1)

  if [[ "$doc_starts" -gt 0 ]] || [[ "$doc_ends" -gt 0 ]]; then
    assert_eq "$doc_starts" "$doc_ends" "All documentation block markers are paired ($doc_starts starts, $doc_ends ends)"
  fi
  
  # Test section order - configuration should come first, core should come last
  local config_count core_count
  config_count=$(count_pattern "$TEMPLATE_FILE" "^${SEC_START} configuration$")
  core_count=$(count_pattern "$TEMPLATE_FILE" "^${SEC_START} core$")
  
  if [[ "$config_count" -eq 1 && "$core_count" -eq 1 ]]; then
    local config_line core_line
    config_line=$(grep -n "^${SEC_START} configuration$" "$TEMPLATE_FILE" | cut -d: -f1 | head -n1)
    core_line=$(grep -n "^${SEC_START} core$" "$TEMPLATE_FILE" | cut -d: -f1 | head -n1)
    
    if [[ -n "$config_line" && -n "$core_line" ]]; then
      assert_ok test "$config_line" -lt "$core_line" "Section 'configuration' (line $config_line) comes before 'core' (line $core_line)"
    fi
  fi
  
  # Test template variable placeholders exist
  assert_ok grep -q '{{app}}' "$TEMPLATE_FILE" "Template contains {{app}} placeholder"
  assert_ok grep -q '{{version}}' "$TEMPLATE_FILE" "Template contains {{version}} placeholder"
  assert_ok grep -q '{{author}}' "$TEMPLATE_FILE" "Template contains {{author}} placeholder"
  assert_ok grep -q '{{email}}' "$TEMPLATE_FILE" "Template contains {{email}} placeholder"
  assert_ok grep -q '{{description}}' "$TEMPLATE_FILE" "Template contains {{description}} placeholder"
  
  # Test for common template issues (fix the patterns to escape parentheses)
  local malformed_starts malformed_ends
  malformed_starts=$(grep -c "^##\([^[:space:]]" "$TEMPLATE_FILE" 2>/dev/null || echo 0)
  malformed_ends=$(grep -c "^##\)[^[:space:]]" "$TEMPLATE_FILE" 2>/dev/null || echo 0)
  
  # Ensure we got single values
  malformed_starts=$(echo "$malformed_starts" | head -n1)
  malformed_ends=$(echo "$malformed_ends" | head -n1)
  
  assert_eq "0" "$malformed_starts" "No malformed section start markers (missing space)"
  assert_eq "0" "$malformed_ends" "No malformed section end markers (missing space)"
  
  # Test for proper shebang
  assert_ok grep -q "^#!/usr/bin/env bash" "$TEMPLATE_FILE" "Template has proper bash shebang"
  
  # Test that the template is syntactically valid bash
  assert_ok bash -n "$TEMPLATE_FILE" "Template passes bash syntax check"
}

test_system_helpers() {
  _section_header "System Helpers"
  
  assert_ok test -n "$(u.os)" "u.os returns a non-empty string"
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
}

test_app_integration() {
  _section_header "App Integration"
  
  # Test file is executable
  assert_file_exists "./$TEMPLATE_FILE" "template file exists"
  assert_ok test -x "./$TEMPLATE_FILE" "template file is executable"
  
  assert_ok "./$TEMPLATE_FILE" -h "runs with -h (help)"
  assert_ok "./$TEMPLATE_FILE" -v "runs with -v (version)"

  # Test basic functionality
  test_app_default() {
    local was_pipefail=false
    if [[ "$(set -o|grep pipefail)" == *on* ]]; then was_pipefail=true; set +o pipefail; fi

    # Accept either processed templates or raw template variables
    local output
    output=$("./$TEMPLATE_FILE" 2>&1)
    if echo "$output" | grep -q 'Template version.*running on' || echo "$output" | grep -q '{{version}}.*running on'; then
      local status=0
    else
      local status=1
    fi

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_ok test_app_default "shows template version and OS"

  # Test file option
  test_app_file_option() {
    local was_pipefail=false
    if [[ "$(set -o|grep pipefail)" == *on* ]]; then was_pipefail=true; set +o pipefail; fi

    "./$TEMPLATE_FILE" -f test.txt 2>&1 | grep -q 'file option: test.txt'
    local status=$?

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_ok test_app_file_option "file option parsing works"

  # Test positional argument
  test_app_positional() {
    local was_pipefail=false
    if [[ "$(set -o|grep pipefail)" == *on* ]]; then was_pipefail=true; set +o pipefail; fi

    "./$TEMPLATE_FILE" arg1 2>&1 | grep -q 'primary argument: arg1'
    local status=$?

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_ok test_app_positional "positional argument handling works"

  # Test combined options
  test_app_combined() {
    local was_pipefail=false
    if [[ "$(set -o|grep pipefail)" == *on* ]]; then was_pipefail=true; set +o pipefail; fi

    local output
    output=$("./$TEMPLATE_FILE" -f config.txt positional_arg 2>&1)
    echo "$output" | grep -q 'file option: config.txt' && echo "$output" | grep -q 'primary argument: positional_arg'
    local status=$?

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_ok test_app_combined "combined options and positional args work"

  # Test version format  
  test_version_format() {
    local was_pipefail=false
    if [[ "$(set -o | grep pipefail)" == *on* ]]; then 
      was_pipefail=true
      set +o pipefail
    fi
    
    local version_output
    version_output=$("./$TEMPLATE_FILE" -v 2>&1)
    
    # Clean the output
    local clean_version
    clean_version=$(echo "$version_output" | head -1 | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Accept version numbers, "unknown", or template variables (for raw templates)
    if [[ -n "$clean_version" ]] && [[ 
      "$clean_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ || 
      "$clean_version" == "unknown" || 
      "$clean_version" == "{{version}}" || 
      "$clean_version" =~ ^\{\{.*\}\}$ 
    ]]; then
      local status=0
    else
      local status=1
    fi
    
    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_ok test_version_format "version output is properly formatted"

  # Test help format
  test_help_format() {
    local was_pipefail=false
    if [[ "$(set -o | grep pipefail)" == *on* ]]; then 
      was_pipefail=true
      set +o pipefail
    fi

    local help_output
    help_output=$("./$TEMPLATE_FILE" -h 2>&1)
    echo "$help_output" | grep -q -i "usage" && echo "$help_output" | grep -q -i "options" && echo "$help_output" | grep -q -i "examples"
    local status=$?

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_ok test_help_format "help output contains usage, options, and examples"

  # Test error handling for invalid options
  test_invalid_option() {
    local was_pipefail=false
    if [[ "$(set -o | grep pipefail)" == *on* ]]; then 
      was_pipefail=true
      set +o pipefail
    fi

    "./$TEMPLATE_FILE" -z 2>/dev/null
    local status=$?

    if [[ "$was_pipefail" == true ]]; then set -o pipefail; fi
    return $status
  }
  assert_fail test_invalid_option "rejects invalid options"
}

test_template_structure() {
  _section_header "Template Structure"
  
  # Test that template has proper shebang
  assert_ok grep -q '^#!/usr/bin/env bash' "$TEMPLATE_FILE" "has proper bash shebang"
  
  # Test that all required template variables are present
  local required_vars=("{{app}}" "{{detail}}" "{{description}}" "{{author}}" "{{email}}" "{{version}}" "{{license_name}}")
  local var
  for var in "${required_vars[@]}"; do
    assert_ok grep -q "$var" "$TEMPLATE_FILE" "contains required template variable: $var"
  done
}
##) tests

##( init
# Initialize test environment
template_preflight_check
source_template
##) init

##( core
# Run all tests using the common framework
_test_runner
##) core