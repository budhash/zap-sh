#!/usr/bin/env bash
##( header
#
# Test Suite for zap-sh Script Generator  
#
# This script tests the zap-sh functionality with comprehensive validation
# including template generation, updates, section extraction, and edge cases.
#
# USAGE: ./test-zap.sh
##) header

##( configuration
set -e
set -u
set -o pipefail
##) configuration

##( setup
# Source the common test framework
source test/.common/test-common

# Configure for zap-sh script
readonly ZAP_SCRIPT="zap-sh"

# Override tool settings for the common framework
NAME="zap-sh"
TOOL="./$ZAP_SCRIPT"

# Ensure zap-sh is executable
chmod +x "./$ZAP_SCRIPT"
##) setup

##( shared temp directory cleanup
# Shared temp directory for all tests
TEST_OUTPUT_DIR=""
declare -a TRACKED_FILES=()

track_test_file() {
  local file="${1:-}"
  [[ -n "$file" ]] && TRACKED_FILES+=("$file")
}

setup_tests() {
  TEST_OUTPUT_DIR="$(mktemp -d)"
  [[ -n "$TEST_OUTPUT_DIR" ]] || { echo "Failed to create temp directory" >&2; exit 1; }
  TRACKED_FILES=()
}

cleanup_test_files() {
  local file
  for file in "${TRACKED_FILES[@]:-}"; do
    [[ -f "$file" ]] && rm -f "$file"
  done
  [[ -n "$TEST_OUTPUT_DIR" && -d "$TEST_OUTPUT_DIR" ]] && rm -rf "$TEST_OUTPUT_DIR"
}

teardown_tests() {
  cleanup_test_files
  TRACKED_FILES=()
  TEST_OUTPUT_DIR=""
}
##) shared temp directory cleanup

##( enhanced test helpers
assert_file_contains() {
  _TESTS_RUN=$((_TESTS_RUN + 1))
  local file="$1" pattern="$2" desc="$3"
  if [[ -f "$file" ]] && grep -q "$pattern" "$file"; then
    printf "  ${_GRN}✓${_RST} %s\n" "$desc"
    return 0
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s\n" "$desc"
    return 0
  fi
}

assert_executable() {
  _TESTS_RUN=$((_TESTS_RUN + 1))
  local file="$1" desc="$2"
  if [[ -x "$file" ]]; then
    printf "  ${_GRN}✓${_RST} %s\n" "$desc"
    return 0
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s\n" "$desc"
    return 0
  fi
}

