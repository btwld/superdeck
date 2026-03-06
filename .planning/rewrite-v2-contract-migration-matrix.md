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
| Embedded watch API guidance | `DeckOptions.watchForChanges` is the current runtime-facing switch for embedded source rebuilds | Embedded watch moves to startup-only `DeckConfiguration.watch`; `DeckOptions.watchForChanges` is removed from the v2 runtime contract and survives only as legacy migration terminology | frozen | `packages/runtime_flutter`, `packages/cli`, `packages/migration_tools`, `packages/contracts` | Use `DeckConfiguration.watch` as a simple startup-only `bool`; planning docs use `watch` as the canonical v2 term and mention `watchForChanges` only as a legacy v1 migration reference | runtime tests, migration tests, API audit |
| Markdown block directive rename | `@column` and `@block` both parse today | Canonical v2 markdown block directive is `@block`; `@column` is migration-only | frozen | `packages/authoring`, `packages/migration_tools` | Keep parser compatibility while docs and migration tooling lead with `@block` | parser fixtures, migration tests |

## Defaults For Reconciliation
- Do not rename current-product docs or current runtime/API references to future-only names unless the public surface is already changed.
- Use canonical v2 terms in planning docs, and refer back to the current v1 surface explicitly when migration context matters.
- Keep legacy names such as `watchForChanges` explicit migration references instead of silently treating them as still canonical.
