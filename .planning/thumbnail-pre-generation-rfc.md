# RFC: Optional Thumbnail Pre-Generation Command

## Status

Draft

## Owner

SuperDeck maintainers

## Date

2026-02-13

## Problem

Today, thumbnails are generated at runtime when missing. This works well as a fallback, but teams may want an optional command that pre-generates thumbnails before release for:

1. Faster first paint in production.
2. Deterministic artifacts in CI.
3. Lower runtime capture work on lower-powered devices.

## Goals

1. Add an optional CLI workflow for thumbnail pre-generation.
2. Keep runtime fallback unchanged and always available.
3. Produce deterministic, cacheable thumbnail artifacts tied to deck + render config.
4. Keep the solution usable by package consumers without custom app wiring.

## Non-goals

1. Make pre-generation mandatory for `superdeck build`.
2. Remove runtime thumbnail generation.
3. Redesign slide rendering pipeline in this RFC.

## Current Behavior Summary

1. Builder default tasks generate Mermaid assets and deck references.
2. Runtime uses `ThumbnailService` and `SlideCaptureService` to generate missing thumbnails.
3. Runtime persistence is platform-aware through `ThumbnailCacheStore`.

## Command UX Candidates

## Option A

`superdeck build-thumbnails [options]`

Pros:

1. Explicit intent.
2. Easy to adopt in CI and release scripts.
3. Does not overload existing `build` semantics.

Cons:

1. Adds a new top-level command to maintain.

## Option B

`superdeck build --with-thumbnails`

Pros:

1. Reuses existing command.
2. Single entry point.

Cons:

1. Mixes two concerns (deck compile and runtime-like rendering).
2. Can increase default build complexity over time.

## Option C

`superdeck release` that composes build + optional thumbnail pass

Pros:

1. Useful for deployment workflows.

Cons:

1. Adds lifecycle orchestration complexity before base behavior is finalized.

## Recommendation

Choose Option A first: `superdeck build-thumbnails`.

Reason:

1. Clean separation from current build pipeline.
2. Easier iterative rollout.
3. Clear CI ergonomics.

## Rendering Architecture Alternatives

## Alternative 1: Headless Flutter App Render Pass

Description:

1. Launch a dedicated Flutter entrypoint that loads the deck and captures each slide.
2. Save outputs into `.superdeck/thumbnails`.
3. Emit manifest metadata.

Pros:

1. Reuses production rendering path.
2. Highest fidelity with runtime visuals.

Cons:

1. Requires managing device/runtime execution in CLI flow.
2. More platform complexity in CI.

## Alternative 2: Dedicated Builder Renderer

Description:

1. Build a non-app rendering path in builder to produce thumbnails.

Pros:

1. Keeps logic in builder package.

Cons:

1. Duplicates rendering behavior.
2. Higher drift risk from runtime visuals.

## Recommendation

Prefer Alternative 1 (headless Flutter render pass) to preserve fidelity and avoid duplicate rendering logic.

## Proposed Output Contract

Filesystem:

1. Use `DeckConfiguration.thumbnailsDir` as output root (do not hardcode `.superdeck/thumbnails`).
2. Use `DeckConfiguration.thumbnailsManifestJson` for manifest output.
3. File naming stays `thumbnail_<slideKey>.png` unless a future versioned scheme is introduced.

Manifest shape:

1. `schema_version`
2. `render_signature`
3. `slides[]` with `slide_key` and `file_name`

Invalidation inputs:

1. Slide key/content hash or deck reference timestamp.
2. Render signature (viewport, DPR, quality).
3. Theme/style fingerprint where applicable.

## Runtime Compatibility Rules

1. Runtime always attempts existing thumbnail path first.
2. If pre-generated thumbnail exists and is valid, runtime reuses it.
3. If missing/invalid, runtime fallback generation still executes.
4. Runtime cache store remains the same fallback layer.

## Web Consumption Gap (Must Be Addressed Before Implementation)

Current gap:

1. Web runtime cache store currently resolves from browser storage keys only.
2. It does not consume pre-generated thumbnail files from bundled assets today.

Required decision before Phase 1 implementation:

1. Define web strategy:
   - Option A: load bundled thumbnail files on web and bridge them into runtime resolution.
   - Option B: treat pre-generation as IO-only initially and keep web runtime generation.
2. Document chosen strategy explicitly in this RFC before coding starts.

## Failure Policy

1. Per-slide failures should be collected and reported.
2. Command exits non-zero only when configured threshold is exceeded.
3. Partial generation is allowed with explicit summary output.
4. Runtime fallback is never disabled by command failure.

## CI Considerations

1. Support `--headless` mode.
2. Support deterministic viewport/profile via flags.
3. Avoid requiring interactive desktop sessions.
4. Emit machine-readable summary for CI logs.

## Proposed CLI Flags

1. `--quality <thumbnail|good|better|best>`
2. `--width <px>`
3. `--height <px>`
4. `--dpr <double>`
5. `--force`
6. `--fail-fast`
7. `--json-report <path>`

## Rollout Plan

Phase 1:

Prerequisite:

1. Gate 3 approval from `thumbnail-runtime-cache-plan.md`.
2. Web consumption strategy decision recorded in this RFC.

1. Implement command skeleton and argument parsing.
2. Implement render pass for local desktop target.
3. Generate thumbnails + manifest.

Phase 2:

1. Add CI-friendly headless mode support and reporting.
2. Add retries and improved diagnostics.

Phase 3:

1. Evaluate optional integration into a release command.
2. Keep standalone command as stable primitive.

## Open Questions

1. Should command execute through Flutter test runner, Flutter run, or a dedicated executable target?
2. What is the minimum cross-platform support matrix for the first stable release?
3. What failure threshold should default to non-zero exit code?
4. Should manifest include a content hash per slide for stronger invalidation?

## Review Gate for Another Client

Before another client/team starts implementing this RFC:

1. Confirm this RFC status is promoted from `Draft` to `Approved`.
2. Confirm command naming decision (`build-thumbnails` vs alternatives).
3. Confirm execution model decision (headless Flutter render pass recommended).
4. Confirm failure policy and CI support requirements.
5. Link the approved decision back to `thumbnail-runtime-cache-plan.md` Gate 3.
