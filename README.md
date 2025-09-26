# Development Environment Recreator

A comprehensive, agent-first Linux environment recreation script designed to recreate complete Ubuntu development environments with all tools, configurations, and frameworks.

## 🚀 Features

- **Agent-First Design**: Optimized for fully automated execution by AI agents
- **Comprehensive Coverage**: Recreates complete development environments
- **Multi-Language Support**: Python, Node.js, Java, Rust, .NET, Go
- **Development Tools**: Docker, formatters, linters, GitHub CLI
- **Claude Code Framework**: Complete SuperClaude setup
- **Rollback Capabilities**: Checkpoint system with automatic recovery
- **Proxy Support**: Automatic detection and configuration
- **Validation Testing**: Comprehensive verification of all installations

## 📋 Prerequisites

- **Operating System**: Ubuntu 22.04+ (native Linux, not WSL)
- **Permissions**: Root/sudo access required
- **Resources**: 5GB disk space, 2GB RAM minimum
- **Network**: Internet connectivity for downloads
- **User**: Will create target user (default: `parajao`)

## 🎯 Quick Start

### Basic Installation

```bash
# Download the script
git clone https://github.com/yourusername/dev-environment-recreator.git
cd dev-environment-recreator

# Make executable
chmod +x recreate-environment.sh

# Run with default settings (creates user 'parajao')
sudo ./recreate-environment.sh
```

### Custom Username

```bash
# Create environment for specific user
sudo ./recreate-environment.sh --username myuser
```

### Dry Run (Preview)

```bash
# See what would be installed without making changes
sudo ./recreate-environment.sh --dry-run
```

### Validation Only

```bash
# Test existing installation
sudo ./recreate-environment.sh --validate-only
```

## 🔧 Command Line Options

```bash
Usage: sudo ./recreate-environment.sh [OPTIONS]

Options:
  --username USER     Target username (default: parajao)
  --dry-run          Show what would be done without executing
  --rollback         Rollback to previous checkpoint
  --validate-only    Run validation tests only
  --help             Show help message

Examples:
  sudo ./recreate-environment.sh
  sudo ./recreate-environment.sh --username developer
  sudo ./recreate-environment.sh --dry-run
  sudo ./recreate-environment.sh --validate-only
```

## 📦 What Gets Installed

### Programming Languages

- **Python 3.12+**: pip, UV package manager, black, ruff, pytest, mypy, flake8, isort, bandit
- **Node.js 18.19+**: npm, prettier, eslint, typescript, ts-node
- **Java OpenJDK 17**: google-java-format JAR and wrapper script
- **Rust**: rustc, cargo, rustfmt via rustup
- **.NET SDK 8.0**: dotnet CLI with ASP.NET Core
- **Go 1.21.5**: gofmt, standard toolchain

### Development Tools

- **Docker**: Community Edition with user permissions
- **Git**: With basic configuration and aliases
- **GitHub CLI (gh)**: Official GitHub command line tool
- **Code Formatters**: clang-format, ktlint, prettier, black
- **System Tools**: curl, wget, jq, shellcheck, tree, htop, vim

### Environment Configuration

- **Shell**: Comprehensive .bashrc with aliases and PATH configuration
- **SSH**: Ed25519 key pair generation
- **Directories**: ~/.local/bin/, ~/.claude/ structure
- **Claude Framework**: Complete SuperClaude setup in ~/.claude/

## 🏗️ Installation Phases

### Phase 1: Environment Detection & Safety

- System requirements validation (OS, disk space, memory)
- Internet connectivity testing
- Proxy detection and configuration
- Agent environment detection
- Checkpoint system initialization

### Phase 2: Base System Setup

- System package updates and base development tools
- User creation with proper groups (sudo, docker)
- SSH key generation (Ed25519)
- Directory structure creation

### Phase 3: Programming Language Runtimes

- Python installation with development tools
- Node.js installation via NodeSource repository
- Java OpenJDK installation with google-java-format
- Rust toolchain via rustup
- .NET SDK via Microsoft repository
- Go installation from official binaries

### Phase 4: Development Tools & Formatters

- Docker installation with user permissions
- Code formatters and linters installation
- GitHub CLI installation
- Claude Code framework setup

### Phase 5: Environment Configuration

- Shell environment configuration (.bashrc)
- Git configuration with aliases
- PATH and environment variables setup
- Development shortcuts and functions

### Phase 6: Agent-First Validation

- Programming language runtime testing
- Development tool validation
- Code formatter verification
- Environment configuration validation
- Comprehensive integration testing

### Phase 7: Rollback Capabilities

- Final system snapshot creation
- Environment summary generation
- Rollback system documentation
- Recovery instructions

## 🔄 Checkpoint & Rollback System

The script creates automatic checkpoints at each phase for easy rollback:

```bash
# List available checkpoints
sudo ./recreate-environment.sh --rollback

# Rollback to specific checkpoint
sudo ./recreate-environment.sh --rollback phase3_complete
```

**Available Checkpoints**:

