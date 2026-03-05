# SuperDeck V2 Build/Watch/Runtime Semantics

## Purpose
This document captures the current build/watch/runtime behavior that the v2 rewrite must either preserve, simplify, or intentionally change.

It exists because the current planning set already has:
- a parser contract in `.planning/rewrite-v2-parser-semantics.md`
- a product-surface inventory in `.planning/rewrite-v2-feature-matrix.md`

What it does not yet have is one place that explains how build execution, watch behavior, runtime deck loading, rebuild state, and thumbnail lifecycle fit together.

## Scope Boundary
This is an operational/runtime planning document.

- It covers build execution, watch ownership, runtime deck loading, rebuild signaling, and thumbnail lifecycle.
- It is not the canonical place for parser syntax decisions.
- It is not the canonical place for artifact renames or public API migration naming.
- It should inform the contract-migration matrix and the eventual runtime/build-engine package boundaries.

## Current Runtime Modes

### `kCanRunProcess`
Current runtime behavior is split by `kCanRunProcess`, which today is:
- `debug && !web && !test`

This matters because it changes what the app is allowed to do:
- on `kCanRunProcess` runtimes, the app can use filesystem-backed deck loading and can start a runtime watcher/builder path
- on web/test/release-like runtimes, the app loads bundled assets only and does not host the file-backed watch/build flow

### Current mode split
There are effectively two runtime modes today:

1. Process-capable runtime mode
- `DeckControllerBuilder` uses `DeckService`
- `DeckController` can subscribe to `DeckService.loadDeckStream()`
- if `DeckOptions.watchForChanges` is enabled, `DeckWatcher` may also start a build/watch loop inside the app

2. Bundled runtime mode
- `DeckControllerBuilder` uses `BundledDeckService`
- `DeckController` loads deck data once from bundled assets
- no file-backed watch/build path exists in this mode

## Current Build/Watch Stack

### 1. Build engine
`DeckBuilder` is the current build engine.

It is responsible for:
- reading `slides.md`
- parsing markdown into raw slides
- running slide tasks
- saving deck references
- saving build status
- clearing the generated-asset accumulator at build start

It is not CLI-only today.

## Current Build Process

The current one-shot build pipeline is:

1. Initialize storage/directories
- `DeckService.initialize()` ensures:
  - `.superdeck/` asset directory exists
  - deck JSON exists
  - build-status JSON exists
  - `slides.md` exists

2. Mark the build as running
- `DeckBuilder.build()` writes `build_status.json` with `status: building`

3. Reset the generated-asset accumulator
- `DeckService.clearGeneratedAssets()` clears the in-memory generated-asset list
- this is not the same thing as a CLI force rebuild, which also deletes files on disk

4. Read and parse authoring input
- `DeckService.readDeckMarkdown()` loads `slides.md`
- `MarkdownParser` splits and parses the raw markdown into slides

5. Run build tasks
- `SlideProcessor.processAll()` runs the configured task pipeline across slides
- the standard CLI/runtime builder pipeline currently includes:
  - `DartFormatterTask()`
  - `AssetGenerationTask.withDefaults(...)`

6. Persist build outputs
- `DeckService.saveReferences()` writes:
  - deck JSON
  - full deck JSON with markdown AST expansion
  - generated-assets reference JSON
  - thumbnail asset references derived from slide keys

7. Mark final status
- success writes `build_status.json` with `status: success`
- failure writes `build_status.json` with `status: failure` and serialized error details

This is the build process that should be reviewed before interface/model design.

### 2. CLI orchestration
`BuildCommand` is one orchestrator over that engine.

Today it provides:
- one-shot build
- `--watch`
- `--force-rebuild`
- stdin command handling in watch mode (`r`, `f`, `q`)

Current watch-mode behavior in the CLI:
- initial build runs first
- a long-lived builder is then reused for watch rebuilds
- manual rebuild and force rebuild reuse that same builder
- watch mode exits through stdin command handling or process termination

### 3. Runtime orchestration
`DeckWatcher` is another orchestrator over the same build engine.

Today it:
- creates a `DeckBuilder`
- subscribes to `watchAndBuild()`
- tracks watcher lifecycle state
- exposes typed-ish runtime signals:
  - status
  - error
  - isRebuilding

### 4. Current duplication
Builder creation is duplicated between CLI and runtime watcher:
- both create the same standard task pipeline
- both carry CI browser-launch concerns

That duplication is one of the rewrite motivations and should be treated as intentional cleanup work.

## Current Watch Behavior

### What is watched
Today the builder-side watcher watches only:
- `configuration.slidesFile`

That means the watch contract is narrower than the full product surface. It does not, by itself, establish a clear watch policy for:
- `styles.yaml`
- `superdeck.yaml`
- generated assets
- other authoring-side inputs

### Current event model
The build engine emits:
- `BuildStarted`
- `BuildCompleted`
- `BuildFailed`

This is the current shared event language between build execution and watch consumers.

### Current failure behavior
Build execution writes `build_status.json`.

