#!/bin/bash

# Script to implement the structure changes outlined in superdeck_builder_structure_alignment.md

echo "Starting implementation of structure changes for superdeck_builder..."

# Change to the project directory
cd /Users/leofarias/Projects/superdeck/packages/superdeck_builder || exit 1

# Step 0: Create a backup
echo "Creating backup..."
mkdir -p backup/lib
cp -r lib backup/

# Step 1: Create missing extension files
echo "Creating missing extension files..."

# Create common/extensions.dart
cat > lib/src/common/extensions.dart << 'EOF'
/// Common extension methods used throughout the package.
///
/// This file contains extension methods that are used in multiple places
/// across the package.

// String extensions
extension StringExtensions on String {
  /// Converts the first character to uppercase and leaves the rest unchanged.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Checks if the string is a valid Dart identifier.
  bool get isDartIdentifier {
    if (isEmpty) return false;
    final regex = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');
    return regex.hasMatch(this);
  }
}

// List extensions
extension ListExtensions<T> on List<T> {
  /// Returns a new list with unique elements.
  List<T> get unique => [...{...this}];
}

// Map extensions
extension MapExtensions<K, V> on Map<K, V> {
  /// Returns a new map with entries filtered by the given predicate.
  Map<K, V> where(bool Function(K key, V value) predicate) {
    return Map.fromEntries(
      entries.where((entry) => predicate(entry.key, entry.value)),
    );
  }
}
EOF

# Create services/service_extensions.dart
mkdir -p lib/src/services
cat > lib/src/services/service_extensions.dart << 'EOF'
/// Extensions for services.
///
/// This file contains extension methods for service classes.

import 'dart:async';
import 'browser_service.dart';

/// Extension for [BrowserService].
extension BrowserServiceExtensions on BrowserService {
  /// Waits for a page to load with a timeout.
  Future<void> waitForPageLoadWithTimeout(Duration timeout) async {
    final completer = Completer<void>();
    Timer? timer;
    
    // Set up a timeout
    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Page load timed out after ${timeout.inSeconds} seconds'),
        );
      }
    });
    
    try {
      // Wait for page load
      await waitForPageLoad();
      if (!completer.isCompleted) {
        completer.complete();
      }
    } finally {
      timer?.cancel();
    }
    
    return completer.future;
  }
}
EOF

# Create services/filesystem_service.dart
cat > lib/src/services/filesystem_service.dart << 'EOF'
/// Service for filesystem operations.
///
/// This service provides an abstraction for filesystem operations.

import 'dart:io';
import 'package:path/path.dart' as path;

import 'disposable.dart';

/// Service for filesystem operations.
class FilesystemService implements Disposable {
  /// Creates a new instance of [FilesystemService].
  const FilesystemService();

  /// Reads a file as a string.
  Future<String> readFileAsString(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    return await file.readAsString();
  }

  /// Writes a string to a file.
  Future<File> writeStringToFile(String filePath, String content) async {
    final file = File(filePath);
    return await file.writeAsString(content);
  }

  /// Creates a directory if it doesn't exist.
  Future<Directory> ensureDirectoryExists(String dirPath) async {
    final directory = Directory(dirPath);
    if (await directory.exists()) {
      return directory;
    }
    return await directory.create(recursive: true);
  }

  /// Lists files in a directory.
  Future<List<FileSystemEntity>> listDirectory(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      throw FileSystemException('Directory not found', dirPath);
    }
    return await directory.list().toList();
  }

  /// Checks if a file exists.
  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Gets a temporary directory.
  Future<Directory> getTemporaryDirectory() async {
    return await Directory.systemTemp.createTemp('superdeck_');
  }

  /// Deletes a file.
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Joins path segments.
  String joinPaths(List<String> segments) {
    return path.joinAll(segments);
  }
  
  @override
  Future<void> dispose() async {
    // No resources to clean up
  }
}
EOF

# Step 2: Restructure tasks directory
echo "Restructuring tasks directory..."

# Create tasks/task_extensions.dart before moving files
mkdir -p lib/src/tasks
cat > lib/src/tasks/task_extensions.dart << 'EOF'
/// Extensions for tasks.
///
/// This file contains extension methods for tasks.

