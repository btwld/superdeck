# SuperDeck 1.0 Public Release Checklist

## Summary

Release target: publish `superdeck`, `superdeck_core`, `superdeck_cli`, and `superdeck_builder` at `1.0.0`.

As of 2026-02-23 baseline:
- All package versions are already `1.0.0` in-repo.
- `superdeck` and `superdeck_core` exist on pub.dev at older versions.
- `superdeck_cli` and `superdeck_builder` are not currently published.

## Release Command Preamble

Always run release checks with FVM SDK binaries.

```bash
export PATH="$(pwd)/.fvm/flutter_sdk/bin:$PATH"
which flutter
which dart
flutter --version
dart --version
```

## Run Log

| Date (UTC) | Command | Result | Notes |
|---|---|---|---|
| 2026-02-23 | `melos run analyze` | Partial pass | Dart analyze passed; DCM failed due activation/license. |
| 2026-02-23 | `melos run test --no-select` | Pass | Unit/widget suites passed across packages. |
| 2026-02-23 | `melos run test:integration --no-select` | Fail | Linux device unavailable on local macOS machine (expected locally). |
| 2026-02-23 | `cd demo && flutter test integration_test -d macos --fail-fast` | Fail/hang | Startup hang; build interrupted manually. |
| 2026-02-23 | `dart/flutter pub publish --dry-run` (all packages) | Warnings | Missing changelog in `superdeck`, `.gitignore` warning for `pubspec_overrides.yaml`, builder `docs` directory warning, builder test `ack` import warning. |
| 2026-02-23 | `fvm flutter pub run melos run analyze:dart --no-select` | Pass | No analyzer issues in `core`, `builder`, `cli`, `superdeck`, `demo`. |
| 2026-02-23 | `fvm flutter pub run melos run test --no-select` | Pass | All package test suites passed (with expected Flutter startup-lock wait messages). |
| 2026-02-23 | `fvm flutter pub run melos run test:integration --no-select` | Fail (expected local) | `-d linux` not available on local macOS; remains CI-only Linux gate. |
| 2026-02-23 | `fvm flutter pub run melos run test:integration:macos --no-select` | Pass | Demo integration suite passed after stabilization fixes in `demo/integration_test/app_test.dart`. |
| 2026-02-23 | `fvm flutter pub run melos run test:e2e:web --no-select` | Pass | Playwright smoke suite green (`4 passed`). |
| 2026-02-23 | `fvm flutter pub run melos run analyze:dcm --no-select` | Fail (non-blocking) | DCM activation/license still missing (documented bypass). |
| 2026-02-23 | `cd packages/core && fvm dart pub publish --dry-run` | Warnings | Pre-release dep warning + dirty git/overrides warnings. |
| 2026-02-23 | `cd packages/builder && fvm dart pub publish --dry-run` | Warnings | Pre-release dep warning + dirty git/overrides warnings; `doc/` rename reflected. |
| 2026-02-23 | `cd packages/cli && fvm dart pub publish --dry-run` | Warnings | Dirty git/overrides warnings/hints (no publish-blocking resolution in dirty tree). |
| 2026-02-23 | `cd packages/superdeck && fvm dart pub publish --dry-run` | Warnings | Pre-release dep warnings (`mix`, `remix`) + dirty git/overrides warnings/hints. |
| 2026-02-23 | `cd packages/cli && fvm flutter test` | Pass | CLI command suite passes after publish command cleanup changes. |
| 2026-03-09 | `melos run analyze:dart --no-select` | Pass | Analyzer clean in `core`, `builder`, `cli`, `superdeck`, `genui`, and `demo`; terminal still prints pre-run `Invalid SDK hash` warning. |
| 2026-03-09 | `melos run test --no-select` | Fail | Failing package: `superdeck_genui` (8 test failures). |
| 2026-03-09 | `cd packages/genui && ../../.fvm/flutter_sdk/bin/flutter test` | Fail | `deck_tools_service_test.dart` fails with schema-validation errors (`DeckToolException(deck_schema_invalid)`) in create/update/read-slide paths. |
| 2026-03-09 | `cd packages/core && ../../.fvm/flutter_sdk/bin/dart pub publish --dry-run` | Warnings | `.gitignore` warning for `pubspec_overrides.yaml` + prerelease dep warnings (`ack`, `ack_annotations`). |
| 2026-03-09 | `cd packages/builder && ../../.fvm/flutter_sdk/bin/dart pub publish --dry-run` | Warnings | `.gitignore` warning for `pubspec_overrides.yaml` + prerelease warning (`ack_annotations`) + override hint. |
| 2026-03-09 | `cd packages/cli && ../../.fvm/flutter_sdk/bin/dart pub publish --dry-run` | Warnings | `.gitignore` warning for `pubspec_overrides.yaml` + dependency override hints. |
| 2026-03-09 | `cd packages/superdeck && ../../.fvm/flutter_sdk/bin/dart pub publish --dry-run` | Warnings | `.gitignore` warning for `pubspec_overrides.yaml` + prerelease warnings (`mix`, `remix`) + override hints. |
| 2026-03-09 | `fvm flutter devices` | Pass | `macos` and `chrome` detected; Apple-device discovery warnings are non-blocking for desktop integration checks. |
| 2026-03-09 | `fvm flutter pub run melos run test:integration:macos --no-select` | Pass | `superdeck_example` integration suite passed (20/20); xcodebuild emitted `DVTBuildVersion` warnings and `Failed to foreground app` message but tests completed and passed. |

