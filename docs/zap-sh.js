/* @budhash/zap-sh — generated browser bundle. Do not edit; run `npm run build:web`. */

// src/templates.generated.js
var TEMPLATES = {
  "basic": `#!/usr/bin/env bash
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
set -eEuo pipefail; IFS=$'\\n\\t'  # fail fast, secure IFS
##) configuration

##( metadata
readonly __SOURCE="\${BASH_SOURCE[0]:-}"
readonly __PIPED=$([[ -t 0 || -n "$__SOURCE" ]] && echo false || echo true)
readonly __APP="$(basename "\${__SOURCE:-$0}")"
readonly __APPFILE="$__SOURCE"
if [[ -n "$__SOURCE" ]]; then
  readonly __APPDIR="$(s="$__SOURCE"; while [[ -h "$s" ]]; do
    d="$(cd -P "$(dirname "$s")" && pwd)"; s="$(readlink "$s")"; [[ "$s" != /* ]] && s="$d/$s"; done; cd -P "$(dirname "$s")" && pwd)"
else
  readonly __APPDIR="$(pwd)"
fi
__DBG=\${DEBUG:-false}
##) metadata

##( globals

##[ colors
_RST=$'\\033[0m' _GRN=$'\\033[0;32m' _YLW=$'\\033[0;33m' _RED=$'\\033[0;31m' _BLU=$'\\033[0;34m'
[[ -n "\${NO_COLOR:-}" || ! -t 1 ]] && _RST='' _GRN='' _YLW='' _RED='' _BLU=''
##] colors

##[ error
# general failure / bad usage / dependency not found / unsupported OS / not found / permission error / not connected / piped mode
readonly _E=1 _E_USG=2 _E_DEP=3 _E_OS=4 _E_NF=5 _E_NP=6 _E_NC=7 _E_PIPE=8
##] error

##) globals

##( helpers

##[ system
u.os() { case "\${OSTYPE:-}" in darwin*) echo mac;; linux*) echo linux;; *) echo unknown;; esac; }
u.die() { u.error "$@"; exit $_E; }
u.require() {
  local tool="\${1:-}"
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
  [[ "\${1:-}" == "-l" ]] && { _l="\${2:-info}"; shift 2; }
  case "$_l" in warn) _co="$_YLW";; error) _co="$_RED";; debug) _co="$_BLU"; [[ "$__DBG" != true ]] && return;; esac
  printf "\${_co}[%s]\${_RST} %s\\n" "$_l" "$*" >&2
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
      f) _file="\${OPTARG:-}";;
      \\?) u.error "unknown option: -\${OPTARG:-}"; exit $_E_USG;;
    esac
  done
  shift $((OPTIND-1))

  [[ "$_help" == true ]] && { _help; exit 0; }
  [[ "$_version" == true ]] && { _version; exit 0; }

  local _primary_arg="\${1:-}"

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

_version() { [[ "$__PIPED" == true ]] && echo "0.0.0" || sed -n 's/^# VERSION:[[:space:]]*\\(.*\\)/\\1/p' "$__APPFILE" 2>/dev/null || echo "unknown"; }

_cleanup() {
  u.debug "cleanup"
}
##] functions

##) app

##( core
_boot() {
  [[ "$__PIPED" == true && "$__ALLOW_PIPED" == false ]] && { u.error "script is disabled in piped mode"; exit $_E_PIPE; }
  printf '%s\\n' "\${__OS[@]}" | grep -Fxq "$(u.os)" || u.die "unsupported OS: $(u.os) [required: \${__OS[*]}]"
  local _tool; for _tool in "\${__APP_DEPS[@]:-}"; do u.require "$_tool"; done
}

trap _cleanup EXIT
_boot
_main "$@"
##) core`,
  "enhanced": `#!/usr/bin/env bash
##( header
# --------------------------------------------------------------------
#
# {{app}} - {{detail}}
#
# --------------------------------------------------------------------
# AUTHOR:   Copyright (C) {{year}} {{author}} <{{email}}>
# VERSION:  {{version}}
# --------------------------------------------------------------------
# DESCRIPTION:
#
# {{description}}
# --------------------------------------------------------------------
# LICENSE: {{license_name}}
# {{license_content}}
# --------------------------------------------------------------------
# USAGE:
#
# Type "{{app}} -h" for usage guidelines.
# --------------------------------------------------------------------
# __TEMPLATE__: https://github.com/budhash/zap-sh/blob/main/templates/enhanced.sh
# __ID__: enhanced-1.0.0
# --------------------------------------------------------------------
##) header

##( configuration
set -e          # exit immediately if a command exits with a non-zero status
set -E          # \`trap\`s are inherited by functions, command substitutions, and subshells
set -u          # treat unset variables as an error when substituting
set -o pipefail # The return value of a pipeline is the status of the last command to exit with a non-zero status
IFS=$'\\n\\t'     # Secure IFS
##) configuration

##( metadata
readonly __SOURCE="\${BASH_SOURCE[0]:-}"
readonly __PIPED=$([[ -t 0 || -n "$__SOURCE" ]] && echo false || echo true)
readonly __APP="$(basename "\${__SOURCE:-$0}")"
readonly __APPFILE="$__SOURCE"
if [[ -n "$__SOURCE" ]]; then
  readonly __APPDIR="$(s="$__SOURCE"; while [[ -h "$s" ]]; do
    d="$(cd -P "$(dirname "$s")" && pwd)"; s="$(readlink "$s")"; [[ "$s" != /* ]] && s="$d/$s"; done; cd -P "$(dirname "$s")" && pwd)"
else
  readonly __APPDIR="$(pwd)"
fi

readonly __L_NEW=\${LOG_NEW:-true}
readonly __L_FS=\${LOG_FS:-false}

readonly __DEPS=(sed curl)
__DBG=\${DEBUG:-false}
##) metadata

##( globals

##[ colors
_RST=$'\\033[0m' _GRN=$'\\033[0;32m' _YLW=$'\\033[0;33m' _RED=$'\\033[0;31m' _BLU=$'\\033[0;34m'
[[ -n "\${NO_COLOR:-}" || ! -t 1 ]] && _RST='' _GRN='' _YLW='' _RED='' _BLU=''
##] colors

##[ error
readonly _E=1               # general failure
readonly _E_USG=2           # bad usage / invalid arguments
readonly _E_DEP=3           # dependency not found
readonly _E_OS=4            # unsupported OS
readonly _E_NF=5            # not found
readonly _E_NP=6            # permission Error
readonly _E_NC=7            # not connected
readonly _E_PIPE=8          # piped mode
##] error

##[ network
readonly _H_JSON="Content-Type: application/json"
readonly _H_ACCEPT_JSON="Accept: application/json"
readonly _CURL_TIMEOUT_CONNECT=10
readonly _CURL_TIMEOUT_MAX=30
##] network

##[ misc
__TEMP_DIRS=()
##] misc

##) globals

##( helpers

##[ system
##{
##@ system utility functions
##: u.os -> os=$(u.os)  # returns: mac, linux, unknown
##: u.arch -> arch=$(u.arch)  # returns: x86_64, x86, arm, arm64, unknown
##: u.require <command> -> u.require curl  # exits on missing dependency
##: u.die <message> -> u.die "fatal error occurred"  # exits with error
u.os() { case "\${OSTYPE:-}" in darwin*) echo mac;; linux*) echo linux;; *) echo unknown;; esac; }
u.arch() { case "$(uname -m 2>/dev/null)" in x86_64*) echo x86_64;; i*86) echo x86;; arm*) echo arm;; aarch64) echo arm64;; *) echo unknown;; esac; }
u.die() { u.error "$@"; exit $_E; }
u.require() {
  local tool="\${1:-}"
  [[ -z "$tool" ]] && { u.error "missing dependency name"; exit $_E_DEP; }
  if [[ "$tool" == /* ]] || [[ "$tool" == ./* ]] || [[ "$tool" == ../* ]]; then
    [[ -x "$tool" ]] || { u.error "missing dependency: $tool"; exit $_E_DEP; } # Absolute or relative path - test directly
  else
    command -v "$tool" >/dev/null || { u.error "missing dependency: $tool"; exit $_E_DEP; }
  fi
}
##}
##] system

##[ logging
##{
##@ unified logging function with level support
##: u.log [-l level] <message> -> u.log "info message" or u.log -l warn "warning"
u.log() {
  local _l="info " _co="$_GRN"
  [[ "\${1:-}" == "-l" ]] && { _l="\${2:-info}"; shift 2; }
  case "$_l" in warn) _co="$_YLW";; error) _co="$_RED";; debug) _co="$_BLU"; [[ "$__DBG" != true ]] && return;; esac
  printf "\${_co}[%s]\${_RST} %s\\n" "$_l" "$*" >&2
  [[ "$__L_FS" == true ]] && printf "[%s] [%s] %s\\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$_l" "$*" >> "\${__LOG:-/dev/null}"
  return 0
}
##}
##{
##@ logging level shortcuts
##: u.info <message> -> u.info "process started"
##: u.warn <message> -> u.warn "deprecated feature used"
##: u.error <message> -> u.error "validation failed"
##: u.debug <message> -> u.debug "variable value: $var"
u.info() { u.log -l "info " "$@"; }
u.warn() { u.log -l "warn " "$@"; }
u.error() { u.log -l "error" "$@"; }
u.debug() { u.log -l "debug" "$@"; }
##}
##] logging

##[ string
##{
##@ string utility functions (Bash 3.x compatible, handles args and stdin)
##: u.lower <string> -> lower=$(u.lower "HELLO") or echo "HELLO" | u.lower
##: u.upper <string> -> upper=$(u.upper "hello") or echo "hello" | u.upper
##: u.trim <string> -> trimmed=$(u.trim "  hello  ") or echo "  hello  " | u.trim
##: u.isnum <string> -> if u.isnum "-123"; then ...; fi
##: u.isalphanum <string> -> if u.isalphanum "abc123"; then ...; fi
##: u.isfloat <string> -> if u.isfloat "-10.5"; then ...; fi
u.lower() { [[ $# -gt 0 ]] && echo "$@" | tr '[:upper:]' '[:lower:]' || tr '[:upper:]' '[:lower:]'; }
u.upper() { [[ $# -gt 0 ]] && echo "$@" | tr '[:lower:]' '[:upper:]' || tr '[:lower:]' '[:upper:]'; }
u.trim() { local _s; _s=$([[ $# -gt 0 ]] && echo "$@" || cat); _s="\${_s#"\${_s%%[![:space:]]*}"}"; printf '%s' "\${_s%"\${_s##*[![:space:]]}"}"; }
u.isnum() { [[ "\${1:-}" =~ ^-?[0-9]+$ ]]; }
u.isalphanum() { [[ "\${1:-}" =~ ^[[:alnum:]]+$ ]]; }
u.isfloat() { echo "\${1:-}" | grep -Eq '^-?[0-9]+(\\.[0-9]+)?$'; }
##}
##] string

##[ array
##{
##@ array utility functions
##: u.array_contains <value> <array_elements...> -> u.array_contains "item" "\${my_array[@]}"
##: u.array_length <array_elements...> -> count=$(u.array_length "\${my_array[@]}")
##: u.array_empty <array_elements...> -> u.array_empty "\${my_array[@]}" && echo "empty"
##: u.array_reverse <array_elements...> -> reversed=($(u.array_reverse "\${my_array[@]}"))
##: u.array_sort [-n] <array_elements...> -> sorted=($(u.array_sort "\${my_array[@]}"))
##: u.array_unique <array_elements...> -> unique=($(u.array_unique "\${my_array[@]}"))
u.array_contains() { local _n="\${1:-}" _h; [[ -n "$_n" ]] || { u.error "value required for contains check"; return $_E_USG; }; shift; for _h in "$@"; do [[ "$_h" == "$_n" ]] && return 0; done; return 1; }
u.array_length() { echo $#; }
u.array_empty() { [[ $# -eq 0 ]]; }
u.array_reverse() { local _a=("$@") _i; for ((_i=\${#_a[@]}-1; _i>=0; _i--)); do echo "\${_a[_i]}"; done; }
u.array_sort() { [[ "\${1:-}" == "-n" ]] && { shift; printf '%s\\n' "$@" | sort -n; } || printf '%s\\n' "$@" | sort; }
u.array_unique() { [[ $# -gt 0 ]] && printf '%s\\n' "$@" | sort -u; }
##}
##{
##@ filters an array based on a simple glob pattern (substring match)
##: u.array_grep <pattern> <array_elements...> -> filtered=($(u.array_grep ".txt" "\${files[@]}"))
u.array_grep() { local _p="\${1:-}" _i; shift; for _i in "$@"; do [[ "$_i" == *$_p* ]] && echo "$_i"; done; }
##}
##{
##@ applies a callback function to each element of an array
##: u.array_map <callback> <array_elements...> -> double() { echo $(($1 * 2)); }; arr=(); while IFS= read -r line; do arr+=("$line"); done < <(u.array_map "double" 1 2 3)
u.array_map() {
    local _callback="\${1:-}" _i
    [[ -n "$_callback" ]] || { u.error "map callback function required"; return $_E_USG; }
    [[ $(type -t "$_callback") == "function" ]] || { u.error "map callback is not a function: $_callback"; return $_E_USG; }
    shift
    for _i in "\${@:-}"; do "$_callback" "$_i"; done
}
##}
##{
##@ filters an array using a callback function that returns 0 for elements to keep
##: u.array_filter <callback> <array_elements...> -> is_even() { (( $1 % 2 == 0 )); }; e=($(u.array_filter "is_even" 1 2 3 4))
u.array_filter() {
    local _callback="\${1:-}" _i
    [[ -n "$_callback" ]] || { u.error "filter callback function required"; return $_E_USG; }
    [[ $(type -t "$_callback") == "function" ]] || { u.error "filter callback is not a function: $_callback"; return $_E_USG; }
    shift
    for _i in "\${@:-}"; do "$_callback" "$_i" && printf '%s\\n' "$_i"; done
}
##}
##{
##@ join array elements with delimiter
##: u.array_join <delimiter> <array_elements...> -> result=$(u.array_join "," "\${my_array[@]}")
u.array_join() {
  local _d="\${1:-}" _f=true _i; [[ $# -gt 0 ]] && shift
  for _i in "$@"; do [[ "$_f" == true ]] && { printf '%s' "$_i"; _f=false; } || printf '%s%s' "$_d" "$_i"; done
}
##}
##] array

##[ input
##{
##@ cross shell read function with character mode support
##: u.read <prompt> [char_mode] -> response=$(u.read "Enter name:" false)
u.read() {
  local _p="\${1:-}" _c="\${2:-false}" _r=""
  printf "\${_YLW}>> %s\${_RST} " "$_p" >&2
  [[ "$_c" == true ]] && { [[ -n "\${ZSH_VERSION:-}" ]] && read -k1 -r _r </dev/tty || read -n1 -r _r </dev/tty; } || read -r _r </dev/tty
  echo >&2; printf '%s' "$_r"
}
##}
##{
##@ reads multi-line text from the terminal until EOF (Ctrl+D)
##: u.readtext <prompt> -> content=$(u.readtext "Paste text here:")
u.readtext() { local _p="\${1:-}"; printf "\${_YLW}>> %s\${_RST}\\n" "$_p" >&2; cat </dev/tty; }
##}
##{
##@ input utility shortcuts and interactive selection
##: u.readline <prompt> -> line=$(u.readline "Enter line:")
##: u.readchar <prompt> -> char=$(u.readchar "Press any key:")
##: u.confirm <prompt> -> u.confirm "Continue?" && echo "yes"
##: u.select <prompt> <options...> -> choice=$(u.select "Pick:" "opt1" "opt2" "opt3")
u.readline() { u.read "\${1:-Enter line:}" false; }
u.readchar() { u.read "\${1:-}" true; }
u.confirm() { local _r; _r=$(u.readchar "\${1:-Continue?} [y/N]:"); [[ "$(echo "$_r" | tr '[:upper:]' '[:lower:]')" == y ]]; }
u.select() {
  local _p="\${1:-Choose option:}"; shift
  u.info "$_p"
  local _i
  PS3="> "
  select _i in "$@" "Quit"; do
    case "$_i" in
      "Quit") return 1;;
      "") u.warn "Invalid selection. Please try again.";;
      *) printf '%s' "$_i"; return 0;;
    esac
  done
}
##}
##] input

##[ filesys
##{
##@ file and directory utilities
##: u.exists <path> -> u.exists "/path/file" && echo "found"
##: u.isfile <path> -> u.isfile "script.sh" || u.error "not a file"
##: u.isdir <path> -> u.isdir "/tmp" && echo "directory exists"
##: u.tempdir [prefix] -> tmpdir=$(u.tempdir "myapp")
u.exists() { [[ -e "\${1:-}" ]] || { u.error "not found: \${1:-}"; return $_E_NF; }; }
u.isfile() { [[ -f "\${1:-}" ]] || { u.error "not a file: \${1:-}"; return $_E_NF; }; }
u.isdir() { [[ -d "\${1:-}" ]] || { u.error "not a directory: \${1:-}"; return $_E_NF; }; }
u.tempdir() {
  local _d
  _d=$(mktemp -d -t "\${1:-\${__APP:-app}}.XXXXXXXXXX") || { u.error "cannot create temporary directory"; return $_E; }
  __TEMP_DIRS+=("$_d")
  echo "$_d"
}
##}
##] filesys

##[ network
##{
##@ network connectivity and HTTP utilities
##: u.online -> u.online && echo "connected"
u.online() { [[ "$(u.os)" == "mac" ]] && ping -c 1 -t 1 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; }
##}
##{
##@ generic curl wrapper for HTTP operations
##: u.kurl <method> <endpoint> [payload] [headers...] -> u.kurl POST "https://api.example.com/users" '{"data":"test"}' "Content-Type: text/plain"
u.kurl() {
  local _method="\${1:-GET}" _endpoint="\${2:-}"
  [[ -n "$_endpoint" ]] || { u.error "endpoint required"; return $_E_USG; }
  local _payload="\${3:-}"; shift 3
  local _opts=("-s" "-f" "--location" "-X" "$_method" "--connect-timeout" "$_CURL_TIMEOUT_CONNECT" "--max-time" "$_CURL_TIMEOUT_MAX")
  [[ -n "$_payload" ]] && _opts+=("-d" "$_payload")
  local _header; for _header in "$@"; do _opts+=("-H" "$_header"); done
  u.debug "request>>>>: $(u.array_join ' ' curl "\${_opts[@]:-}" "$_endpoint")"
  local _r _e
  _r=$(curl "\${_opts[@]}" "$_endpoint")
  _e=$?
  u.debug "response<<<<: $_r"
  echo "$_r" && return $_e
}
##}
##{
##@ JSON API wrappers with automatic headers
##: u.api_get     <endpoint> [headers...]       -> data=$(u.api_get "https://\u2026" "Authorization: Bearer $TOK")
##: u.api_post    <endpoint> <payload> [headers...] -> u.api_post "https://\u2026" '{"foo":"bar"}' "Authorization: Bearer $TOK"
##: u.api_put     <endpoint> <payload> [headers...] -> u.api_put  "https://\u2026" '{"foo":"baz"}' "Authorization: Bearer $TOK"
##: u.api_delete  <endpoint> [headers...]       -> u.api_delete "https://\u2026" "Authorization: Bearer $TOK"
u.api_get() { local _e="\${1:-}"; [[ -n "$_e" ]] || { u.error "endpoint required"; return $_E_USG; }; shift; u.kurl GET "$_e" "" "$_H_ACCEPT_JSON" "$@"; }
u.api_post() { local _e="\${1:-}" _p="\${2:-}"; [[ -n "$_e" && -n "$_p" ]] || { u.error "endpoint and payload required"; return $_E_USG; }; shift 2; u.kurl POST "$_e" "$_p" "$_H_ACCEPT_JSON" "$_H_JSON" "$@"; }
u.api_put() { local _e="\${1:-}" _p="\${2:-}"; [[ -n "$_e" && -n "$_p" ]] || { u.error "endpoint and payload required"; return $_E_USG; }; shift 2; u.kurl PUT "$_e" "$_p" "$_H_ACCEPT_JSON" "$_H_JSON" "$@"; }
u.api_delete() { local _e="\${1:-}"; [[ -n "$_e" ]] || { u.error "endpoint required"; return $_E_USG; }; shift; u.kurl DELETE "$_e" "" "$_H_ACCEPT_JSON" "$@"; }
##}
##] network

##[ time
##{
##@ timestamp generation in various formats
##: u.timestamp [format] -> timestamp=$(u.timestamp file)  # formats: iso, date, time, unix, utc, file
u.timestamp() { case "\${1:-iso}" in iso) date "+%Y-%m-%d %H:%M:%S";; date) date "+%Y-%m-%d";; time) date "+%H:%M:%S";; unix) date "+%s";; utc) TZ=UTC date "+%Y-%m-%dT%H:%M:%SZ";; file) date "+%Y%m%d-%H%M%S";; *) date "+%Y-%m-%d %H:%M:%S";; esac; }
##}

##{
##@ generate random string with specified charset and length
##: u.random [charset] [length] -> token=$(u.random alphanum 32)  # charsets: alpha, num, alphanum, full
u.random() {
  local _m="\${1:-full}" _l="\${2:-16}" _c
  case "$_m" in alpha)    _c="A-Za-z";; num) _c="0-9";; alphanum) _c="A-Za-z0-9";; *) _c="A-Za-z0-9!@#$%^&*()+-=";; esac
  [[ "$_l" -eq 0 ]] && return 0

  # appending '|| true' to the pipelines makes them immune to the pipefail issue caused by 'head' closing the pipe early.
  if [[ -r /dev/urandom ]]; then
    LC_ALL=C tr -dc "$_c" < /dev/urandom | head -c "$_l" || true
  else
    openssl rand -base64 $((_l * 2)) | LC_ALL=C tr -dc "$_c" | head -c "$_l" || true
  fi
}
##}
##] time

##[ json
##{
##@ safe JSON value extraction using awk (portable and robust)
##: u.json_get <json> <key> [default] -> value=$(u.json_get "$json" "temperature" "0")
u.json_get() {
  local _json="\${1:-}" _key="\${2:-}" _default="\${3:-}"
  local _val
  [[ -n "$_json" && -n "$_key" ]] || { u.error "u.json_get: json and key required"; return $_E_USG; }
  # First try to match quoted values
  _val=$(echo "$_json" | sed -n 's/.*"'$_key'"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p')
  # If no match, try unquoted values (numbers, booleans)
  if [[ -z "$_val" ]]; then
    _val=$(echo "$_json" | sed -n 's/.*"'$_key'"[[:space:]]*:[[:space:]]*\\([^,}[:space:]]*\\).*/\\1/p')
  fi
  [[ -n "$_val" ]] && echo "$_val" || { [[ -n "$_default" ]] && echo "$_default" || return 1; }
}
##}
##] json

##) helpers

##( app
##[ config
readonly __NAME=template
readonly __OS=(mac linux)
readonly __APP_DEPS=(find)
readonly __ALLOW_PIPED=true  # Set to false to disable piped execution (e.g., curl | bash)
readonly __ARG_AUTO=true     # Enable automatic argument parsing
# format: "short_spec|variable_name|long_name|description"
readonly __APP_OPTS=(
  "n:|_name|name|Your name for personalized greeting"
  "c:|_count|count|Number of greetings (default: 1)"
  "l|_loud|loud|Use uppercase output"
)
##] config

##[ constants
##] constants

##[ functions
_main() {
  local _greeting="Hello"
  local _target="\${_name:-World}"
  local _num="\${_count:-1}"

  [[ "\${_loud:-false}" == true ]] && {
    _greeting=$(u.upper "$_greeting")
    _target=$(u.upper "$_target")
  }

  local _i
  for ((_i=1; _i<=_num; _i++)); do
    u.info "$_greeting, $_target! (greeting $_i of $_num)"
  done

  u.info "Template version: $(_version) running on $(u.os)"
  return 0
}

_app_info() { echo "Simple greeting tool demonstrating zap-sh template"; }
_app_usage() { echo "$__APP [OPTIONS]"; }
_app_examples() {
  cat << EOF
    $__APP
    $__APP -n "Alice" -c 3
    $__APP -n "Bob" -l
EOF
}
_app_env() { return 0; }
_app_cleanup() { u.debug "app cleanup"; }
##] functions
##) app

##( core
_version() { sed -n 's/^# VERSION:[[:space:]]*\\(.*\\)/\\1/p' "$__APPFILE"; }

_help() {
  cat << EOF
$(_version) - $(_app_info)

USAGE:
    $(_app_usage)

OPTIONS:
    Core:
EOF
  printf "        %-25s %s\\n" "-h" "Show help"
  printf "        %-25s %s\\n" "-v" "Show version"

  echo "    App:"
  local _line _short _var _long _desc _rem
  while read -r _line; do
    _short="\${_line%%|*}"; _rem="\${_line#*|}";
    _var="\${_rem%%|*}";   _rem="\${_rem#*|}";
    _long="\${_rem%%|*}";  _desc="\${_rem#*|}";
    [[ -n "$_short" ]] && printf "        %-25s %s\\n" "-\${_short%:}" "$_desc"
  done <<< "$(printf '%s\\n' "\${__APP_OPTS[@]}")"

  cat << EOF

ENVIRONMENT:
    Core:
EOF
  printf "        %-25s %s\\n" "DEBUG=true" "Enable debug output"
  printf "        %-25s %s\\n" "LOG_FS=true" "Enable file logging to ./\${__APP}.log"
  printf "        %-25s %s\\n" "LOG_NEW=false" "Append to existing log file"
  printf "        %-25s %s\\n" "ARG_AUTO=false" "Disable automatic argument parsing"

  if [[ -n "$(_app_env)" ]]; then
    echo "    App:"
    while IFS='|' read -r _var _desc; do
      [[ -n "$_var" ]] && printf "        %-25s %s\\n" "$_var" "$_desc"
    done < <(_app_env)
  fi

  cat << EOF

EXAMPLES:
$(_app_examples)

EOF
}

_args() {
  # Build optstring for getopts
  local _optstr="hv" _e
  while IFS='|' read -r _short _var _long _desc; do
    _optstr+="\${_short}"
  done <<< "$(printf '%s\\n' "\${__APP_OPTS[@]}")"

  # Preprocess: separate flags from positional args
  local _reordered=() _positional=() _i _next_is_value=false

  for _i in "$@"; do
    if [[ "$_next_is_value" == true ]]; then
      # This is a value for the previous flag
      _reordered+=("$_i")
      _next_is_value=false
    elif [[ "$_i" =~ ^-[a-zA-Z]$ ]]; then
      # Single character flag (e.g., -l, -a)
      _reordered+=("$_i")
      # Check if this flag expects a value
      local _flag_char="\${_i#-}"
      [[ "$_optstr" == *"$_flag_char:"* ]] && _next_is_value=true
    elif [[ "$_i" =~ ^-[a-zA-Z] ]]; then
      # Flag with attached value (e.g., -lvalue) or multi-char flag
      _reordered+=("$_i")
    elif [[ "$_i" == -* ]]; then
      # Other dash arguments (handle edge cases)
      _reordered+=("$_i")
    else
      # Positional argument
      _positional+=("$_i")
    fi
  done

  # Parse the reordered flags using standard getopts
  if [[ \${#_reordered[@]} -gt 0 ]]; then
    local OPTIND=1 OPTERR=0 _opt
    while getopts "$_optstr-:" _opt "\${_reordered[@]}"; do
      case $_opt in
        -) u.error "long options not supported" >&2; exit $_E_USG;;
        h|v) ;; # Core flags handled in _init
        \\?) u.error "unknown option: -\${OPTARG}" >&2; exit $_E_USG;;
        *)
          # Find matching option in __APP_OPTS
          for _e in "\${__APP_OPTS[@]}"; do
            IFS='|' read -r _short _var _long _desc <<< "$_e"
            if [[ "\${_short%:}" == "$_opt" ]]; then
              if [[ "$_short" == *":"* ]]; then
                printf '%s:%s\\n' "$_var" "\${OPTARG:-}"
              else
                printf '%s:true\\n' "$_var"
              fi
              break
            fi
          done
          ;;
      esac
    done
  fi

  # Output positional arguments
  if [[ \${#_positional[@]} -gt 0 ]]; then
    for _i in "\${_positional[@]}"; do
      printf '__ARG_FNL:%s\\n' "$_i"
    done
  fi
}

_boot() {
  [[ "$__PIPED" == true && "$__ALLOW_PIPED" == false ]] && { u.error "script is disabled in piped mode"; exit $_E_PIPE; }
  
  readonly __LOG="./\${__APP}.log"

  u.debug "location:"
  u.debug " __APPDIR: \${__APPDIR}"
  u.debug " __APPFILE: \${__APPFILE}"

  if [[ "$__L_FS" == true ]]; then
    [[ "$__L_NEW" == true && -f "$__LOG" ]] && rm -f "$__LOG"
    echo "-------- $(date) --------" >> "$__LOG"
  fi
  u.debug "checking - os requirement: current [$(u.os)]"
  printf '%s\\n' "\${__OS[@]}" | grep -Fxq "$(u.os)" || u.die "unsupported OS: $(u.os) [required: \${__OS[*]}]"
  u.debug "checking - framework dependencies"
  local _tool; for _tool in "\${__DEPS[@]:-}"; do u.require "$_tool"; done
  u.debug "checking - app dependencies"
  local _tool; for _tool in "\${__APP_DEPS[@]:-}"; do u.require "$_tool"; done
}

_init() {
  case "\${1:-}" in
    -h|--help) _help; exit 0;;
    -v|--version) _version; exit 0;;
  esac

  if [[ "$__ARG_AUTO" == true ]]; then
    if [[ $# -gt 0 ]]; then
      local _assignments _var _val
      # Capture the key:value output from _args
      _assignments=$(_args "$@") || exit $?

      __ARG_FNL=()
      while IFS=: read -r _var _val; do
        [[ -n "$_var" ]] || continue
        if [[ "$_var" == "__ARG_FNL" ]]; then
          __ARG_FNL+=("$_val")
        else
          printf -v "$_var" '%s' "$_val" # printf -v for safe, indirect variable assignment
        fi
      done <<< "$_assignments"
    fi

    local _e _n _v
    u.debug "args (auto-parsed):"
    u.debug " remaining [__ARG_FNL]: '$(u.array_join ' ' "\${__ARG_FNL[@]:-}")'"
    u.debug " parsed               :"
    for _e in "\${__APP_OPTS[@]}"; do
      IFS='|' read -r _short _n _long _desc <<< "$_e"
      if declare -p "$_n" &>/dev/null; then
        _v="\${!_n}"
        u.debug " - \${_n}: '\${_v}'"
      else
        u.debug " - \${_n}: unset"
      fi
    done
  else
    u.debug "args (manual parsing): '$(u.array_join ' ' "$@")'"
  fi

  u.info "starting - $(_version)"
}

_cleanup() {
  [[ \${#__TEMP_DIRS[@]} -eq 0 ]] && return 0
  local _probe _path _dir
  _probe=$(mktemp -d) || { u.warn "cleanup: could not determine temp path, skipping cleanup"; return 1; }
  _path=$(dirname "$_probe"); rm -rf "$_probe"
  for _dir in "\${__TEMP_DIRS[@]:-}"; do
    [[ "$_dir" == "$_path"/* ]] && { u.debug "cleanup: removing '$_dir'"; rm -rf "$_dir"; } || u.warn "cleanup: skipping non-temporary path '$_dir'"
  done
  _app_cleanup
}
trap _cleanup EXIT

_boot || exit $?
_init "$@"
# Execute _main in a subshell to isolate its environment.
# It restores the default IFS for user code and prevents variables created in _main from polluting the global scope.
(
  IFS=$' \\t\\n' # Restore default IFS for user-land code
  if [[ "$__ARG_AUTO" == true ]]; then
    _main "\${__ARG_FNL[@]:-}"
  else
    _main "$@"
  fi
)
##) core`
};
var LICENSES = {
  "Apache": '\n# Licensed under the Apache License, Version 2.0 (the "License");\n# you may not use this file except in compliance with the License.\n# You may obtain a copy of the License at\n# \n#      http://www.apache.org/licenses/LICENSE-2.0\n# \n# Unless required by applicable law or agreed to in writing, software\n# distributed under the License is distributed on an "AS IS" BASIS,\n# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n# See the License for the specific language governing permissions and\n# limitations under the License.',
  "GPL": "\n# This program is free software: you can redistribute it and/or modify\n# it under the terms of the GNU General Public License as published by\n# the Free Software Foundation, either version 3 of the License, or\n# (at your option) any later version.\n# \n# This program is distributed in the hope that it will be useful,\n# but WITHOUT ANY WARRANTY; without even the implied warranty of\n# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n# GNU General Public License for more details.\n# \n# You should have received a copy of the GNU General Public License\n# along with this program.  If not, see <https://www.gnu.org/licenses/>.",
  "MIT": '\n# Copyright (c) {{year}} {{author}}\n#\n# Permission is hereby granted, free of charge, to any person obtaining a copy\n# of this software and associated documentation files (the "Software"), to deal\n# in the Software without restriction, including without limitation the rights\n# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n# copies of the Software, and to permit persons to whom the Software is\n# furnished to do so, subject to the following conditions:\n#\n# The above copyright notice and this permission notice shall be included in all\n# copies or substantial portions of the Software.\n#\n# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n# SOFTWARE.'
};

