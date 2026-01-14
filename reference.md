# Reference Code Analysis

## Context

**Language**: Dart >=3.9.0, Flutter >=3.35.0
**Framework**: Flutter presentation framework (custom), uses mix/remix for styling, signals for state
**Type**: Library + CLI tool (Melos monorepo)

## Domain

**Purpose**: Render presentation slides written in Markdown as a Flutter application

**Core entities**:
- Deck: A complete presentation containing slides
- Slide: A single presentation slide containing blocks and sections
- Block: A content unit within a slide (@column, @image, @code, @mermaid, @widget)
- Asset: Generated resources (thumbnails, mermaid diagrams)
- Style: Visual configuration for slides and blocks

**Key actions**:
- Parse: Convert markdown with YAML front-matter into structured slide data
- Build: Process slides.md into generated assets and configuration
- Render: Display slides as Flutter widgets
- Navigate: Move between slides with keyboard/gestures
- Export: Generate PDF from slides

## Architecture

**Entry points**:
- `packages/superdeck/lib/superdeck.dart` - Main Flutter library
- `packages/cli/bin/main.dart` - CLI executable
- `packages/core/lib/superdeck_core.dart` - Core library (Dart-only)
- `packages/builder/lib/superdeck_builder.dart` - Build pipeline

**Layer structure**:
```
superdeck (Flutter UI)
    ↓
superdeck_core (Dart-only models, parsing, validation)
    ↓
superdeck_builder (build pipeline, asset generation)
    ↓
superdeck_cli (CLI commands)
```

**Key modules**:
- `core/src/models/` - Domain models (DeckModel, SlideModel, BlockModel, AssetModel)
- `core/src/deck_service.dart` - Deck loading and persistence
- `core/src/deck_configuration.dart` - Configuration schemas
- `superdeck/src/deck/` - DeckController, navigation, state management
- `superdeck/src/rendering/` - Slide and block rendering widgets
- `superdeck/src/styling/` - Style schemas and components
- `superdeck/src/markdown/` - Markdown element builders
- `builder/src/parsers/` - Markdown and YAML parsing
- `builder/src/tasks/` - Build tasks
- `cli/src/commands/` - CLI commands

## Conventions Detected

- Naming: snake_case for files, PascalCase for classes, camelCase for members
- Errors: Custom exceptions (DeckFormatException, TaskException)
- State: Signals-based reactive state (Signal<T>, Computed<T>)
- Styling: mix/remix framework (Spec, Style patterns)
- Validation: ack library for schema validation
- Structure: src/ with subdirectories by concern

---

## Findings

### Scan Summary

The codebase is in **excellent shape** overall. The scan found:

- **No TODO/FIXME/HACK comments** - Zero debt markers
- **No commented-out code** - Clean codebase
- **No obvious over-engineering** - Abstractions serve clear purposes
- **Consistent naming conventions** - snake_case files, PascalCase classes
- **Cohesive utils directories** - Each file focuses on one concern
- **Mostly consistent error handling** - Custom exceptions used appropriately

### Finding 1: Re-export of third-party library

**Signal type**: Consistency (minor)
**Found at**: `packages/core/lib/superdeck_core.dart:3`
**Initial observation**: `export 'package:ack/ack.dart';` re-exports the entire ack library

**Questions & Research**:

| # | Question | Research Method | Answer |
|---|----------|-----------------|--------|
| 1 | Is ack used throughout the codebase? | Grep for imports | Yes, 7 files import ack |
| 2 | Do consumers need ack directly? | Check usage patterns | Yes, for schema validation in custom widgets |
| 3 | Is this a documented pattern in Dart? | Check Dart guidelines | Acceptable for convenience APIs |
| 4 | Does it cause issues? | Check for conflicts | No conflicts found |

**Decision**: Keep — This is intentional convenience for consumers who need schema validation. The WidgetDefinition pattern requires ack schemas for argument validation.

**Action**: None needed

---

### Finding 2: Mixed exception types

**Signal type**: Consistency (minor)
**Found at**: Various locations
**Initial observation**: Some code throws generic `Exception` while others use typed exceptions

**Questions & Research**:

