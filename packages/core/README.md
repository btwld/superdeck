# SuperDeck Core

Core library for SuperDeck - provides the foundational models, repositories, and utilities for building and managing deck data.

## Overview

The `superdeck_core` package contains the essential components that power SuperDeck presentations:

- **Models**: Data structures for slides, blocks, and presentation metadata
- **Repositories**: Interfaces and implementations for loading and managing deck data
- **Utilities**: Helper functions for file watching, JSON formatting, and more

## Key Components

### Models

- `Slide`: Represents a single slide with content sections and metadata
- `Block`: Base class for various content blocks (columns, images, widgets, etc.)
- `Deck`: Container for all slides and deck configuration
- `DeckConfiguration`: Configuration settings for the deck system

### Repositories

- `DeckRepository`: Unified repository using strategy pattern for platform-specific data access
- `DeckReader`: Abstract interface for reading deck data
- `LocalDeckReader`: File system-based implementation
- `AssetBundleDeckReader`: Flutter asset bundle implementation

### Utilities

- File watching capabilities for hot reload
- JSON pretty printing for readable output
- YAML utilities for configuration parsing
- Hash generation for content identification

## Usage

This package is typically used as a dependency by other SuperDeck packages:

```yaml
dependencies:
  superdeck_core: ^0.0.1
```

```dart
import 'package:superdeck_core/superdeck_core.dart';

// Create a configuration
final config = DeckConfiguration(
  projectDir: Directory.current.path,
  slidesPath: 'slides.md',
);

// Initialize a repository with local file system reader
final repository = DeckRepository(
  configuration: config,
  reader: DeckReader.local(configuration: config),
);
await repository.initialize();

// Load deck data
final deck = await repository.loadDeck();
```

## Architecture

The core package follows a clean architecture pattern:

1. **Models** define the data structures
2. **Repositories** provide data access abstractions
3. **Utilities** offer cross-cutting functionality

This separation ensures the core logic remains independent of specific UI frameworks or build tools.

## Contributing

See the main [SuperDeck repository](https://github.com/leoafarias/superdeck) for contribution guidelines.