assert_template_id() {
  _TESTS_RUN=$((_TESTS_RUN + 1))
  local file="$1" expected_template="$2" desc="$3"
  # Try new format first
  local template_id=$(sed -n 's/^#[[:space:]]*__ID__:[[:space:]]*\(.*\)$/\1/p' "$file" 2>/dev/null | head -1)
  # Fallback to old format
  if [[ -z "$template_id" ]]; then
    template_id=$(grep "__ID=" "$file" 2>/dev/null | sed 's/.*="\(.*\)".*/\1/' || echo "")
  fi
  
  # Extract template name and version parts
  local template_name="${template_id%-*}"  # Everything before last hyphen
  local template_version="${template_id##*-}"  # Everything after last hyphen
  
  # Validate template name matches
  if [[ "$template_name" == "$expected_template" ]]; then
    # Validate version follows semantic versioning (X.Y.Z or X.Y.Z-prerelease)
    if [[ "$template_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.][a-zA-Z0-9.-]*)?$ ]]; then
      printf "  ${_GRN}✓${_RST} %s (%s)\n" "$desc" "$template_id"
      return 0
    else
      _FAILURES=$((_FAILURES + 1))
      printf "  ${_RED}✗${_RST} %s (invalid version format: %s)\n" "$desc" "$template_version"
      return 0
    fi
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s (got template: %s, expected: %s)\n" "$desc" "$template_name" "$expected_template"
    return 0
  fi
}

assert_no_placeholders() {
  _TESTS_RUN=$((_TESTS_RUN + 1))
  local file="$1" desc="$2"
  
  if [[ ! -f "$file" ]]; then
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s (file not found)\n" "$desc"
    return 0
  fi
  
  local remaining=$(grep -c "{{.*}}" "$file" 2>/dev/null || echo "0")
  remaining=$(echo "$remaining" | tr -d '[:space:]' | grep -o '^[0-9]*' | head -1)
  remaining=${remaining:-0}
  
  if [[ $remaining -eq 0 ]]; then
    printf "  ${_GRN}✓${_RST} %s\n" "$desc"
    return 0
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s (%d placeholders remain)\n" "$desc" "$remaining"
    if [[ $remaining -le 5 ]]; then
      local placeholders=$(grep -o "{{.*}}" "$file" | head -3 | tr '\n' ' ')
      printf "    ${_YLW}Remaining:${_RST} %s\n" "$placeholders"
    fi
    return 0
  fi
}

assert_script_valid() {
  _TESTS_RUN=$((_TESTS_RUN + 1))
  local file="$1" desc="$2"
  
  if [[ ! -f "$file" ]]; then
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s (file not found)\n" "$desc"
    return 0
  fi
  
  local actual_lines=$(wc -l < "$file" | tr -d ' ')
  local actual_utils=$(grep -c "^u\." "$file")
  
  if [[ $actual_lines -gt 50 && $actual_utils -gt 3 ]]; then
    printf "  ${_GRN}✓${_RST} %s (lines: %d, utils: %d)\n" "$desc" "$actual_lines" "$actual_utils"
    return 0
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s (too small: lines:%d, utils:%d)\n" "$desc" "$actual_lines" "$actual_utils"
    return 0
  fi
}
##) enhanced test helpers

##( tests
test_basic_functionality() {
  _section_header "Basic zap-sh Functionality"
  
  assert_ok "./$ZAP_SCRIPT" -h "shows help"
  assert_ok "./$ZAP_SCRIPT" -v "shows version"
  assert_fail "./$ZAP_SCRIPT" "fails without command"
  
  echo
}

test_project_creation() {
  _section_header "Project Creation"
  
  # Test basic project creation
  local output_file="basic-test.sh"
  track_test_file "$output_file"
  assert_ok "./$ZAP_SCRIPT" init basic-test --author="Test User" "creates basic project"
  assert_file_exists "$output_file" "basic project file exists"
  assert_executable "$output_file" "basic project is executable"
  assert_script_valid "$output_file" "basic template is valid"
  assert_template_id "$output_file" "basic" "basic template ID correct"
  assert_no_placeholders "$output_file" "basic template variables substituted"
  assert_file_contains "$output_file" "Test User" "contains author"
  
  # Test project with custom output path
  output_file="$TEST_OUTPUT_DIR/custom-output.sh"  
  assert_ok "./$ZAP_SCRIPT" init custom-test -o "$output_file" --author="Test User" "creates project with custom output"
  assert_file_exists "$output_file" "custom output file exists"
  assert_executable "$output_file" "custom output file is executable"
  
  # Test project with enhanced template
  output_file="$TEST_OUTPUT_DIR/enhanced-test.sh"
  assert_ok "./$ZAP_SCRIPT" init enhanced-test -t enhanced -o "$output_file" --author="Test User" "creates enhanced template project"
  assert_file_exists "$output_file" "enhanced project file exists"
  assert_script_valid "$output_file" "enhanced template is valid"
  assert_template_id "$output_file" "enhanced" "enhanced template ID correct"
  
  # Test project with license
  output_file="$TEST_OUTPUT_DIR/licensed-test.sh"  
  assert_ok "./$ZAP_SCRIPT" init licensed-test -o "$output_file" --author="Test User" --license=mit "creates project with MIT license"
  assert_file_exists "$output_file" "licensed project file exists"
  assert_file_contains "$output_file" "MIT License" "contains MIT license"
  
  # Test project with all options
  output_file="$TEST_OUTPUT_DIR/complete-test.sh"
  assert_ok "./$ZAP_SCRIPT" init complete-test \
    -o "$output_file" \
    -t basic \
    --author="John Doe" \
    --email="john@test.com" \
    --license=apache \
    --version="2.0.0" \
    --detail="Test script" \
    --description="A test script" "creates project with all options"
  assert_file_exists "$output_file" "complete project file exists"
  assert_file_contains "$output_file" "John Doe" "contains author"
  assert_file_contains "$output_file" "john@test.com" "contains email" 
  assert_file_contains "$output_file" "Apache License" "contains Apache license"
  assert_file_contains "$output_file" "2.0.0" "contains version"
  assert_file_contains "$output_file" "Test script" "contains detail"
  
  echo
}

test_template_handling() {
  _section_header "Template Handling"
  
  # Test basic template
  local basic_file="$TEST_OUTPUT_DIR/basic-template.sh"
  assert_ok "./$ZAP_SCRIPT" init template-basic -t basic -o "$basic_file" --author="Test User" "creates basic template"
  assert_file_exists "$basic_file" "basic template file exists"
  assert_script_valid "$basic_file" "basic template is valid"
  
  # Test enhanced template
  local enhanced_file="$TEST_OUTPUT_DIR/enhanced-template.sh"
  assert_ok "./$ZAP_SCRIPT" init template-enhanced -t enhanced -o "$enhanced_file" --author="Test User" "creates enhanced template"
  assert_file_exists "$enhanced_file" "enhanced template file exists"
  assert_script_valid "$enhanced_file" "enhanced template is valid"
  
  # Simple template comparison
  if [[ -f "$basic_file" && -f "$enhanced_file" ]]; then
    local basic_lines=$(wc -l < "$basic_file" | tr -d ' ')
    local enhanced_lines=$(wc -l < "$enhanced_file" | tr -d ' ')
    
    if [[ $enhanced_lines -gt $basic_lines ]]; then
      printf "  ${_GRN}✓${_RST} enhanced template is larger than basic (%d vs %d lines)\n" "$enhanced_lines" "$basic_lines"
    else
      _FAILURES=$((_FAILURES + 1))
      printf "  ${_RED}✗${_RST} enhanced template should be larger than basic (%d vs %d lines)\n" "$enhanced_lines" "$basic_lines"
    fi
    _TESTS_RUN=$((_TESTS_RUN + 1))
  fi
  
  # Test invalid template
  assert_fail "./$ZAP_SCRIPT" init template-invalid -t invalid --author="Test User" "rejects invalid template"
  
  echo
}

test_license_handling() {
  _section_header "License Handling"
  
  local licenses=("mit" "apache" "gpl")
  local license
  
  for license in "${licenses[@]}"; do
    local output_file="$TEST_OUTPUT_DIR/license-${license}.sh"
    assert_ok "./$ZAP_SCRIPT" init "license-${license}-test" \
      -o "$output_file" \
      --author="Test Author" \
      --license="$license" "creates project with $license license"
    assert_file_exists "$output_file" "$license license file exists"
    
    case "$license" in
      mit) assert_file_contains "$output_file" "MIT License" "$license license content present" ;;
      apache) assert_file_contains "$output_file" "Apache License" "$license license content present" ;;
      gpl) assert_file_contains "$output_file" "GPL License" "gpl license content present" ;;
    esac
  done
  
  assert_fail "./$ZAP_SCRIPT" init invalid-license-test --license=invalid --author="Test User" "rejects invalid license"
  
  echo
}