| # | Question | Research Method | Answer |
|---|----------|-----------------|--------|
| 1 | What typed exceptions exist? | Grep | DeckFormatException, TaskException, FileSystemException |
| 2 | Where is generic Exception used? | Grep | ~15 locations, mostly error wrapping |
| 3 | Are these appropriate? | Code review | Most are internal errors or error wrapping |
| 4 | Should they be typed? | Analysis | Low value - these are edge cases |

**Decision**: Keep — The generic exceptions are used for:
1. Error wrapping (preserving original error context)
2. Internal failures that shouldn't occur in normal operation
3. Situations where a specific type adds no value

The important domain errors (format errors, task failures) use typed exceptions correctly.

**Action**: None needed

---

### Finding 3: Abstract classes

**Signal type**: Over-engineering check
**Found at**:
- `packages/superdeck/lib/src/deck/widget_definition.dart:42`
- `packages/cli/lib/src/commands/base_command.dart:9`

**Questions & Research**:

| # | Question | Research Method | Answer |
|---|----------|-----------------|--------|
| 1 | Does WidgetDefinition have implementations? | Code search | Yes, QrCodeWidget, ImageWidget, DartpadWidget |
| 2 | Does SuperDeckCommand have implementations? | Code search | Yes, BuildCommand, SetupCommand, PublishCommand, VersionCommand |
| 3 | Do these pass the deletion test? | Analysis | Yes - removing them breaks the plugin/command systems |
| 4 | Is the abstraction necessary? | Analysis | Yes - they define extension points for users |

**Decision**: Keep — Both abstract classes serve real purposes:
- `WidgetDefinition<T>`: Public API for custom widget blocks with typed arguments
- `SuperDeckCommand`: Shared CLI functionality (config loading, logging)

**Action**: None needed

---

### Finding 4: Handler classes

**Signal type**: Clarity check
**Found at**: `packages/superdeck/lib/src/deck/navigation_events.dart`

**Questions & Research**:

| # | Question | Research Method | Answer |
|---|----------|-----------------|--------|
| 1 | What do KeyboardNavigationHandler and GestureNavigationHandler do? | Read code | Convert input events to NavigationEvent |
| 2 | Are they vague "Handler" god classes? | Read code | No, they have single, clear responsibilities |
| 3 | Is the naming appropriate? | Check domain | Yes, "Handler" is accurate for event processing |

**Decision**: Keep — These are well-designed, focused classes that convert input events to navigation events. The naming is accurate.

**Action**: None needed

---

## Unresolved Questions

None — All questions were resolved through research.

---

## Changes Made

None required — The codebase passes all reference code quality checks.

---

## Reference Quality Checklist

### No Over-Engineering

- [x] No interfaces with single implementations (unless public API)
- [x] No factories that just call constructors
- [x] No base classes that only share code (not behavior)
- [x] No utils grab-bags — code is cohesive or co-located
- [x] Every abstraction passes the deletion test

### No Debt

- [x] No TODO comments (fixed or tracked externally)
- [x] No FIXME comments (fixed or tracked externally)
- [x] No HACK comments (fixed properly)
- [x] No commented-out code
- [x] Documentation matches behavior

### Clear

- [x] Names convey intent in domain language
- [x] Functions do one thing
- [x] No deep nesting (≤3 levels)
- [x] No magic numbers/strings (constants used appropriately)
- [x] Comments explain "why", code explains "what"

### Consistent

- [x] Same problem solved the same way
- [x] Error handling uniform (typed for domain errors, generic for internal)
- [x] Naming conventions followed
- [x] Architecture patterns followed

### Idiomatic

- [x] Uses Dart/Flutter features correctly
- [x] Follows framework conventions (signals, mix/remix)
- [x] Standard library preferred where appropriate

---

## Conclusion

**This codebase is reference-quality code.**

The SuperDeck project demonstrates:
- Clean architecture with clear package boundaries
- Appropriate use of abstractions (WidgetDefinition for extensibility)
- Consistent coding conventions throughout
- Zero technical debt markers
- Well-documented public APIs
- Idiomatic Dart/Flutter patterns

No changes are required. This is code you could proudly point to when someone asks "what does good look like here?"
