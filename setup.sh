#!/bin/bash
#
# SuperDeck Development Environment Setup Script
#
# This script installs all dependencies required to run the development workflow:
# - FVM (Flutter Version Manager)
# - Flutter SDK (via FVM)
# - Melos (monorepo management)
# - DCM (Dart Code Metrics)
# - Project dependencies via melos bootstrap
#
# Usage:
#   ./setup.sh           # Full setup
#   ./setup.sh --ci      # CI mode (skip interactive prompts)
#   ./setup.sh --help    # Show help
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REQUIRED_DART_SDK="3.6.0"
REQUIRED_FLUTTER="3.27.0"
MELOS_VERSION="6.3.3"

# Flags
CI_MODE=false
SKIP_FLUTTER=false
SKIP_BUILD_RUNNER=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ci)
            CI_MODE=true
            shift
            ;;
        --skip-flutter)
            SKIP_FLUTTER=true
            shift
            ;;
        --skip-build-runner)
            SKIP_BUILD_RUNNER=true
            shift
            ;;
        --help|-h)
            echo "SuperDeck Development Setup Script"
            echo ""
            echo "Usage: ./setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ci               Run in CI mode (non-interactive, skip optional steps)"
            echo "  --skip-flutter     Skip Flutter/FVM installation (use existing Flutter)"
            echo "  --skip-build-runner Skip build_runner code generation"
            echo "  --help, -h         Show this help message"
            echo ""
            echo "Requirements:"
            echo "  - Dart SDK >= $REQUIRED_DART_SDK"
            echo "  - Flutter >= $REQUIRED_FLUTTER"
            echo "  - Git"
            echo "  - curl"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  $1${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking Prerequisites"

    local missing=()

    if ! command_exists git; then
        missing+=("git")
    fi

    if ! command_exists curl; then
        missing+=("curl")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Please install them and run this script again."
        exit 1
    fi

    log_success "All prerequisites are installed"
}

# Install FVM (Flutter Version Manager)
install_fvm() {
    log_step "Installing FVM (Flutter Version Manager)"

    if command_exists fvm; then
        log_info "FVM is already installed"
        fvm --version || true
    else
        log_info "Installing FVM..."
        curl -fsSL https://fvm.app/install.sh | bash

        # Add FVM to PATH for this session
        export PATH="$HOME/.pub-cache/bin:$PATH"
        export PATH="$HOME/fvm/default/bin:$PATH"

        if command_exists fvm; then
            log_success "FVM installed successfully"
            fvm --version || true
        else
            log_warn "FVM installed but not in PATH. You may need to restart your shell."
        fi
    fi
}

# Setup Flutter via FVM
setup_flutter() {
    log_step "Setting up Flutter via FVM"

    if [ "$SKIP_FLUTTER" = true ]; then
        log_info "Skipping Flutter setup (--skip-flutter flag)"
        return
    fi

    # Check if .fvmrc exists
    if [ ! -f ".fvmrc" ]; then
        log_error ".fvmrc file not found. Are you in the superdeck directory?"
        exit 1
    fi

    log_info "Installing Flutter SDK via FVM..."
    fvm install

    log_info "Setting Flutter version for this project..."
    fvm use stable --force

    # Verify Flutter installation
    if [ -d ".fvm/flutter_sdk" ]; then
        log_success "Flutter SDK configured at .fvm/flutter_sdk"
        .fvm/flutter_sdk/bin/flutter --version
    else
        log_warn "Flutter SDK not found at expected location"
    fi
}

# Install Dart global tools
install_dart_tools() {
    log_step "Installing Dart Global Tools"

    # Determine Flutter/Dart binary path
    local DART_BIN=""
    local FLUTTER_BIN=""

    if [ -d ".fvm/flutter_sdk" ]; then
        DART_BIN=".fvm/flutter_sdk/bin/dart"
        FLUTTER_BIN=".fvm/flutter_sdk/bin/flutter"
    elif command_exists dart; then
        DART_BIN="dart"
        FLUTTER_BIN="flutter"
    else
        log_error "No Dart SDK found. Please install Flutter first."
        exit 1
    fi

    # Install Melos
    log_info "Installing Melos (monorepo management)..."
    $DART_BIN pub global activate melos
    log_success "Melos installed"

    # Install DCM (Dart Code Metrics)
    log_info "Installing DCM (Dart Code Metrics)..."
    $DART_BIN pub global activate dart_code_metrics
    log_success "DCM installed"

    # Verify installations
    log_info "Verifying tool installations..."

    if command_exists melos || [ -f "$HOME/.pub-cache/bin/melos" ]; then
        log_success "Melos: $(melos --version 2>/dev/null || echo 'installed')"
    else
        log_warn "Melos may not be in PATH. Add ~/.pub-cache/bin to your PATH."
    fi

    if command_exists dcm || [ -f "$HOME/.pub-cache/bin/dcm" ]; then
        log_success "DCM: $(dcm --version 2>/dev/null || echo 'installed')"
    else
        log_warn "DCM may not be in PATH. Add ~/.pub-cache/bin to your PATH."
    fi
}

