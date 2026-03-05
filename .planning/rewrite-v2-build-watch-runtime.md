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

## Current Configuration Inputs

### Frozen scope for this pass
For the current runtime/build sign-off, the configuration scope is intentionally narrower than the full historical surface.

- freeze the in-app/local runtime configuration model first:
  - explicit `DeckConfiguration` passed into the app
  - `DeckOptions` passed into the app
  - runtime defaults when nothing explicit is provided
- defer external configuration-source policy:
  - `superdeck.yaml` acquisition and strictness
  - `styles.yaml` loading and merge policy

That keeps this phase focused on runtime behavior rather than on how configuration is discovered from disk.

### `superdeck.yaml`
`superdeck.yaml` is currently part of the implementation surface, but it is deferred from the current runtime sign-off scope.

Configuration handling is not uniform today.

CLI behavior:
- `BaseCommand.loadConfiguration()` reads `superdeck.yaml`
- invalid YAML or invalid schema shape is a hard command failure

Runtime IO behavior:
- `resolveConfiguration()` reads `superdeck.yaml` only when no explicit override is passed
- malformed YAML, invalid schema, empty files, and comment-only files all fall back to default configuration

Runtime web/test behavior:
- `resolveConfiguration()` does not read local YAML at all
- bundled runtimes use the explicit override if provided, otherwise default configuration

So the current system already has different strictness and different configuration availability by runtime.
That should be revisited later as an external config-source decision, not as a blocker for freezing embedded runtime watch behavior.

### `styles.yaml`
`styles.yaml` is currently a separate, opt-in runtime concern and is also deferred from the current runtime sign-off scope.

- `StyleConfigLoader.loadAndMerge()` can load and merge `styles.yaml`
- merge precedence is YAML first, then code options on top
- this is not wired into `SuperDeckApp` automatically today
- the demo app does not load it by default

That means `styles.yaml` changes are not part of the current watch contract unless an app explicitly builds that behavior itself.

### Configuration lifecycle inside the app
`DeckControllerBuilder` currently resolves configuration only during `initState()`.

- it creates the deck service once
- it creates the optional runtime watcher once
- `didUpdateWidget()` updates only `DeckOptions`
- changing `configuration` after the controller is created does not rebuild the service/watcher graph

This makes configuration effectively startup-only in the current app lifecycle.

## Frozen v2 local runtime configuration contract

### 1. App-facing local runtime surface
For this phase, the frozen local runtime configuration surface is:

- `SuperDeckApp(options: DeckOptions, configuration: DeckConfiguration?)`
- runtime defaults when `configuration` is omitted

This is the configuration contract we freeze now.
How values are loaded from external YAML sources is deferred.

### 2. `DeckConfiguration` ownership
`DeckConfiguration` owns local source/artifact location semantics.

Its current/frozen field set is:
- `projectDir`
- `slidesPath`
- `outputDir`
- `assetsPath`

Recommended v2 contract:
- keep `DeckConfiguration` limited to local path/layout concerns
- keep path values relative/path-safe local configuration
- do not put style/template/widget/plugin/render behavior into `DeckConfiguration`
- `slidesPath` matters for embedded source rebuild/watch
- `outputDir` / `assetsPath` matter for generated artifact lookup and asset resolution

### 3. `DeckOptions` ownership
`DeckOptions` owns local runtime/render composition.

Its current v1 surface includes:
- `baseStyle`
- `styles`
- `widgets`
- `parts`
- `debug`
- `templates`
- `defaultTemplate`
- `watchForChanges`
- `plugins`

Recommended v2 contract:
- keep style/template/widget/chrome/plugin/render composition in `DeckOptions`
- keep file-system/source/artifact location out of `DeckOptions`
- move embedded watch control out of `DeckOptions` and into the startup-only local runtime/session surface

Frozen composition split for v2:
- live render/styling composition:
  - `baseStyle`
  - `styles`
  - `widgets`
  - `parts`
    - header
    - footer
    - background
  - `templates`
  - `defaultTemplate`
  - `debug`
