# Makefile for zap-sh
# Lightning-fast bash script generator

.PHONY: help test lint ci clean sync-version bump-version bump-major bump-minor bump-patch bump-pre create-archive update-deps update-scripts check-tools check-network validate-version all
.DEFAULT_GOAL := help

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m

# Project info
PROJECT := zap-sh

## Show this help message
help:
	@echo "$(GREEN)$(PROJECT)$(NC)"
	@echo "Lightning-fast bash script generator"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@awk '/^##/ { \
		help_text = substr($$0, 4); \
		getline; \
		if ($$1 ~ /:/) { \
			target = $$1; \
			gsub(/:/, "", target); \
			printf "  $(GREEN)%-18s$(NC) %s\n", target, help_text \
		} \
	}' $(MAKEFILE_LIST) | head -25
	@echo ""
	@echo "$(YELLOW)Version management:$(NC)"
	@echo "  $(GREEN)bump-patch$(NC)         Auto-increment patch (1.0.0 -> 1.0.1)"
	@echo "  $(GREEN)bump-minor$(NC)         Auto-increment minor (1.0.0 -> 1.1.0)"
	@echo "  $(GREEN)bump-major$(NC)         Auto-increment major (1.0.0 -> 2.0.0)"
	@echo "  $(GREEN)bump-pre$(NC)           Add pre-release (make bump-pre PRERELEASE=alpha.1)"
	@echo "  $(GREEN)sync-version$(NC)       Sync all files from version.txt"
	@echo "  $(GREEN)update-deps$(NC)        Download latest ver-kit and sem-ver tools"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make test              # Run all test suites"
	@echo "  make lint              # Run shellcheck linting" 
	@echo "  make ci                # Simulate full CI pipeline"
	@echo "  make update-deps       # Download dependency tools"
	@echo "  make bump-patch        # Auto-increment patch version"
	@echo "  make bump-version VERSION=1.0.0    # Manual version update"

## Download and update dependency scripts (ver-kit, sem-ver)
update-deps: update-scripts

## Check network connectivity for downloads
check-network:
	@echo "$(YELLOW)Checking network connectivity...$(NC)"
	@if ! curl -s --max-time 5 https://raw.githubusercontent.com >/dev/null 2>&1; then \
		echo "$(RED)❌ Cannot reach GitHub - check network connection$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Network connectivity verified$(NC)"

update-scripts: check-network
	@echo "$(YELLOW)Updating dependency scripts...$(NC)"
	@mkdir -p .github/scripts
	@echo "$(BLUE)Downloading sem-ver...$(NC)"
	@curl -sSL https://raw.githubusercontent.com/budhash/shed/refs/heads/main/sem-ver/sem-ver -o .github/scripts/sem-ver
	@echo "$(BLUE)Downloading ver-kit...$(NC)"
	@curl -sSL https://raw.githubusercontent.com/budhash/shed/refs/heads/main/ver-kit/ver-kit -o .github/scripts/ver-kit
	@chmod +x .github/scripts/sem-ver .github/scripts/ver-kit
	@echo "$(GREEN)✅ Dependency scripts updated$(NC)"
	@echo "$(BLUE)Tools available:$(NC)"
	@echo "  sem-ver: $$(cd .github/scripts && ./sem-ver -v 2>/dev/null || echo 'unknown')"
	@echo "  ver-kit: $$(cd .github/scripts && ./ver-kit -v 2>/dev/null || echo 'unknown')"

## Run all test suites using unified test driver
test:
	@echo "$(YELLOW)Running all test suites...$(NC)"
	@if [ -f test/.common/test-driver ]; then \
		chmod +x test/.common/test-driver && ./test/.common/test-driver; \
	else \
		echo "$(RED)❌ test/.common/test-driver not found$(NC)"; \
		echo "$(YELLOW)Please ensure test framework is set up$(NC)"; \
		exit 1; \
	fi

