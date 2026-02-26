# Desktop Gap Remediation Plan

Date: 2026-02-06  
Repository: `/Users/leofarias/Concepta/superdeck_ai`

## Goal

Implement all remaining desktop-readiness findings from review:

1. Prevent startup crash in read-only working directories.
2. Make generation metadata persistence reliable on first run.
3. Remove brittle hardcoded `.superdeck/assets/...` emission from generation pipeline.
4. Expand desktop smoke coverage beyond Linux in CI.

## Constraints and Dependencies

1. `superdeck` currently initializes `DeckConfiguration()` with default output `.superdeck` relative to current working directory, inside package code.
2. For this cut, avoid upstream package changes (no edits in `superdeck` repo).
3. Therefore, app-level hardening should prioritize:
   - non-fatal behavior when local `.superdeck` is not writable
   - consistent path construction in one local place
   - stronger CI coverage for desktop build integrity

## Execution Strategy

Implement in this order to reduce risk and keep each change testable:

1. Startup resilience (fatal -> non-fatal).
2. Metadata persistence reliability.
3. Path contract centralization for generated image references.
4. CI matrix extension.
5. Tests and validation pass.

## Workstream 1: Startup Resilience

### Files

- `/Users/leofarias/Concepta/superdeck_ai/lib/core/debug_logger.dart`
- `/Users/leofarias/Concepta/superdeck_ai/lib/main.dart`

### Changes

1. Make `DebugLogger.init()` fail-safe:
   - wrap directory creation and file initialization in `try/catch`.
   - if filesystem init fails, disable file logging but keep `debugPrint` output.
   - do not throw from logger initialization.
2. Add explicit startup guard in `main()`:
   - wrap `await DebugLogger.instance.init()` in `try/catch`.
   - continue app startup even when logger file init fails.
3. Emit one clear console/debug message indicating logger file output is disabled when initialization fails.

### Why first

This removes a known hard crash path before any other runtime operations.

## Workstream 2: Metadata Persistence Reliability

### File

- `/Users/leofarias/Concepta/superdeck_ai/lib/chat/chat_viewmodel.dart`

### Changes

1. Before writing `last_generation.json` and `last_prompt.txt`, ensure parent directory exists:
   - `await Directory(Paths.superdeckDir).create(recursive: true);`
2. Keep existing `try/catch` to avoid user-facing crashes.
3. Improve error log message to include target path and operation.

### Optional hardening (if low effort)

1. Use write-then-rename for metadata file to avoid partial writes on interruption.

## Workstream 3: Path Contract Centralization

### Files

- `/Users/leofarias/Concepta/superdeck_ai/lib/core/constants/paths.dart`
- `/Users/leofarias/Concepta/superdeck_ai/lib/core/ai/services/deck_generator_pipeline.dart`

### Changes

1. Add one helper in `Paths` for generated image references, for example:
   - `static String generatedAssetRef(String fileName) => '.superdeck/assets/$fileName';`
2. Replace hardcoded string in pipeline:
   - from `'.superdeck/assets/$filename'`
   - to `Paths.generatedAssetRef(filename)`.
3. Keep emitted value unchanged in this cut for compatibility with current `superdeck` behavior.

### Why this shape

This resolves brittle duplication now and keeps future path strategy changes localized.

## Workstream 4: CI Desktop Matrix Coverage

### File

- `/Users/leofarias/Concepta/superdeck_ai/.github/workflows/test.yml`

### Changes

1. Keep existing quality gates:
   - `dart format --set-exit-if-changed .`
   - `flutter analyze`
   - `flutter test`
2. Add desktop smoke builds across all supported desktop OS:
   - Linux: `flutter build linux --debug`
   - macOS: `flutter build macos --debug`
   - Windows: `flutter build windows --debug`
3. Recommended workflow structure:
   - `quality` job (single OS, fast feedback)
   - `desktop-smoke` matrix job (`ubuntu-latest`, `macos-latest`, `windows-latest`)
4. Linux matrix leg keeps prerequisite package install step.
5. Enable corresponding desktop target per runner before build.

### Why split jobs

Separates test/lint failure signal from platform-specific build issues and improves triage speed.

## Test Plan

### Automated

1. `dart format --set-exit-if-changed .`
2. `flutter analyze`
3. `flutter test`

### Manual desktop checks

1. Normal run from repo root:
   - `flutter run -d macos --no-resident --dart-define=GOOGLE_AI_API_KEY=test_key`
2. Startup from read-only working directory context:
   - launch built app from `/`
   - verify no crash in startup path
   - verify graceful logging fallback message
3. Generation metadata:
   - trigger generation flow once
   - verify `.superdeck/last_generation.json` and `.superdeck/last_prompt.txt` are created.

## Acceptance Criteria

1. Launching from read-only CWD no longer crashes at startup due to logger initialization.
2. Metadata files are reliably persisted on first generation attempt.
3. No hardcoded `.superdeck/assets/...` strings remain in generation pipeline logic.
4. CI validates desktop smoke build on Linux, macOS, and Windows.
5. Existing test suite remains green.

## Risk Register

1. CI duration increases due matrix builds.
   - Mitigation: keep quality checks in separate fast job; use caching.
2. Path refactoring could unintentionally change generated asset URLs.
   - Mitigation: preserve exact output string in this cut; only centralize construction.
3. Logger fallback could hide useful diagnostics.
   - Mitigation: always keep console `debugPrint` active and emit explicit fallback notice.

## Rollout

1. Land in one PR with commits grouped by workstream.
2. Verify matrix CI is green before merge.
3. After merge, run one desktop end-to-end generation smoke test on macOS and one on Windows/Linux if available.
