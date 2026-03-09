# SuperDeck V2 Implementation Audit

Date: 2026-03-09

## Scope

This audit records the implemented runtime/bootstrap surface after the provider/app
cleanup. Its job is to keep future planning aligned with code, not to preserve
intermediate rewrite shapes that were later deleted.

Primary references:
- `.planning/rewrite-v2-api-surface.md`
- `.planning/rewrite-v2-build-watch-runtime.md`
- `.planning/rewrite-v2-feature-matrix.md`
- `.planning/rewrite-v2-contract-migration-matrix.md`

## Executive Summary

The implemented runtime surface is now provider-first and deck-driven:

- `initializeSuperDeck()` is the async startup entrypoint.
- `DeckConfig.local(...)` and `DeckConfig.bundle(...)` select deck origin and
  local watch behavior.
- `SuperDeckProvider(config: ..., builder: ...)` owns deck loading, root-safe
  loading/error UI, rebuild overlay, and local `DeckWatcher` orchestration.
- `SuperDeckApp(deck: ..., theme: ..., extensions: ...)` is the render/runtime
  shell for a loaded `Deck`.
- `SuperDeck.of(context)` returns `DeckController` directly.
- `PresentationDeckHost`, `SuperDeckRuntime`, `DeckSource`,
  `DeckRuntimeConfig`, `DeckDataState`, and `SuperDeckHandle` are not current
  public APIs.

The remaining work in this area is documentation and validation hygiene, not a
new architecture pass.

## Plan-Conformance Review

| Area | Evidence | Status | Notes |
|---|---|---|---|
| Runtime bootstrap | `packages/superdeck/lib/src/runtime/superdeck_init.dart`, `packages/superdeck/lib/src/runtime/deck_config.dart`, `packages/superdeck/lib/src/runtime/superdeck_provider.dart`, `packages/superdeck/lib/src/ui/superdeck_app.dart`, `demo/lib/main.dart` | conforming | Canonical flow is `initializeSuperDeck(...)` then `SuperDeckProvider(...)` and `SuperDeckApp(deck: ...)`. |
| Runtime watch ownership | `packages/superdeck/lib/src/runtime/superdeck_provider.dart`, `packages/superdeck/lib/src/utils/deck_watcher.dart` | conforming | Local watch is provider-owned and enabled only through `DeckConfig.local(watch: true)`. |
| Render/runtime split | `packages/superdeck/lib/src/runtime/deck_controller.dart`, `packages/superdeck/lib/src/ui/superdeck_app.dart` | conforming | `DeckController` owns render/navigation/UI state; provider owns loading/error/rebuild lifecycle. |
| Advanced control surface | `packages/superdeck/lib/src/runtime/superdeck_context.dart`, `packages/superdeck/lib/src/runtime/deck_controller.dart` | conforming | `SuperDeck.of(context)` returns `DeckController`; there is no extra public handle layer. |
| Public docs/examples | `packages/superdeck/README.md`, `docs/`, `demo/slides.md` | in progress | Active docs are being reconciled to remove runtime-first/bootstrap-wrapper guidance. |
| GenUI presentation integration | `packages/genui/lib/src/routes.dart`, `packages/genui/lib/superdeck_genui.dart` | conforming | Default presentation composition is now in `genUiRoutes()`; `PresentationDeckHost` is removed. |

## Removed Or Non-Canonical Surfaces

These should not be reintroduced as target API shapes in planning docs:

- `SuperDeckRuntime`
- `DeckSource`
- `DeckRuntimeConfig`
- `DeckDataState`
- `SuperDeckProvider.of(context)`
- `SuperDeckHandle`
- `PresentationDeckHost`
- `SuperDeckApp(runtime: ...)`
- `SuperDeckApp.initialize()`

Historical references may still exist in session logs or migration discussion,
but they are not the current implementation contract.

## Current Ownership Boundaries

### `SuperDeckProvider`

Owns:
- resolving `DeckConfig`
- selecting `DeckService` vs `BundledDeckService`
- subscribing to deck updates
- root-safe loading/error UI
- rebuild overlay while keeping the last good deck visible
- local `DeckWatcher` startup when `watch: true`

Does not own:
- presentation routing
- slide navigation state
- menu/notes UI state
- extension-contributed UI

### `SuperDeckApp`

Owns:
- `DeckController` creation and disposal
- updating the controller when `deck` or `theme` changes
- `MaterialApp.router` and presentation shell wiring

Does not own:
- deck loading
- retry/rebuild lifecycle
- config/service selection

### `DeckController`

Owns:
- slide derivation from `Deck` + `DeckTheme`
- navigation/router state
- presentation UI state
- extension routes/actions/floating action integration
- thumbnail generation and PDF export in the current implementation

Deferred cleanup:
- thumbnail/export extraction remains a separate pass if it becomes necessary.

## Validation Status

This audit expects the following gates for the current cleanup slice:

- `./.fvm/flutter_sdk/bin/dart analyze packages/superdeck packages/genui demo --fatal-infos`
- `./.fvm/flutter_sdk/bin/dart run melos run test --no-select`
- `./.fvm/flutter_sdk/bin/dart run melos run test:integration:macos --no-select`

The audit content above reflects the intended canonical surface regardless of
whether those reruns are still pending in the current working session.

## Follow-Up

1. Keep planning/docs aligned with the provider/app surface.
2. Keep `genUiRoutes(..., presentationBuilder: ...)` as the customization seam
   instead of adding another public wrapper widget.
3. Revisit thumbnail/export ownership only if it blocks a concrete runtime
   simplification.