## Run tests with system Bash (3.2 on macOS)
test-bash3:
	@echo "$(YELLOW)Running tests with system Bash (/bin/bash)...$(NC)"
	@echo "$(BLUE)Bash version: $$(/bin/bash --version | head -1)$(NC)"
	@if [ -f test/.common/test-driver ]; then \
		chmod +x test/.common/test-driver && /bin/bash test/.common/test-driver; \
	else \
		echo "$(RED)❌ test/.common/test-driver not found$(NC)"; \
		exit 1; \
	fi

## Run tests with both system and modern Bash
test-all: test
	@echo "$(GREEN)✅ All Bash version tests completed$(NC)"

## Run shellcheck linting on all scripts
lint: lint-main lint-tests
	@echo "$(GREEN)✅ All linting completed$(NC)"

lint-main:
	@echo "$(YELLOW)Linting main scripts...$(NC)"
	@if command -v shellcheck >/dev/null; then \
		shellcheck zap-sh templates/enhanced.sh templates/basic.sh; \
		echo "$(GREEN)✅ Main scripts pass shellcheck$(NC)"; \
	else \
		echo "$(RED)❌ shellcheck not found - install with: brew install shellcheck$(NC)"; exit 1; \
	fi

lint-tests:
	@echo "$(YELLOW)Linting test framework...$(NC)"
	@if command -v shellcheck >/dev/null; then \
		if [ -f test/.common/test-driver ]; then shellcheck test/.common/test-driver; fi; \
		if [ -f test/.common/test-common ]; then shellcheck test/.common/test-common; fi; \
		echo "$(GREEN)✅ Test framework passes shellcheck$(NC)"; \
	else \
		echo "$(RED)❌ shellcheck not found$(NC)"; exit 1; \
	fi

## Simulate full CI pipeline (deps + lint + test + version)
ci: check-deps lint test version
	@echo ""
	@echo "$(GREEN)🎉 Local CI simulation completed successfully!$(NC)"
	@echo ""
	@echo "  ✅ Deps job: validate project structure"
	@echo "  ✅ Lint job: shellcheck on all scripts"
	@echo "  ✅ Test job: run test suites" 
	@echo "  ✅ Version job: display current versions"

## Check required dependencies
check-deps:
	@echo "$(YELLOW)Checking dependencies...$(NC)"
	@if command -v shellcheck >/dev/null; then \
		echo "$(GREEN)✅ shellcheck available$(NC)"; \
	else \
		echo "$(RED)❌ shellcheck not found$(NC)"; \
		echo "Install with: brew install shellcheck (macOS) or apt install shellcheck (Ubuntu)"; \
		exit 1; \
	fi
	@if [ -f zap-sh ] && [ -x zap-sh ]; then \
		echo "$(GREEN)✅ zap-sh executable$(NC)"; \
	else \
		echo "$(RED)❌ zap-sh not found or not executable$(NC)"; exit 1; \
	fi
	@if [ -f templates/enhanced.sh ] && [ -f templates/basic.sh ]; then \
		echo "$(GREEN)✅ templates available$(NC)"; \
	else \
		echo "$(RED)❌ template files not found$(NC)"; exit 1; \
	fi
	@if [ -f test/.common/test-driver ]; then \
		echo "$(GREEN)✅ test framework available$(NC)"; \
	else \
		echo "$(RED)❌ test framework not found$(NC)"; exit 1; \
	fi

## Check if dependency tools are available
check-tools:
	@if [ ! -f .github/scripts/sem-ver ] || [ ! -f .github/scripts/ver-kit ]; then \
		echo "$(RED)❌ Dependency tools missing$(NC)"; \
		echo "$(YELLOW)Run 'make update-deps' to download required tools$(NC)"; \
		exit 1; \
	fi
	@if [ ! -x .github/scripts/sem-ver ] || [ ! -x .github/scripts/ver-kit ]; then \
		echo "$(RED)❌ Dependency tools not executable$(NC)"; \
		chmod +x .github/scripts/sem-ver .github/scripts/ver-kit; \
		echo "$(GREEN)✅ Fixed permissions$(NC)"; \
	fi