- startup-only runtime/session wiring:
  - embedded watch/build enablement
  - plugin set / plugin initialization

Note:
- the contract frozen here is that embedded watch is not a normal render option anymore
- the still-open part is only the exact startup API placement/name for that watch control

### 4. Mutability contract
Not all local runtime configuration is equally dynamic today.

Startup-only local runtime configuration:
- all of `DeckConfiguration`
- plugin set / plugin initialization
- embedded watch ownership/control

Live-update-capable local runtime configuration:
- `baseStyle`
- `styles`
- `widgets`
- `parts`
- `debug`
- `templates`
- `defaultTemplate`

Reason:
- `DeckControllerBuilder.didUpdateWidget()` updates `DeckOptions`
- but it does not rebuild the service/watcher/router graph
- plugin routes are created during controller construction
- watcher setup happens during builder initialization

So the recommended v2 rule is:
- render composition may update live
- operational/runtime wiring requires app restart/recreation

### 5. Defaults
Default local runtime configuration remains:

- `projectDir = '.'`
- `slidesPath = 'slides.md'`
- `outputDir = '.superdeck'`
- `assetsPath = 'assets'`

Default runtime behavior remains:
- consume already-built deck artifacts
- embedded app watch/build is off unless explicitly enabled on process-capable runtimes

### 6. Deferred from this contract
The following are intentionally deferred:
- `superdeck.yaml` acquisition/strictness policy
- `styles.yaml` loading/merge policy
- exact bundled-runtime custom-path support rules

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

### Frozen v2 trigger-surface decision
For the initial embedded runtime watch contract:

- automatic deck rebuild/watch is required only for `configuration.slidesFile`
- in the default case, that means `slides.md`
- markdown/content source changes rebuild and reparse the deck artifacts

This does not mean all presentation changes must go through the deck watcher.

Code-driven render/styling changes should continue to flow through normal Flutter workflow instead:
- header/footer/background changes via `parts`
- style/template/widget definition changes in app code
- other code-side render composition changes

Those changes should be expected to appear through Flutter hot reload / widget rebuild behavior, not through deck-watcher file watching.

So the frozen split is:
- markdown authoring changes -> deck watcher / builder rebuild
- code composition changes -> Flutter hot reload / app rebuild path

External config-source files such as `styles.yaml` / `superdeck.yaml` remain deferred from this pass.

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

## Current Deck Update Lifecycle

This is the current end-to-end flow when source content changes in a process-capable runtime:

1. Configuration is chosen
- from explicit `SuperDeckApp(configuration: ...)`, or
- from runtime `resolveConfiguration()`, or
- from CLI `loadConfiguration()`

2. A build is triggered
- by CLI watch, or
- by runtime `DeckWatcher` when `watchForChanges` is enabled

3. The builder rebuilds from `slides.md`
- `DeckBuilder` parses markdown
- slide tasks run
- deck/build status/assets are saved

4. The runtime deck stream sees artifact changes
- `DeckService.loadDeckStream()` watches the generated deck JSON, not `slides.md`
- successful rebuilds that rewrite `superdeck.json` cause a deck reload

5. The controller recomputes presentation state
- `_currentDeck` is replaced
- `slides` is recomputed
- current index is clamped if the deck became shorter

6. Thumbnail state is not fully reconciled at deck-load time
- thumbnails are not regenerated automatically just because a new deck arrived
- stale in-memory thumbnail entries are only cleaned when `generateThumbnails()` runs

7. Build failures do not become main deck-controller errors
- `build_status.json` is written
- `DeckWatcher` status/error are updated
- `DeckController` only receives rebuilding on/off
- if the last good deck artifact still exists, the app usually continues showing that deck

This is the core distinction:
- build/watch drives source-to-artifact updates
- deck streaming drives artifact-to-UI updates
- thumbnail reconciliation is currently adjacent to, but not owned by, either pipeline

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

