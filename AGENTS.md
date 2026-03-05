# AGENTS.md

This file provides guidance to Claude Code and other AI assistants working on the SuperDeck codebase.

> **Note**: `CLAUDE.md` is a symlink to this file.

## Start Here

Before doing substantive work in this repository:
- Always read `.planning/session.md` first.
- Treat `.planning/session.md` as the live handoff and working-memory document for the repo.
- Update `.planning/session.md` when:
  - you start a meaningful task
  - you change the plan or direction
  - you discover important constraints or risks
  - you finish a meaningful chunk of work

For very small, read-only, or trivial tasks, keep the update minimal, but do not skip checking the file first.

## Project Overview

SuperDeck is a Flutter presentation framework that renders slides written in Markdown. Users write slides in a `slides.md` file using Markdown syntax with custom block annotations, and SuperDeck renders them as a Flutter application.

- **Live demo**: https://superdeck-dev.web.app
- **Repository**: https://github.com/leoafarias/superdeck

## Project Structure

This is a Melos monorepo with the following packages:

```
packages/
  core/       # Rendering primitives, Markdown parsing, schema validation (Dart-only)
  superdeck/  # Flutter widgets and presentation components
  cli/        # superdeck CLI tool (setup, build, watch)
  builder/    # Code generators and build_runner integration
demo/         # Sample presentation app
docs/         # User-facing documentation (MDX format)
.planning/    # Internal development docs (not published)
```

### Key Package Responsibilities

- **core**: Markdown processing, slide/block configuration, style schemas, YAML validation (no Flutter dependency)
- **superdeck**: Flutter widgets, DeckController, navigation, PDF export, theme system
- **cli**: CLI commands for project setup and building slides
- **builder**: build_runner generators for code generation

## Environment Setup

This project uses FVM (Flutter Version Management) pinned via `.fvmrc`:

```bash
fvm use --force
dart pub global activate melos
melos bootstrap
```

Always work inside the FVM-provided SDK (`.fvm/flutter_sdk`) to avoid toolchain drift.

**Required SDK versions**: Dart >=3.10.0, Flutter >=3.38.1

## Common Commands

### Analysis & Linting
```bash
melos run analyze          # Run dart analyze + DCM analysis
melos run analyze:all      # Full analysis including unused code/files
melos run fix              # Apply dart fix + DCM autofixes
melos run custom_lint_analyze  # Run custom lint rules
```

### Code Generation
```bash
melos run build_runner:build   # Generate code (run before tests)
melos run build_runner:watch   # Watch mode for development
melos run build_runner:clean   # Clean generated files
```

### Testing
```bash
melos run test             # Run all tests
melos run test:coverage    # Run tests with coverage
fvm flutter test <path>    # Run specific test file
```

### Cleaning
```bash
melos run clean            # Clean all Flutter build artifacts
```

## AI Assistant Workflow

This repository is a Dart/Flutter codebase end-to-end. Agent workflow should reflect that.

### Required skills
- Always use the `dart-flutter` skill for work in this repository.
- Also use the `code-simplifier` skill for code changes, reviews, refactors, rewrite planning, and architecture work.
- In practice, most SuperDeck tasks should use both skills together.

### Recommended order when both skills apply
1. `dart-flutter`
   - validate Dart/Flutter API design
   - validate state, lifecycle, package boundaries, and runtime behavior
   - validate test strategy and operational safety
2. `code-simplifier`
   - remove unnecessary abstraction
   - reduce duplication and incidental complexity
   - keep the final design aligned with KISS/YAGNI/clarity

### Rewrite and architecture best practices
- Before proposing or changing architecture, inventory the current feature surface from code, docs, and tests.
- Do not trust docs alone when validating rewrite scope or feature parity.
- For any major rewrite, keep a feature matrix in `.planning/` that maps:
  - current behavior
  - source files
  - target v2 owner
  - parity decision
  - migration note
  - validation/test gate
- Treat parsing, contracts, runtime bootstrap, export flows, and CLI setup/publish behavior as high-risk surfaces that must be specified explicitly.
- If a parser or contract rule cannot be written as a testable rule, the design is not complete enough yet.

### Working expectations for agents
- Prefer changes that make invalid states harder to represent.
- Prefer one clear owner per behavior over shared implicit coordination.
- Preserve user-visible behavior unless the change is explicitly documented as a migration.
- When behavior is intentionally changed, document:
  - why the current behavior is insufficient
  - what replaces it
  - how existing users migrate

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
- Files matching `*.g.dart`, `*.mapper.dart` are auto-generated
- Regenerate with `melos run build_runner:build` before testing
- Commit generated files when they change and keep them synchronized with source updates

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
- **ack**: Schema validation for YAML configuration
- **markdown**: Markdown parsing
- **go_router**: Navigation/routing

## Architecture Notes

### Reactive State
The project uses Signals for reactive state management. `DeckController` is the central state manager for presentations.

### Block System
Slides are composed of "blocks" defined by `@blockname` annotations in Markdown:
- `@block` - Markdown content blocks
- `@image` - Image blocks
- `@code` - Syntax-highlighted code
- `@mermaid` - Mermaid diagrams
- `@widget` - Custom Flutter widgets

### Style System
Styles are defined in YAML and validated against schemas. See `packages/core` for style schema definitions.

## Documentation Locations

- **User docs**: `docs/` (getting-started, guides, reference)
- **Internal planning**: `.planning/` (architecture decisions, feature specs)
- **Package READMEs**: Each package has its own README

## Quick Reference

| Task | Command |
|------|---------|
| Bootstrap workspace | `melos bootstrap` |
| Run all analysis | `melos run analyze` |
| Generate code | `melos run build_runner:build` |
| Run tests | `melos run test` |
| Apply fixes | `melos run fix` |
| Clean workspace | `melos run clean` |