## Freshness Policy (Anti-Drift)

- Release publish decisions require fresh gate evidence no older than 24 hours.
- Required commands before starting publish:
  - `melos run analyze:dart --no-select`
  - `melos run test --no-select`
  - `cd packages/core && ../../.fvm/flutter_sdk/bin/dart pub publish --dry-run`
  - `cd packages/builder && ../../.fvm/flutter_sdk/bin/dart pub publish --dry-run`
  - `cd packages/cli && ../../.fvm/flutter_sdk/bin/dart pub publish --dry-run`
  - `cd packages/superdeck && ../../.fvm/flutter_sdk/bin/dart pub publish --dry-run`
- Any new warning category outside the approved list below blocks publish until explicitly accepted in this file.

## Risk Sign-off

- DCM gate:
  - Status: accepted temporary bypass for 1.0.
  - Rationale: environment requires DCM activation/license; release gates rely on Dart analyzer + tests + integration + E2E.
  - Owner: release owner.

- Pre-release dependency exceptions:
  - `ack`, `ack_annotations`, `ack_generator`, `mix`, `remix`
  - Rationale: required by current architecture and/or package ecosystem state.
  - Constraint: no unreviewed prerelease additions beyond this list.
  - Owner: release owner.

- Dry-run warning categories (approved for local monorepo dry-runs):
  - `.gitignore` warning for checked-in `pubspec_overrides.yaml`
  - dependency override hints from `pubspec_overrides.yaml`
  - Constraint: these warnings are acceptable for local path-override dry-runs only; publish session must use intended release dependency graph.
  - Owner: release owner.

- Flaky/skipped tests:
  - Require explicit per-test disposition before publish.

## Code Review Findings (Release-Focused)

### P1 (fixed)

- `packages/cli/lib/src/commands/publish_command.dart`
  - Risk: publish flow did not guarantee cleanup of temporary git worktrees and did not guarantee restoring backed-up `web/index.html` on success paths.
  - Fix: moved cleanup and backup restoration into `finally`, with guarded cleanup logging.
  - Validation: CLI tests pass (`cd packages/cli && fvm flutter test`).

### P2 (accepted for 1.0, documented)

- `packages/core/lib/src/utils/file_watcher.dart`
  - Observation: file-watcher behavior remains platform-sensitive; related watcher tests are explicitly skipped as flaky.
  - Risk: edge cases in filesystem event behavior may still differ by platform/editor save mode.
  - Tracking reference: `REL-1.0-P2-file-watcher` (issue link to be attached before final publish sign-off).
  - Disposition: accepted for 1.0 with existing test skip rationale; keep under post-1.0 hardening backlog.

### No open P0 findings

- No P0 release blockers were found in the scoped pass for:
  - `packages/core` (fallback/IO paths)
  - `packages/builder` (browser lifecycle/mermaid generation)
  - `packages/cli` (git safety/worktree flow)
  - `packages/superdeck` (controller lifecycle/navigation/style loading)

## Phase 0: Checklist Setup

- [x] Create `.planning/release-1.0.md` and paste checklist.
- [x] Add a Run Log table.
- [x] Add a Risk Sign-off section.
- [x] Keep this checklist updated as source of truth.

## Phase 1: Reproducible Toolchain and Environment

- [x] Pin `.fvmrc` to exact version (`3.38.9`).
- [x] Align SDK constraints across root/melos/packages/demo.
- [x] Standardize melos scripts to FVM SDK commands.
- [ ] Verify no `Invalid SDK hash` appears in current release command logs.
- [x] Document release command preamble.

## Phase 2: Package Publish Readiness Fixes

