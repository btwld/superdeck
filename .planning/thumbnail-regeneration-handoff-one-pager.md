# Thumbnail Regeneration One-Pager (RFC + Execution Plan + Handoff)

## Status Snapshot (2026-02-13)

Objective:

1. Keep thumbnail generation reliable on desktop/web today.
2. Prepare optional pre-generation command for release/CI workflows.

Current state:

1. Runtime fallback generation is active via `ThumbnailService` + `SlideCaptureService`.
2. Platform cache abstraction is active via `ThumbnailCacheStore`.
3. Web cache store was hardened (non-throwing resolve/write/delete, invalid payload eviction).
4. IO cache store delete is now hardened to avoid uncaught async file errors.
5. Web cache store regression tests were added.
6. Docs now clearly separate build-time Mermaid generation vs runtime thumbnail generation.
7. Browser-storage stress tests now cover quota/failure paths (set false/throw, init failure, cleanup failure).
8. Pre-generation is still RFC-only (not implemented yet).

## What Is Already Implemented

Code:

1. `packages/superdeck/lib/src/export/thumbnail_service.dart`
2. `packages/superdeck/lib/src/export/async_thumbnail.dart`
3. `packages/superdeck/lib/src/export/thumbnail_cache_store.dart`
4. `packages/superdeck/lib/src/export/thumbnail_cache_store_base.dart`
5. `packages/superdeck/lib/src/export/thumbnail_cache_store_io.dart`
6. `packages/superdeck/lib/src/export/thumbnail_cache_store_web.dart`
7. `packages/superdeck/lib/src/export/thumbnail_cache_store_stub.dart`
8. `packages/superdeck/lib/src/ui/widgets/cache_image_widget.dart`
9. `packages/superdeck/test/export/thumbnail_service_test.dart`
10. `packages/superdeck/test/export/thumbnail_write_contract_test.dart`
11. `packages/superdeck/test/export/thumbnail_cache_store_web_test.dart`

Docs:

1. `docs/guides/cli-reference.mdx`
2. `docs/guides/superdeck-overview.mdx`

Planning:

1. `.planning/thumbnail-runtime-cache-plan.md`
2. `.planning/thumbnail-pre-generation-rfc.md`

## Decisions (Working Baseline)

1. Keep runtime thumbnail fallback as mandatory safety net.
2. Keep `ThumbnailCacheStore` abstraction in current cycle.
3. Do not switch to `flutter_cache_manager` in this cycle.
4. Keep `cached_network_image` usage only for `http/https`.
5. Pre-generation command remains optional and should not break runtime fallback.

## RFC Recommendation (Pre-Generation)

Recommended command:

1. `superdeck build-thumbnails`

Recommended rendering model:

1. Headless Flutter render pass (reuse runtime rendering path for fidelity).

Expected outputs:

1. `DeckConfiguration.thumbnailsDir/<thumbnail_file_name>`
2. `DeckConfiguration.thumbnailsManifestJson`

## Remaining Implementation Work

Phase 1 (after Gate 3 RFC approval):

1. Implement `build-thumbnails` command skeleton in CLI.
2. Implement thumbnail render pass + output write.
3. Emit/update thumbnails manifest via `DeckConfiguration` paths.
4. Define and implement web pre-generated thumbnail consumption strategy.
5. Add command-level tests and docs.

Phase 2:

1. Add CI/headless flags and machine-readable report.
2. Add retry and failure-threshold behavior.

## Cross-Client Execution Steps

1. Read this file first.
2. Read `.planning/thumbnail-runtime-cache-plan.md` for full task matrix.
3. Read `.planning/thumbnail-pre-generation-rfc.md` for command/RFC details.
4. Run validation commands before touching code.
5. Execute only pending tasks; do not reopen completed tasks.
6. Update `Execution Status` in `thumbnail-runtime-cache-plan.md` with date.
7. Stop for review at each gate below.

## Review Gates (Must Pass in Order)

Gate 1:

1. Runtime/store/test baseline remains green.

Gate 2:

1. User docs match behavior after any new changes.

Gate 3:

1. RFC decisions are approved before implementing pre-generation command behavior changes.

## Validation Commands

1. `melos run analyze`
2. `fvm flutter test packages/superdeck/test/export/thumbnail_service_test.dart`
3. `fvm flutter test packages/superdeck/test/export/thumbnail_write_contract_test.dart`
4. `fvm flutter test packages/superdeck/test/export/async_thumbnail_test.dart`
5. `fvm flutter test packages/superdeck/test/export/thumbnail_cache_store_web_test.dart`

## Pre-Review Packet (What to Send)

1. Short summary: completed/pending.
2. Exact changed file list.
3. Command outputs (analyze/tests).
4. Known limitations/deferred items.

## Definition of Done for Handoff Consumer

1. Reviewer can execute commands without guessing hidden steps.
2. Reviewer can distinguish completed vs pending work immediately.
3. Runtime fallback remains intact.
4. Pre-generation work is either RFC-approved or explicitly blocked pending approval.
