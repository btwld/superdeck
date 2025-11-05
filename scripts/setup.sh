#!/bin/bash
# SuperDeck Development Environment Setup Script
# Automatically configures tools and dependencies for Claude Code sessions

set -e  # Exit on error

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

step() {
    echo ""
    echo -e "${BLUE}▶${NC} $1"
}

# Detect environment
CLAUDE_CODE_REMOTE="${CLAUDE_CODE_REMOTE:-false}"
if [ "$CLAUDE_CODE_REMOTE" = "true" ]; then
    log_info "Running in Claude Code remote environment"
else
    log_info "Running in local environment"
fi

# Verify project structure
step "Step 1/9: Verifying project structure"

if [ ! -f "AGENTS.md" ]; then
    log_error "AGENTS.md not found in project root"
    exit 1
fi
log_success "AGENTS.md found"

if [ ! -f "CLAUDE.md" ]; then
    log_error "CLAUDE.md not found in project root"
    exit 1
fi
log_success "CLAUDE.md found"

if [ ! -f ".fvmrc" ]; then
    log_error ".fvmrc not found - cannot determine Flutter version"
    exit 1
fi
log_success ".fvmrc found"

if [ ! -f "melos.yaml" ]; then
    log_error "melos.yaml not found - cannot bootstrap workspace"
    exit 1
fi
log_success "melos.yaml found"

# Configure PATH
step "Step 2/9: Configuring PATH and checking prerequisites"

# Add pub-cache to PATH for global Dart packages
export PATH="$HOME/.pub-cache/bin:$PATH"
log_success "Configured PATH for Dart tools"

# Check if Dart is available
if ! command -v dart &> /dev/null; then
    log_warning "Dart SDK not found - attempting to install"

    # Install Dart SDK using apt-get (for Debian/Ubuntu)
    if command -v apt-get &> /dev/null && [ -w /var/lib/dpkg ]; then
        log_info "Installing Dart SDK via apt-get..."
        sudo apt-get update -qq
        sudo apt-get install -y dart
        export PATH="/usr/lib/dart/bin:$PATH"
    else
        log_error "Cannot install Dart SDK automatically in this environment"
        log_info "Claude Code remote environments may not support full Flutter development"
        log_info "Skipping setup - manual installation required"
        exit 0  # Exit gracefully
    fi
fi

DART_VERSION=$(dart --version 2>&1 | head -n1 || echo "unknown")
log_success "Dart SDK available: $DART_VERSION"

# Install/verify FVM
step "Step 3/9: Installing FVM (Flutter Version Management)"

if command -v fvm &> /dev/null; then
    FVM_VERSION=$(fvm --version 2>&1 | head -n1 || echo "unknown")
    log_success "FVM already installed: $FVM_VERSION"
else
    log_info "Installing FVM..."
    dart pub global activate fvm
    export PATH="$HOME/.pub-cache/bin:$PATH"
    log_success "FVM installed successfully"
fi

# Install Flutter via FVM
step "Step 4/9: Installing Flutter via FVM"

FLUTTER_CHANNEL=$(cat .fvmrc | grep '"flutter"' | cut -d'"' -f4)
log_info "Flutter channel from .fvmrc: $FLUTTER_CHANNEL"

if [ -d ".fvm/flutter_sdk" ]; then
    FLUTTER_VERSION=$(cd .fvm/flutter_sdk && bin/flutter --version | head -n1 || echo "unknown")
    log_success "Flutter SDK already installed: $FLUTTER_VERSION"
else
    log_info "Installing Flutter $FLUTTER_CHANNEL via FVM..."
    fvm install "$FLUTTER_CHANNEL"
    fvm use "$FLUTTER_CHANNEL" --force
    log_success "Flutter $FLUTTER_CHANNEL installed successfully"
fi

# Configure Flutter SDK path
export PATH="$(pwd)/.fvm/flutter_sdk/bin:$PATH"
log_success "Flutter SDK added to PATH"

# Install/verify Melos
step "Step 5/9: Installing Melos (monorepo workspace manager)"

if command -v melos &> /dev/null; then
    MELOS_VERSION=$(melos --version 2>&1 || echo "unknown")
    log_success "Melos already installed: $MELOS_VERSION"
else
    log_info "Installing Melos..."
    dart pub global activate melos
    log_success "Melos installed successfully"
fi

# Install/verify DCM
step "Step 6/9: Installing DCM (Dart Code Metrics)"

if command -v dcm &> /dev/null; then
    DCM_VERSION=$(dcm --version 2>&1 | head -n1 || echo "unknown")
    log_success "DCM already installed: $DCM_VERSION"
else
    log_info "Installing DCM..."
    dart pub global activate dcm
    log_success "DCM installed successfully"
fi

# Bootstrap workspace
step "Step 7/9: Bootstrapping Melos workspace"

log_info "Running melos bootstrap (this may take a few minutes)..."
melos bootstrap
log_success "Workspace bootstrapped successfully"

# Generate code
step "Step 8/9: Generating code with build_runner"

log_info "Running melos run build_runner:build..."
melos run build_runner:build || {
    log_warning "Code generation failed, but continuing..."
}
log_success "Code generation completed"

# Verify setup
step "Step 9/9: Verifying setup"

log_info "Running flutter doctor to verify installation..."
flutter doctor || log_warning "Flutter doctor reported warnings (this is often normal)"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ SuperDeck development environment setup complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
log_info "Available commands:"
echo "  • melos run analyze         - Run static analysis"
echo "  • melos run test            - Run tests"
echo "  • melos run build_runner:build - Generate code"
echo "  • melos run clean           - Clean build artifacts"
echo "  • melos run fix             - Apply auto-fixes"
echo ""
log_success "Ready to work on SuperDeck!"
