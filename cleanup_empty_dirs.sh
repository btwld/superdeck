#!/bin/bash

# Script to remove empty directories in superdeck_builder

echo "Removing empty directories in superdeck_builder..."

# Remove the empty assets directory
rm -rf packages/superdeck_builder/lib/src/assets

# Remove the nested packages structure
rm -rf packages/superdeck_builder/packages

echo "Empty directories removed successfully." 