#!/bin/bash
# Version Update Script for Development Environment Recreator
# Updates version across all files and creates git tag

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    local message="$2"
    local color=""

    case "$level" in
        "ERROR") color="$RED" ;;
        "WARN")  color="$YELLOW" ;;
        "INFO")  color="$GREEN" ;;
        "DEBUG") color="$BLUE" ;;
        *)       color="$NC" ;;
    esac

    echo -e "${color}[$level] $message${NC}"
}

# Show usage
show_usage() {
    echo "Usage: $0 <new-version> [--commit]"
    echo ""
    echo "Examples:"
    echo "  $0 1.1.0           # Update version to 1.1.0"
    echo "  $0 1.1.0 --commit  # Update version and create commit/tag"
    echo ""
    echo "Version format: MAJOR.MINOR.PATCH (semantic versioning)"
}

# Validate version format
validate_version() {
    local version="$1"

    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "ERROR" "Invalid version format: $version"
        log "INFO" "Use semantic versioning format: MAJOR.MINOR.PATCH (e.g., 1.2.3)"
        return 1
    fi

    return 0
}

# Get current version
get_current_version() {
    if [[ -f "$PROJECT_DIR/VERSION" ]]; then
        cat "$PROJECT_DIR/VERSION"
    else
        echo "0.0.0"
    fi
}

# Update version in files
update_version_files() {
    local new_version="$1"
    local current_version
    current_version=$(get_current_version)

    log "INFO" "Updating version from $current_version to $new_version"

    # Update VERSION file
    echo "$new_version" > "$PROJECT_DIR/VERSION"
    log "INFO" "Updated VERSION file"

    # Update version in recreate-environment.sh
    if [[ -f "$PROJECT_DIR/recreate-environment.sh" ]]; then
        sed -i "s/readonly SCRIPT_VERSION=\".*\"/readonly SCRIPT_VERSION=\"$new_version\"/" "$PROJECT_DIR/recreate-environment.sh"
        log "INFO" "Updated version in recreate-environment.sh"
    fi

    # Update README.md if it contains version references
    if [[ -f "$PROJECT_DIR/README.md" ]]; then
        # Update any version badges or references (if they exist)
        sed -i "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/v$new_version/g" "$PROJECT_DIR/README.md" || true
        log "INFO" "Updated version references in README.md"
    fi

    log "INFO" "Version updated successfully"
}

# Add changelog entry template
add_changelog_entry() {
    local new_version="$1"
    local changelog_file="$PROJECT_DIR/CHANGELOG.md"

    if [[ ! -f "$changelog_file" ]]; then
        log "WARN" "CHANGELOG.md not found, skipping changelog update"
        return 0
    fi

    # Check if version already exists in changelog
    if grep -q "\[$new_version\]" "$changelog_file"; then
        log "INFO" "Version $new_version already exists in CHANGELOG.md"
        return 0
    fi

    # Create temporary file with new entry
    local temp_file
    temp_file=$(mktemp)

    # Add new version entry after [Unreleased] section
    awk -v version="$new_version" -v date="$(date +%Y-%m-%d)" '
    /^## \[Unreleased\]/ {
        print $0
        print ""
        print "### Added"
        print "- New features and enhancements"
        print ""
        print "### Changed"
        print "- Changes in existing functionality"
        print ""
        print "### Fixed"
        print "- Bug fixes"
        print ""
        print "## [" version "] - " date
        print ""
        print "### Added"
        print "- Update version to " version
        print ""
        next
    }
    { print }
    ' "$changelog_file" > "$temp_file"

    mv "$temp_file" "$changelog_file"
    log "INFO" "Added changelog entry for version $new_version"
    log "WARN" "Please edit CHANGELOG.md to add proper release notes"
}

# Create git commit and tag
create_git_commit_and_tag() {
    local new_version="$1"

    cd "$PROJECT_DIR"

    # Check if we have uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log "INFO" "Staging version update changes"
        git add VERSION recreate-environment.sh README.md CHANGELOG.md

        # Create commit
        git commit -m "🔖 Bump version to $new_version

- Update version across all files
- Add changelog entry template
- Prepare for release $new_version

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

        log "INFO" "Created commit for version $new_version"
    else
        log "INFO" "No changes to commit"
    fi

    # Create annotated tag
    if git tag | grep -q "^v$new_version$"; then
        log "WARN" "Tag v$new_version already exists"
    else
        git tag -a "v$new_version" -m "🏷️ Release v$new_version

Version $new_version of the Development Environment Recreator.

See CHANGELOG.md for detailed changes and improvements."

        log "INFO" "Created tag v$new_version"
    fi

    log "INFO" "Ready to push: git push origin main --tags"
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    local new_version="$1"
    local create_commit=false

    # Parse arguments
    if [[ $# -eq 2 && "$2" == "--commit" ]]; then
        create_commit=true
    elif [[ $# -gt 1 ]]; then
        log "ERROR" "Invalid arguments"
        show_usage
        exit 1
    fi

    # Validate version
    if ! validate_version "$new_version"; then
        exit 1
    fi

    # Check if we're in a git repository (for commit option)
    if [[ "$create_commit" == true && ! -d "$PROJECT_DIR/.git" ]]; then
        log "ERROR" "Not in a git repository. Cannot create commit and tag."
        exit 1
    fi

    local current_version
    current_version=$(get_current_version)

    log "INFO" "Version Update Process"
    log "INFO" "Current version: $current_version"
    log "INFO" "New version: $new_version"
    log "INFO" "Create commit: $create_commit"

    # Confirm action
    read -p "Continue with version update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Version update cancelled"
        exit 0
    fi

    # Update version in files
    update_version_files "$new_version"

    # Add changelog entry
    add_changelog_entry "$new_version"

    # Create commit and tag if requested
    if [[ "$create_commit" == true ]]; then
        create_git_commit_and_tag "$new_version"
    fi

    log "INFO" "🎉 Version update completed successfully!"
    log "INFO" "Version: $new_version"

    if [[ "$create_commit" == true ]]; then
        log "INFO" ""
        log "INFO" "Next steps:"
        log "INFO" "1. Edit CHANGELOG.md with proper release notes"
        log "INFO" "2. Review changes: git log --oneline -2"
        log "INFO" "3. Push changes: git push origin main --tags"
        log "INFO" "4. Create GitHub release"
    else
        log "INFO" ""
        log "INFO" "Next steps:"
        log "INFO" "1. Review changed files"
        log "INFO" "2. Edit CHANGELOG.md with proper release notes"
        log "INFO" "3. Create commit: $0 $new_version --commit"
    fi
}

# Execute main function
main "$@"