## Validate current version exists and is readable  
validate-version: check-tools
	@CURRENT="$$(./.github/scripts/ver-kit get -f version.txt 2>/dev/null)"; \
	if [ -z "$$CURRENT" ]; then \
		echo "$(RED)❌ Could not extract current version from version.txt$(NC)"; \
		echo "$(YELLOW)Create version.txt with: echo '1.0.0' > version.txt$(NC)"; \
		exit 1; \
	fi

## Clean up log and backup files
clean:
	@echo "$(YELLOW)Cleaning up artifacts...$(NC)"
	@find . -name "*.log" -type f -delete 2>/dev/null || true
	@find . -name "*.bak" -type f -delete 2>/dev/null || true
	@find . -name ".DS_Store" -type f -delete 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup completed$(NC)"

## Sync all project files from version.txt (source of truth)
sync-version: check-tools
	@echo "$(YELLOW)Syncing version files from version.txt...$(NC)"
	@VERSION="$$(./.github/scripts/ver-kit get -f version.txt 2>/dev/null)"; \
	if [ -n "$$VERSION" ]; then \
		echo "$(BLUE)Source version: $$VERSION$(NC)"; \
		echo "$(YELLOW)Updating zap-sh...$(NC)"; \
		./.github/scripts/ver-kit set -f zap-sh "$$VERSION" >/dev/null; \
		echo "$(GREEN)✅ All files synced to $$VERSION$(NC)"; \
	else \
		echo "$(RED)❌ Could not read version from version.txt$(NC)"; \
		echo "$(YELLOW)Create version.txt with a version like: echo '1.0.0' > version.txt$(NC)"; \
		exit 1; \
	fi

sync-templates: check-tools
	@echo "$(YELLOW)Syncing version files from version.txt...$(NC)"
	@VERSION="$$(./.github/scripts/ver-kit get -f version.txt 2>/dev/null)"; \
	if [ -n "$$VERSION" ]; then \
		echo "$(BLUE)Source version: $$VERSION$(NC)"; \
		echo "$(YELLOW)Updating basic template...$(NC)"; \
		sed -i.bak "s/^#[[:space:]]*__ID__:[[:space:]]*.*/# __ID__: basic-$$VERSION/" templates/basic.sh && rm -f templates/basic.sh.bak; \
		echo "$(YELLOW)Updating enhanced template...$(NC)"; \
		sed -i.bak "s/^#[[:space:]]*__ID__:[[:space:]]*.*/# __ID__: enhanced-$$VERSION/" templates/enhanced.sh && rm -f templates/enhanced.sh.bak; \
		echo "$(GREEN)✅ All templates synced to $$VERSION$(NC)"; \
	else \
		echo "$(RED)❌ Could not read version from version.txt$(NC)"; \
		echo "$(YELLOW)Create version.txt with a version like: echo '1.0.0' > version.txt$(NC)"; \
		exit 1; \
	fi


## Update version files and prepare for release (make bump-version VERSION=1.0.0)
bump-version: check-tools ci
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)❌ VERSION required$(NC)"; \
		echo "$(YELLOW)Usage: make bump-version VERSION=1.0.0$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Updating version to $(VERSION)...$(NC)"
	@./.github/scripts/ver-kit set -f version.txt "$(VERSION)" >/dev/null
	@$(MAKE) sync-version
	@echo ""
	@echo "$(GREEN)🚀 Version update completed!$(NC)"
	@echo ""
	@echo "$(YELLOW)Updated versions:$(NC)"
	@$(MAKE) version
	@echo ""
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Review changes: git diff"
	@echo "  2. Commit: git add . && git commit -m 'Bump version to $(VERSION)'"
	@echo "  3. Tag: git tag v$(VERSION)"
	@echo "  4. Push: git push origin main v$(VERSION)"