## Runtime Mode Matrix

### Frozen v2 runtime-mode decision
For v2, the runtime-mode contract is:

- process-capable runtimes (`kCanRunProcess`) support embedded app watch/build as a first-class mode
- the app must be able to watch source changes, rebuild, parse, and live-reload deck artifacts without depending on the CLI
- bundled web/release-like runtimes are consume-only:
  - they do not watch local files
  - they do not rebuild from source markdown
  - they read the already-built bundled deck value and bundled assets

This freezes the mode boundary itself.
What remains open is the exact API placement, trigger surface, and failure/reporting contract inside the process-capable mode.

### 1. Process-capable runtime with `watchForChanges: false`
This is the current "consume built artifacts only" mode.

- the app uses `DeckService`
- the app watches generated deck JSON for changes
- the app does not rebuild source markdown itself
- this is the current compatibility mode for "external build flow rewrites artifacts, app live-reloads them"

### 2. Process-capable runtime with `watchForChanges: true`
This is the current embedded build/watch mode and the intended first-class v2 watch mode.

- the app uses `DeckService`
- the app also starts `DeckWatcher`
- the app can rebuild from `slides.md` itself and then live-reload the resulting deck JSON

In v2 planning, this mode should remain supported explicitly.
CLI watch may still exist as optional orchestration, but it is not the required owner of dev watch behavior.

Operationally, this still means CLI watch and runtime watch can overlap if both are used at once.
The exact ownership rule and overlap-prevention behavior are still open.

### 3. Bundled web/test/release-like runtime
This is the current bundled-only mode and the intended v2 bundled/runtime contract.

- the app uses `BundledDeckService`
- deck loading is one-shot from bundled assets
- no local markdown watch/build loop exists
- local `superdeck.yaml` is not read automatically

This mode has materially different behavior from process-capable runtimes and should be treated as its own contract.
In v2 planning, it remains a consume-only runtime mode.

### Frozen workflow simplification for local development
For the current/next local development workflow on process-capable runtimes:

- the primary dev loop should be `flutter run` plus embedded app watch/build
- CLI watch is not required for the active local dev loop

This simplifies the architecture because it removes the need to treat CLI watch as a peer workflow owner during normal runtime iteration.

CLI still remains important outside that primary loop for now:
- one-time/bootstrap setup responsibilities
  - sample `slides.md`
  - `pubspec.yaml` asset patching
  - web `index.html` setup
  - macOS entitlements
- publish/deployment responsibilities
- optional one-shot/manual build workflows

So the simplification is:
- remove CLI from the primary day-to-day dev watch loop
- do not remove CLI from the product surface entirely yet

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

There is an additional operational nuance:
- `watchForChanges` does not control deck JSON live-reload
- on `kCanRunProcess` runtimes, the app already live-reloads deck artifacts through `DeckService.loadDeckStream()`
- `watchForChanges` only adds source-side rebuild ownership inside the app

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

## Detailed Thumbnail Workflow

### 1. Thumbnail identity
- `SlideConfigurationBuilder` derives `thumbnailFile` as `thumbnail_<slideKey>.png`
- the slide key is stable for the parsed slide content and duplicate-collision handling, so thumbnail identity currently follows slide identity

### 2. Build-time output contract
- `DeckService.saveReferences()` includes thumbnail paths in `generated_assets.json`
- but the standard build pipeline does not generate thumbnail bytes
- that means thumbnail paths are currently declared in the generated-assets manifest before runtime capture necessarily creates any file for them

### 3. Runtime trigger
- thumbnails are generated from the app shell when the menu/panel is opened
- `DeckController.generateThumbnails()` currently:
  - computes the active slide set
  - removes stale `AsyncThumbnail` instances from the in-memory controller cache
  - delegates generation/load to `ThumbnailService`
- there is also a manual force-regenerate action in the bottom bar

