#!/usr/bin/env bash
##( header
#
# Conformance suite for zap-sh generation (the bash oracle).
#
# For every fixture in test/conformance/fixtures/*.json, regenerate the
# script with the real `zap-sh init` and assert it is byte-for-byte
# identical to the committed golden file in test/conformance/expected/.
#
# This freezes the oracle: any accidental change to generation behavior
# fails here. The JavaScript generator (added later) runs the SAME fixtures
# against the SAME golden files, guaranteeing bash/JS parity. See SPEC.md.
#
# USAGE: test/test-conformance.sh   (also run via `make test`)
##) header

##( configuration
set -eEuo pipefail
##) configuration

##( setup
# Locate this file, then source the shared framework + conformance helpers.
_SELF_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test/.common/test-common
source "$_SELF_DIR/.common/test-common"
# shellcheck source=test/conformance/lib.sh
source "$_SELF_DIR/conformance/lib.sh"
##) setup

##( tests
# Compare one fixture's freshly generated output against its golden file.
conf_check_fixture() {
  local fixture="$1"
  local name expected actual
  name=$(jq -r '.name' "$fixture")
  expected="$CONF_EXPECTED_DIR/$name.sh"

  _TESTS_RUN=$((_TESTS_RUN + 1))

  if [[ ! -f "$expected" ]]; then
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s (missing golden: expected/%s.sh)\n" "$name" "$name"
    return
  fi

  actual=$(mktemp)
  if ! conf_generate "$fixture" "$actual"; then
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s (oracle failed to generate)\n" "$name"
    rm -f "$actual"
    return
  fi

  if diff -u "$expected" "$actual" >/dev/null 2>&1; then
    printf "  ${_GRN}✓${_RST} %s\n" "$name"
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s (output differs from golden)\n" "$name"
    diff -u "$expected" "$actual" | sed 's/^/      /' | head -30
    printf "      (run test/conformance/gen-expected.sh only after a spec-approved change)\n"
  fi
  rm -f "$actual"
}

conf_run() {
  _section_header "Conformance: bash oracle vs golden files"

  if ! conf_have_jq; then
    printf "  %s!%s jq not found — conformance suite skipped (install jq to run)\n" "$_YLW" "$_RST"
    echo
    return
  fi

  local fixture found=false
  for fixture in "$CONF_FIXTURES_DIR"/*.json; do
    [[ -e "$fixture" ]] || continue
    found=true
    conf_check_fixture "$fixture"
  done

  if [[ "$found" != true ]]; then
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} no fixtures found in %s\n" "$CONF_FIXTURES_DIR"
  fi
  echo
}
##) tests

##( core
conf_run

echo "=================================="
if [[ $_FAILURES -eq 0 ]]; then
  printf "%s (%d fixtures)\n" "${_GRN}✓ ALL CONFORMANCE TESTS PASSED${_RST}" "$_TESTS_RUN"
else
  printf "%s (out of %d)\n" "${_RED}✗ $_FAILURES CONFORMANCE TESTS FAILED${_RST}" "$_TESTS_RUN"
fi
echo "=================================="

exit $_FAILURES
##) core