import 'dart:async';
import 'task.dart';

/// Extension for [Task].
extension TaskExtensions on Task {
  /// Executes the task with timing information.
  Future<void> executeWithTiming(dynamic context) async {
    final stopwatch = Stopwatch()..start();
    await run(context);
    stopwatch.stop();
    
    logger.fine('Task ${name} completed in ${stopwatch.elapsedMilliseconds}ms');
  }
  
  /// Wraps this task with another task that will be executed after this one.
  Task then(Task nextTask) {
    return _ChainedTask(this, nextTask);
  }
}

/// A task that chains two tasks together.
class _ChainedTask implements Task {
  final Task first;
  final Task second;
  
  _ChainedTask(this.first, this.second);
  
  @override
  String get name => "${first.name} → ${second.name}";
  
  @override
  dynamic get logger => first.logger;
  
  @override
  FutureOr<void> run(dynamic context) async {
    await first.run(context);
    await second.run(context);
  }
  
  @override
  FutureOr<void> dispose() async {
    await first.dispose();
    await second.dispose();
  }
}
EOF

# Now move task files to their new locations
# Copy task.dart from base directory to tasks directory
cp lib/src/tasks/base/task.dart lib/src/tasks/

# Copy dart_formatter_task.dart from formatting directory to tasks directory
cp lib/src/tasks/formatting/dart_formatter_task.dart lib/src/tasks/

# Copy mermaid_task.dart from generation directory to tasks directory
cp lib/src/tasks/generation/mermaid_task.dart lib/src/tasks/

# Step 3: Update imports in the moved files
echo "Updating imports in moved files..."

# Update imports in task.dart - no changes needed as it's already referencing pipeline correctly

# Update imports in dart_formatter_task.dart
sed -i '' 's|../../parsers/fenced_code_parser.dart|../parsers/fenced_code_parser.dart|g' lib/src/tasks/dart_formatter_task.dart
sed -i '' 's|../../pipeline/builder_context.dart|../pipeline/builder_context.dart|g' lib/src/tasks/dart_formatter_task.dart
sed -i '' 's|../../utils/process_utils.dart|../utils/process_utils.dart|g' lib/src/tasks/dart_formatter_task.dart
sed -i '' 's|../base/task.dart|task.dart|g' lib/src/tasks/dart_formatter_task.dart

# Update imports in mermaid_task.dart
sed -i '' 's|../../parsers/fenced_code_parser.dart|../parsers/fenced_code_parser.dart|g' lib/src/tasks/mermaid_task.dart
sed -i '' 's|../../pipeline/builder_context.dart|../pipeline/builder_context.dart|g' lib/src/tasks/mermaid_task.dart
sed -i '' 's|../../services/browser_service.dart|../services/browser_service.dart|g' lib/src/tasks/mermaid_task.dart
sed -i '' 's|../base/task.dart|task.dart|g' lib/src/tasks/mermaid_task.dart

# Step 4: Update builder_pipeline.dart to reference the new task location
sed -i '' 's|../tasks/base/task.dart|../tasks/task.dart|g' lib/src/pipeline/builder_pipeline.dart

# Optional: Rename builder_context_extensions.dart to builder_extensions.dart
# Uncomment the following lines if you decide to do this rename
# cp lib/src/pipeline/builder_context_extensions.dart lib/src/pipeline/builder_extensions.dart
# sed -i '' 's|builder_context_extensions.dart|builder_extensions.dart|g' lib/src/pipeline/*.dart
# sed -i '' 's|builder_context_extensions.dart|builder_extensions.dart|g' lib/src/tasks/*.dart

echo "Structure changes implementation complete."
echo "Please run 'dart analyze' and 'dart test' to verify everything works."
echo ""
echo "Note: The old directory structure and files still exist alongside the new ones."
echo "After confirming everything works, you may want to delete:"
echo "  - lib/src/tasks/base/"
echo "  - lib/src/tasks/formatting/"
echo "  - lib/src/tasks/generation/"
echo ""
echo "You may also want to update any other files in the project that import from these locations." 