#!/bin/bash

# Script to restructure the superdeck_core package based on TASK-001.md

# Define the base directory for superdeck_core
CORE_PKG_DIR="packages/superdeck_core/lib"
SRC_DIR="$CORE_PKG_DIR/src" # Updated base for new structure

# Ensure the script exits if any command fails
set -e

echo "Starting superdeck_core restructuring..."

# --- Create new directory structure ---
echo "Creating new directories..."
mkdir -p "$SRC_DIR/presentation"
mkdir -p "$SRC_DIR/blocks"
mkdir -p "$SRC_DIR/assets"
mkdir -p "$SRC_DIR/common"
echo "Directory structure created."

# --- Move and rename files ---
echo "Moving and renaming files..."

# Function to safely move files
move_file() {
  local src_rel=$1
  local dest_rel=$2
  local src_abs="$CORE_PKG_DIR/$src_rel"
  local dest_abs="$SRC_DIR/$dest_rel"
  local dest_dir=$(dirname "$dest_abs")

  if [ -f "$src_abs" ]; then
    echo "Moving '$src_rel' to '$dest_rel'"
    # Ensure destination directory exists just in case
    mkdir -p "$dest_dir"
    mv "$src_abs" "$dest_abs"
  else
    echo "WARNING: Source file not found: '$src_abs'. Skipping."
  fi
}

# Mappings from TASK-001.md
move_file "src/models/slide_element.dart" "blocks/block.dart"
move_file "src/models/slide_model.dart" "presentation/slide.dart"
move_file "src/models/deck_reference.dart" "presentation/presentation.dart"
move_file "src/models/asset_model.dart" "assets/asset.dart"
move_file "src/models/asset_source.dart" "assets/source.dart"
move_file "src/storage/asset_storage.dart" "assets/storage.dart"
move_file "src/helpers/generate_hash.dart" "common/hash.dart"
move_file "src/helpers/uuid_v4.dart" "common/uuid.dart"
move_file "src/helpers/extensions.dart" "common/extensions.dart"

# Note: presentation/parser.dart is a new file, not moved.

echo "File moving and renaming complete."

# --- Cleanup potential old directories if empty ---
# Be cautious with automated deletion. We'll list potential candidates.
echo "Checking for potentially empty old directories..."
# If src/models, src/storage, src/helpers are now empty, they could be removed.
# Example check (manual deletion recommended after verification):
find "$CORE_PKG_DIR/src/models" "$CORE_PKG_DIR/src/storage" "$CORE_PKG_DIR/src/helpers" -maxdepth 0 -type d -empty -print

echo "-----------------------------------------------------"
echo "Restructuring script finished."
echo "Manual Steps Recommended:"
echo "1. Verify the new structure in '$SRC_DIR'."
echo "2. Manually remove any old directories if they are confirmed empty (e.g., 'src/models', 'src/storage', 'src/helpers')."
echo "3. Update the main barrel file '$CORE_PKG_DIR/superdeck_core.dart' to export from the new locations."
echo "4. Update all import statements across the entire project that reference these moved files."
echo "5. Address the class renames specified in TASK-001.md within the moved files (e.g., SlideElement -> Block)."
echo "6. Create the new file 'presentation/parser.dart'."
echo "7. Run tests and verify functionality."
echo "-----------------------------------------------------" 