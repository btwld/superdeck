# SuperDeck V2 Implementation Audit

Date: 2026-03-06

## Scope And Method

This audit reviewed the implemented rewrite against the approved v2 planning set in this order:

1. `.planning/rewrite-v2-api-surface.md`
2. `.planning/rewrite-v2-full-plan.md`
3. `.planning/rewrite-v2-feature-matrix.md`
4. parser/runtime planning docs
5. `.planning/session.md`

Audit stance:

- behavior drift matters more than rename drift
- protected surfaces are block-widget rendering, hero behavior, and export-mode interaction suppression
- temporary compatibility is acceptable only if it is explicit, scoped, and not leaking back into the public v2 surface

## Executive Summary

The shipped rewrite is substantially aligned with the approved v2 API. The public runtime-first bootstrap is in place, the demo and `genui` consumers are migrated, core v2 artifacts and `notes`/`block` contract changes are live, and the current validation sweep is green except for environment-limited integration coverage.

The audit cleanup slice is now complete. The cleanup removed the active `must remove now` items from the audit:

- `StyleConfigLoader` is no longer part of the public styling export surface.
- CLI docs now match the transitional v2.0 `build` / `build --watch` support.
- `watchForChanges`, `DeckControllerBuilder`, `SuperDeckPlugin`, and public-facing `DeckController.of(...)` usage were removed from the active runtime surface.
- tracked demo v1 artifact files were deleted, leaving the `.v2.json` contract as the only tracked artifact set.

The remaining work is intentionally scoped internal cleanup, not another architecture pass:

- keep `DeckOptions` as an internal presentation bridge until a later simplification slice removes it entirely
- keep `DeckController` as an internal runtime implementation detail
- keep `SuperDeckRuntime.forTesting(...)` and `LegacyMarkdownMigrator` as explicit test/migration helpers

## Plan-Conformance Review

| Area | Evidence | Status | Notes |
|---|---|---|---|
| Runtime bootstrap | `packages/superdeck/lib/superdeck.dart`, `packages/superdeck/lib/src/runtime/superdeck_runtime.dart`, `packages/superdeck/lib/src/ui/superdeck_app.dart`, `demo/lib/main.dart` | conforming | Canonical v2 flow is live: `SuperDeckRuntime.create(...)` then `SuperDeckApp(runtime: runtime)`. |
| Explicit deck source types | `packages/superdeck/lib/src/runtime/deck_source.dart`, `demo/lib/main.dart` | conforming | `DeckSource.local(...)` and `DeckSource.bundle(...)` are the active entry path. |
| Runtime/presentation split | `packages/superdeck/lib/src/runtime/deck_runtime_config.dart`, `packages/superdeck/lib/src/presentation/deck_presentation.dart`, `packages/superdeck/lib/src/runtime/superdeck_runtime.dart` | intentional compatibility | Public split is correct, but runtime still adapts into internal `DeckConfiguration` + `DeckOptions`. |
| `DeckExtension` behavioral surface | `packages/superdeck/lib/src/presentation/deck_extension.dart`, `packages/superdeck/lib/superdeck.dart` | conforming | Canonical public type is correct. |
| `SuperDeckHandle` / `SuperDeck.of(context)` | `packages/superdeck/lib/src/runtime/superdeck_handle.dart`, `packages/superdeck/lib/src/runtime/superdeck_context.dart`, `demo/integration_test/helpers/test_helpers.dart` | conforming | Public access path is migrated. |
| Public barrel shape | `packages/superdeck/lib/superdeck.dart`, `packages/superdeck/lib/src/styling/styling.dart`, `packages/superdeck/lib/src/styling/schema/style_config.dart` | conforming | Main barrel is v2-shaped and no longer exports the `DeckOptions`-based style helper. |
| Docs and demo bootstrap | `demo/lib/main.dart`, public docs/READMEs | conforming | Runtime-first examples are live in demo and most docs. |
| CLI docs vs executable surface | `packages/cli/lib/runner.dart`, `packages/cli/README.md`, `docs/guides/cli-reference.mdx` | conforming | Docs and executable surface now agree that `build` / `build --watch` remain transitional v2.0 support. |
| Integration validation | `melos.yaml`, `flutter devices --machine`, direct demo macOS integration run | environment-only blocker | Linux integration cannot run on this host. Direct macOS integration did not reach app startup; it stalled inside Xcode build after repeated `DVTDeviceOperation` warnings. |

## Legacy Surface And Shim Inventory

Removed in this cleanup slice:

