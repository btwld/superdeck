# Thumbnail Runtime Cache Plan

## Objective

Execute a robust thumbnail workflow that is consistent across desktop and web, while keeping the path open for a future generalized generated-asset cache.

## Execution Status (2026-02-13)

Completed in this cycle:

1. Web store hardening in `thumbnail_cache_store_web.dart`:
   - resolve/write/delete now handle failures without surfacing exceptions to UI flow.
   - invalid base64 cache entries are evicted on read.
2. IO store delete hardening in `thumbnail_cache_store_io.dart`:
   - delete now catches filesystem/async failures and logs without surfacing uncaught exceptions.
3. Reduced thumbnail refresh cache impact in `async_thumbnail.dart`:
   - replaced global `imageCache.clear()` with targeted provider eviction.
4. Added web-store regression tests in `thumbnail_cache_store_web_test.dart`.
5. Updated docs to align runtime vs build-time behavior:
   - `docs/guides/cli-reference.mdx`
   - `docs/guides/superdeck-overview.mdx`
6. Added optional pre-generation RFC document:
   - `.planning/thumbnail-pre-generation-rfc.md`
7. Added browser-storage stress coverage for quota/failure paths in
   `thumbnail_cache_store_web_test.dart`:
   - persistence returns false
   - persistence throws
   - preferences init throws
   - delete/cleanup remove failures

Pending for next cycle:

1. Implementation of the optional pre-generation command (RFC only at this stage).

## Scope

In scope:

1. Runtime thumbnail generation fallback when no file exists.
2. Runtime thumbnail persistence on IO and web.
3. Runtime cache sync behavior in `DeckController` and `ThumbnailService`.
4. Documentation alignment for runtime vs build-time generation.
5. Execution plan for optional future CLI thumbnail pre-generation.

Out of scope for this execution cycle:

1. Full generic asset cache refactor across all asset types.
2. New mandatory release workflow that requires thumbnail pre-generation.
3. Replacing the existing `SlideCaptureService` pipeline.

## Confirmed Baseline

1. `SlideConfiguration.copyWith` is type-safe now with `String? thumbnailFile` and `setThumbnailFile`.
2. Runtime thumbnail generation is done by `SlideCaptureService` through `ThumbnailService`.
3. `ThumbnailService` already uses the platform store abstraction `ThumbnailCacheStore`.
4. Builder default pipeline generates Mermaid assets only.
5. Runtime thumbnail path is still projected to `.superdeck/thumbnails/thumbnail_<slideKey>.png`.
6. IO store supports fallback write to application cache directory.
7. Web store persists base64 payloads in `shared_preferences`.

## Decision Log

### D1 - Keep `ThumbnailCacheStore` in current cycle

Decision:

1. Keep the current thumbnail-focused abstraction.

Reason:

1. It already isolates platform behavior.
2. It avoids widening scope during stabilization.

### D2 - Keep runtime generation fallback as primary safety net

Decision:

1. If bundled/configured thumbnail is missing, runtime generation remains active on desktop and web.

Reason:

1. Works for local development and package consumers.
2. Avoids adding hard build requirements.

### D3 - Do not switch to `flutter_cache_manager` yet

Decision:

1. Keep direct store implementations for now.

Reason:

1. Current logic is explicit and deterministic.
2. `flutter_cache_manager` does not materially improve the current web persistence path.
3. Introducing it now adds complexity without immediate product value.

### D4 - Keep `cached_network_image` usage limited to remote URLs

Decision:

1. Continue using it for `http/https` only.

Reason:

1. Generated thumbnails are local/data payloads and are better served by explicit stores.

## Architecture Contract (Target Behavior)

1. Slide config provides deterministic thumbnail identity path per slide key.
2. Runtime resolve attempts configured path first.
3. On miss, runtime resolve attempts platform cache key.
4. On miss, runtime capture generates thumbnail bytes.
5. Runtime write attempts configured path on IO.
6. If configured path write fails on IO, write to application cache directory.
7. On web, write to persistent browser-backed key-value store.
8. `AsyncThumbnail` transitions to `done` with URI or `done` with null when unavailable.
9. Cache entries are invalidated when slide key set changes or thumbnail path changes.
10. Force regeneration bypasses resolve and rewrites cache.

## Workstreams

## WS1 - Runtime Store Hardening

Goal:

1. Make cache writes/reads resilient and explicit under failure conditions.

Tasks:

1. `WS1-T1` Add explicit error handling in web store `write` and `resolve`.
2. `WS1-T2` Ensure failures do not throw to UI flow unless unrecoverable.
3. `WS1-T3` Add compact diagnostics logs for cache write/read failures.
4. `WS1-T4` Confirm IO fallback behavior remains unchanged and tested.

