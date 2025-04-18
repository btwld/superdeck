# Superdeck Builder Architecture

This document outlines the key components of the Superdeck Builder.

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