#!/usr/bin/env bash
##( header
# --------------------------------------------------------------------
# {{app}} - {{detail}}
#
# {{description}}
# --------------------------------------------------------------------
# AUTHOR: {{author}} <{{email}}>
# VERSION: {{version}}
# LICENSE: {{license_name}}
# --------------------------------------------------------------------
# __TEMPLATE__: https://github.com/budhash/zap-sh/blob/main/templates/basic.sh
# __ID__: basic-1.0.0
# --------------------------------------------------------------------
##) header

##( configuration
set -eEuo pipefail; IFS=$'\n\t'  # fail fast, secure IFS
##) configuration

##( metadata
readonly __SOURCE="${BASH_SOURCE[0]:-}"
readonly __PIPED=$([[ -t 0 || -n "$__SOURCE" ]] && echo false || echo true)
readonly __APP="$(basename "${__SOURCE:-$0}")"
readonly __APPFILE="$__SOURCE"
if [[ -n "$__SOURCE" ]]; then
  readonly __APPDIR="$(s="$__SOURCE"; while [[ -h "$s" ]]; do
    d="$(cd -P "$(dirname "$s")" && pwd)"; s="$(readlink "$s")"; [[ "$s" != /* ]] && s="$d/$s"; done; cd -P "$(dirname "$s")" && pwd)"
else
  readonly __APPDIR="$(pwd)"
fi
__DBG=${DEBUG:-false}
##) metadata

##( globals

##[ colors
_RST=$'\033[0m' _GRN=$'\033[0;32m' _YLW=$'\033[0;33m' _RED=$'\033[0;31m' _BLU=$'\033[0;34m'
[[ -n "${NO_COLOR:-}" || ! -t 1 ]] && _RST='' _GRN='' _YLW='' _RED='' _BLU=''
##] colors

##[ error
# general failure / bad usage / dependency not found / unsupported OS / not found / permission error / not connected / piped mode
readonly _E=1 _E_USG=2 _E_DEP=3 _E_OS=4 _E_NF=5 _E_NP=6 _E_NC=7 _E_PIPE=8
##] error

##) globals

##( helpers

##[ system
u.os() { case "${OSTYPE:-}" in darwin*) echo mac;; linux*) echo linux;; *) echo unknown;; esac; }
u.die() { u.error "$@"; exit $_E; }
u.require() {
  local tool="${1:-}"
  [[ -z "$tool" ]] && { u.error "missing dependency name"; exit $_E_DEP; }
  if [[ "$tool" == /* ]] || [[ "$tool" == ./* ]] || [[ "$tool" == ../* ]]; then
    [[ -x "$tool" ]] || { u.error "missing dependency: $tool"; exit $_E_DEP; } # Absolute or relative path - test directly
  else
    command -v "$tool" >/dev/null || { u.error "missing dependency: $tool"; exit $_E_DEP; }
  fi
}
##] system

##[ logging
u.log() {
  local _l="info " _co="$_GRN"
  [[ "${1:-}" == "-l" ]] && { _l="${2:-info}"; shift 2; }
  case "$_l" in warn) _co="$_YLW";; error) _co="$_RED";; debug) _co="$_BLU"; [[ "$__DBG" != true ]] && return;; esac
  printf "${_co}[%s]${_RST} %s\n" "$_l" "$*" >&2
  return 0
}
u.info() { u.log -l "info " "$@"; }
u.warn() { u.log -l "warn " "$@"; }
u.error() { u.log -l "error" "$@"; }
u.debug() { u.log -l "debug" "$@"; }
##] logging

##) helpers

##( app

##[ config
readonly __NAME=template
readonly __OS=(mac linux)
readonly __APP_DEPS=(find)
readonly __ALLOW_PIPED=true  # Set to false to disable piped execution (e.g., curl | bash)
##] config

##[ constants
##] constants

##[ functions
_main() {
  # Simple getopts-based argument parsing
  local _opt _help=false _version=false _file=""
  local OPTIND=1  # Explicitly reset OPTIND for function safety

  while getopts "hvf:" _opt; do
    case $_opt in
      h) _help=true;;
      v) _version=true;;
      f) _file="${OPTARG:-}";;
      \?) u.error "unknown option: -${OPTARG:-}"; exit $_E_USG;;
    esac
  done
  shift $((OPTIND-1))

  [[ "$_help" == true ]] && { _help; exit 0; }
  [[ "$_version" == true ]] && { _version; exit 0; }

  local _primary_arg="${1:-}"

  u.info "template version: $(_version) running on $(u.os)"
  [[ -n "$_file" ]] && u.info "file option: $_file"
  [[ -n "$_primary_arg" ]] && u.info "primary argument: $_primary_arg"

  # Input validation example
  if [[ -n "$_file" ]]; then
    [[ -f "$_file" ]] || { u.error "file not found: $_file"; return $_E_NF; }
    u.info "processing file: $_file"
  fi

  # Add your main application logic here
  return 0
}

_help() {
  cat << EOF
$(_version) - {{detail}}

USAGE:
    $__APP [OPTIONS] [ARGUMENT]

OPTIONS:
    -h              Show this help
    -v              Show version
    -f FILE         Process specified file

EXAMPLES:
    $__APP
    $__APP -f config.txt
    $__APP -f data.csv input_file

EOF
}

_version() { [[ "$__PIPED" == true ]] && echo "0.0.0" || sed -n 's/^# VERSION:[[:space:]]*\(.*\)/\1/p' "$__APPFILE" 2>/dev/null || echo "unknown"; }

_cleanup() {
  u.debug "cleanup"
}
##] functions

##) app

##( core
_boot() {
  [[ "$__PIPED" == true && "$__ALLOW_PIPED" == false ]] && { u.error "script is disabled in piped mode"; exit $_E_PIPE; }
  printf '%s\n' "${__OS[@]}" | grep -Fxq "$(u.os)" || u.die "unsupported OS: $(u.os) [required: ${__OS[*]}]"
  local _tool; for _tool in "${__APP_DEPS[@]:-}"; do u.require "$_tool"; done
}

trap _cleanup EXIT
_boot
_main "$@"
##) core