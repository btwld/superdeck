# Superdeck Builder Structure Alignment Task

## Current Structure vs. Target Structure

The current structure of `superdeck_builder` mostly follows the target pattern but has some differences. This task outlines the necessary changes to fully align with the target structure.

### Target Directory Structure
```
lib/
  ├── common/                     # Common utilities
  │   ├── exceptions.dart         # Shared exceptions
  │   ├── extensions.dart         # Common extension methods
  │   ├── constants.dart          # Package-wide constants
  │   └── utils/                  # Utility functions
  │
  ├── pipeline/                   # Core pipeline functionality
  │   ├── builder_pipeline.dart   # Main orchestrator
  │   ├── builder_context.dart    # Execution context
  │   └── builder_extensions.dart # Extensions for pipeline components
  │
  ├── parsers/                    # Content parsing features
  │   ├── block_parser.dart       # Block parsing
  │   ├── section_parser.dart     # Section parsing 
  │   ├── markdown_parser.dart    # Markdown document parsing
  │   ├── comment_parser.dart     # Comment extraction
  │   └── parser_extensions.dart  # Extensions for parsers
  │
  ├── tasks/                      # Processing tasks
  │   ├── task.dart              # Base task interface
  │   ├── dart_formatter_task.dart # Dart code formatting
  │   ├── mermaid_task.dart       # Mermaid diagram generation
  │   └── task_extensions.dart    # Extensions for tasks
  │
  ├── services/                   # External services
  │   ├── browser_service.dart    # Browser interaction
  │   ├── filesystem_service.dart # File system operations 
  │   └── service_extensions.dart # Extensions for services
  │
  └── superdeck_builder.dart      # Package entry point
```

## Required Changes

### 1. Common Directory
- [x] `constants.dart` and `exceptions.dart` already exist
- [ ] **ACTION**: Create `extensions.dart` with common extension methods

### 2. Pipeline Directory 
- [x] `builder_pipeline.dart` and `builder_context.dart` already exist
- [x] `builder_context_extensions.dart` exists (similar to the target's `builder_extensions.dart`)
- [ ] **ACTION**: Consider renaming `builder_context_extensions.dart` to `builder_extensions.dart` for consistency

### 3. Parsers Directory
- [x] All required files exist
- [x] `parser_extensions.dart` exists
- [ ] **NO ACTION NEEDED**

### 4. Tasks Directory
- [ ] Current structure has tasks organized in subdirectories:
  - `base/task.dart`
  - `formatting/dart_formatter_task.dart`
  - `generation/mermaid_task.dart`
- [ ] **ACTION**: Restructure to have files directly in the tasks directory:
  - Move `base/task.dart` to `tasks/task.dart`
  - Move `formatting/dart_formatter_task.dart` to `tasks/dart_formatter_task.dart`
  - Move `generation/mermaid_task.dart` to `tasks/mermaid_task.dart`
  - Create `tasks/task_extensions.dart`
  - Update imports in all affected files

### 5. Services Directory
- [x] `browser_service.dart` exists
- [ ] **ACTION**: Create `filesystem_service.dart` with file system operations
- [ ] **ACTION**: Create `service_extensions.dart` with extensions for services

## Implementation Steps

1. Create missing extension files:
   - Create `common/extensions.dart`
   - Create `tasks/task_extensions.dart`
   - Create `services/service_extensions.dart`

2. Create missing service file:
   - Create `services/filesystem_service.dart`

3. Restructure tasks directory:
   - Move task files to match the target structure
   - Update all import references

4. Consider renaming `builder_context_extensions.dart` to `builder_extensions.dart`

5. Run tests after each change to ensure nothing breaks

## Notes

- Before restructuring, ensure a proper backup of the current structure
- Some imports might need to be updated after moving files
- Remember to run `dart analyze` and `dart test` after making changes to verify everything still works 