## Auto-increment patch version (make bump-patch)
bump-patch: validate-version
	@echo "$(YELLOW)Auto-incrementing patch version...$(NC)"; \
	CURRENT="$$(./.github/scripts/ver-kit get -f version.txt 2>/dev/null)"; \
	NEW="$$(./.github/scripts/sem-ver patch "$$CURRENT")"; \
	echo "$(BLUE)Bumping $$CURRENT -> $$NEW$(NC)"; \
	$(MAKE) bump-version VERSION="$$NEW"

## Auto-increment minor version (make bump-minor)  
bump-minor: validate-version
	@echo "$(YELLOW)Auto-incrementing minor version...$(NC)"; \
	CURRENT="$$(./.github/scripts/ver-kit get -f version.txt 2>/dev/null)"; \
	NEW="$$(./.github/scripts/sem-ver minor "$$CURRENT")"; \
	echo "$(BLUE)Bumping $$CURRENT -> $$NEW$(NC)"; \
	$(MAKE) bump-version VERSION="$$NEW"

## Auto-increment major version (make bump-major)
bump-major: validate-version
	@echo "$(YELLOW)Auto-incrementing major version...$(NC)"; \
	CURRENT="$$(./.github/scripts/ver-kit get -f version.txt 2>/dev/null)"; \
	NEW="$$(./.github/scripts/sem-ver major "$$CURRENT")"; \
	echo "$(BLUE)Bumping $$CURRENT -> $$NEW$(NC)"; \
	$(MAKE) bump-version VERSION="$$NEW"

## Auto-increment pre-release version (make bump-pre PRERELEASE=alpha.1)
bump-pre: validate-version
	@if [ -z "$(PRERELEASE)" ]; then \
		echo "$(RED)❌ PRERELEASE required$(NC)"; \
		echo "$(YELLOW)Usage: make bump-pre PRERELEASE=alpha.1$(NC)"; \
		echo "$(YELLOW)Examples: alpha.1, beta.2, rc.1$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Auto-incrementing pre-release version...$(NC)"; \
	CURRENT="$$(./.github/scripts/ver-kit get -f version.txt 2>/dev/null)"; \
	NEW="$$(./.github/scripts/sem-ver pre -p "$(PRERELEASE)" "$$CURRENT")"; \
	echo "$(BLUE)Bumping $$CURRENT -> $$NEW$(NC)"; \
	$(MAKE) bump-version VERSION="$$NEW"

## Create release archive for specified version (make create-archive VERSION=1.0.0)
create-archive:
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)❌ VERSION required$(NC)"; \
		echo "$(YELLOW)Usage: make create-archive VERSION=1.0.0$(NC)"; \
		exit 1; \
	fi
	@chmod +x .github/scripts/create-release.sh
	@./.github/scripts/create-release.sh -p $(PROJECT) v$(VERSION)

## Show version information for all components
version: check-tools
	@printf "version.txt:  "; ./.github/scripts/ver-kit get -f version.txt 2>/dev/null || echo 'missing'
	@printf "zap-sh:       "; ./.github/scripts/ver-kit get -f zap-sh 2>/dev/null || echo 'unknown'
	@printf "basic.sh:     "; ./.github/scripts/ver-kit get -f templates/basic.sh 2>/dev/null || echo 'unknown'
	@printf "enhanced.sh:  "; ./.github/scripts/ver-kit get -f templates/enhanced.sh 2>/dev/null || echo 'unknown'
	@printf "\n"
	@printf "Bash:         "; bash --version | head -1 | cut -d' ' -f4
	@if command -v shellcheck >/dev/null; then \
		printf "Shellcheck:   "; shellcheck --version | grep '^version:' | cut -d' ' -f2; \
	fi
	@printf "sem-ver:      "; ./.github/scripts/sem-ver -v 2>/dev/null || echo 'unknown'
	@printf "ver-kit:      "; ./.github/scripts/ver-kit -v 2>/dev/null || echo 'unknown'

## Run complete build and test cycle
all: clean check-deps lint test
	@echo "$(GREEN)🚀 Complete build and test cycle finished!$(NC)"