test_script_updates() {
  _section_header "Script Updates with Preservation"
  
  local templates=("basic" "enhanced")
  local template
  
  for template in "${templates[@]}"; do
    local test_file="$TEST_OUTPUT_DIR/update-${template}.sh"
    local user_marker="# MY_CUSTOM_$(echo "$template" | tr '[:lower:]' '[:upper:]')_CODE_MUST_SURVIVE"
    
    # Create script
    assert_ok "./$ZAP_SCRIPT" init "update-${template}-test" -t "$template" -o "$test_file" --author="Update User" "creates $template for update testing"
    
    if [[ -f "$test_file" ]]; then
      # Inject simple change in app section
      if grep -q "##( app" "$test_file"; then
        sed -i.bak "/##( app/a\\
# $user_marker" "$test_file"
      else
        printf "  ${_YLW}⚠${_RST} Could not find app section in $test_file\n"
        continue
      fi
      
      # Verify injection worked
      assert_file_contains "$test_file" "$user_marker" "$template user code injected"
      assert_ok "$test_file" "modified $template script works"
      
      # Update script  
      assert_ok "./$ZAP_SCRIPT" update -y -f "$test_file" -t "$template" "updates $template script"
      
      # Verify preservation
      assert_executable "$test_file" "$template executable permission restored"
      assert_file_contains "$test_file" "$user_marker" "$template user code preserved after update"
      assert_ok "$test_file" "updated $template script still works"
      
      printf "  ${_GRN}ℹ${_RST} %s update test: user code survived\n" "$template"
    fi
  done
  
  # Test update failures
  assert_fail "./$ZAP_SCRIPT" update -y -f nonexistent.sh "fails with nonexistent file"
  
  echo
}

