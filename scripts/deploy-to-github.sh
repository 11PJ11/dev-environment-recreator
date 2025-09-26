#!/bin/bash
# GitHub Repository Setup and Deployment Script
# Creates GitHub repository and pushes the environment recreator

set -euo pipefail

# Configuration
REPO_NAME="dev-environment-recreator"
REPO_DESCRIPTION="Agent-First Linux Development Environment Recreation Script"
DEFAULT_BRANCH="main"

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

# Check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log "ERROR" "GitHub CLI (gh) is not installed"
        log "INFO" "Install with: sudo apt install gh"
        return 1
    fi

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        log "WARN" "GitHub CLI not authenticated"
        log "INFO" "Run: gh auth login"
        return 1
    fi

    log "INFO" "GitHub CLI is installed and authenticated"
    return 0
}

# Create GitHub repository
create_github_repo() {
    log "INFO" "Creating GitHub repository: $REPO_NAME"

    # Check if repository already exists
    if gh repo view "$REPO_NAME" &> /dev/null; then
        log "WARN" "Repository $REPO_NAME already exists"
        read -p "Do you want to use the existing repository? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "INFO" "Exiting without creating repository"
            return 1
        fi
    else
        # Create new repository
        gh repo create "$REPO_NAME" \
            --description "$REPO_DESCRIPTION" \
            --public \
            --clone=false \
            --add-readme=false

        log "INFO" "Repository created successfully"
    fi

    return 0
}

# Add remote and push
setup_remote_and_push() {
    log "INFO" "Setting up remote and pushing code"

    # Get GitHub username
    local github_username
    github_username=$(gh api user | jq -r '.login')

    # Add remote if not exists
    if ! git remote get-url origin &> /dev/null; then
        git remote add origin "git@github.com:$github_username/$REPO_NAME.git"
        log "INFO" "Added remote origin"
    else
        log "INFO" "Remote origin already exists"
    fi

    # Push code
    git push -u origin main
    git push origin --tags

    log "INFO" "Code pushed successfully"
    log "INFO" "Repository URL: https://github.com/$github_username/$REPO_NAME"
}

# Setup repository settings
setup_repo_settings() {
    local github_username
    github_username=$(gh api user | jq -r '.login')

    log "INFO" "Configuring repository settings"

    # Enable GitHub Actions
    gh api -X PUT "repos/$github_username/$REPO_NAME/actions/permissions" \
        --field enabled=true \
        --field allowed_actions=all \
        || log "WARN" "Could not configure Actions permissions"

    # Set default branch protection (optional)
    log "INFO" "Consider setting up branch protection rules in GitHub UI"
    log "INFO" "Repository settings: https://github.com/$github_username/$REPO_NAME/settings"
}

# Create release
create_release() {
    local version
    version=$(cat VERSION 2>/dev/null || echo "1.0.0")

    log "INFO" "Creating release v$version"

    # Check if release already exists
    if gh release view "v$version" &> /dev/null; then
        log "WARN" "Release v$version already exists"
        return 0
    fi

    # Extract changelog for this version
    local release_notes=""
    if [[ -f "CHANGELOG.md" ]]; then
        # Extract changelog section for this version
        release_notes=$(awk "/## \[$version\]/,/## \[/{if(/## \[/ && !/## \[$version\]/) exit; if(!/## \[$version\]/) print}" CHANGELOG.md || echo "")
    fi

    if [[ -z "$release_notes" ]]; then
        release_notes="Release v$version of the Development Environment Recreator

Features:
- Agent-first Linux environment recreation
- Multi-language support (Python, Node.js, Java, Rust, .NET, Go)
- Comprehensive development tools and formatters
- Claude Code framework integration
- Checkpoint system with rollback capabilities

See CHANGELOG.md for detailed changes."
    fi

    # Create release
    echo "$release_notes" | gh release create "v$version" \
        --title "Development Environment Recreator v$version" \
        --notes-file - \
        recreate-environment.sh

    log "INFO" "Release v$version created successfully"
}

# Main function
main() {
    log "INFO" "GitHub Repository Setup and Deployment"
    log "INFO" "Repository: $REPO_NAME"

    # Check prerequisites
    if ! check_gh_cli; then
        log "ERROR" "Prerequisites not met"
        exit 1
    fi

    # Ensure we're in the right directory
    if [[ ! -f "recreate-environment.sh" ]]; then
        log "ERROR" "recreate-environment.sh not found. Run from project directory."
        exit 1
    fi

    # Ensure git repository is initialized
    if [[ ! -d ".git" ]]; then
        log "ERROR" "Not a git repository. Initialize with 'git init' first."
        exit 1
    fi

    # Create GitHub repository
    if ! create_github_repo; then
        log "ERROR" "Failed to create GitHub repository"
        exit 1
    fi

    # Setup remote and push
    if ! setup_remote_and_push; then
        log "ERROR" "Failed to push to GitHub"
        exit 1
    fi

    # Setup repository settings
    setup_repo_settings

    # Create release
    create_release

    log "INFO" "🎉 Deployment completed successfully!"
    log "INFO" "Repository: https://github.com/$(gh api user | jq -r '.login')/$REPO_NAME"
    log "INFO" ""
    log "INFO" "Next steps:"
    log "INFO" "1. Review repository settings and branch protection"
    log "INFO" "2. Update README.md with correct repository URLs"
    log "INFO" "3. Test the installation script on a fresh Ubuntu system"
    log "INFO" "4. Share the repository with others"
}

# Execute main function
main "$@"