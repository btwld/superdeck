# SuperDeck CLI

The SuperDeck CLI sets up your Flutter project, builds slide assets from `slides.md`, and can publish a web build to GitHub Pages.

## Features

- **Setup** - Configure your project
- **Build** - Generate assets from slides
- **Watch** - Auto-rebuild on changes
- **Publish** - Deploy to GitHub Pages

## Installation

```bash
dart pub global activate superdeck_cli
```

Or add it to your Flutter project as a dev dependency:

```bash
dart pub add --dev superdeck_cli
```

Then run the CLI with:

```bash
dart run superdeck_cli:main --help
```

## Commands

### Setup

Configure your project for SuperDeck.

```bash
superdeck setup
```

Options:
- `--force` (`-f`) - Skip confirmations
- `--[no-]setup-web` - Create a custom `web/index.html` with a loading indicator (default: `true`)

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
- Dart SDK version 3.9.0 or higher
- Git (for publish command)

## Additional information

### Resources

- [Documentation](https://github.com/leoafarias/superdeck/tree/main/docs)
- [Demo app](https://github.com/leoafarias/superdeck/tree/main/demo)
- [Live Demo](https://superdeck-dev.web.app)

### Contributing

Open a pull request on GitHub. If you change dependencies, run `melos bootstrap` in the repo root.

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

BSD 3-Clause License - see [LICENSE](https://github.com/leoafarias/superdeck/blob/main/LICENSE).
