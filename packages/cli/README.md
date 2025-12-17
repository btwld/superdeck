# SuperDeck CLI

Create beautiful, interactive presentations in Flutter using Markdown.

## Features

- **Setup** - Configure your project
- **Build** - Generate assets from slides
- **Watch** - Auto-rebuild on changes
- **Publish** - Deploy to GitHub Pages

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

Configure your project for SuperDeck.

```bash
superdeck setup
```

Options:
- `--force` (`-f`) - Skip confirmations

Creates `slides.md`, updates `pubspec.yaml`, and configures macOS entitlements.

### Build

Build required assets.

```bash
superdeck build
```

Options:
- `--watch` (`-w`) - Auto-rebuild on changes
- `--skip-pubspec` - Skip updating pubspec.yaml
- `--force-rebuild` (`-f`) - Force rebuild all

### Publish

Deploy to GitHub Pages.

```bash
superdeck publish
```

Options:
- `--branch` (`-b`) - Target branch (default: `gh-pages`)
- `--message` (`-m`) - Commit message
- `--[no-]push` - Push to remote (default: `true`)
- `--[no-]build` - Build before publishing (default: `true`)
- `--build-dir` - Build directory (default: `build/web`)
- `--example-dir` - App directory (default: `.`)
- `--dry-run` - Preview without changes

Builds for web, updates target branch, commits, and pushes.

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

### Resources

- [Documentation](https://github.com/leoafarias/superdeck)
- [Examples](https://github.com/leoafarias/superdeck/tree/main/packages/superdeck/example)
- [Live Demo](https://superdeck-dev.web.app)

### Contributing

See [contributing guidelines](https://github.com/leoafarias/superdeck/blob/main/CONTRIBUTING.md).

### Issues

File issues on [GitHub](https://github.com/leoafarias/superdeck/issues). Include:
- Problem description
- Reproduction steps
- Flutter/Dart versions
- Error messages

### Support

- [Discussions](https://github.com/leoafarias/superdeck/discussions)
- [Issues](https://github.com/leoafarias/superdeck/issues)

### License

MIT License - see [LICENSE](https://github.com/leoafarias/superdeck/blob/main/LICENSE).
