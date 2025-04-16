# Formatting Tasks

This directory contains tasks that format or transform slide content without generating external assets.

## Available Tasks

### DartFormatterTask

Formats Dart code blocks in slides using the Dart formatter (`dart format`).

```dart
DartFormatterTask({
  Map<String, String>? environmentOverrides,
  Map<String, dynamic> configuration = const {},
})
```

**Configuration Options:**
- `lineLength`: Maximum line length for formatted code (optional)
- `fix`: Whether to apply fixes to the code (default: true)

**Behavior:**
1. Identifies code blocks with `dart` language identifier
2. Extracts the code content
3. Runs the Dart formatter on the content
4. Replaces the original code block with the formatted version

This task can run in parallel with other tasks for the same slide.

## Creating New Formatting Tasks

When creating new formatting tasks:

1. Focus on transformation of existing content
2. Consider whether the task can run in parallel
3. Handle errors gracefully, as formatting failures should not break the build
4. Document configuration options clearly 