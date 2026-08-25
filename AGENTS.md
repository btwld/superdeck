# AGENTS.md

This file provides guidance to Claude Code and other AI assistants working on the SuperDeck codebase.

> **Note**: `CLAUDE.md` is a symlink to this file.

## Project Overview

SuperDeck is a Flutter presentation framework that renders slides written in Markdown. Users write slides in a `slides.md` file using Markdown syntax with custom block annotations, and SuperDeck renders them as a Flutter application.

- **Live demo**: https://superdeck-dev.web.app
- **Repository**: https://github.com/btwld/superdeck

## Project Structure

This is a Melos monorepo with the following packages:

```
packages/
  core/       # Rendering primitives, Markdown parsing, schema validation (Dart-only)
  superdeck/  # Flutter widgets and presentation components
  cli/        # superdeck CLI tool (setup, build, publish, version)
  builder/    # Code generators and build_runner integration
demo/         # Sample presentation app
docs/         # User-facing documentation (MDX format)
```

### Key Package Responsibilities

- **core**: Markdown processing, slide/block configuration, shared model/schema validation, YAML utilities (no Flutter dependency)
- **superdeck**: Flutter widgets, DeckController, navigation, thumbnail/capture services, theme system
- **cli**: CLI commands for project setup and building slides
- **builder**: build_runner generators for code generation

## Environment Setup

This project uses FVM (Flutter Version Management) configured via `.fvmrc` (pinned to Flutter `3.44.6`):

```bash
fvm use --force
fvm dart run melos bootstrap
```

Always work inside the FVM-provided SDK (`.fvm/flutter_sdk`) to avoid toolchain drift.

**Required SDK versions**: Dart >=3.12.0, Flutter >=3.44.6

## Common Commands

### Analysis & Linting
```bash
fvm dart run melos run analyze          # Run dart analyze + DCM analysis
fvm dart run melos run analyze:all      # Full analysis including unused code/files
fvm dart run melos run fix              # Apply dart fix + DCM autofixes
fvm dart run melos run custom_lint_analyze  # Run custom lint rules
```

### Code Generation
```bash
fvm dart run melos run build_runner:build   # Generate code (run before tests)
fvm dart run melos run build_runner:watch   # Watch mode for development
fvm dart run melos run build_runner:clean   # Clean generated files
```

### Testing
```bash
fvm dart run melos run test             # Run all tests
fvm dart run melos run test:coverage    # Run tests with coverage
fvm flutter test <path>    # Run specific test file
```

### Running Apps & Live Debugging
```bash
cd packages/playground
fvm flutter run -d macos -t lib/main.dart --dart-define-from-file=../../.env
```

The playground reads `GOOGLE_AI_API_KEY` from the ignored repository-root
`.env` file through Flutter's compile-time define-file option. Without that
flag, the Wizard intentionally shows a configuration error before accepting
input.

Wizard image generation is enabled by default for local/debug demos and is
opt-in for release builds. Validate the image-enabled smoke flow before adding
`--dart-define=SUPERDECK_WIZARD_IMAGE_GENERATION=true` to a release launch.

When running an app to reproduce or diagnose a UI/runtime issue, launch it with
`fvm flutter run` and keep that process attached for the entire reproduction.
Continue reading its output after each UI interaction so Dart exceptions,
Flutter framework errors, plugin failures, and native macOS logs are captured as
they happen. Do not use `open <path>.app` as the primary debugging launch: it
detaches the app from the observable Flutter process and hides the logs needed
to identify the root cause. Opening a compiled `.app` directly is appropriate
only for a distribution smoke test where live diagnostics are not required.

### Cleaning
```bash
fvm dart run melos run clean            # Clean all Flutter build artifacts
```

## Coding Standards

### Style
- Two-space Dart indentation
- `snake_case.dart` filenames
- Prefer relative imports over package imports
- Avoid exporting from entry-point files
- Keep widgets focused; colocate private helpers with their widget
- Run `melos run fix` before committing

### Member Ordering (enforced by DCM)
1. Public fields
2. Private fields
3. Constructors
4. Static methods
5. Private methods/getters/setters
6. Public getters/setters/methods
7. Overridden methods
8. `build` method (last)