Files:

1. `packages/superdeck/lib/src/export/thumbnail_cache_store_web.dart`
2. `packages/superdeck/lib/src/export/thumbnail_cache_store_io.dart`
3. `packages/superdeck/lib/src/export/thumbnail_service.dart`

Acceptance:

1. Web storage errors do not crash thumbnail render flow.
2. IO write failure still succeeds via fallback cache file.
3. Regeneration still works after cache read failure.

## WS2 - Test Coverage Expansion

Goal:

1. Add regression coverage for cache behavior and failure paths.

Tasks:

1. `WS2-T1` Add store-level tests for web resolve/write/delete contract.
2. `WS2-T2` Add service-level tests for resolve miss then capture then write.
3. `WS2-T3` Add service-level tests for stale cache invalidation on path change.
4. `WS2-T4` Add tests for fallback URI reuse without recapture.
5. `WS2-T5` Add tests covering force refresh semantics.

Files:

1. `packages/superdeck/test/export/thumbnail_service_test.dart`
2. `packages/superdeck/test/export/thumbnail_write_contract_test.dart`
3. `packages/superdeck/test/export/async_thumbnail_test.dart`
4. New test file for web store behavior if needed.

Acceptance:

1. All thumbnail runtime paths have direct test assertions.
2. Error/fallback logic is covered and reproducible.

## WS3 - Documentation Correction and Clarity

Goal:

1. Remove ambiguity about what is generated at build-time vs runtime.

Tasks:

1. `WS3-T1` Fix CLI file-tree docs to avoid implying thumbnail-in-assets path.
2. `WS3-T2` Add explicit statement that Mermaid is build-time and thumbnails are runtime fallback.
3. `WS3-T3` Add short note on platform persistence behavior and limits.
4. `WS3-T4` Verify docs do not state that `superdeck build` pre-generates thumbnails.

Files:

1. `docs/guides/cli-reference.mdx`
2. `docs/guides/superdeck-overview.mdx`
3. Optional reference page updates if needed.

Acceptance:

1. Docs match actual behavior in code.
2. Runtime fallback model is clear to users.

## WS4 - Optional CLI Pre-Generation RFC

Goal:

1. Produce a design-ready path for optional thumbnail pre-generation without blocking current runtime workflow.

Tasks:

1. `WS4-T1` Define command contract candidates.
2. `WS4-T2` Compare execution models.
3. `WS4-T3` Define output manifest format and compatibility expectations.
4. `WS4-T4` Define failure behavior and fallback policy.
5. `WS4-T5` Define CI/headless constraints and developer ergonomics.

Command candidates:

1. `superdeck build-thumbnails`
2. `superdeck build --with-thumbnails`
3. `superdeck release` composing build plus optional thumbnail pass

Execution model candidates:

1. Headless Flutter runtime rendering of slides.
2. Dedicated renderer pipeline in builder package.

Acceptance:

1. Clear RFC with recommended approach and explicit non-goals.
2. Runtime fallback remains in place regardless of RFC outcome.

## WS5 - Future Generalized Generated Asset Cache (Deferred)

Goal:

1. Prepare path to support runtime-generated non-thumbnail assets without premature refactor.

Tasks:

1. `WS5-T1` Define a typed cache key model.
2. `WS5-T2` Rename abstraction to generic form only when second asset type is ready.
3. `WS5-T3` Add migration notes for existing thumbnail keys.

Acceptance:

1. No immediate change required in current cycle.
2. Design is ready when a second runtime asset type is introduced.

## Detailed Task Backlog

## Sprint A - Stabilization

1. `A1` Harden web store error handling.
2. `A2` Add/adjust tests for web store failure and success paths.
3. `A3` Validate no behavioral regression in IO fallback path.
4. `A4` Confirm `AsyncThumbnail.shouldRefreshOnSync` behavior under null URI.

Exit criteria:

1. Runtime path is resilient across expected storage failures.
2. Tests demonstrate resolve, generate, write, and reuse behavior.

## Sprint B - Docs and Product Clarity

1. `B1` Correct CLI docs file-tree description.
2. `B2` Update overview docs on build/runtime asset split.
3. `B3` Add platform-specific persistence notes.

Exit criteria:

1. No contradictory statements remain in user docs.
2. Expected behavior is clear for web and desktop users.

## Sprint C - RFC for Optional Pre-Generation

1. `C1` Write RFC with command UX and expected artifacts.
2. `C2` Include headless execution constraints.
3. `C3` Include rollout and fallback strategy.

Exit criteria:

1. Team can approve or reject pre-generation implementation with low ambiguity.