On failure:
- the builder/runtime path records failure status
- deck artifacts are usually not replaced with a new failed deck
- the last good deck commonly remains available unless the deck artifact itself becomes unreadable

That distinction matters:
- build failure behavior
- deck-loading failure behavior

should not be treated as the same thing.

## Current Deck Consumption Loop

The app has a separate deck-consumption loop from the build/watch loop.

### File-backed consumption
`DeckService.loadDeckStream()`:
- emits the current deck immediately
- then watches the generated deck JSON for modifications
- reloads the deck when the generated deck artifact changes

This means there are really two loops today:

1. build/watch loop
- source markdown -> build engine -> artifacts

2. runtime deck-consumption loop
- artifacts -> runtime deck stream -> UI

These loops are related, but they are not the same thing and should not be collapsed conceptually.

### Bundled consumption
`BundledDeckService.loadDeckStream()` yields once from bundled assets.

So on non-process-capable runtimes, deck consumption still exists, but it is not a live file-backed stream.

## `watchForChanges` Today

`DeckOptions.watchForChanges` currently behaves like an app-level flag that allows runtime-triggered watch/build behavior on process-capable runtimes.

What it currently means in practice:
- if disabled, the app still loads and streams the generated deck artifact when file-backed deck loading is active
- if enabled and `kCanRunProcess` is true, the app also starts `DeckWatcher`, which can rebuild the deck from markdown and update rebuilding state

So `watchForChanges` is not just a UI flag.
It is currently a runtime/build orchestration flag.

That is why it needs a more explicit v2 definition than “compatibility shim or hard removal”.

There is also current code/comment drift here:
- the `DeckOptions.watchForChanges` inline doc still says it starts a CLI watcher process
- the actual implementation starts `DeckWatcher` directly inside the app on `kCanRunProcess` runtimes
- planning should follow implementation, not the stale inline comment

## Thumbnail Lifecycle Today

Thumbnail behavior is part of the same operational surface.

### Current thumbnail contract
- thumbnail file names are deterministic from slide keys
- `DeckService.saveReferences()` includes thumbnail asset paths in the generated-assets reference
- `SlideConfigurationBuilder` derives `thumbnailFile` from the slide key

### Current generation model
Thumbnail generation is runtime-side today.

`ThumbnailService`:
- resolves an existing thumbnail from cache or bundled assets
- captures a fresh slide image when needed
- writes it into the runtime asset cache

`DeckController.generateThumbnails()`:
- cleans stale thumbnail entries for removed slides
- triggers async thumbnail loading/generation
- updates the thumbnail cache owned by the controller

### Why thumbnails matter to build/watch planning
Thumbnail behavior depends on:
- stable slide identity
- runtime mode (`kCanRunProcess` vs bundled)
- asset-cache freshness rules
- when rebuilds change the effective slide render shape

So thumbnail invalidation and rebuild semantics should be planned together, not separately.

## Working Assumptions From Current Discussion

These are the current working assumptions to carry into the next decision pass:

1. The build engine must exist independently of the CLI.
- The app must be able to host the engine when the runtime allows it.
- CLI is an orchestrator, not the sole owner of build capability.

2. `kCanRunProcess` is a first-class runtime boundary.
- Process-capable and bundled-only runtimes should be treated as distinct operational modes.

3. `watchForChanges` is important as a feature, but compatibility is not the main concern.
- The important question is what the feature means and how it works.
- The less important question is preserving the current v1 surface exactly.

4. `superdeck.yaml` compatibility is low priority.
- It can be substantially redesigned or replaced if needed.

5. Build/watch behavior needs a deeper review before final model/interface design.
- The model contracts depend on the operational ownership boundaries here.

## Decisions Still To Freeze

The next pass should explicitly freeze the following:

1. Build-engine ownership
- Is the build engine a first-class runtime-capable service on process-capable runtimes, with CLI as optional orchestration?

2. Watch ownership
- Which layer is authoritative for starting/stopping watching:
  - app runtime
  - CLI
  - a shared dev session abstraction

3. Watch trigger surface
- What inputs should trigger rebuilds:
  - `slides.md` only
  - plus `styles.yaml`
  - plus operational config
  - plus other local authoring assets

4. Rebuild event/state model
- Which states are canonical and who consumes them:
  - building
  - success
  - failure
  - restarting
  - stopped

5. Failure policy
- What should happen on build failure versus deck-artifact load failure?
- When should the last good deck remain active?
- When should runtime surface a typed error state?

6. Force rebuild semantics
- What exactly is cleared?
- Which layer owns that behavior?

7. Thumbnail invalidation contract
- What changes invalidate thumbnails?
- Should invalidation be based only on slide key, or on slide key plus render signature?

## Recommended Next Step
Use this document as the operational companion to the parser contract.

The next planning pass should either:
- freeze the build/watch/runtime decisions listed above in this document, or
- fold the frozen outcomes into `.planning/rewrite-v2-feature-matrix.md` and the eventual contract-migration matrix

but it should not jump straight to package/interface modeling before these operational boundaries are explicit.
