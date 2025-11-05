#!/bin/bash
# Setup script for SuperDeck
# Compatible with both local and Claude Code remote environments

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

# ANSI color codes for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Logging functions
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
  exit 1
}

log_step() {
  echo ""
  echo -e "${BLUE}▶${NC} ${GREEN}$1${NC}"
  echo "─────────────────────────────────────────────────"
}

# Detect environment
detect_environment() {
  if [ "${CLAUDE_CODE_REMOTE:-false}" = "true" ]; then
    log_info "Environment: Claude Code Remote"
    export IS_REMOTE=true
  else
    log_info "Environment: Local"
    export IS_REMOTE=false
  fi
}

# Setup Claude Code memory symlink
setup_claude_memory() {
  log_step "Setting up Claude Code memory"

  if [ ! -f "AGENTS.md" ]; then
    log_warning "AGENTS.md not found, skipping symlink creation"
    return 0
  fi

  # Remove existing CLAUDE.local.md if it's a regular file
  if [ -f "CLAUDE.local.md" ] && [ ! -L "CLAUDE.local.md" ]; then
    log_info "Removing existing CLAUDE.local.md file"
    rm "CLAUDE.local.md"
  fi

  # Create symlink if it doesn't exist
  if [ ! -e "CLAUDE.local.md" ]; then
    log_info "Creating symlink: CLAUDE.local.md -> AGENTS.md"
    ln -s AGENTS.md CLAUDE.local.md
    log_success "Symlink created successfully"
  else
    log_info "CLAUDE.local.md already exists"
  fi

  # Verify the symlink
  if [ -L "CLAUDE.local.md" ]; then
    local target=$(readlink CLAUDE.local.md)
    log_success "CLAUDE.local.md -> $target"
  fi
}

# Setup PATH for Dart/Flutter tools
setup_path() {
  log_step "Setting up environment PATH"

  # Add Dart/Flutter global bins
  export PATH="$HOME/.pub-cache/bin:$PATH"

  # Add FVM Flutter SDK to PATH (if exists)
  if [ -d ".fvm/flutter_sdk" ]; then
    export PATH="$(pwd)/.fvm/flutter_sdk/bin:$PATH"
    log_success "FVM Flutter SDK added to PATH"
  fi

  # Add local bin paths
  export PATH="$HOME/.local/bin:$PATH"

  log_success "PATH configured"
}

# Install and configure FVM
setup_fvm() {
  log_step "Setting up FVM (Flutter Version Management)"

  # Check if dart is available
  if ! command -v dart &> /dev/null; then
    log_warning "Dart not found in PATH. FVM setup will be skipped."
    log_info "Please ensure Flutter/Dart is installed in your environment."
    return 0
  fi

  # Install FVM if not already installed
  if ! command -v fvm &> /dev/null; then
    log_info "Installing FVM globally..."
    dart pub global activate fvm

    # Add to PATH if not already there
    export PATH="$HOME/.pub-cache/bin:$PATH"
  else
    log_info "FVM already installed"
  fi

  # Use stable Flutter version as per AGENTS.md guidelines
  log_info "Configuring Flutter stable via FVM..."
  if [ "$IS_REMOTE" = "true" ]; then
    # In remote environments, just use the installed Flutter
    log_info "Remote environment: using pre-installed Flutter"
  else
    # Local environment: install and use stable
    fvm install stable || log_warning "FVM install failed, continuing..."
    fvm use stable --force || log_warning "FVM use failed, continuing..."
  fi

  log_success "FVM setup complete"
}

# Install and configure Melos
setup_melos() {
  log_step "Setting up Melos (Monorepo Management)"

  # Check if dart is available
  if ! command -v dart &> /dev/null; then
    log_warning "Dart not found. Melos setup will be skipped."
    return 0
  fi

  # Install Melos if not already installed
  if ! command -v melos &> /dev/null; then
    log_info "Installing Melos globally..."
    dart pub global activate melos

    # Add to PATH if not already there
    export PATH="$HOME/.pub-cache/bin:$PATH"
  else
    log_info "Melos already installed"
  fi

  # Install DCM (Dart Code Metrics) if not already installed
  if ! command -v dcm &> /dev/null; then
    log_info "Installing DCM (Dart Code Metrics)..."
    dart pub global activate dcm || log_warning "DCM installation failed, continuing..."
  else
    log_info "DCM already installed"
  fi

  # Bootstrap the Melos workspace
  log_info "Bootstrapping Melos workspace..."
  if command -v melos &> /dev/null; then
    melos bootstrap || log_warning "Melos bootstrap failed, continuing..."
    log_success "Melos workspace bootstrapped"
  else
    log_warning "Melos command not found after installation, skipping bootstrap"
  fi
}