## Verification Matrix

Desktop IO:

1. Thumbnail file already exists at configured path.
2. Thumbnail file missing and configured path writable.
3. Thumbnail file missing and configured path not writable.
4. Stale cache entry after slide removal.
5. Force regeneration overwrites old bytes.

Web:

1. Cached entry exists in preferences and resolves to data URI.
2. No cached entry triggers capture and write.
3. Write failure does not crash UI and returns fallback null path behavior.
4. Slide key/path change invalidates old cached key.

Cross-cutting:

1. Thumbnail panel renders loading then image.
2. Error state renders placeholder and does not loop infinitely.
3. Cache hit avoids repeat capture.

## Commands for Verification

Analysis:

1. `melos run analyze`

Targeted tests:

1. `fvm flutter test packages/superdeck/test/export/thumbnail_service_test.dart`
2. `fvm flutter test packages/superdeck/test/export/thumbnail_write_contract_test.dart`
3. `fvm flutter test packages/superdeck/test/export/async_thumbnail_test.dart`

Optional broader confidence:

1. `melos run test`

## Risks and Mitigations

Risk 1:

1. Web storage quota and browser-specific behavior may cause intermittent persistence failures.

Mitigation:

1. Treat write failures as cache miss.
2. Keep generation fallback functional.
3. Add diagnostics logs.

Risk 2:

1. Docs drift from implementation.

Mitigation:

1. Tie doc updates to WS3 completion gate.
2. Add docs review checklist item before merge.

Risk 3:

1. Future generalized cache refactor introduces unnecessary churn now.

Mitigation:

1. Defer WS5 to explicit trigger event.
2. Keep current implementation focused on thumbnails.

## Release Gates

Gate 1:

1. WS1 and WS2 complete.
2. No regressions in targeted export/thumbnail tests.

Gate 2:

1. WS3 complete.
2. User-facing docs reviewed for consistency.

Gate 3:

1. WS4 RFC approved before any pre-generation implementation starts.

## Cross-Client Execution Handoff

Use this when another client/team picks up execution.

Pre-handoff package:

1. Share `.planning/thumbnail-runtime-cache-plan.md`.
2. Share `.planning/thumbnail-pre-generation-rfc.md`.
3. Share current touched implementation files:
   - `packages/superdeck/lib/src/export/thumbnail_cache_store_io.dart`
   - `packages/superdeck/lib/src/export/thumbnail_cache_store_web.dart`
   - `packages/superdeck/lib/src/export/async_thumbnail.dart`
   - `packages/superdeck/test/export/thumbnail_cache_store_web_test.dart`
   - `docs/guides/cli-reference.mdx`
   - `docs/guides/superdeck-overview.mdx`

Execution order for the next client:

1. Confirm baseline and decisions (`Objective`, `Decision Log`, `Architecture Contract`).
2. Run Gate 1 verification commands before adding new behavior.
3. Execute remaining pending tasks only (do not reopen completed tasks).
4. Update `Execution Status` with date and explicit completed/pending bullets.
5. Stop at each gate for review sign-off before continuing.

Handoff acceptance checklist:

1. Reviewer can identify current status without reading git history.
2. Reviewer can run all listed verification commands as-is.
3. Pending items are explicit and non-ambiguous.
4. No documentation statement contradicts runtime behavior.

## Pre-Review Checklist

Run this checklist before requesting a review.

Code and tests:

1. `melos run analyze` passes.
2. Thumbnail-focused tests pass:
   - `fvm flutter test packages/superdeck/test/export/thumbnail_service_test.dart`
   - `fvm flutter test packages/superdeck/test/export/thumbnail_write_contract_test.dart`
   - `fvm flutter test packages/superdeck/test/export/async_thumbnail_test.dart`
   - `fvm flutter test packages/superdeck/test/export/thumbnail_cache_store_web_test.dart`
3. Any new failure-path behavior has direct regression coverage.

Docs and planning:

1. `docs/guides/cli-reference.mdx` matches actual build/runtime behavior.
2. `docs/guides/superdeck-overview.mdx` reflects the same runtime/build split.
3. `Execution Status` in this plan is updated with exact date.
4. RFC status is accurate (`Draft`/`Approved`/`Implemented`).

Review packet for maintainers:

1. Short summary of what changed.
2. Explicit list of files changed.
3. Commands run and pass/fail status.
4. Known limitations and deferred items.

## Definition of Done

1. Runtime thumbnail generation and caching are stable on desktop and web.
2. Failure paths are graceful and tested.
3. Documentation accurately reflects current behavior.
4. Optional pre-generation path is specified as an approved RFC, not implicit behavior.