test_section_extraction() {
  _section_header "Section Extraction (Snip)"
  
  local basic_file="$TEST_OUTPUT_DIR/snip-basic.sh"
  local enhanced_file="$TEST_OUTPUT_DIR/snip-enhanced.sh"
  
  assert_ok "./$ZAP_SCRIPT" init snip-basic-test -t basic -o "$basic_file" --author="Snip User" "creates basic for snip testing"
  assert_ok "./$ZAP_SCRIPT" init snip-enhanced-test -t enhanced -o "$enhanced_file" --author="Snip User" "creates enhanced for snip testing"
  
  # Test app section extraction (default)
  assert_ok "./$ZAP_SCRIPT" snip -f "$basic_file" "extracts basic app section"
  assert_ok "./$ZAP_SCRIPT" snip -f "$enhanced_file" "extracts enhanced app section"
  
  # Test extraction to file
  local extract_file="$TEST_OUTPUT_DIR/extracted-basic-app.txt"
  assert_ok "./$ZAP_SCRIPT" snip -f "$basic_file" -o "$extract_file" "extracts basic to file"
  assert_file_exists "$extract_file" "extraction file created"
  assert_file_contains "$extract_file" "##( app" "extracted content has section markers"
  assert_file_contains "$extract_file" "##) app" "extracted content has end markers"
  
  # Test specific section extractions
  local sections=("header" "helpers" "app")
  local section
  for section in "${sections[@]}"; do
    local basic_section_file="$TEST_OUTPUT_DIR/basic-${section}.txt"
    local enhanced_section_file="$TEST_OUTPUT_DIR/enhanced-${section}.txt"
    
    assert_ok "./$ZAP_SCRIPT" snip -f "$basic_file" -s "$section" -o "$basic_section_file" "extracts basic $section"
    assert_ok "./$ZAP_SCRIPT" snip -f "$enhanced_file" -s "$section" -o "$enhanced_section_file" "extracts enhanced $section"
    
    assert_file_exists "$basic_section_file" "basic $section extraction created"
    assert_file_exists "$enhanced_section_file" "enhanced $section extraction created"
  done
  
  assert_fail "./$ZAP_SCRIPT" snip -f nonexistent.sh "fails with nonexistent file"
  
  echo
}

