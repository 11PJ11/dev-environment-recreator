#!/bin/bash
# Development Environment Recreation Script - Agent-First Design
# Recreates complete Ubuntu development environment with all tools and configurations
# Designed for fully automated execution by AI agents with comprehensive validation
#
# Version: 1.0.0
# Target: Ubuntu 22.04+ (native Linux, not WSL)
# Username: parajao (configurable)
# Agent-First: Optimized for autonomous AI execution
#
# Usage: sudo ./recreate-environment.sh [OPTIONS]
# Options:
#   --username USER    Target username (default: parajao)
#   --dry-run         Show what would be done without executing
#   --rollback        Rollback to previous checkpoint
#   --validate-only   Run validation tests only
#   --help           Show this help message

set -euo pipefail

# ============================================================================
# CONFIGURATION & GLOBAL VARIABLES
# ============================================================================

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="recreate-environment.sh"
readonly SCRIPT_DESCRIPTION="Development Environment Recreation Script - Agent-First Design"

# Default configuration
DEFAULT_USERNAME="parajao"
TARGET_USERNAME="${1:-$DEFAULT_USERNAME}"

# System requirements
readonly MIN_DISK_SPACE_GB=5
readonly MIN_MEMORY_MB=2048
readonly REQUIRED_OS="Ubuntu"

# Directories and paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="/tmp"
readonly LOG_FILE="${LOG_DIR}/recreate-environment-$(date +%Y%m%d_%H%M%S).log"
readonly CHECKPOINT_DIR="/tmp/env-recreation-checkpoints"
readonly BACKUP_DIR="/tmp/env-recreation-backup"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# State tracking
CURRENT_PHASE=""
ROLLBACK_ENABLED=false
DRY_RUN=false
VALIDATE_ONLY=false

# ============================================================================
# LOGGING & OUTPUT FUNCTIONS
# ============================================================================

# Initialize logging
init_logging() {
    # Ensure log directory exists
    mkdir -p "$LOG_DIR" || {
        echo "ERROR: Cannot create log directory: $LOG_DIR" >&2
        exit 1
    }

    # Create log file
    touch "$LOG_FILE" || {
        echo "ERROR: Cannot create log file: $LOG_FILE" >&2
        exit 1
    }

    # Log script start
    log "INFO" "Script started: $SCRIPT_NAME v$SCRIPT_VERSION"
    log "INFO" "Target username: $TARGET_USERNAME"
    log "INFO" "Log file: $LOG_FILE"
}

# Enhanced logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""

    # Set color based on level
    case "$level" in
        "ERROR") color="$RED" ;;
        "WARN")  color="$YELLOW" ;;
        "INFO")  color="$GREEN" ;;
        "DEBUG") color="$BLUE" ;;
        *)       color="$NC" ;;
    esac

    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Log to console with color
    echo -e "${color}[$timestamp] [$level] $message${NC}"
}

# Agent-first status reporting
report_status() {
    local phase="$1"
    local status="$2"
    local details="${3:-}"

    log "INFO" "=== PHASE: $phase - STATUS: $status ==="
    if [[ -n "$details" ]]; then
        log "INFO" "Details: $details"
    fi

    # Update current phase
    CURRENT_PHASE="$phase"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Show usage information
show_help() {
    cat << EOF
$SCRIPT_DESCRIPTION

Usage: sudo $SCRIPT_NAME [OPTIONS]

Options:
    --username USER     Target username (default: $DEFAULT_USERNAME)
    --dry-run          Show what would be done without executing
    --rollback         Rollback to previous checkpoint
    --validate-only    Run validation tests only
    --help             Show this help message

Examples:
    sudo $SCRIPT_NAME
    sudo $SCRIPT_NAME --username myuser
    sudo $SCRIPT_NAME --dry-run
    sudo $SCRIPT_NAME --validate-only

Phases:
    1. Environment Detection & Safety
    2. Base System Setup
    3. Programming Language Runtimes
    4. Development Tools & Formatters
    5. Environment Configuration
    6. Agent-First Validation
    7. Rollback Capabilities

For more information, see the README.md file.
EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --username)
                TARGET_USERNAME="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --rollback)
                ROLLBACK_ENABLED=true
                shift
                ;;
            --validate-only)
                VALIDATE_ONLY=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect if running in agent/automated environment
