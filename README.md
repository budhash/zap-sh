# zap-sh

<div align="center">
  <img src="logo.png" alt="zap-sh logo" width="200" height="200">
  <br>
  <strong>Lightning-fast bash script generator</strong>
</div>

<div align="center">

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/budhash/zap-sh)
[![CI](https://github.com/budhash/zap-sh/workflows/CI/badge.svg)](https://github.com/budhash/zap-sh/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash 4.0+](https://img.shields.io/badge/bash-4.0+-blue.svg)](https://www.gnu.org/software/bash/)
[![Language](https://img.shields.io/github/languages/top/budhash/zap-sh)](https://github.com/budhash/zap-sh)
[![Issues](https://img.shields.io/github/issues/budhash/zap-sh)](https://github.com/budhash/zap-sh/issues)

</div>

A bash script template generator for creating maintainable shell scripts.

**Status**: Initial release. Core functionality is stable.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [How It Works](#how-it-works)
- [Usage](#usage)
- [Development](#development)
- [Requirements](#requirements)
- [Environment Variables](#environment-variables)
- [Workflow Examples](#workflow-examples)
- [FAQ](#faq)
- [Support](#support)
- [License](#license)
- [Changelog](#changelog)

## Overview

### What is zap-sh?

zap-sh generates bash scripts from templates, similar to how cookiecutter works for other languages. Instead of starting from scratch or copying boilerplate, you get a structured script with proper error handling, logging, and cross-platform utilities.

**The key idea**: Your code lives in a protected section (`##( app`) while the framework can be updated independently. This means you can improve your scripts' infrastructure without touching your business logic.

### Key Features

- Self-contained scripts with no runtime dependencies
- Interactive setup wizard for new projects
- Built-in license templates (MIT, Apache, GPL)
- Your code stays safe during framework updates
- Works on Linux (macOS coming soon)
- Automatic updates from GitHub

## Quick Start

```bash
# Install zap-sh
curl -Lo ~/.local/bin/zap-sh https://raw.githubusercontent.com/budhash/zap-sh/main/zap-sh
chmod +x ~/.local/bin/zap-sh

# Create your first script (recommended)
zap-sh init -w

# Or quick generation
zap-sh init my-script --author="Your Name" --email="you@example.com" --license="mit"

# Start coding in the ##( app section
./my-script.sh --help
```

## Installation

```bash
# User installation (recommended)
curl -Lo ~/.local/bin/zap-sh https://raw.githubusercontent.com/budhash/zap-sh/main/zap-sh
chmod +x ~/.local/bin/zap-sh

# System-wide installation
sudo curl -Lo /usr/local/bin/zap-sh https://raw.githubusercontent.com/budhash/zap-sh/main/zap-sh
sudo chmod +x /usr/local/bin/zap-sh

# Verify installation
zap-sh --version
zap-sh --help
```

## How It Works

### Templates

**Basic Template** - Essential utilities for simple scripts (~200 lines)
- Cross-platform compatibility
- Structured logging
- Basic argument parsing
- Error handling
- [View basic.sh template →](https://github.com/budhash/zap-sh/blob/main/templates/basic.sh)

**Enhanced Template** - Rich utilities for complex tools (~400+ lines)  
- All basic features plus 60+ utility functions
- JSON processing, HTTP helpers
- Advanced argument parsing
- Array and string operations
- [View enhanced.sh template →](https://github.com/budhash/zap-sh/blob/main/templates/enhanced.sh)

#### Template Structure

Generated scripts follow a section-based organization:

```bash
#!/usr/bin/env bash
##( header          # Script metadata, license, description
##( configuration   # Bash safety settings (set -eEuo pipefail)
##( metadata        # Internal script variables and constants
##( globals         # Colors, error codes, global constants
##( helpers         # Utility functions (u.* namespace)
##( app             # YOUR CODE GOES HERE - preserved during updates
  ##[ config        # Your configuration and constants
  ##[ functions     # Your business logic functions
    _main()         # Your main entry point
##) app
##( core            # Framework bootstrap and initialization
```

#### Section Markers

The section system enables safe updates:
- `##( section` / `##) section` - Major sections
- `##[ subsection` / `##] subsection` - Subsections within major sections
- **Your code** goes in the `##( app` section and is preserved during updates
- **Framework code** in other sections gets updated automatically

### The Protected App Section

When you generate a script, your business logic goes in the `##( app` section:

```bash
##( app
# YOUR CODE GOES HERE - this section is never touched by updates

_main() {
  # Your application logic
  u.info "Hello from my app!"
}
##) app
```

Everything else (error handling, utilities, configuration) can be updated to newer versions while your code stays untouched.

## Usage

### Command Overview

```bash
zap-sh init <project>        # Generate new script from template
zap-sh init -w               # Interactive guided setup (recommended)
zap-sh update -f <script>    # Update framework sections (preserves your code)
zap-sh snip -f <script>      # Extract sections for reuse
zap-sh upgrade               # Update zap-sh binary and templates
```

### Script Generation (`init`)

Generate new bash scripts from templates with customizable metadata.

#### Interactive Wizard (Recommended)
```bash
# Guided setup with prompts for all options
zap-sh init -w

# Example wizard flow:
# >> Template (basic / enhanced [basic]): enhanced
# >> Project name: api-client
# >> Output file (api-client.sh): tools/api-client.sh
# >> Author (anonymous): Jane Doe
# >> Email (optional): jane@company.com
# >> Brief description (Generated by zap-sh): API client for external services
# >> Long description (...): Comprehensive API client with retry logic and authentication
# >> License (mit / apache / gpl [mit]): apache
```

#### Command Line Generation
```bash
# Minimal script (uses defaults)
zap-sh init my-tool

# With custom output path
zap-sh init backup-tool -o scripts/backup.sh

# Complete metadata
zap-sh init api-client \
  -o tools/api.sh \
  --author="John Smith" \
  --email="john@company.com" \
  --license="apache"
```

#### Template Selection
```bash
# Use basic template (default - minimal, fast)
zap-sh init simple-tool -t basic

# Use enhanced template (comprehensive utilities)
zap-sh init complex-tool -t enhanced -o bin/tool.sh

# With license selection
zap-sh init production-tool \
  -t enhanced \
  --author="DevOps Team" \
  --license="mit"
```

#### Advanced Options
```bash
# Custom version and details
zap-sh init deploy-script \
  --author="SRE Team" \
  --version="3.1.0" \
  --detail="Deployment automation script" \
  --description="Handles blue-green deployments with rollback support"

# Custom template directory
ZAP_HOME=/path/to/templates zap-sh init custom-tool
```

### Script Updates (`update`)

Update framework sections of existing scripts while preserving your app code. The **header** and **app** sections remain untouched, while all other sections (configuration, metadata, globals, helpers, core) get updated to the latest template.

#### Basic Updates
```bash
# Update script sections (preserves ##( app section)
zap-sh update -f my-script.sh

# Force specific template
zap-sh update -f my-script.sh -t basic

# Update with template detection
zap-sh update -f auto-detect.sh  # Detects original template
```

#### Update Examples
```bash
# Update an old script to latest framework
zap-sh update -f legacy-tool.sh

# Update but force different template (with warning)
zap-sh update -f basic-script.sh -t enhanced

# Skip confirmation prompts
zap-sh update -f my-script.sh -y
```

**Note**: Updates preserve your code in the `##( app` section and script metadata in the `##( header` section while refreshing all framework sections with the latest template improvements.

### Section Extraction (`snip`)

Templates are organized into logical sections, with the expectation that your business logic lives in the `##( app` section. The main purpose of snip is to extract the app section from a script for reuse or analysis.

#### Basic Extraction
```bash
# Extract app section to console (most common use)
zap-sh snip -f my-script.sh

# Extract specific section
zap-sh snip -f my-script.sh -s helpers

# Extract to file
zap-sh snip -f my-script.sh -s app -o reusable-logic.sh
```

#### Advanced Extraction
```bash
# Extract different sections
zap-sh snip -f my-script.sh -s header -o script-header.txt
zap-sh snip -f my-script.sh -s globals -o script-globals.txt
```

### Self-Updating (`upgrade`)

Keep zap-sh and templates current with the latest version.

```bash
# Check for updates and upgrade
zap-sh upgrade

# Force upgrade regardless of version
zap-sh upgrade --force

# Debug output
DEBUG=true zap-sh upgrade
```

## Development

### Template Storage

Templates are stored in:
1. `ZAP_HOME` (if set)
2. `~/.config/zap-sh/` (default)

Structure:
```
~/.config/zap-sh/
├── templates/
│   ├── basic.sh           # Minimal template
│   ├── enhanced.sh        # Full-featured template
│   └── licenses/          # License templates
│       ├── MIT.txt
│       ├── Apache.txt
│       └── GPL.txt
```

### Remote Configuration

```bash
# Use different repository
ZAP_REMOTE=https://raw.githubusercontent.com/your-org/zap-templates/main zap-sh upgrade

# Custom template directory
ZAP_HOME=/path/to/templates zap-sh init project
```

### Local Template Development

```bash
# Enable development mode (uses local templates/ directory)
ZAP_DEV=true zap-sh init test-project

# Directory structure for development
zap-sh/
├── zap-sh              # Binary
├── templates/
│   ├── basic.sh
│   ├── enhanced.sh
│   └── licenses/
│       ├── MIT.txt
│       └── Apache.txt
```

### Repository Structure

```
zap-sh/
├── zap-sh                 # Main binary (self-contained generator)
├── templates/
│   ├── basic.sh          # Minimal template
│   ├── enhanced.sh       # Full-featured template
│   └── licenses/         # License templates
├── version.txt           # Current version for updates
├── manifest.txt          # File manifest for downloads
├── test-*.sh            # Test suites
├── .common/             # Test framework
├── .github/
│   ├── workflows/       # CI and release automation
│   └── scripts/         # Release automation scripts
├── Makefile             # Development automation
└── README.md
```

### Release Process

Creating a new release is straightforward with the automated workflow:

```bash
# 1. Prepare release (runs CI + updates version files)
make bump-version VERSION=1.0.0

# 2. Review and commit changes
git diff                    # Review what changed
git add zap-sh version.txt
git commit -m "Bump version to 1.0.0"

# 3. Tag and push (triggers automatic release)
git tag v1.0.0
git push origin main v1.0.0
```

**What happens automatically**:
- GitHub Actions runs full CI validation
- Release archive (`zap-sh-1.0.0.zip`) is created from `manifest.txt`
- GitHub Release is published with changelog from README
- Release assets are uploaded and ready for download

**Development commands**:
```bash
make ci                     # Run full CI pipeline locally
make bump-version VERSION=1.0.0  # Update version files
make create-archive VERSION=1.0.0  # Test release creation
make version                # Show all component versions
```

### Testing

```bash
# Test basic functionality
zap-sh init test-basic -t basic
./test-basic.sh --help

# Test enhanced template
zap-sh init test-enhanced -t enhanced
./test-enhanced.sh --version

# Test wizard mode
zap-sh init -w

# Test development mode
ZAP_DEV=true zap-sh init dev-test
```

## Requirements

- **bash**  4+ (Linux) - (3.2 coming soon)
- **curl** (for template downloads and updates)
- **Standard Unix tools**: `sed`, `grep`, `find`

## Environment Variables

```bash
ZAP_DEV=true           # Enable development mode (use local templates)
ZAP_HOME=/path         # Custom template directory location  
ZAP_REMOTE=https://... # Custom remote repository for templates
DEBUG=true             # Enable debug logging
```

## Workflow Examples

### Typical Development Workflow

```bash
# 1. Generate script with wizard
zap-sh init -w
# Choose template, set project name, output path, author, license

# 2. Develop your logic in ##( app section
vim scripts/deploy.sh

# 3. Update framework when needed (preserves your ##( app code)
zap-sh update -f scripts/deploy.sh

# 4. Extract reusable components
zap-sh snip -f scripts/deploy.sh -s app -o shared/deploy-logic.sh
```

### Command Line Workflow

```bash
# Quick generation with specific options
zap-sh init deploy-tool -t enhanced -o scripts/deploy.sh \
  --author="DevOps Team" --license="apache"

# Your business logic goes here
# Edit the ##( app section in scripts/deploy.sh

# Keep framework updated
zap-sh update -f scripts/deploy.sh
```

## FAQ

**Q: How is this different from other script generators?**  
A: zap-sh focuses on updateable templates with section-based organization. Your code stays protected in the `##( app` section while framework sections can be updated independently.

**Q: Can I modify the generated script?**  
A: Yes! It's your script. Keep custom code in the `##( app` section to preserve it during updates.

**Q: What's the difference between basic and enhanced templates?**  
A: Basic (~200 lines) provides essential utilities for simple scripts. Enhanced (~400+ lines) includes 60+ utility functions for complex tools, JSON processing, and HTTP utilities.

**Q: Is bash 3.2 supported?**  
A: 3.2  will be supported soon. Note: macOS ships with bash 3.2 due to licensing. Supporting it ensures scripts work everywhere without requiring users to upgrade bash.

**Q: How do updates work?**  
A: `zap-sh upgrade` downloads the latest binary and templates. `zap-sh update -f script.sh` updates framework sections while preserving your app code.

**Q: Can I use my own templates?**  
A: Not yet.

**Q: What happens if GitHub is down?**  
A: zap-sh uses cached templates from `~/.config/zap-sh/`. First download requires internet, subsequent use is offline-capable.

## Support

- **Issues**: [GitHub Issues](https://github.com/budhash/zap-sh/issues)
- **Documentation**: This README and built-in help (`zap-sh --help`)

## License

MIT License. See [LICENSE](LICENSE) file for details.

Generated scripts inherit their license from the template used (configurable via `--license` option or wizard).

## Changelog

### v1.0.0 - Initial Release

#### Features
- Script generation with `zap-sh init` command
- Interactive wizard mode with `zap-sh init -w`
- Framework updates with `zap-sh update` (preserves user code)
- Section extraction with `zap-sh snip`
- Self-updating with `zap-sh upgrade`
- Built-in license support (MIT, Apache, GPL)

#### Templates
- **Basic Template**: Essential utilities for simple scripts (~200 lines)
- **Enhanced Template**: Comprehensive utilities with 60+ functions (~400+ lines)

#### Compatibility
- No runtime dependencies for generated scripts