test_input_validation() {
  _section_header "Input Validation"
  
  # Test invalid project names
  assert_fail "./$ZAP_SCRIPT" init "invalid name" "rejects name with spaces"
  assert_fail "./$ZAP_SCRIPT" init "invalid@name" "rejects name with special chars"
  assert_fail "./$ZAP_SCRIPT" init "invalid.name" "rejects name with dots"
  
  # Test valid project names
  local output_file="$TEST_OUTPUT_DIR/valid-name.sh"
  assert_ok "./$ZAP_SCRIPT" init valid-name-123 -o "$output_file" --author="Test User" "accepts valid name"
  assert_ok "./$ZAP_SCRIPT" init valid_underscore -o "$TEST_OUTPUT_DIR/underscore.sh" --author="Test User" "accepts underscores"
  assert_ok "./$ZAP_SCRIPT" init valid-hyphen -o "$TEST_OUTPUT_DIR/hyphen.sh" --author="Test User" "accepts hyphens"
  
  echo
}

test_generated_script_quality() {
  _section_header "Generated Script Quality"
  
  local templates=("basic" "enhanced")
  local template
  
  for template in "${templates[@]}"; do
    local output_file="$TEST_OUTPUT_DIR/quality-${template}.sh"
    assert_ok "./$ZAP_SCRIPT" init "quality-${template}" \
      -o "$output_file" \
      -t "$template" \
      --author="Quality Tester" \
      --email="test@example.com" \
      --license=mit "creates quality $template script"
    
    if [[ -f "$output_file" ]]; then
      chmod +x "$output_file"
      
      # Test script basics
      assert_ok bash -n "$output_file" "$template script has valid syntax"
      assert_ok "$output_file" -h "$template script shows help"
      assert_ok "$output_file" -v "$template script shows version"
      assert_ok "$output_file" "$template script runs successfully"
      
      # Test content
      assert_file_contains "$output_file" "Quality Tester" "$template contains author"
      assert_file_contains "$output_file" "test@example.com" "$template contains email"
      assert_file_contains "$output_file" "MIT License" "$template contains license"
      
      # Test structure
      assert_file_contains "$output_file" "##( header" "$template has header section"
      assert_file_contains "$output_file" "##( app" "$template has app section"
      assert_file_contains "$output_file" "##( core" "$template has core section"
      
      assert_script_valid "$output_file" "$template quality check"
    fi
  done
  
  echo
}

test_directory_creation() {
  _section_header "Output Directory Creation"
  
  local nested_file="$TEST_OUTPUT_DIR/deep/nested/path/test.sh"
  assert_ok "./$ZAP_SCRIPT" init nested-test -o "$nested_file" --author="Test User" "creates nested directories"
  assert_file_exists "$nested_file" "nested file created"
  assert_executable "$nested_file" "nested file is executable"
  assert_ok test -d "$TEST_OUTPUT_DIR/deep/nested/path" "nested directories exist"
  
  echo
}

test_environment_integration() {
  _section_header "Environment Integration"
  
  # Test DEBUG output
  local debug_output
  debug_output=$(DEBUG=true "./$ZAP_SCRIPT" init debug-test -o "$TEST_OUTPUT_DIR/debug.sh" --author="Debug User" 2>&1)
  if echo "$debug_output" | grep -q "debug"; then
    printf "  ${_GRN}✓${_RST} %s\n" "DEBUG=true shows debug output"
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s\n" "DEBUG=true does not show debug output"
  fi
  _TESTS_RUN=$((_TESTS_RUN + 1))
  
  # Test NO_COLOR
  local normal_output
  normal_output=$(NO_COLOR=1 "./$ZAP_SCRIPT" init no-color-test -o "$TEST_OUTPUT_DIR/no-color.sh" --author="No Color User" 2>&1)
  if ! echo "$normal_output" | grep -q $'\033\['; then
    printf "  ${_GRN}✓${_RST} %s\n" "NO_COLOR=1 removes color codes"
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s\n" "NO_COLOR=1 does not remove color codes"
  fi
  _TESTS_RUN=$((_TESTS_RUN + 1))
  
  echo
}

test_error_handling() {
  _section_header "Error Handling"
  
  assert_fail "./$ZAP_SCRIPT" init "fails without project name"
  assert_fail "./$ZAP_SCRIPT" init permission-test -o "/root/unwritable.sh" --author="Test User" "fails with unwritable path"
  assert_fail "./$ZAP_SCRIPT" init test --invalid-option "fails with invalid option"
  
  echo
}

