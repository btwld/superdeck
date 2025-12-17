# Repository Guidelines

SuperDeck runs as a Melos workspace pinned to Flutter stable via FVM. Use these notes before sending changes.

## Project Structure & Module Organization
- `packages/core`: rendering primitives shared by apps and CLI.
- `packages/superdeck`: Flutter widgets and presentation components.
- `packages/cli`: source for the `superdeck` CLI wrapper.
- `packages/builder`: generators and build-runner glue.
- `demo/` sample app, `assets/` shared media, docs live under `docs/`.

## Environment Setup
- `fvm use stable --force` to align with CI.
- `dart pub global activate melos`, then `melos bootstrap` whenever dependencies shift.
- Work inside the FVM-provided SDK (`.fvm/flutter_sdk`) to avoid toolchain drift.

## Build, Test, and Development Commands
- `melos run analyze` → runs `dart analyze` and Dart Code Metrics across all packages.
- `melos run build_runner:build` (or `:watch`) → regenerates generated sources before tests.
- `melos run custom_lint_analyze` → executes required custom lint rules.
- `melos run test` / `melos run test:coverage` → runs Flutter tests, optionally collecting coverage.
- `melos run clean` → resets Flutter build artifacts across the workspace.

## Coding Style & Naming Conventions
- Default to two-space Dart indentation and `snake_case.dart` filenames.
- Prefer relative imports; avoid exporting from entry-point files.
- Run `melos run fix` before committing to apply `dart fix` and DCM autofixes.
- Keep widgets focused, respect analyzer member ordering, and colocate private helpers with the widget they support.

## Testing Guidelines
- Unit tests belong under each package's `test/`.
- Regenerate code before tests (`melos run build_runner:build`) to keep generated files current.
- Use `melos run test` for a full pass; run targeted cases with `fvm flutter test <path>` when needed.
- Add regression tests with bug fixes; CI blocks merges on failing analyze/test jobs and posts integration results per platform.

## Commit & Pull Request Guidelines
- Use Conventional commits (`feat:`, `fix:`, `chore:`) with imperative subjects under 72 characters.
- Keep commits focused and prefer multiple smaller commits over mixed changes.
- PR descriptions should list intent, impacted packages, and commands executed (analyze, build_runner, test).
- Attach UI screenshots or clips when visual output shifts and call out integration coverage added or skipped.
- Do not commit generated artifacts unless explicitly required (assets under `packages/superdeck/assets/` are the main exception).