### 4. Runtime resolve-or-capture behavior
`ThumbnailService.generateThumbnail()` currently does:

1. resolve existing thumbnail by `thumbnailFile`
2. if `force`, delete runtime cache entry first
3. if no resolved thumbnail exists, capture the slide widget to PNG
4. write the PNG through the active runtime cache store

### 5. Runtime storage layers
There are currently two thumbnail storage/fallback layers on IO platforms:

1. app runtime cache
- stored under system temp, scoped by `.superdeck` path hash
- persists across app restarts until temp cleanup

2. bundled/build asset fallback
- if the runtime cache misses, the store falls back to `.superdeck/assets/<thumbnailFile>`
- if both exist, the newer file wins by last-modified timestamp

On web:
- the cache store resolves bundled assets first and otherwise uses in-memory data URIs
- writes are not persisted across refreshes

### 6. Capture model
- thumbnail bytes are produced by `SlideCaptureService`
- it renders `SlideView(exportingSlide)` into an off-screen render tree
- capture uses the current Flutter theme/media context
- concurrency is intentionally capped (`_maxConcurrentGenerations = 3`)

This means current thumbnails are render-derived runtime snapshots, not pure parser/build artifacts.

### 7. Reset behavior
Thumbnail reset currently happens in several different ways:

- deck-change cleanup:
  - stale `AsyncThumbnail` objects are removed only when `DeckController.generateThumbnails()` runs
- per-thumbnail force refresh:
  - `ThumbnailService.generateThumbnail(force: true)` deletes the runtime cache entry for that thumbnail key before recapturing
- CLI force rebuild:
  - clears `.superdeck/assets/` and `generated_assets.json`
  - does not clear runtime temp thumbnail cache

So "reset thumbnails" does not currently mean one thing across the system.

### 8. Mode-specific cache behavior
On process-capable IO runtimes:
- runtime writes thumbnails to a temp-cache directory scoped by `.superdeck` path hash
- resolve order is:
  - temp runtime cache
  - bundled/build asset fallback
- if both exist, the newer file wins

On bundled web runtimes:
- resolve order is:
  - in-memory runtime cache
  - bundled asset bytes
- writes stay in memory only
- refreshing the app clears runtime-written thumbnail cache

On bundled release-like IO runtimes:
- deck loading is bundled-only
- thumbnail fallback still goes through the IO runtime cache abstraction
- so deck loading and thumbnail resolution do not have exactly the same storage semantics

## Thumbnail Findings And Risks

### 1. Build artifact vs runtime cache semantics are mixed
- the build manifest lists thumbnail paths
- the runtime is what usually creates the actual thumbnail bytes
- the same `AssetCacheStore` abstraction is used for:
  - build-time persistent generated assets
  - runtime thumbnail cache/fallback resolution

That makes the contract harder to reason about because "asset cache" does not mean one thing.

### 2. Invalidation is keyed only by slide key
- if slide content changes enough to change the slide key, thumbnail identity changes too
- but if effective rendering changes without changing the slide key, the current cache key may stay stable

Examples of likely stale-thumbnail cases:
- external style/template changes
- deck-level visual changes
- runtime-only rendering changes that affect the preview but do not change the parsed slide key

### 3. Triggering is panel-open-centric, not deck-change-centric
- thumbnails are kicked off when the menu opens
- the current trigger is not explicitly tied to deck reload completion or slide-set changes
- if the deck changes while the menu remains open, missing/new thumbnails may rely on manual regeneration or another trigger path

### 4. Cleanup is only partial today
- `DeckController.generateThumbnails()` removes stale in-memory `AsyncThumbnail` entries
- it does not delete old runtime cache files for no-longer-used slide keys
- temp-cache thumbnail files can therefore accumulate over time

### 5. Eager generation can be expensive for large decks
- opening the menu starts generation/load work for the whole slide set
- concurrency is capped, which helps memory pressure
- but the workflow is still eager rather than visible-first or nearby-first