test_security_handling() {
  _section_header "Security - Special Characters"
  
  local output_file="$TEST_OUTPUT_DIR/security-test.sh"
  assert_ok "./$ZAP_SCRIPT" init security-test \
    -o "$output_file" \
    --author="Author & Co." \
    --email="test/user@domain.com" "handles special characters"
  
  if [[ -f "$output_file" ]]; then
    assert_file_contains "$output_file" "Author & Co." "preserves ampersand in author"
    assert_file_contains "$output_file" "test/user@domain.com" "preserves slash in email"
    assert_ok bash -n "$output_file" "script with special chars has valid syntax"
  fi
  
  echo
}

test_integration_workflow() {
  _section_header "Integration Workflow"
  
  local project_file="$TEST_OUTPUT_DIR/integration.sh"
  
  # Create project
  assert_ok "./$ZAP_SCRIPT" init integration-test \
    -o "$project_file" \
    --author="Integration Tester" \
    --license=apache "creates integration project"
  
  # Verify creation
  assert_file_exists "$project_file" "integration file exists"
  assert_executable "$project_file" "integration file is executable"
  assert_script_valid "$project_file" "integration script is valid"
  assert_file_contains "$project_file" "Integration Tester" "has correct author"
  
  # Modify app section (simulate development)
  if [[ -f "$project_file" ]]; then
    # Add custom code to app section
    sed -i.bak '/##( app/,/##) app/{
      /# Add your main application logic here/a\
echo "Custom integration code"\
local integration_var="test"\
integration_custom_function() { u.info "Integration function"; }
    }' "$project_file"
    
    # Update script
    assert_ok "./$ZAP_SCRIPT" update -y -f "$project_file" "updates integration project"
    
    # Verify preservation
    assert_executable "$project_file" "integration permissions preserved"
    assert_file_contains "$project_file" "Custom integration code" "preserves custom code"
    assert_file_contains "$project_file" "integration_var=" "preserves custom variables"
    assert_file_contains "$project_file" "integration_custom_function" "preserves custom functions"
    
    # Extract section
    local extract_file="$TEST_OUTPUT_DIR/integration-extract.txt"
    assert_ok "./$ZAP_SCRIPT" snip -f "$project_file" -o "$extract_file" "extracts from updated project"
    assert_file_exists "$extract_file" "extraction successful"
    assert_file_contains "$extract_file" "Custom integration code" "extracted custom code"
    
    # Verify script still works
    assert_ok "$project_file" "updated script still runs"
  fi
  
  echo
}