- `phase1_start` / `phase1_complete` - Environment detection
- `phase2_start` / `phase2_complete` - Base system setup
- `phase3_start` / `phase3_complete` - Programming languages
- `phase4_start` / `phase4_complete` - Development tools
- `phase5_start` / `phase5_complete` - Environment configuration
- `phase6_start` / `phase6_complete` - Validation
- `installation_complete` - Final system state

## 🧪 Testing & Validation

### Comprehensive Validation

```bash
# Run all validation tests
sudo ./recreate-environment.sh --validate-only
```

### Manual Testing Commands

```bash
# Test programming languages
python3 --version
node --version
java -version
rustc --version
dotnet --version
go version

# Test development tools
docker --version
git --version
gh --version

# Test formatters
black --version
prettier --version
clang-format --version
~/.local/bin/ktlint --version
~/.local/bin/google-java-format --version
```

## 🌐 Agent-First Features

Designed for AI agents with:

- **Non-interactive execution**: `DEBIAN_FRONTEND=noninteractive`
- **Automated detection**: Recognizes CI/CD and automated environments
- **Comprehensive logging**: Complete audit trail for debugging
- **Error handling**: Graceful failure recovery and reporting
- **Validation checkpoints**: Verification at each step
- **Rollback system**: Automatic recovery from failures

### Agent Environment Detection

The script automatically detects agent/automated environments:

- CI/CD systems (GitHub Actions, GitLab CI, etc.)
- Container environments
- Non-TTY execution contexts
- `AGENT_MODE` environment variable

## 📁 Directory Structure

After installation:

```
/home/parajao/
├── .bashrc                 # Enhanced shell configuration
├── .ssh/
│   ├── id_ed25519         # SSH private key
│   └── id_ed25519.pub     # SSH public key
├── .local/bin/            # User-local executables
│   ├── google-java-format # Java formatter wrapper
│   ├── ktlint            # Kotlin linter
│   └── ...               # Other tools
├── .claude/              # Claude Code framework
│   ├── CLAUDE.md         # Configuration files
│   ├── hooks/            # Git hooks
│   ├── agents/           # AI agents
│   └── lib/              # Libraries
├── .cargo/               # Rust environment
└── environment_summary.txt # Installation summary
```

## 🔒 Security Considerations

- **SSH Keys**: New Ed25519 keys generated for each installation
- **User Permissions**: Proper group memberships (sudo, docker)
- **Package Verification**: Uses official repositories and checksums
- **Proxy Support**: Respects existing proxy configurations
- **Minimal Permissions**: Only installs necessary components

## 🐛 Troubleshooting

### Common Issues

**Permission Denied**

```bash
# Ensure running with sudo
sudo ./recreate-environment.sh
```

**Network Issues**

```bash
# Check internet connectivity
ping -c 3 8.8.8.8

# Check proxy settings
echo $http_proxy $https_proxy
```

**Disk Space**

```bash
# Check available space (requires 5GB minimum)
df -h /
```

**Log Files**

```bash
# View installation log
tail -f /tmp/recreate-environment-*.log

# View all logs
ls -la /tmp/recreate-environment-*.log
```

### Recovery Options

**Rollback Installation**

```bash
# List available checkpoints
sudo ./recreate-environment.sh --rollback

# Rollback to specific phase
sudo ./recreate-environment.sh --rollback phase2_complete
```

**Manual Cleanup**

```bash
# Remove created user (if needed)
sudo userdel -r parajao

# Clean up directories
sudo rm -rf /tmp/env-recreation-*
```

## 📚 Documentation

- **Installation Log**: `/tmp/recreate-environment-TIMESTAMP.log`
- **Environment Summary**: `/home/parajao/environment_summary.txt`
- **Checkpoint Data**: `/tmp/env-recreation-checkpoints/`
- **SSH Keys**: `/home/parajao/.ssh/`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and test thoroughly
4. Commit with clear messages: `git commit -m "Add feature"`
5. Push and create a Pull Request

### Testing Changes

```bash
# Test with dry run
sudo ./recreate-environment.sh --dry-run

# Test validation
sudo ./recreate-environment.sh --validate-only

# Test in VM or container first
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Version History

- **v1.0.0** - Initial release with agent-first design
  - Complete Ubuntu environment recreation
  - Multi-language support (Python, Node.js, Java, Rust, .NET, Go)
  - Comprehensive validation and rollback system
  - Claude Code framework integration

## 💡 Future Enhancements

- [ ] Support for additional Linux distributions (CentOS, Fedora, Arch)
- [ ] Container-based development environment options
- [ ] GUI application installations (VS Code, IDEs)
- [ ] Custom package lists and configuration profiles
- [ ] Remote execution and deployment capabilities
- [ ] Integration with cloud providers (AWS, GCP, Azure)

## 📞 Support

- **Issues**: Create GitHub issues for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Documentation**: Check the wiki for detailed guides
- **Logs**: Always include log files when reporting issues

---

**Made with ❤️ for developers who need consistent, reproducible development environments**
