# SuperDeck Builder Package

This package is responsible for transforming markdown content into structured presentation slides.

## Proposed Feature-Based Structure

```
lib/
  ├── src/
  │   ├── pipeline/              # Core pipeline functionality
  │   │   ├── builder_pipeline.dart    # Main pipeline execution
  │   │   ├── builder_context.dart     # Context for processing slides
  │   │   ├── builder_exception.dart   # Builder-specific exceptions
  │   │   └── builder_metrics.dart     # Metrics collection
  │   │
  │   ├── tasks/                 # Task execution modules
  │   │   ├── base/              # Base task abstractions
  │   │   │   ├── task.dart            # Task interface
  │   │   │   └── task_result.dart     # Task execution results
  │   │   │
  │   │   ├── formatting/        # Code formatting tasks
  │   │   │   └── dart_formatter_task.dart
  │   │   │
  │   │   ├── generation/        # Content generation tasks
  │   │   │   └── mermaid_task.dart
  │   │   │
  │   │   └── caching/           # Asset caching tasks
  │   │       └── image_caching_task.dart
  │   │
  │   ├── parsers/               # Content parsing modules
  │   │   ├── base/              # Base parser abstractions
  │   │   │   └── base_parser.dart
  │   │   │
  │   │   ├── block/             # Block-related parsers
  │   │   │   ├── block_parser.dart
  │   │   │   └── section_parser.dart
  │   │   │
  │   │   ├── content/           # Content-related parsers
  │   │   │   ├── markdown_parser.dart
  │   │   │   └── comment_parser.dart
  │   │   │
  │   │   └── metadata/          # Metadata parsing
  │   │       └── front_matter_parser.dart
  │   │
  │   ├── services/              # Supporting services
  │   │   └── filesystem_service.dart
  │   │
  │   └── utils/                 # Utility functions and helpers
  │       ├── yaml_utils.dart
  │       └── string_utils.dart
  │
  └── superdeck_builder.dart     # Main library exports
```

## Migration Strategy

1. First refactor the directory structure while maintaining existing functionality
2. Then update class names for consistency (TaskPipeline → BuilderPipeline)
3. Add extension methods following the same pattern as the core package
4. Update tests to match the new structure

## Design Principles

- Feature-based organization with clear module boundaries
- Consistent naming conventions across packages
- Strong typing with explicit relationships between models
- Comprehensive testing of all components

## Core Components

### Task Pipeline

The `TaskPipeline` orchestrates the processing of slides through a sequence of tasks. Each task performs a specific operation on the slides, such as parsing, formatting, or generating assets.

### Asset Management

Assets in Superdeck are managed through several integrated components:

1. **FileSystemPresentationRepository**:
   - Tracks assets through the `getAssetPath` method
   - Creates asset manifests via `saveReferences`
   - Handles asset cleanup with `_cleanupAssets`

2. **AssetRepository**:
   - Defined in superdeck_core
   - Provides interfaces for asset storage operations
   - Implementations for different platforms (filesystem, memory, etc.)

3. **Specialized Asset Tasks**:
   - `MermaidConverterTask`: Generates and manages Mermaid diagram assets
   - Task-specific asset cleanup through the `CleanupCapableTask` interface

## Processing Flow

1. Markdown content is loaded from the repository
2. Raw slides are parsed from the markdown
3. Each slide is processed through all registered tasks
4. Tasks may generate or reference assets during processing
5. The presentation repository creates an asset manifest of all referenced assets
6. Unused assets are cleaned up
7. The processed slides are saved back to the repository

## Task Implementation

Tasks should implement the `Task` interface and can optionally implement the `CleanupCapableTask` interface if they need to clean up resources after processing. 