# Run build_runner to generate code
generate_code() {
  log_step "Generating code with build_runner"

  if ! command -v melos &> /dev/null; then
    log_warning "Melos not available, skipping code generation"
    return 0
  fi

  log_info "Running build_runner:build..."
  melos run build_runner:build || log_warning "Code generation failed, continuing..."

  log_success "Code generation complete"
}

# Run static analysis
run_analysis() {
  log_step "Running static analysis"

  if ! command -v melos &> /dev/null; then
    log_warning "Melos not available, skipping analysis"
    return 0
  fi

  log_info "Running dart analyze and DCM..."
  melos run analyze || log_warning "Analysis found issues, continuing..."

  log_success "Analysis complete"
}

# Display available commands
show_commands() {
  log_step "Available Melos Commands"

  echo "  Build & Generate:"
  echo "    • melos run build_runner:build   → Generate code once"
  echo "    • melos run build_runner:watch   → Watch and regenerate"
  echo ""
  echo "  Analysis & Quality:"
  echo "    • melos run analyze              → Run dart analyze + DCM"
  echo "    • melos run custom_lint_analyze  → Run custom lint rules"
  echo "    • melos run fix                  → Apply auto-fixes"
  echo ""
  echo "  Testing:"
  echo "    • melos run test                 → Run all tests"
  echo "    • melos run test:coverage        → Run with coverage"
  echo ""
  echo "  Maintenance:"
  echo "    • melos run clean                → Clean build artifacts"
  echo "    • melos bootstrap                → Re-bootstrap workspace"
}

# Verify setup
verify_setup() {
  log_step "Verifying setup"

  local issues=0

  # Check for CLAUDE.local.md symlink
  if [ -L "CLAUDE.local.md" ]; then
    log_success "CLAUDE.local.md symlink exists"
  else
    log_warning "CLAUDE.local.md symlink not found"
    issues=$((issues + 1))
  fi

  # Check if dart is available
  if command -v dart &> /dev/null; then
    local dart_version=$(dart --version 2>&1 | head -n1)
    log_success "Dart: $dart_version"
  else
    log_warning "Dart not found in PATH"
    issues=$((issues + 1))
  fi

  # Check if flutter is available
  if command -v flutter &> /dev/null; then
    local flutter_version=$(flutter --version 2>&1 | head -n1)
    log_success "Flutter: $flutter_version"
  else
    log_warning "Flutter not found in PATH"
    issues=$((issues + 1))
  fi

  # Check if melos is available
  if command -v melos &> /dev/null; then
    local melos_version=$(melos --version 2>&1)
    log_success "Melos: $melos_version"
  else
    log_warning "Melos not found in PATH"
    issues=$((issues + 1))
  fi

  # Check if DCM is available
  if command -v dcm &> /dev/null; then
    local dcm_version=$(dcm --version 2>&1 | head -n1)
    log_success "DCM: $dcm_version"
  else
    log_warning "DCM not found in PATH"
    issues=$((issues + 1))
  fi

  if [ $issues -eq 0 ]; then
    log_success "All checks passed!"
  else
    log_warning "$issues issue(s) found, but setup will continue"
  fi
}

# Main setup flow
main() {
  echo ""
  echo "════════════════════════════════════════════════"
  echo "  SuperDeck Flutter/Melos Workspace Setup"
  echo "════════════════════════════════════════════════"
  echo ""

  detect_environment
  setup_claude_memory
  setup_path
  setup_fvm
  setup_melos
  generate_code

  # Skip analysis in remote environments to speed up setup
  if [ "$IS_REMOTE" = "false" ]; then
    run_analysis
  else
    log_info "Skipping analysis in remote environment"
  fi

  verify_setup
  show_commands

  echo ""
  echo "════════════════════════════════════════════════"
  echo -e "  ${GREEN}✓ SuperDeck Setup Complete!${NC}"
  echo "════════════════════════════════════════════════"
  echo ""
  echo "The workspace is ready for development! 🚀"
  echo ""
  echo "Architecture context loaded via CLAUDE.local.md"
  echo "See AGENTS.md for project guidelines and structure"
  echo ""
}

# Run main function
main

exit 0
