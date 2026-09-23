# Copilot Coding Agent Instructions for SuperDeck

## What this repository is
- SuperDeck is a Melos monorepo for a Flutter presentation framework that renders Markdown slides.
- Main packages:
  - `packages/core`: Markdown parsing, schemas, validation (Dart-only)
  - `packages/superdeck`: Flutter runtime/widgets
  - `packages/cli`: `superdeck` CLI commands
  - `packages/builder`: deck parsing, serialization, and the build/watch pipeline
  - `packages/playground`: the Wizard app for AI deck generation, presenting, and saving
  - `packages/plugins/pdf`: PDF export
  - `demo/`: reference app and slide content used by CI smoke/integration flows

## First-time setup (required)
Use the repo-pinned Flutter SDK via FVM to avoid version drift.

```bash
fvm use --force
fvm dart run melos bootstrap
```

> Required by workspace config: Dart `>=3.12.0`, Flutter `>=3.44.6`.

## High-signal commands (run from repo root)
- Analyze: `fvm dart run melos run analyze`
- Auto-fix: `fvm dart run melos run fix`
- Generate code: `fvm dart run melos run build_runner:build`
- Unit/widget tests: `fvm dart run melos run test`
- Integration tests (Linux): `fvm dart run melos run test:integration`
- Web smoke tests: `fvm dart run melos run test:e2e:web`

## Agent workflow expectations
1. Keep changes surgical and package-scoped.
2. Run `fvm dart run melos run build_runner:build` before tests when touching code that can affect generated output.
3. Commit generated files when they change (`*.g.dart`, `*.ack.dart`).
4. Prefer relative imports in Dart files.
5. Follow existing style: two-space indentation, `snake_case.dart` filenames.

## Known pitfalls and fixes
- **Missing toolchain locally (`fvm: command not found`, `dart: command not found`)**
  - Cause: environment does not have Dart/FVM preinstalled.
  - Workaround: install Dart, then install FVM and Melos, then bootstrap:
    ```bash
    dart pub global activate fvm
    export PATH="$HOME/.pub-cache/bin:$PATH"
    fvm use --force
    fvm dart run melos bootstrap
    ```

## CI notes
- Main validation workflow: `.github/workflows/test.yml`
- CI sequence is effectively: bootstrap -> build_runner -> contracts check -> tests/integration/web smoke.
- If CI fails in Integration/Web Smoke at "Build SuperDeck Assets", inspect demo slide syntax and frontmatter first.