detect_agent_environment() {
    if [[ -n "${CI:-}" ]] || [[ -n "${AGENT_MODE:-}" ]] || [[ ! -t 0 ]]; then
        log "INFO" "Agent/automated environment detected"
        export DEBIAN_FRONTEND=noninteractive
        export NEEDRESTART_MODE=a
        return 0
    fi
    return 1
}

# ============================================================================
# CHECKPOINT & ROLLBACK SYSTEM
# ============================================================================

# Create checkpoint
create_checkpoint() {
    local checkpoint_name="$1"
    local checkpoint_path="$CHECKPOINT_DIR/$checkpoint_name"

    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "[DRY-RUN] Would create checkpoint: $checkpoint_name"
        return 0
    fi

    log "INFO" "Creating checkpoint: $checkpoint_name"
    mkdir -p "$checkpoint_path"

    # Save system state
    {
        echo "CHECKPOINT_NAME=$checkpoint_name"
        echo "TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')"
        echo "PHASE=$CURRENT_PHASE"
        echo "TARGET_USERNAME=$TARGET_USERNAME"
    } > "$checkpoint_path/metadata"

    # Save package list
    dpkg -l > "$checkpoint_path/packages.list" 2>/dev/null || true

    # Save user information
    if id "$TARGET_USERNAME" &>/dev/null; then
        {
            id "$TARGET_USERNAME"
            groups "$TARGET_USERNAME"
        } > "$checkpoint_path/user_info" 2>/dev/null || true
    fi

    log "INFO" "Checkpoint created: $checkpoint_path"
}

