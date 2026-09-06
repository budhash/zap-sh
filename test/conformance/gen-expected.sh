#!/usr/bin/env bash
##( header
#
# Regenerate the conformance golden files (expected/*.sh) from the fixtures
# using the real `zap-sh init` (the bash oracle). The committed golden files
# are ground truth; run this only when a deliberate, spec-approved change to
# generation behavior has been made (and bump SPEC-VERSION accordingly).
#
# USAGE: test/conformance/gen-expected.sh
##) header

##( configuration
set -eEuo pipefail
##) configuration

##( main
# shellcheck source=test/conformance/lib.sh
source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if ! conf_have_jq; then
  echo "error: jq is required to regenerate conformance fixtures" >&2
  exit 1
fi

mkdir -p "$CONF_EXPECTED_DIR"

count=0
for fixture in "$CONF_FIXTURES_DIR"/*.json; do
  [[ -e "$fixture" ]] || { echo "error: no fixtures found in $CONF_FIXTURES_DIR" >&2; exit 1; }
  conf_build_args "$fixture"
  out="$CONF_EXPECTED_DIR/$CONF_NAME.sh"
  if conf_generate "$fixture" "$out"; then
    echo "  generated: expected/$CONF_NAME.sh"
    count=$((count + 1))
  else
    echo "error: oracle failed for fixture: $CONF_NAME" >&2
    exit 1
  fi
done

echo "regenerated $count golden file(s)"
##) main
