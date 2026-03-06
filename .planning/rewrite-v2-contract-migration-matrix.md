# SuperDeck V2 Contract And Migration Matrix

## Purpose
This document is the canonical planning home for compatibility and public-surface migration decisions.

Use it for:
- artifact names and schema/versioning
- serialized field renames
- public package/barrel entry points
- migration guidance for runtime/API surface changes

This document does not force unresolved decisions closed.
Its job is to make them explicit, assign an owner, and attach a validation gate.

## Relationship To Other Planning Docs
- `.planning/rewrite-v2-parser-semantics.md` freezes parser-semantic names such as canonical `notes` and canonical `block`.
- `.planning/rewrite-v2-api-surface.md` freezes the canonical runtime/bootstrap API surface.
- `.planning/rewrite-v2-build-watch-runtime.md` freezes runtime/build ownership and operational boundaries.
- `.planning/rewrite-v2-feature-matrix.md` inventories the current product surface and tracks which migration/public rows are still open.
- `.planning/rewrite-v2-full-plan.md` is the umbrella rewrite plan and should point here for migration/public-surface details.

## Status Legend
- `frozen`: the canonical v2 surface is decided; remaining work is implementation and migration mechanics
- `open`: the current surface and target area are known, but the exact compatibility/migration policy still needs sign-off

## Matrix

| Surface | Current v1 surface | Canonical v2 surface | Status | Owner | Migration note | Validation gate |
|---|---|---|---|---|---|---|
| Slide note field | Slide notes serialize and flow through runtime/public contracts as `comments` | Planning, artifacts, and runtime/public v2 contracts use canonical `notes` | frozen | `packages/contracts`, `packages/migration_tools`, `packages/runtime_flutter` | Treat `comments` -> `notes` as a hard v2 break: no runtime dual-read compatibility, no artifact compatibility shim, and migration guidance/tooling is responsible for the rename | migration tests, contract tests, runtime tests |
| Deck artifact filenames and versioning | `.superdeck/superdeck.json`, `.superdeck/superdeck_full.json`, `.superdeck/generated_assets.json`, `.superdeck/build_status.json` | `.superdeck/superdeck.v2.json`, `.superdeck/superdeck_full.v2.json`, `.superdeck/generated_assets.v2.json`, `.superdeck/build_status.v2.json` | frozen | `packages/contracts`, `packages/build_engine`, `packages/migration_tools` | Use explicit v2 filenames during the breaking-contract transition so runtime/artifact expectations do not silently mix v1 and v2 files; migration tooling/docs own the rename | contract tests, integration tests |
| Public package/barrel entry surface | Public API currently flows through existing barrel exports such as `superdeck.dart` and `superdeck_core.dart`, with extra top-level helpers like `superdeck_core/asset_cache_store_io.dart` and `superdeck_cli/runner.dart` | Canonical v2 entry points are `package:superdeck/superdeck.dart`, `package:superdeck_core/superdeck_core.dart`, `package:superdeck_builder/superdeck_builder.dart`, `package:superdeck_genui/superdeck_genui.dart`, and `package:superdeck_cli/superdeck_cli.dart`; `package:superdeck_core/asset_cache_store_io.dart` remains an explicit platform-specific helper; `package:superdeck_cli/runner.dart` is removed from the supported public API surface | frozen | `packages/contracts`, `packages/runtime_flutter`, `packages/cli` | Keep one canonical primary barrel per package, keep the IO cache helper as an explicit specialized surface, and remove `runner.dart` from the long-term supported import set | API audit, migration tests |
| Primary runtime bootstrap surface | `SuperDeckApp(options: DeckOptions, configuration: DeckConfiguration?)` plus `SuperDeckApp.initialize()` | `SuperDeckRuntime.create(source, runtimeConfig, presentation)` followed by `SuperDeckApp(runtime: runtime)` | frozen | `packages/runtime_flutter`, `packages/migration_tools` | `SuperDeckApp.initialize()` and widget-first bootstrap are no longer canonical; migration guidance owns the move to runtime-first bootstrap | API audit, runtime tests, migration tests |
| Runtime/presentation config split | `DeckOptions` mixes presentation composition and embedded watch; `DeckConfiguration` carries local paths | `DeckSource` owns content origin, `DeckRuntimeConfig` owns startup-only operational paths, and `DeckPresentation` owns render composition | frozen | `packages/runtime_flutter`, `packages/migration_tools`, `packages/contracts` | `DeckOptions` survives only as migration scaffolding if needed; it is not the canonical v2 surface | API audit, runtime tests, migration tests |
| Embedded watch API guidance | `DeckOptions.watchForChanges` is the current runtime-facing switch for embedded source rebuilds | Embedded watch moves to `DeckSource.local(watch: true)` and is no longer a render-option concern | frozen | `packages/runtime_flutter`, `packages/cli`, `packages/migration_tools`, `packages/contracts` | Use `DeckSource.local(watch: ...)` as the canonical v2 term and treat `watchForChanges` only as legacy migration language | runtime tests, migration tests, API audit |
| Extension surface rename | `SuperDeckPlugin` is the current behavioral add-on concept | `DeckExtension` is the canonical behavioral/runtime add-on surface | frozen | `packages/runtime_flutter`, `packages/migration_tools` | Migrate plugin initialization/routes/actions/floating action behavior onto `DeckExtension`; `SuperDeckPlugin` is not canonical in v2 | API audit, runtime tests, migration tests |
| Advanced control surface | Advanced consumers currently reach into `DeckController` directly | `SuperDeckHandle` plus `SuperDeck.of(context)` are the canonical advanced-control surfaces | frozen | `packages/runtime_flutter`, `packages/migration_tools` | Keep controller internals non-primary and migrate advanced code to the narrow handle API | API audit, runtime tests |
| Markdown block directive rename | `@column` and `@block` both parse today | Canonical v2 markdown block directive is `@block`; `@column` is migration-only | frozen | `packages/authoring`, `packages/migration_tools` | Remove `@column` from public docs/examples and treat it as migration-only authoring terminology | parser fixtures, migration tests |

## Defaults For Reconciliation
- Do not rename current-product docs or current runtime/API references to future-only names unless the public surface is already changed.
- Use canonical v2 terms in planning docs, and refer back to the current v1 surface explicitly when migration context matters.
- Keep legacy names such as `watchForChanges` explicit migration references instead of silently treating them as still canonical.