# Bootstrap the workspace with Melos
bootstrap_workspace() {
    log_step "Bootstrapping Workspace with Melos"

    # Add pub-cache to PATH for melos command
    export PATH="$HOME/.pub-cache/bin:$PATH"

    if ! command_exists melos; then
        log_error "Melos not found. Please ensure it's installed and in PATH."
        exit 1
    fi

    log_info "Running melos bootstrap..."
    melos bootstrap

    log_success "Workspace bootstrapped successfully"
}

# Run build_runner to generate code
run_build_runner() {
    log_step "Running Build Runner (Code Generation)"

    if [ "$SKIP_BUILD_RUNNER" = true ]; then
        log_info "Skipping build_runner (--skip-build-runner flag)"
        return
    fi

    export PATH="$HOME/.pub-cache/bin:$PATH"

    log_info "Generating code with build_runner..."
    melos run build_runner:build

    log_success "Code generation completed"
}

# Verify the setup
verify_setup() {
    log_step "Verifying Setup"

    local all_good=true

    # Check Flutter
    if [ -d ".fvm/flutter_sdk" ]; then
        log_success "Flutter SDK: .fvm/flutter_sdk"
    else
        log_warn "Flutter SDK not configured via FVM"
    fi

    # Check Melos
    if command_exists melos; then
        log_success "Melos: available"
    else
        log_warn "Melos: not in PATH"
        all_good=false
    fi

    # Check DCM
    if command_exists dcm; then
        log_success "DCM: available"
    else
        log_warn "DCM: not in PATH"
        all_good=false
    fi

    # Check if packages are bootstrapped
    if [ -f "packages/superdeck/pubspec.lock" ]; then
        log_success "Packages: bootstrapped"
    else
        log_warn "Packages: not bootstrapped"
        all_good=false
    fi

    if [ "$all_good" = true ]; then
        log_success "All verifications passed!"
    else
        log_warn "Some verifications failed. You may need to add ~/.pub-cache/bin to your PATH."
    fi
}

# Print available commands
print_available_commands() {
    log_step "Available Commands"

    echo "You can now use the following commands:"
    echo ""
    echo "  Analysis:"
    echo "    melos run analyze          - Run Dart analyzer and DCM"
    echo "    melos run analyze:all      - Run all analysis including unused code checks"
    echo "    melos run analyze:dart     - Run Dart static analysis only"
    echo "    melos run analyze:dcm      - Run DCM analysis only"
    echo ""
    echo "  Fixes:"
    echo "    melos run fix              - Apply Dart and DCM fixes"
    echo "    melos run fix:dart         - Apply Dart fixes only"
    echo "    melos run fix:dcm          - Apply DCM fixes only"
    echo ""
    echo "  Build & Code Generation:"
    echo "    melos run build_runner:build  - Generate code (one-time)"
    echo "    melos run build_runner:watch  - Generate code (watch mode)"
    echo "    melos run build_runner:clean  - Clean generated code"
    echo ""
    echo "  Testing:"
    echo "    melos run test             - Run all tests"
    echo "    melos run test:coverage    - Run tests with coverage"
    echo ""
    echo "  Other:"
    echo "    melos run clean            - Clean all packages"
    echo "    melos bootstrap            - Re-bootstrap dependencies"
    echo ""
}

# Main execution
main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                                            ║${NC}"
    echo -e "${BLUE}║              SuperDeck Development Environment Setup                       ║${NC}"
    echo -e "${BLUE}║                                                                            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ "$CI_MODE" = true ]; then
        log_info "Running in CI mode"
    fi

    check_prerequisites
    install_fvm
    setup_flutter
    install_dart_tools
    bootstrap_workspace

    if [ "$CI_MODE" = false ]; then
        run_build_runner
    else
        log_info "Skipping build_runner in CI mode (run separately if needed)"
    fi

    verify_setup

    if [ "$CI_MODE" = false ]; then
        print_available_commands
    fi

    echo ""
    log_success "Setup completed successfully!"
    echo ""

    if [ "$CI_MODE" = false ]; then
        echo "If tools are not found, add this to your shell profile:"
        echo ""
        echo '  export PATH="$HOME/.pub-cache/bin:$PATH"'
        echo ""
    fi
}

# Run main function
main