### Generated Files
- Files matching `*.g.dart` and `*.ack.dart` are auto-generated
- Regenerate with `melos run build_runner:build` before testing
- Commit generated files when they change and keep them synchronized with source updates

### File Organization Convention

**Feature/domain folders** — group `lib/src/` files by the domain they belong to, not by type:
```
lib/src/
  deck/           # Domain: configuration, models, loading, storage
  markdown/       # Domain: parsing, syntaxes, helpers
  cache/          # Domain: caching stores
  rendering/      # Domain: slide/block rendering (Flutter)
  ui/             # Domain: app shell, panels, widgets (Flutter)
  utils/          # Cross-cutting utilities
```

**Co-locate models with their domain** — no separate `models/` folder. Place `slide_model.dart` in `deck/`, not in a shared `models/` directory.

**Earned role suffixes** — use `_model`, `_service`, `_controller`, `_view`, `_widget`, `_store`, `_parser` only when the file's role would be ambiguous without the suffix. Don't force a suffix when the name is already clear (e.g., `background.dart`, `constants.dart`).

**Tests mirror `lib/src/`** — test file paths match source paths. If source is `lib/src/deck/deck_loader.dart`, test is `test/src/deck/deck_loader_test.dart`.

**Relative imports** within a package — use relative imports for intra-package references, package imports only for cross-package dependencies.

**Single barrel file** per package — one entry-point file (e.g., `superdeck_core.dart`) using relative exports.

### Repository Conventions
- Use `docs/` for maintainer-facing documentation that should not live under `lib/`
- Use `test/helpers/` for reusable Dart test support code
- Use `test/fixtures/` for static test inputs, snapshots, and reference artifacts
- Use `snake_case` for repo-owned non-standard filenames
- Prefer `.yaml` for repo-owned configuration and fixture files
- Keep ecosystem-standard names as-is, including `README.md`, `CHANGELOG.md`, generated platform files, and existing GitHub workflow `.yml` files

## Testing Guidelines

- Unit tests live under each package's `test/` directory
- Always regenerate code before running tests
- Add regression tests with bug fixes
- CI blocks merges on failing analyze/test jobs

## Commit Guidelines

- Use Conventional Commits: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`
- Imperative subjects under 72 characters
- Keep commits focused; prefer multiple smaller commits
- PR descriptions should list intent, impacted packages, and commands run

## Key Dependencies

- **mix/remix**: UI styling framework used throughout
- **signals/signals_flutter**: Reactive state management
- **ack**: Schema validation plus generated JSON models and discriminated unions
- **markdown**: Markdown parsing
- **go_router**: Navigation/routing

## Architecture Notes

### Reactive State
The project uses Signals for reactive state management. `DeckController` is the central state manager for presentations.

### AI Generation Models

Use the current stable Gemini model split for the Playground deck-generation
pipeline:

- `gemini-3.5-flash` for the single global outline/planning request
- `gemini-3.1-flash-lite` for concurrent narrative-section composition and
  targeted outline/slide repair

Keep model thinking at the lowest supported setting for this latency-sensitive
workflow. Do not silently switch back to an older model, a preview model, or
one request per slide. Any model or reasoning-setting change must be validated
with the opt-in live 10-slide generation smoke test and its saved timing,
validation, render, and quality artifacts. Target 20 seconds and treat 30
seconds as the maximum acceptable generation time before local rendering.

### Block System
Slides use `@tag` directives in Markdown to define layout and content:
- `@section` - Groups child blocks into a horizontal section
- `@block` - Markdown content block
- `@widget` - Named Flutter widget block
- Any unrecognized `@name` becomes a `WidgetBlock` (e.g., `@image`, `@chart`, `@callout`)

### Style System
Styles are defined in Dart through `SlideStyler`, `DeckOptions.baseStyle`, and `DeckOptions.styles`.

## Documentation Locations

- **User docs**: `docs/` (getting-started, guides, reference)
- **Package READMEs**: Each package has its own README

## Quick Reference

| Task | Command |
|------|---------|
| Bootstrap workspace | `fvm dart run melos bootstrap` |
| Run all analysis | `fvm dart run melos run analyze` |
| Generate code | `fvm dart run melos run build_runner:build` |
| Run tests | `fvm dart run melos run test` |
| Apply fixes | `fvm dart run melos run fix` |
| Clean workspace | `fvm dart run melos run clean` |
