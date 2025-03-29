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
- **Publish** - Publish your SuperDeck app to GitHub Pages

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

### Publish

Publish your SuperDeck app to GitHub Pages.

```bash
superdeck publish
```

Options:
- `--branch` (`-b`): The git branch where the built content will be published (default: `gh-pages`)
- `--message` (`-m`): The commit message for the publication (default: `Publish Superdeck app to GitHub Pages`)
- `--[no-]push`: Push the changes to remote after publication (default: `true`)
- `--[no-]build`: Build the web app before publishing with the correct base-href for GitHub Pages (default: `true`)
- `--build-dir`: Directory containing the built web assets to publish (default: `build/web`)
- `--dry-run`: Run through the publication process without making actual changes

This command will:
1. Build your app for web with the correct base-href for GitHub Pages (unless `--no-build` is specified)
2. Create or update the target Git branch (default: `gh-pages`)
3. Copy the build output to the target branch
4. Commit the changes
5. Push to remote (unless `--no-push` is specified)

#### Reverting a Publication

To revert a publication:
```bash
superdeck publish --revert
```

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

### Publishing to GitHub Pages

```bash
# Build and publish your SuperDeck app to GitHub Pages (simplest usage)
superdeck publish

# Publish without building (if you've already built the web app)
superdeck publish --no-build

# Commit to gh-pages branch but don't push to remote
superdeck publish --no-push

# Specify a custom branch
superdeck publish --branch my-pages

# Use a custom commit message
superdeck publish --message "Deploy my awesome presentation"

# Test the publishing process without making changes
superdeck publish --dry-run
```

## Requirements

- Flutter SDK
- Dart SDK version 3.0.0 or higher
- Git (for publish command)

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
