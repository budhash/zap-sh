#!/usr/bin/env bash
##( header
# --------------------------------------------------------------------
# create-release - Generic release archive creator
# 
# Usage: ./create-release.sh [OPTIONS] <version>
# --------------------------------------------------------------------
# AUTHOR: Copyright (C) 2025 Budha <budhash@gmail.com>
# VERSION: 1.0.0
# LICENSE: MIT
# --------------------------------------------------------------------
##) header

##( configuration
set -eEuo pipefail; IFS=$'\n\t'  # fail fast, secure IFS
##) configuration

##( metadata
readonly __ID="basic-1.0.0"
readonly __APP="$(basename "${BASH_SOURCE[0]:-}")"
readonly __APPFILE="${BASH_SOURCE[0]}"
readonly __APPDIR="$(s="${BASH_SOURCE[0]}"; while [[ -h "$s" ]]; do 
  d="$(cd -P "$(dirname "$s")" && pwd)"; s="$(readlink "$s")"; [[ "$s" != /* ]] && s="$d/$s"; done; cd -P "$(dirname "$s")" && pwd)"
__DBG=${DEBUG:-false}
##) metadata

##( globals

##[ colors
_RST=$'\033[0m' _GRN=$'\033[0;32m' _YLW=$'\033[0;33m' _RED=$'\033[0;31m' _BLU=$'\033[0;34m'
[[ -n "${NO_COLOR:-}" || ! -t 1 ]] && _RST='' _GRN='' _YLW='' _RED='' _BLU=''
##] colors

##[ error
# general failure / bad usage / dependency not found / unsupported OS / not found / permission error / not connected
readonly _E=1 _E_USG=2 _E_DEP=3 _E_OS=4 _E_NF=5 _E_NP=6 _E_NC=7  
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
readonly __NAME=create-release
readonly __OS=(mac linux)
readonly __APP_DEPS=(find sed grep zip unzip)
readonly PROJECT_ROOT="$(dirname "$(dirname "$__APPDIR")")"
##] config

##[ constants
##] constants

##[ functions
_main() {
  # Simple getopts-based argument parsing
  local _opt _help=false _version=false _project="" _output_dir=""
  while getopts "hvp:d:" _opt; do
    case $_opt in
      h) _help=true;;
      v) _version=true;;
      p) _project="$OPTARG";;
      d) _output_dir="$OPTARG";;
      \?) u.error "unknown option: -${OPTARG:-}"; exit $_E_USG;;
    esac
  done
  shift $((OPTIND-1))

  [[ "$_help" == true ]] && { _help; exit 0; }
  [[ "$_version" == true ]] && { _version; exit 0; }
  
  local VERSION="${1:-}"
  local PROJECT_NAME="${_project:-$(basename "$PROJECT_ROOT")}"
  local OUTPUT_DIR="${_output_dir:-$PROJECT_ROOT}"
  
  # Validate version
  [[ -n "$VERSION" ]] || u.die "Version required. Usage: $__APP <version>"
  [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || u.die "Invalid version format. Expected: v1.0.0"
  
  # Validate/create output directory
  if [[ -n "$_output_dir" ]]; then
    if [[ ! -d "$OUTPUT_DIR" ]]; then
      mkdir -p "$OUTPUT_DIR" || u.die "Cannot create output directory: $OUTPUT_DIR"
    fi
    if [[ ! -w "$OUTPUT_DIR" ]]; then
      u.die "Output directory not writable: $OUTPUT_DIR"
    fi
    OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"  # Get absolute path
  fi
  
  u.info "Creating release for $PROJECT_NAME version: $VERSION"
  [[ "$OUTPUT_DIR" != "$PROJECT_ROOT" ]] && u.info "Output directory: $OUTPUT_DIR"
  
  cd "$PROJECT_ROOT"
  _create_release_archive "$VERSION" "$PROJECT_NAME" "$OUTPUT_DIR"
  _show_summary "$VERSION" "$PROJECT_NAME" "$OUTPUT_DIR"
}

_read_package() {
    local release_dir="$1"
    local package_file="$PROJECT_ROOT/package.txt"
    
    [[ -f "$package_file" ]] || u.die "package.txt not found in project root"
    
    u.info "Reading package.txt for files and directories to include"
    
    local line_num=0
    # Ensure file ends with newline to avoid missing last line
    while IFS=':' read -r item_type item_path || [[ -n "$item_type" ]]; do
        line_num=$((line_num + 1))
        
        # Skip comments and empty lines
        [[ "$item_type" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$item_type" || -z "$item_path" ]] && continue
        
        # Validate format
        if [[ ! "$item_type:$item_path" =~ ^[^:]+:.+ ]]; then
            u.warn "Line $line_num: Invalid format, expected 'type:path'"
            continue
        fi
        
        case "$item_type" in
            file)
                local source_file="$PROJECT_ROOT/$item_path"
                local target_file="$release_dir/$item_path"
                
                if [[ -f "$source_file" ]]; then
                    mkdir -p "$(dirname "$target_file")"
                    cp "$source_file" "$target_file"
                    u.debug "Added file: $item_path"
                else
                    u.warn "File not found: $item_path (line $line_num)"
                fi
                ;;
            dir)
                local source_dir="$PROJECT_ROOT/$item_path"
                local target_dir="$release_dir/$item_path"
                
                if [[ -d "$source_dir" ]]; then
                    mkdir -p "$(dirname "$target_dir")"
                    cp -r "$source_dir" "$target_dir"
                    u.debug "Added directory: $item_path"
                else
                    u.warn "Directory not found: $item_path (line $line_num)"
                fi
                ;;
            *)
                u.warn "Line $line_num: Unknown package type '$item_type' (valid: file, dir)"
                ;;
        esac
    done < "$package_file"
    
    u.info "Package processing completed"
}

_extract_changelog() {
    local version="$1"
    local project_name="$2" 
    local changelog_file="$3"
    local version_number="${version#v}"
    
    u.info "Extracting changelog for version $version_number"
    
    # Check for CHANGELOG.md first, then README.md
    local source_file=""
    if [[ -f "$PROJECT_ROOT/CHANGELOG.md" ]]; then
        source_file="$PROJECT_ROOT/CHANGELOG.md"
        u.debug "Using CHANGELOG.md for release notes"
    elif [[ -f "$PROJECT_ROOT/README.md" ]]; then
        source_file="$PROJECT_ROOT/README.md"
        u.debug "Using README.md for release notes"
    else
        u.warn "No CHANGELOG.md or README.md found, creating basic release notes"
        cat > "$changelog_file" << EOF
## $project_name $version

Release $version of $project_name.
EOF
        return 0
    fi
    
    # Extract changelog section
    local extracted=false
    for pattern in "### $version" "### v$version_number" "## $version" "## v$version_number"; do
        if grep -q "$pattern" "$source_file"; then
            # Extract from this version to next ### or ## or end of file
            sed -n "/$pattern/,/^## /p" "$source_file" | sed '$d' > "$changelog_file"
            # If file is empty (no next section), extract to end
            if [[ ! -s "$changelog_file" ]]; then
                sed -n "/$pattern/,\$p" "$source_file" > "$changelog_file"
            fi
            extracted=true
            break
        fi
    done
    
    # Fallback if no matching section found
    if [[ "$extracted" == false ]]; then
        cat > "$changelog_file" << EOF
## $project_name $version

See $(basename "$source_file") for details.
EOF
    fi
    
    u.info "Changelog extracted to: $changelog_file"
}

_create_release_archive() {
    local version="$1"
    local project_name="$2"
    local output_dir="$3"
    local version_number="${version#v}"
    local release_name="${project_name}-${version_number}"
    local release_dir="$PROJECT_ROOT/$release_name"
    local archive_file="$output_dir/${release_name}.zip"
    
    # Clean up any existing release directory and archive
    [[ -d "$release_dir" ]] && rm -rf "$release_dir"
    [[ -f "$archive_file" ]] && rm -f "$archive_file"
    
    u.info "Creating release directory: $release_name"
    mkdir -p "$release_dir"
    
    # Copy all files and directories from package.txt
    _read_package "$release_dir"
    
    # Create release notes
    _extract_changelog "$version" "$project_name" "$release_dir/RELEASE_NOTES.md"
    
    # Create archive in specified output directory
    u.info "Creating archive: ${release_name}.zip"
    (cd "$PROJECT_ROOT" && zip -r "$archive_file" "$release_name/" >/dev/null)
    
    # Verify archive
    if [[ -f "$archive_file" ]]; then
        local file_count
        file_count=$(unzip -l "$archive_file" | grep -c "${project_name}-" || echo "0")
        u.info "Archive created successfully with $file_count files"
        u.info "Archive location: $archive_file"
        
        # Show contents (compact format)
        u.info "Archive contents:"
        unzip -l "$archive_file" | grep "${project_name}-" | awk '{print "  " $4}' | head -20
        local total_files=$(unzip -l "$archive_file" | grep "${project_name}-" | wc -l)
        [[ $total_files -gt 20 ]] && echo "  ... and $((total_files - 20)) more files"
    else
        u.die "Failed to create archive"
    fi
    
    # Clean up temp directory but keep archive
    rm -rf "$release_dir"
    
    u.info "Release archive ready: ${release_name}.zip"
}

_show_summary() {
    local version="$1"
    local project_name="$2"
    local output_dir="$3"
    local version_number="${version#v}"
    
    echo
    u.info "Release Summary"
    echo "  Project: $project_name"
    echo "  Version: $version"
    echo "  Archive: ${project_name}-${version_number}.zip"
    echo "  Location: $output_dir"
    echo "  Release Notes: RELEASE_NOTES.md (included in archive)"
    echo
    u.info "Next steps:"
    echo "  1. Review the archive contents"
    echo "  2. Test the release locally"  
    echo "  3. Create and push git tag: git tag $version && git push origin $version"
    echo "  4. GitHub Actions will automatically create the release"
}

_help() {
  cat << EOF
$(_version) - Generic release archive creator

USAGE:
    $__APP [OPTIONS] <version>

ARGUMENTS:
    version         Version to release (e.g., v1.0.0)

OPTIONS:
    -h              Show this help
    -v              Show version  
    -p PROJECT      Project name (default: directory name)
    -d DIRECTORY    Output directory for archive (default: project root)

EXAMPLES:
    $__APP v1.0.0
    $__APP -p my-tool v1.2.3
    $__APP -d /tmp/releases v1.0.0
    $__APP -p my-tool -d ~/Desktop v2.1.0

REQUIREMENTS:
    - package.txt file in project root defining files/directories to include
    - CHANGELOG.md or README.md with changelog section

PACKAGE.TXT FORMAT:
    # Lines starting with # are comments
    # Format: type:relative/path
    
    file:binary-name          # Include individual file
    file:README.md            # Include documentation
    file:LICENSE              # Include license file
    file:version.txt          # Include version file
    dir:templates             # Include entire directory
    
    # Types: 
    #   file - copies individual file
    #   dir  - copies entire directory recursively

CHANGELOG DETECTION:
    1. Looks for CHANGELOG.md first
    2. Falls back to README.md  
    3. Searches for patterns: ### v1.0.0, ## v1.0.0, ### 1.0.0, ## 1.0.0
    4. Creates basic notes if no section found

NOTES:
    - Script must be run from project containing package.txt
    - Output directory will be created if it doesn't exist
    - Release directory is temporary and cleaned up after archive creation
    - Archive path in output uses absolute paths for clarity

EOF
}

_version() { 
  sed -n 's/^# VERSION:[[:space:]]*\(.*\)/\1/p' "$__APPFILE" 2>/dev/null || echo "unknown"
}

_cleanup() { 
  u.debug "cleanup"
}
##] functions

##) app

##( core
_boot() {
  printf '%s\n' "${__OS[@]}" | grep -Fxq "$(u.os)" || u.die "unsupported OS: $(u.os) [required: ${__OS[*]}]"
  local _tool; for _tool in "${__APP_DEPS[@]:-}"; do u.require "$_tool"; done
}

trap _cleanup EXIT
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  _boot
  _main "$@"
fi
##) core