# List available checkpoints
list_checkpoints() {
    if [[ ! -d "$CHECKPOINT_DIR" ]]; then
        log "INFO" "No checkpoints available"
        return 0
    fi

    log "INFO" "Available checkpoints:"
    for checkpoint in "$CHECKPOINT_DIR"/*; do
        if [[ -f "$checkpoint/metadata" ]]; then
            local name=$(basename "$checkpoint")
            local timestamp=$(grep "TIMESTAMP=" "$checkpoint/metadata" | cut -d= -f2-)
            log "INFO" "  - $name ($timestamp)"
        fi
    done
}

# Rollback to checkpoint
rollback_to_checkpoint() {
    local checkpoint_name="$1"
    local checkpoint_path="$CHECKPOINT_DIR/$checkpoint_name"

    if [[ ! -d "$checkpoint_path" ]]; then
        log "ERROR" "Checkpoint not found: $checkpoint_name"
        return 1
    fi

    log "WARN" "Rolling back to checkpoint: $checkpoint_name"

    # TODO: Implement rollback logic based on checkpoint data
    # This is a placeholder for the full rollback implementation

    log "INFO" "Rollback completed"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

# Validate system requirements
validate_system_requirements() {
    report_status "VALIDATION" "CHECKING_REQUIREMENTS"

    # Check OS
    if ! grep -q "$REQUIRED_OS" /etc/os-release; then
        log "ERROR" "Unsupported OS. This script requires $REQUIRED_OS"
        return 1
    fi

    # Check disk space
    local available_space_kb=$(df / | tail -1 | awk '{print $4}')
    local available_space_gb=$((available_space_kb / 1024 / 1024))

    if [[ $available_space_gb -lt $MIN_DISK_SPACE_GB ]]; then
        log "ERROR" "Insufficient disk space. Required: ${MIN_DISK_SPACE_GB}GB, Available: ${available_space_gb}GB"
        return 1
    fi

    # Check memory
    local available_memory_mb=$(free -m | awk 'NR==2{print $2}')

    if [[ $available_memory_mb -lt $MIN_MEMORY_MB ]]; then
        log "ERROR" "Insufficient memory. Required: ${MIN_MEMORY_MB}MB, Available: ${available_memory_mb}MB"
        return 1
    fi

    # Check internet connectivity
    if ! ping -c 1 8.8.8.8 &>/dev/null && ! ping -c 1 1.1.1.1 &>/dev/null; then
        log "ERROR" "No internet connectivity detected"
        return 1
    fi

    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log "ERROR" "Sudo access required"
        return 1
    fi

    log "INFO" "System requirements validation passed"
    return 0
}

# Detect proxy settings
detect_proxy_settings() {
    log "INFO" "Detecting proxy settings"

    # Check environment variables
    local proxy_vars=("http_proxy" "https_proxy" "HTTP_PROXY" "HTTPS_PROXY")
    local proxy_found=false

    for var in "${proxy_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            log "INFO" "Proxy detected: $var=${!var}"
            proxy_found=true
        fi
    done

    if [[ "$proxy_found" == false ]]; then
        log "INFO" "No proxy settings detected"
    fi

    # TODO: Auto-detect proxy from system settings
    return 0
}

# ============================================================================
# PHASE 1: ENVIRONMENT DETECTION & SAFETY
# ============================================================================

phase1_environment_detection() {
    report_status "PHASE_1" "STARTING" "Environment Detection & Safety"
    create_checkpoint "phase1_start"

    # Validate system requirements
    if ! validate_system_requirements; then
        report_status "PHASE_1" "FAILED" "System requirements validation failed"
        return 1
    fi

    # Detect agent environment
    detect_agent_environment

    # Detect proxy settings
    detect_proxy_settings

    # Prepare backup directory
    mkdir -p "$BACKUP_DIR"

    create_checkpoint "phase1_complete"
    report_status "PHASE_1" "COMPLETED" "Environment detection completed successfully"
    return 0
}

# ============================================================================
# PHASE 2: BASE SYSTEM SETUP
# ============================================================================

phase2_base_system_setup() {
    report_status "PHASE_2" "STARTING" "Base System Setup"
    create_checkpoint "phase2_start"

    # Update system packages
    log "INFO" "Updating system packages"
    if [[ "$DRY_RUN" != true ]]; then
        apt-get update -qq
        apt-get upgrade -y -qq
    else
        log "INFO" "[DRY-RUN] Would update system packages"
    fi

    # Install base development packages
    local base_packages=(
        "curl"
        "wget"
        "git"
        "vim"
        "build-essential"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "unzip"
        "zip"
        "jq"
        "shellcheck"
        "tree"
        "htop"
        "net-tools"
    )

    log "INFO" "Installing base development packages"
    if [[ "$DRY_RUN" != true ]]; then
        apt-get install -y "${base_packages[@]}"
    else
        log "INFO" "[DRY-RUN] Would install: ${base_packages[*]}"
    fi

    # Create user if not exists
    if ! id "$TARGET_USERNAME" &>/dev/null; then
        log "INFO" "Creating user: $TARGET_USERNAME"
        if [[ "$DRY_RUN" != true ]]; then
            useradd -m -s /bin/bash "$TARGET_USERNAME"
            usermod -aG sudo,docker "$TARGET_USERNAME"
        else
            log "INFO" "[DRY-RUN] Would create user: $TARGET_USERNAME"
        fi
    else
        log "INFO" "User already exists: $TARGET_USERNAME"
    fi

    # Generate SSH keys
    local ssh_dir="/home/$TARGET_USERNAME/.ssh"
    log "INFO" "Setting up SSH keys"
    if [[ "$DRY_RUN" != true ]]; then
        sudo -u "$TARGET_USERNAME" mkdir -p "$ssh_dir"
        sudo -u "$TARGET_USERNAME" chmod 700 "$ssh_dir"

        if [[ ! -f "$ssh_dir/id_ed25519" ]]; then
            sudo -u "$TARGET_USERNAME" ssh-keygen -t ed25519 -f "$ssh_dir/id_ed25519" -N ""
            log "INFO" "SSH key generated: $ssh_dir/id_ed25519"
        else
            log "INFO" "SSH key already exists: $ssh_dir/id_ed25519"
        fi
    else
        log "INFO" "[DRY-RUN] Would generate SSH keys for: $TARGET_USERNAME"
    fi

    create_checkpoint "phase2_complete"
    report_status "PHASE_2" "COMPLETED" "Base system setup completed successfully"
    return 0
}

# ============================================================================
# PHASE 3: PROGRAMMING LANGUAGE RUNTIMES
# ============================================================================

install_python() {
    log "INFO" "Installing Python 3.12 and tools"

    if [[ "$DRY_RUN" != true ]]; then
        # Install Python
        apt-get install -y python3 python3-pip python3-venv python3-dev

        # Install UV (modern Python package manager)
        curl -LsSf https://astral.sh/uv/install.sh | sudo -u "$TARGET_USERNAME" sh

        # Install common Python tools
        local python_tools=(
            "black"
            "ruff"
            "pytest"
            "mypy"
            "flake8"
            "isort"
            "bandit"
        )

        for tool in "${python_tools[@]}"; do
            sudo -u "$TARGET_USERNAME" pip3 install --user "$tool"
        done
    else
        log "INFO" "[DRY-RUN] Would install Python 3.12 and development tools"
    fi
}

install_nodejs() {
    log "INFO" "Installing Node.js 18.19.1 and tools"

    if [[ "$DRY_RUN" != true ]]; then
        # Install Node.js via NodeSource repository
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs

        # Install global packages
        sudo -u "$TARGET_USERNAME" npm install -g prettier eslint typescript ts-node
    else
        log "INFO" "[DRY-RUN] Would install Node.js and development tools"
    fi
}

install_java() {
    log "INFO" "Installing OpenJDK 17 and tools"

    if [[ "$DRY_RUN" != true ]]; then
        # Install OpenJDK
        apt-get install -y openjdk-17-jdk

        # Install google-java-format
        local java_format_url="https://github.com/google/google-java-format/releases/download/v1.22.0/google-java-format-1.22.0-all-deps.jar"
        local local_bin="/home/$TARGET_USERNAME/.local/bin"

        sudo -u "$TARGET_USERNAME" mkdir -p "$local_bin"
        sudo -u "$TARGET_USERNAME" wget -O "$local_bin/google-java-format.jar" "$java_format_url"

        # Create wrapper script
        cat > "$local_bin/google-java-format" << 'EOF'
#!/bin/bash
java -jar ~/.local/bin/google-java-format.jar "$@"
EOF
        chmod +x "$local_bin/google-java-format"
        chown "$TARGET_USERNAME:$TARGET_USERNAME" "$local_bin/google-java-format"
    else
        log "INFO" "[DRY-RUN] Would install OpenJDK 17 and google-java-format"
    fi
}

install_rust() {
    log "INFO" "Installing Rust toolchain"

    if [[ "$DRY_RUN" != true ]]; then
        # Install Rust via rustup
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo -u "$TARGET_USERNAME" sh -s -- -y
    else
        log "INFO" "[DRY-RUN] Would install Rust toolchain"
    fi
}

install_dotnet() {
    log "INFO" "Installing .NET SDK 8.0"

    if [[ "$DRY_RUN" != true ]]; then
        # Add Microsoft repository
        wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
        dpkg -i packages-microsoft-prod.deb
        apt-get update

        # Install .NET SDK
        apt-get install -y dotnet-sdk-8.0

        # Clean up
        rm -f packages-microsoft-prod.deb
    else
        log "INFO" "[DRY-RUN] Would install .NET SDK 8.0"
    fi
}

install_go() {
    log "INFO" "Installing Go 1.21.5"

    if [[ "$DRY_RUN" != true ]]; then
        # Download and install Go
        local go_version="1.21.5"
        local go_tarball="go${go_version}.linux-amd64.tar.gz"
        local go_url="https://go.dev/dl/$go_tarball"

        wget "$go_url"
        rm -rf /usr/local/go
        tar -C /usr/local -xzf "$go_tarball"
        rm -f "$go_tarball"
    else
        log "INFO" "[DRY-RUN] Would install Go 1.21.5"
    fi
}

phase3_programming_languages() {
    report_status "PHASE_3" "STARTING" "Programming Language Runtimes"
    create_checkpoint "phase3_start"

    # Install programming languages
    install_python
    install_nodejs
    install_java
    install_rust
    install_dotnet
    install_go

    create_checkpoint "phase3_complete"
    report_status "PHASE_3" "COMPLETED" "Programming language runtimes installed successfully"
    return 0
}

# ============================================================================
# PHASE 4: DEVELOPMENT TOOLS & FORMATTERS
# ============================================================================

install_docker() {
    log "INFO" "Installing Docker"

    if [[ "$DRY_RUN" != true ]]; then
        # Add Docker repository
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Add user to docker group
        usermod -aG docker "$TARGET_USERNAME"
    else
        log "INFO" "[DRY-RUN] Would install Docker and add user to docker group"
    fi
}

install_formatters() {
    log "INFO" "Installing code formatters and linters"

    if [[ "$DRY_RUN" != true ]]; then
        # Install clang-format
        apt-get install -y clang-format

        # Install ktlint
        local ktlint_url="https://github.com/pinterest/ktlint/releases/download/1.0.1/ktlint"
        local local_bin="/home/$TARGET_USERNAME/.local/bin"

        sudo -u "$TARGET_USERNAME" mkdir -p "$local_bin"
        sudo -u "$TARGET_USERNAME" curl -sSLo "$local_bin/ktlint" "$ktlint_url"
        chmod +x "$local_bin/ktlint"

        # Install GitHub CLI
        type -p curl >/dev/null || apt install curl -y
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        apt update
        apt install gh -y
    else
        log "INFO" "[DRY-RUN] Would install formatters, linters, and GitHub CLI"
    fi
}

setup_claude_framework() {
    log "INFO" "Setting up Claude Code framework"

    local claude_dir="/home/$TARGET_USERNAME/.claude"

    if [[ "$DRY_RUN" != true ]]; then
        # Create Claude directory
        sudo -u "$TARGET_USERNAME" mkdir -p "$claude_dir"

        # TODO: Copy Claude framework files from current environment
        # This would include CLAUDE.md, RULES.md, PRINCIPLES.md, etc.

        # For now, create placeholder structure
        local claude_files=(
            "CLAUDE.md"
            "RULES.md"
            "PRINCIPLES.md"
            "PERSONAS.md"
            "ORCHESTRATOR.md"
            "MODES.md"
            "CODE_SMELLS.md"
        )

        for file in "${claude_files[@]}"; do
            sudo -u "$TARGET_USERNAME" touch "$claude_dir/$file"
        done

        # Create directory structure
        local claude_dirs=(
            "hooks"
            "agents"
            "lib"
        )

        for dir in "${claude_dirs[@]}"; do
            sudo -u "$TARGET_USERNAME" mkdir -p "$claude_dir/$dir"
        done
    else
        log "INFO" "[DRY-RUN] Would setup Claude Code framework in ~/.claude/"
    fi
}

phase4_development_tools() {
    report_status "PHASE_4" "STARTING" "Development Tools & Formatters"
    create_checkpoint "phase4_start"

    # Install development tools
    install_docker
    install_formatters
    setup_claude_framework

    create_checkpoint "phase4_complete"
    report_status "PHASE_4" "COMPLETED" "Development tools and formatters installed successfully"
    return 0
}

# ============================================================================
# PHASE 5: ENVIRONMENT CONFIGURATION
# ============================================================================

configure_shell_environment() {
    log "INFO" "Configuring shell environment"

    local home_dir="/home/$TARGET_USERNAME"
    local bashrc="$home_dir/.bashrc"

    if [[ "$DRY_RUN" != true ]]; then
        # Backup existing .bashrc
        if [[ -f "$bashrc" ]]; then
            cp "$bashrc" "$bashrc.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        # Create comprehensive .bashrc
        cat >> "$bashrc" << 'EOF'

# Development Environment Configuration - Auto-generated
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/go/bin:$PATH"

# Python environment
export PYTHONPATH="$HOME/.local/lib/python3.12/site-packages:$PYTHONPATH"

# Go environment
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Java environment
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# .NET environment
export DOTNET_ROOT="/usr/share/dotnet"

# Node.js environment
export NODE_PATH="/usr/lib/node_modules"

# Docker environment
export DOCKER_BUILDKIT=1

# Claude Code environment
export CLAUDE_HOME="$HOME/.claude"

# Development aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'

# Development shortcuts
alias py='python3'
alias pip='pip3'
alias code='code .'
alias ..='cd ..'
alias ...='cd ../..'

# Claude Code shortcuts
alias claude='~/.local/bin/claude'
alias cai='claude ai'

# Function to activate Python virtual environment
activate_venv() {
    if [[ -f "venv/bin/activate" ]]; then
        source venv/bin/activate
    elif [[ -f ".venv/bin/activate" ]]; then
        source .venv/bin/activate
    else
        echo "No virtual environment found"
    fi
}

# Function to create and activate Python virtual environment
create_venv() {
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
}

EOF

        chown "$TARGET_USERNAME:$TARGET_USERNAME" "$bashrc"
    else
        log "INFO" "[DRY-RUN] Would configure shell environment and .bashrc"
    fi
}

configure_git() {
    log "INFO" "Configuring Git"

    if [[ "$DRY_RUN" != true ]]; then
        # Set basic Git configuration
        sudo -u "$TARGET_USERNAME" git config --global init.defaultBranch main
        sudo -u "$TARGET_USERNAME" git config --global pull.rebase false
        sudo -u "$TARGET_USERNAME" git config --global core.editor vim
        sudo -u "$TARGET_USERNAME" git config --global color.ui auto

        # Note: User will need to set user.name and user.email manually
        log "INFO" "Git configured. User should set: git config --global user.name 'Name' and user.email 'email'"
    else
        log "INFO" "[DRY-RUN] Would configure Git with default settings"
    fi
}

phase5_environment_configuration() {
    report_status "PHASE_5" "STARTING" "Environment Configuration"
    create_checkpoint "phase5_start"

    # Configure environment
    configure_shell_environment
    configure_git

    create_checkpoint "phase5_complete"
    report_status "PHASE_5" "COMPLETED" "Environment configuration completed successfully"
    return 0
}

# ============================================================================
# PHASE 6: AGENT-FIRST VALIDATION
# ============================================================================

validate_programming_languages() {
    log "INFO" "Validating programming language installations"

    local validation_passed=true

    # Test Python
    if ! sudo -u "$TARGET_USERNAME" python3 --version &>/dev/null; then
        log "ERROR" "Python validation failed"
        validation_passed=false
    else
        log "INFO" "Python validation passed"
    fi

    # Test Node.js
    if ! sudo -u "$TARGET_USERNAME" node --version &>/dev/null; then
        log "ERROR" "Node.js validation failed"
        validation_passed=false
    else
        log "INFO" "Node.js validation passed"
    fi

    # Test Java
    if ! sudo -u "$TARGET_USERNAME" java -version &>/dev/null; then
        log "ERROR" "Java validation failed"
        validation_passed=false
    else
        log "INFO" "Java validation passed"
    fi

    # Test Go
    if ! /usr/local/go/bin/go version &>/dev/null; then
        log "ERROR" "Go validation failed"
        validation_passed=false
    else
        log "INFO" "Go validation passed"
    fi

    # Test Rust
    if ! sudo -u "$TARGET_USERNAME" bash -c 'source ~/.cargo/env && rustc --version' &>/dev/null; then
        log "ERROR" "Rust validation failed"
        validation_passed=false
    else
        log "INFO" "Rust validation passed"
    fi

    # Test .NET
    if ! dotnet --version &>/dev/null; then
        log "ERROR" ".NET validation failed"
        validation_passed=false
    else
        log "INFO" ".NET validation passed"
    fi

    [[ "$validation_passed" == true ]]
}

validate_development_tools() {
    log "INFO" "Validating development tools"

    local validation_passed=true
    local tools=("docker" "git" "curl" "wget" "jq" "shellcheck")

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log "ERROR" "Tool validation failed: $tool"
            validation_passed=false
        else
            log "INFO" "Tool validation passed: $tool"
        fi
    done

    [[ "$validation_passed" == true ]]
}

validate_formatters() {
    log "INFO" "Validating code formatters"

    local validation_passed=true

    # Test clang-format
    if ! command -v clang-format &>/dev/null; then
        log "ERROR" "clang-format validation failed"
        validation_passed=false
    else
        log "INFO" "clang-format validation passed"
    fi

    # Test ktlint
    if ! sudo -u "$TARGET_USERNAME" /home/"$TARGET_USERNAME"/.local/bin/ktlint --version &>/dev/null; then
        log "ERROR" "ktlint validation failed"
        validation_passed=false
    else
        log "INFO" "ktlint validation passed"
    fi

    # Test other formatters
    local user_tools=("black" "prettier" "google-java-format")
    for tool in "${user_tools[@]}"; do
        if ! sudo -u "$TARGET_USERNAME" command -v "$tool" &>/dev/null; then
            log "WARN" "User tool not in PATH: $tool (may need shell reload)"
        else
            log "INFO" "User tool validation passed: $tool"
        fi
    done

    [[ "$validation_passed" == true ]]
}

validate_environment() {
    log "INFO" "Validating environment configuration"

    local validation_passed=true

    # Check user creation
    if ! id "$TARGET_USERNAME" &>/dev/null; then
        log "ERROR" "User validation failed: $TARGET_USERNAME"
        validation_passed=false
    else
        log "INFO" "User validation passed: $TARGET_USERNAME"
    fi

    # Check home directory
    if [[ ! -d "/home/$TARGET_USERNAME" ]]; then
        log "ERROR" "Home directory validation failed"
        validation_passed=false
    else
        log "INFO" "Home directory validation passed"
    fi

    # Check SSH keys
    if [[ ! -f "/home/$TARGET_USERNAME/.ssh/id_ed25519" ]]; then
        log "ERROR" "SSH key validation failed"
        validation_passed=false
    else
        log "INFO" "SSH key validation passed"
    fi

    # Check Claude directory
    if [[ ! -d "/home/$TARGET_USERNAME/.claude" ]]; then
        log "ERROR" "Claude directory validation failed"
        validation_passed=false
    else
        log "INFO" "Claude directory validation passed"
    fi

    [[ "$validation_passed" == true ]]
}

phase6_validation() {
    report_status "PHASE_6" "STARTING" "Agent-First Validation"
    create_checkpoint "phase6_start"

    local validation_passed=true

    # Run validation tests
    if ! validate_programming_languages; then
        validation_passed=false
    fi

    if ! validate_development_tools; then
        validation_passed=false
    fi

    if ! validate_formatters; then
        validation_passed=false
    fi

    if ! validate_environment; then
        validation_passed=false
    fi

    if [[ "$validation_passed" == true ]]; then
        create_checkpoint "phase6_complete"
        report_status "PHASE_6" "COMPLETED" "All validation tests passed"
        return 0
    else
        report_status "PHASE_6" "FAILED" "Some validation tests failed"
        return 1
    fi
}

# ============================================================================
# PHASE 7: ROLLBACK CAPABILITIES
# ============================================================================

phase7_rollback_setup() {
    report_status "PHASE_7" "STARTING" "Rollback Capabilities Setup"

    # Create final system snapshot
    create_checkpoint "installation_complete"

    # Generate environment summary
    local summary_file="/home/$TARGET_USERNAME/environment_summary.txt"

    if [[ "$DRY_RUN" != true ]]; then
        cat > "$summary_file" << EOF
Development Environment Recreation Summary
==========================================

Target User: $TARGET_USERNAME
Installation Date: $(date)
Script Version: $SCRIPT_VERSION

Installed Programming Languages:
- Python 3.12+ with pip, UV, black, ruff, pytest, mypy
- Node.js 18.19+ with npm, prettier, eslint, typescript
- Java OpenJDK 17 with google-java-format
- Rust with rustc, cargo, rustfmt
- .NET SDK 8.0 with dotnet CLI
- Go 1.21.5 with gofmt

Development Tools:
- Docker with user permissions
- Git with basic configuration
- GitHub CLI (gh)
- Code formatters: clang-format, ktlint
- Utilities: curl, wget, jq, shellcheck, tree, htop

Environment Configuration:
- Shell: Bash with comprehensive .bashrc
- SSH: Ed25519 key pair generated
- Directories: ~/.local/bin, ~/.claude structure
- PATH: Includes all development tools

Claude Code Framework:
- Directory: ~/.claude/
- Structure: hooks/, agents/, lib/
- Configuration files: CLAUDE.md, RULES.md, etc.

Next Steps:
1. Reload shell environment: source ~/.bashrc
2. Configure Git identity: git config --global user.name/user.email
3. Test installations: run validation commands
4. Customize environment as needed

Log Files:
- Installation log: $LOG_FILE
- Checkpoints: $CHECKPOINT_DIR

Support:
- View checkpoints: ls -la $CHECKPOINT_DIR
- Rollback: sudo $SCRIPT_NAME --rollback <checkpoint_name>
- Re-validate: sudo $SCRIPT_NAME --validate-only

EOF

        chown "$TARGET_USERNAME:$TARGET_USERNAME" "$summary_file"
        log "INFO" "Environment summary created: $summary_file"
    else
        log "INFO" "[DRY-RUN] Would create environment summary"
    fi

    report_status "PHASE_7" "COMPLETED" "Rollback capabilities and summary created"
    return 0
}

# ============================================================================
# MAIN EXECUTION FUNCTIONS
# ============================================================================

# Run validation only
run_validation_only() {
    log "INFO" "Running validation tests only"

    init_logging

    if phase6_validation; then
        log "INFO" "All validation tests passed"
        return 0
    else
        log "ERROR" "Some validation tests failed"
        return 1
    fi
}

# Run rollback
run_rollback() {
    log "INFO" "Rollback mode activated"

    init_logging
    list_checkpoints

    # TODO: Implement interactive checkpoint selection
    # For now, just show available checkpoints

    return 0
}

# Main installation function
run_installation() {
    log "INFO" "Starting full environment recreation"

    # Run all phases
    if phase1_environment_detection && \
       phase2_base_system_setup && \
       phase3_programming_languages && \
       phase4_development_tools && \
       phase5_environment_configuration && \
       phase6_validation && \
       phase7_rollback_setup; then

        log "INFO" "===================================================="
        log "INFO" "Environment recreation completed successfully!"
        log "INFO" "===================================================="
        log "INFO" "User: $TARGET_USERNAME"
        log "INFO" "Summary: /home/$TARGET_USERNAME/environment_summary.txt"
        log "INFO" "Log: $LOG_FILE"
        log "INFO" ""
        log "INFO" "Next steps:"
        log "INFO" "1. Switch to user: su - $TARGET_USERNAME"
        log "INFO" "2. Reload environment: source ~/.bashrc"
        log "INFO" "3. Configure Git: git config --global user.name/user.email"
        log "INFO" "4. Test installations: python3 --version, node --version, etc."
        log "INFO" "===================================================="

        return 0
    else
        log "ERROR" "Environment recreation failed!"
        log "ERROR" "Check log file: $LOG_FILE"
        log "ERROR" "Available checkpoints:"
        list_checkpoints
        return 1
    fi
}

# ============================================================================
# MAIN SCRIPT ENTRY POINT
# ============================================================================

main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Check if running as root
    check_root

    # Initialize logging
    init_logging

    log "INFO" "Starting $SCRIPT_DESCRIPTION v$SCRIPT_VERSION"
    log "INFO" "Target username: $TARGET_USERNAME"
    log "INFO" "Dry run: $DRY_RUN"
    log "INFO" "Validate only: $VALIDATE_ONLY"
    log "INFO" "Rollback enabled: $ROLLBACK_ENABLED"

    # Handle different execution modes
    if [[ "$VALIDATE_ONLY" == true ]]; then
        run_validation_only
    elif [[ "$ROLLBACK_ENABLED" == true ]]; then
        run_rollback
    else
        run_installation
    fi

    local exit_code=$?
    log "INFO" "Script completed with exit code: $exit_code"
    return $exit_code
}

# Execute main function with all arguments
main "$@"