// src/index.js
var SHEBANG = "#!/usr/bin/env bash";
var SECTIONS = ["header", "configuration", "metadata", "globals", "helpers", "app", "core"];
var NAME = "zap-sh";
var PROJECT_RE = /^[a-zA-Z0-9_-]+$/;
var VARNAME_RE = /^[a-zA-Z_][a-zA-Z0-9_]*$/;
function substitute(content, pairs) {
  let result = content;
  for (const [key, value] of pairs) {
    result = result.split(`{{${key}}}`).join(value);
  }
  return result;
}
function extractSection(templateText, name) {
  const lines = templateText.split("\n");
  const open = `##( ${name}`;
  const close = `##) ${name}`;
  let start = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i] === open) {
      start = i;
      break;
    }
  }
  if (start === -1) return null;
  for (let i = start; i < lines.length; i++) {
    if (lines[i] === close) return lines.slice(start, i + 1).join("\n");
  }
  return null;
}
function listLicenses() {
  return Object.keys(LICENSES).map((n) => n.toLowerCase()).sort();
}
function listTemplates() {
  return Object.keys(TEMPLATES);
}
function resolveLicenseName(code) {
  const lower = String(code).toLowerCase();
  for (const name of Object.keys(LICENSES)) {
    if (name.toLowerCase() === lower) return name;
  }
  return null;
}
function hasVar(pairs, key) {
  return pairs.some(([k]) => k === key);
}
function generate(opts = {}) {
  const { template, project, variables = {}, license, year, output } = opts;
  if (!template || !Object.prototype.hasOwnProperty.call(TEMPLATES, template)) {
    throw new Error(`invalid template: '${template}' (available: ${listTemplates().join(", ")})`);
  }
  if (typeof project !== "string" || !PROJECT_RE.test(project)) {
    throw new Error(`invalid project name: '${project}' (letters/numbers/hyphens/underscores only)`);
  }
  const noNewline = (name, v) => {
    if (v !== void 0 && v !== null && String(v).includes("\n")) {
      throw new Error(`variable value must not contain a newline: '${name}'`);
    }
  };
  noNewline("year", year);
  noNewline("license", license);
  for (const key of Object.keys(variables)) {
    if (!VARNAME_RE.test(key)) {
      throw new Error(`invalid variable name: '${key}' (must start with letter/underscore, contain only letters/numbers/underscore)`);
    }
    noNewline(key, variables[key]);
  }
  const resolvedYear = String(year !== void 0 && year !== null && year !== "" ? year : (/* @__PURE__ */ new Date()).getFullYear());
  const userVars = [];
  if (year !== void 0 && year !== null && year !== "") userVars.push(["year", resolvedYear]);
  if (license !== void 0 && license !== null && license !== "") userVars.push(["license", String(license)]);
  for (const [k, v] of Object.entries(variables)) userVars.push([k, String(v)]);
  const baseDefaults = [
    ["app", project],
    ["year", resolvedYear],
    ["detail", `Generated by ${NAME}`],
    ["description", `Generated by ${NAME} template`]
  ];
  if (!hasVar(userVars, "author")) baseDefaults.push(["author", "anonymous"]);
  if (!hasVar(userVars, "version")) baseDefaults.push(["version", "0.1.0"]);
  if (!hasVar(userVars, "email")) baseDefaults.push(["email", ""]);
  let licenseName = "MIT License";
  let licenseContent = "";
  if (license !== void 0 && license !== null && license !== "") {
    const resolved = resolveLicenseName(license);
    if (!resolved) {
      throw new Error(`license file not found: ${license} (available: ${listLicenses().join(" ")})`);
    }
    licenseName = `${resolved} License`;
    licenseContent = substitute(LICENSES[resolved], [...userVars, ...baseDefaults]);
  }
  const fullDefaults = [...baseDefaults, ["license_name", licenseName]];
  if (licenseContent !== "") fullDefaults.push(["license_content", licenseContent]);
  const allVars = [...userVars, ...fullDefaults];
  const templateText = TEMPLATES[template];
  let content = SHEBANG + "\n";
  for (const section of SECTIONS) {
    const sectionText = extractSection(templateText, section);
    if (sectionText !== null && sectionText !== "") {
      content += substitute(sectionText, allVars) + "\n";
    }
  }
  const filename = output || `${project}.sh`;
  return { filename, content };
}
var index_default = { generate, substitute, extractSection, listTemplates, listLicenses };
export {
  index_default as default,
  extractSection,
  generate,
  listLicenses,
  listTemplates,
  substitute
};