- public `StyleConfigLoader` export from `packages/superdeck/lib/src/styling/styling.dart`
- `watchForChanges`
- `DeckControllerBuilder`
- `SuperDeckPlugin` alias
- public-facing `DeckController.of(...)` reads in runtime UI/widgets
- `comments_panel.dart` / `CommentsPanel`
- demo integration helper aliases `findDeckController(...)` and `describeDeckControllerState(...)`
- tracked demo v1 artifact files and the stale CLI `generated_assets.json` log string

Remaining legacy items:

| Marker | Evidence | Status | Reason | Owner / Next Step |
|---|---|---|---|---|
| Internal `StyleConfigLoader` helper | `packages/superdeck/lib/src/styling/schema/style_config.dart` | keep as internal compatibility | YAML style merging remains opt-in and intentionally non-canonical for v2. | later styling cleanup |
| `DeckController` internal runtime state | `packages/superdeck/lib/src/runtime/deck_controller.dart`, `packages/superdeck/lib/src/runtime/superdeck_handle.dart`, `packages/superdeck/lib/src/ui/superdeck_app.dart` | keep as internal compatibility | Controller internals still back the runtime and handle, but no longer leak through public-facing widgets. | internal simplification slice |
| Downstream `package:superdeck/src/...` imports | `demo`, `packages/genui`, `packages/cli` scan | false positive / documentation history only | No active downstream consumer imports remain. Remaining hits are package-internal code/tests only. | none |
| Package-internal `src/` imports in tests | `packages/superdeck/test/...` | keep as test-only helper | Internal package tests still use `src/` access patterns. This is acceptable until test cleanup. | test-only cleanup |
| `@column` usage outside migration/test scope | `packages/core/lib/src/migrations/legacy_markdown_migrator.dart`, builder parser comments/tests | keep as migration tool | Canonical parser contract is already `@block`; remaining `@column` references are migration or test coverage. | migration tooling cleanup later |
| `SuperDeckRuntime.forTesting(...)` | `packages/superdeck/lib/src/runtime/superdeck_runtime.dart`, `packages/genui/test/presentation/view/presentation_deck_host_test.dart` | keep as test-only helper | Explicitly scoped for runtime-first widget tests. | test-only cleanup later |
| `LegacyMarkdownMigrator` | `packages/core/lib/src/migrations/legacy_markdown_migrator.dart`, `packages/builder/lib/src/slide_processor.dart`, `packages/builder/lib/src/parsers/markdown_parser.dart` | keep as migration tool | This is the correct place to isolate `@column` compatibility. | migration tooling |

## Protected-Surface Review

### Block Widgets

Status: signed off unchanged.

Evidence:

- `packages/superdeck/test/rendering/block_widget_test.dart`
- `packages/superdeck/test/behavior/layout_behavior_test.dart`
- `packages/superdeck/test/rendering/section_widget_test.dart`
- `packages/superdeck/test/behavior/alignment_behavior_test.dart`

No audit finding required deep block-widget changes. Remaining work is around bootstrap and legacy seams, not block rendering behavior.

### Hero Behavior

Status: signed off unchanged.

Evidence:

- `packages/superdeck/test/markdown/markdown_builders_test.dart`
- `packages/superdeck/test/markdown/markdown_helpers_test.dart`
- `packages/superdeck/test/markdown/builders/text_element_builder_test.dart`
- `packages/superdeck/test/markdown/builders/text_element_builder_widget_test.dart`
- `packages/core/test/src/hero_tag_helpers_test.dart`

Hero parsing, tag extraction, and runtime rendering still have direct coverage. No unexpected drift showed up in the runtime rewrite audit.

### Export / Thumbnail / Interaction Suppression

Status: signed off with one residual test-gap note.

Evidence:

- `packages/superdeck/test/export/thumbnail_service_test.dart`
- `packages/superdeck/test/export/async_thumbnail_test.dart`
- `packages/superdeck/test/export/pdf_controller_test.dart`
- `packages/superdeck/test/deck/slide_configuration_builder_test.dart`
- `demo/e2e/tests/smoke.spec.ts`

Observed result:

- thumbnail generation, cache behavior, PDF controller behavior, and thumbnail UI flows are still covered and green
- no audit evidence suggests a regression in export-mode interaction suppression
- there is still no narrowly named regression test dedicated only to export-mode hero/scroll suppression, so this remains a residual test gap rather than a drift finding

## Consumer And Cleanup Review

### `demo`