- [x] Add `packages/superdeck/CHANGELOG.md`.
- [x] Add `.pubignore` files for all publishable packages.
- [x] Rename `packages/builder/docs` to `packages/builder/doc`.
- [x] Resolve builder test import warning by adding direct `ack` dev dependency.
- [x] Re-run dry-runs and reduce warnings to approved categories only.
- [x] Record final dependency exception sign-off after dry-runs.

## Phase 3: Validation Gate Definition and Execution

Blocking gates:
- [x] `melos run analyze:dart`
- [ ] `melos run test --no-select`
- [ ] Linux integration tests in CI (`melos run test:integration`)
- [x] Playwright web smoke suite
- [x] `pub publish --dry-run` for each package with approved warnings only

Non-blocking (document-only for this release):
- [x] DCM (`melos run analyze:dcm`) marked temporary bypass in Risk Sign-off.

## Phase 4: Integration and E2E Stabilization

- [x] Keep CI Linux integration command and add explicit local macOS command.
- [x] Add hard timeout/failure diagnostics for integration startup hangs.
- [x] Expand integration assertions with visible UI behavior checks.
- [x] Add Playwright smoke tests:
  - [x] app boot without error UI
  - [x] keyboard/mouse navigation smoke
  - [x] panel interaction smoke
  - [x] asset-heavy slide render + no fatal network failures
- [x] Wire Playwright smoke into CI pre-release gating.

## Phase 5: Release-Focused Code Review

- [x] Core review (`packages/core`): file watching, deck fallback, IO edge cases.
- [x] Builder review (`packages/builder`): browser lifecycle, Mermaid generation failures.
- [x] CLI review (`packages/cli`): git safety, branch/worktree behavior, dry-run parity.
- [x] Superdeck review (`packages/superdeck`): controller lifecycle/disposal, navigation state, style/font loading.
- [x] Apply must-fix policy:
  - [x] Fix all P0/P1 before publish.
  - [x] Document any accepted P2 with issue link/reference and risk note.
- [x] Add/adjust regression tests for fixed defects.

## Phase 6: Single-Batch Publish Session

- [ ] Confirm clean tree + all blocking gates green.
- [ ] Publish in dependency-safe order (single batch session):
  - [ ] `packages/core`
  - [ ] `packages/builder`
  - [ ] `packages/cli`
  - [ ] `packages/superdeck`
- [ ] For each package:
  - [ ] `pub publish --dry-run`
  - [ ] publish
  - [ ] verify pub.dev API reflects `1.0.0`
- [ ] Tag release (`v1.0.0`) and update release notes/changelog links.

## Phase 7: Post-Release Verification

- [ ] Verify pub.dev `1.0.0` for all four packages.
- [ ] Clean-room install flow:
  - [ ] `dart pub global activate superdeck_cli`
  - [ ] new app + `flutter pub add superdeck`
  - [ ] `superdeck setup` + `flutter run` + `superdeck publish`
- [ ] Demo web build + Playwright smoke on release artifacts.
- [ ] Record final completion report and risk status in this file.

## Required Test Coverage Checklist

### Static/Unit/Widget
- [ ] All unit/widget tests pass in all packages.
- [x] Each skipped/flaky test has release disposition (fix/keep-skip/replace).

### Integration (Flutter)
- [x] Demo startup path
- [x] Slide load + slide count sanity
- [x] next/previous/go-to navigation
- [x] menu/notes state transitions
- [x] controlled error-state behavior
- [x] startup timeout/failure diagnostics

### E2E (Playwright)
- [x] web boot smoke
- [x] keyboard/mouse navigation smoke
- [x] panel/UI interaction smoke
- [x] console + network failure checks

### Publish Validation
- [x] dry-run executed for each package
- [x] only approved warning categories remain
- [x] no unexpected warnings before final publish

## Skipped/Flaky Test Disposition

- `packages/builder/test/manual_error_output_test.dart` (skip):
  - Disposition: keep skipped.
  - Rationale: non-strict YAML logging path not exposed in this harness; covered by parser unit tests.

- `packages/core/test/src/deck_service_test.dart` (skip):
  - Disposition: keep skipped.
  - Rationale: filesystem watch stream timing is flaky across environments; covered by integration/runtime validation.

- `packages/core/test/src/helpers/watcher_test.dart` (skip):
  - Disposition: keep skipped.
  - Rationale: CI/event-loop variability can hang file watch assertions.

- `packages/superdeck/test/deck/deck_controller_test.dart` (multiple skips):
  - Disposition: keep skipped for 1.0.
  - Rationale: these tests require bundled Google Fonts assets or further style-layer test seam changes.
