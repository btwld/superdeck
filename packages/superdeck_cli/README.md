<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

# SuperDeck CLI

Command line interface for SuperDeck - Create beautiful and interactive presentations directly within your Flutter app, using the simplicity and power of Markdown.

## Features

- **Setup** - Configure your Flutter project for SuperDeck
- **Build** - Generate required assets from your slides
- **Watch** - Automatically rebuild when slides are modified

## Installation

```bash
dart pub global activate superdeck_cli
```

Or add it to your `pubspec.yaml` as a dev dependency:

```yaml
dev_dependencies:
  superdeck_cli: ^1.0.0
```

## Commands

### Setup

Configure your Flutter project for SuperDeck, including adding asset configurations to `pubspec.yaml` and configuring macOS entitlements if needed.

```bash
superdeck setup
```

Options:
- `--force` (`-f`): Skip confirmation prompts and apply all changes

This command will:
1. Create a `slides.md` file if it doesn't exist
2. Add necessary assets to `pubspec.yaml` for SuperDeck
3. Configure macOS entitlements (if macOS is supported in your project)

### Build

Build all required assets for your slide deck.

```bash
superdeck build
```

Options:
- `--watch` (`-w`): Watch for changes in the slides file and rebuild automatically

## Usage Examples

### Setting up a new project

```bash
# Create a new Flutter project
flutter create my_presentation

# Navigate to the project directory
cd my_presentation

# Set up SuperDeck
superdeck setup

# Build assets
superdeck build

# Run your app
flutter run
```

### Development workflow

```bash
# Start the build in watch mode to automatically rebuild when slides are modified
superdeck build --watch

# Run your app in a separate terminal
flutter run
```

## Requirements

- Flutter SDK
- Dart SDK version 3.0.0 or higher

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