- bootstrap is correctly runtime-first
- web/non-web source split is correct
- tracked `.superdeck` output now keeps only `.v2.json` artifacts
- integration helpers now expose only `SuperDeckHandle` terminology

### `packages/genui`

- migrated off `package:superdeck/src/...` imports
- runtime-first host path is in place
- prompt wording now uses `notes`

### `packages/cli`

- real command surface still includes transitional `build`
- package README and CLI guide both document `build` / `build --watch` as supported through v2.0
- runtime watch via `DeckSource.local(watch: true)` is documented as the preferred workflow

### Public Docs / README Surface

- runtime/bootstrap docs are aligned
- CLI, demo, and widget docs no longer teach `DeckOptions`, `comments`, or controller-era bootstrap

## Validation Evidence

### Drift Scans

- targeted `rg` scans completed for:
  - `DeckOptions`
  - `watchForChanges`
  - `DeckControllerBuilder`
  - `SuperDeckPlugin`
  - `DeckController.of(...)`
  - `package:superdeck/src/...`
  - `comments`
  - `@column`
  - old artifact names
  - `forTesting(...)`
  - `LegacyMarkdownMigrator`

### Code Generation

- `packages/builder`: `../../.fvm/flutter_sdk/bin/dart run build_runner build --delete-conflicting-outputs`
  - passed
  - build_runner reported one output during the run, but no persistent repo diff remained under `packages/builder`
- `packages/genui`: `../../.fvm/flutter_sdk/bin/dart run build_runner build --delete-conflicting-outputs`
  - passed
  - wrote 0 outputs on the final audit pass

### Contracts And Analysis

- `packages/core`: `../../.fvm/flutter_sdk/bin/dart run tool/export_contract_schemas.dart --check`
  - passed
- repo analysis: `./.fvm/flutter_sdk/bin/dart analyze packages/core packages/builder packages/superdeck packages/genui packages/cli demo --fatal-infos`
  - passed

### Unit / Widget Tests

- `packages/core`: `../../.fvm/flutter_sdk/bin/dart test`
  - passed
- `packages/builder`: `../../.fvm/flutter_sdk/bin/dart test`
  - passed
- `packages/cli`: `../../.fvm/flutter_sdk/bin/dart test`
  - passed
- `packages/superdeck`: `../../.fvm/flutter_sdk/bin/flutter test`
  - passed
- `packages/genui`: `../../.fvm/flutter_sdk/bin/flutter test`
  - passed
- `demo`: `../.fvm/flutter_sdk/bin/flutter test`
  - passed

Note:

- `melos run test` is currently non-ideal for local non-TTY audit runs because it prompts for package selection unless `--no-select` is supplied
- package-level pinned-SDK commands were used instead for deterministic audit evidence

### Demo Build And Web Smoke

- `demo`: `../.fvm/flutter_sdk/bin/dart run superdeck_cli:main build`
  - passed, generated 30 slides
- `demo`: `../.fvm/flutter_sdk/bin/flutter build web --release`
  - passed
  - emitted wasm dry-run warnings only; build still completed successfully
- `demo/e2e`: `npm run test:smoke`
  - passed
  - 5/5 smoke tests green

### Integration Tests

- Linux CI-default integration could not be run locally because `flutter devices --machine` exposed only `macos` and `chrome`
- direct local macOS attempt:
  - command: `../.fvm/flutter_sdk/bin/flutter test integration_test -d macos --fail-fast --timeout 5m`
  - reached Xcode build phase but did not reach app test output before stalling
  - repeated `DVTDeviceOperation` warnings were observed from `xcodebuild`
  - classified as an environment/tooling blocker until reproduced or cleared on a clean local/CI macOS path

## Decision-Complete Next Cleanup Slice

Priority order:

1. Internal simplification
- remove the remaining internal `DeckOptions` bridge by teaching controller/template internals to consume v2 presentation types directly
- decide whether `StyleConfigLoader` should stay internal indefinitely or move into a dedicated migration/styling helper package

2. Test-only cleanup
- reduce package-internal `src/` imports in tests where reasonable
- keep `SuperDeckRuntime.forTesting(...)` only where runtime-first widget tests still need it

3. Migration tooling review
- keep `LegacyMarkdownMigrator` as the only intentional `@column` compatibility surface
- do a focused follow-up audit to ensure no non-migration/runtime code reintroduces legacy contract names

4. Environment follow-up
- rerun Linux/macOS integration coverage in a supported environment and classify the current macOS Xcode stall as `code issue` or `tooling issue`