### 6. Bundled runtime path handling is not fully aligned with `DeckConfiguration`
- `BundledDeckService` loads deck JSON from a fixed `'.superdeck/superdeck.json'` path by default
- other runtime pieces still derive asset paths from `DeckConfiguration`
- this means custom bundled `outputDir` / `assetsPath` behavior is not clearly one coherent contract today

### 7. Watch/build failures are not promoted into the main runtime error model
- watcher failure details live on `DeckWatcher`
- `DeckController` only exposes `isRebuilding`
- `build_status.json` is written but not consumed by the runtime UI

This keeps the last good deck visible, but it also means embedded build/watch failures are easy to miss unless logs are visible.

## Recommended V2 Direction

### 1. Keep thumbnails as a runtime-rendered concern unless v2 adds a true build-time Flutter renderer
- today thumbnails depend on Flutter rendering, active theme/context, and widget definitions
- that makes them qualitatively different from Mermaid/image asset generation

### 2. Split the contract conceptually into two owners
- build assets:
  - deterministic assets produced during build and written to `.superdeck/assets`
- runtime thumbnails:
  - render-derived preview snapshots resolved from a dedicated runtime thumbnail store

Even if the code still reuses some helpers, the planning contract should stop treating those as the same category.

### 3. Use a thumbnail-specific cache identity instead of slide key alone
- preserve `slide.key` as the stable slide identity
- derive a separate thumbnail cache key/signature from:
  - slide key
  - effective style/template identity
  - other render-affecting inputs that should invalidate previews

### 4. Tie thumbnail refresh to deck/slide-set changes, not only menu-open
- when a new deck arrives, reconcile thumbnail state against the new slide set
- generate missing thumbnails automatically when the thumbnail UI is active
- keep force-regenerate as an explicit manual escape hatch

### 5. Decide whether the manifest should describe existing files or declared thumbnail references
- if `generated_assets.json` is a manifest of files that actually exist, current thumbnail entries are misleading
- if it is instead a manifest of resolvable asset references, that should be stated explicitly

### 6. Prefer visible-first thumbnail generation for large decks
- generate visible thumbnails first
- prefetch nearby slides second
- avoid treating "open the panel" as "render every slide preview immediately"

### 7. Freeze bundled-runtime path support explicitly
- decide whether bundled runtimes officially support custom `outputDir` / `assetsPath`
- if yes, the deck asset path, asset fallback path, and publish/setup flows need one shared rule
- if not, document the bundled-runtime path restrictions clearly

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

## Remaining Open Items After Current Sign-Off

The following decisions remain open in this runtime/build planning surface:

1. External config source policy
- Keep `superdeck.yaml` strictness and `styles.yaml` loading/merge behavior explicitly deferred.
- Do not infer automatic startup config/style loading from the current implementation.

2. Embedded runtime watch API placement
- Embedded app watch/build is frozen as first-class on process-capable runtimes.
- CLI watch is frozen as optional/manual orchestration only.
- The remaining open work is the final startup-only API placement/name that replaces `DeckOptions.watchForChanges`.

3. Thumbnail storage and invalidation contract
- Freeze whether thumbnails are runtime snapshots, build artifacts, or a hybrid contract.
- Freeze invalidation rules so correctness does not depend on incidental UI timing.

4. Bundled runtime path support
- Decide whether bundled runtimes officially support custom `outputDir` / `assetsPath`.
- If yes, define one canonical deck-json, bundled-asset, and runtime-fallback path rule.

## Recommended Next Step
Use this document as the operational companion to the parser contract.

The next planning pass should either:
- freeze the remaining open runtime/build decisions listed above, or
- fold the frozen outcomes into `.planning/rewrite-v2-feature-matrix.md` and `.planning/rewrite-v2-contract-migration-matrix.md`

but it should not jump straight to package/interface modeling before these operational boundaries are explicit.