test_piped_execution() {
  _section_header "Piped Execution"
  
  # Test help in piped mode
  local output
  output=$(cat "$ZAP_SCRIPT" | bash -s -- -h 2>&1 || true)
  assert_contains "$output" "Lightning-fast bash script generator" "piped help displays correctly"
  assert_contains "$output" "bash init" "piped help shows bash as command name"
  
  # Test version in piped mode
  output=$(cat "$ZAP_SCRIPT" | bash -s -- -v 2>&1 || true)
  assert_eq "0.0.0" "$output" "piped version returns 0.0.0"
  
  # Test init in piped mode
  output=$(cat "$ZAP_SCRIPT" | bash -s -- init piped-test -t basic 2>&1)
  assert_ok test -f "piped-test.sh" "piped init creates script"
  assert_contains "$output" "created: piped-test.sh" "piped init shows success message"
  
  # Verify generated script has piped mode detection
  assert_contains "$(cat piped-test.sh)" "__PIPED=" "generated script includes piped mode detection"
  rm -f "piped-test.sh"
  
  # Test upgrade in piped mode - should fail gracefully for binary upgrade
  output=$(cat "$ZAP_SCRIPT" | bash -s -- upgrade 2>&1 || true)
  assert_contains "$output" "binary upgrade not supported in piped mode" "piped upgrade shows error for binary"
  assert_contains "$output" "curl -Lo" "piped upgrade shows installation instructions"
  
  # Test upgrade with --templates-only in piped mode - should attempt to work
  output=$(cat "$ZAP_SCRIPT" | bash -s -- upgrade --templates-only 2>&1 || true)
  assert_not_contains "$output" "binary upgrade not supported in piped mode" "piped upgrade --templates-only allowed"
  
  # Test update in piped mode with a dummy file
  echo "#!/usr/bin/env bash" > dummy-script.sh
  output=$(cat "$ZAP_SCRIPT" | bash -s -- update -y -f dummy-script.sh 2>&1 || true)
  assert_contains "$output" "template ID not found" "piped update attempts to work"
  rm -f dummy-script.sh
  
  # Test init with custom variables in piped mode
  output=$(cat "$ZAP_SCRIPT" | bash -s -- init piped-custom --author="Test Author" --email="test@example.com" 2>&1)
  assert_ok test -f "piped-custom.sh" "piped init with variables creates script"
  assert_contains "$(cat piped-custom.sh)" "Test Author" "piped init applies author variable"
  assert_contains "$(cat piped-custom.sh)" "test@example.com" "piped init applies email variable"
  rm -f "piped-custom.sh"
  
  echo
}

test_piped_mode_restriction() {
  _section_header "Piped Mode Restriction"
  
  # Test that scripts can disable piped mode
  local project="no-pipe-test-$$"
  local script_file="${project}.sh"
  
  # Create a script that disables piped mode
  assert_ok "$TOOL" init "$project" -t basic "creates project with basic template"
  assert_ok test -f "$script_file" "script file exists"
  
  # Track files immediately after creation
  track_test_file "$script_file"
  
  # Change __ALLOW_PIPED from true to false
  sed -i.bak 's/readonly __ALLOW_PIPED=true/readonly __ALLOW_PIPED=false/' "$script_file"
  
  # Track the backup file created by sed
  track_test_file "${script_file}.bak"
  
  # Test normal execution - should work
  local output
  output=$("./$script_file" -h 2>&1 || true)
  assert_contains "$output" "USAGE:" "normal execution works with __ALLOW_PIPED=false"
  
  # Test piped execution - should fail with proper error
  output=$(cat "$script_file" | bash 2>&1 || true)
  assert_contains "$output" "script is disabled in piped mode" "piped execution fails with error message"
  
  # Check exit code is _E_PIPE (8)
  # Temporarily disable set -e to capture exit code
  set +e
  cat "$script_file" | bash >/dev/null 2>&1
  local exit_code=$?
  set -e
  [[ "${DEBUG:-false}" == "true" ]] && echo "[debug] Exit code from piped execution: $exit_code" >&2
  assert_eq "8" "$exit_code" "piped execution exits with _E_PIPE (8)"
  
  # Test with enhanced template
  local enhanced_project="no-pipe-enhanced-$$"
  local enhanced_file="${enhanced_project}.sh"
  
  assert_ok "$TOOL" init "$enhanced_project" -t enhanced "creates enhanced project"
  
  # Track files immediately
  track_test_file "$enhanced_file"
  
  # Change __ALLOW_PIPED from true to false
  sed -i.bak 's/readonly __ALLOW_PIPED=true/readonly __ALLOW_PIPED=false/' "$enhanced_file"
  
  # Track the backup file
  track_test_file "${enhanced_file}.bak"
  
  output=$(cat "$enhanced_file" | bash 2>&1 || true)
  [[ "${DEBUG:-false}" == "true" ]] && echo "[debug] Enhanced template output: '$output'" >&2
  assert_contains "$output" "script is disabled in piped mode" "enhanced template respects __ALLOW_PIPED"
  
  echo
}
##) tests

##( init
setup_tests
##) init

##( core
trap 'teardown_tests' EXIT
_test_runner
teardown_tests
##) core