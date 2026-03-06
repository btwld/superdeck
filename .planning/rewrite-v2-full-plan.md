# SuperDeck V2 Full Rewrite Plan

## Summary
Rewrite SuperDeck as a simpler, more explicit system with one responsibility per layer:

- authoring and parsing
- contracts and schema versioning
- build and asset generation
- Flutter runtime and rendering
- CLI orchestration and publishing

This rewrite is justified by concrete issues in the current implementation:
- parser rules are split across multiple components and are not fully consistent
- build orchestration is duplicated between CLI and runtime watcher
- runtime thumbnail and rebuild behavior has hidden stale-state paths
- command flow mixes domain work, process control, IO, and UI concerns
- some validation paths are intentionally permissive where they should be deterministic

The rewrite is a breaking `v2`, keeps the current top-level package layout for `v2.0`, and includes `packages/genui` in the migration scope.

## Canonical Planning Docs After Reconciliation
This file is the umbrella rewrite plan.

Detailed sign-off lives in:
- `.planning/rewrite-v2-api-surface.md`
- `.planning/rewrite-v2-feature-matrix.md`
- `.planning/rewrite-v2-parser-semantics.md`
- `.planning/rewrite-v2-build-watch-runtime.md`
- `.planning/rewrite-v2-contract-migration-matrix.md`

Use this file for:
- rewrite goals
- package/layer responsibilities
- phase sequencing
- risks and acceptance criteria

Do not use this file as the sole source of truth for parser grammar, runtime watch semantics, or migration/public-surface naming.
Do not use older `DeckOptions` / `DeckConfiguration.watch` planning text as the final API shape; `.planning/rewrite-v2-api-surface.md` now owns that.

## Approved API Reset

The v2 rewrite now has an approved primary runtime/bootstrap surface:

- `SuperDeckRuntime.create(...)` is the canonical bootstrap entrypoint
- `SuperDeckApp(runtime: runtime)` is the main widget surface
- deck origin is explicit via `DeckSource.local(...)` and `DeckSource.bundle(...)`
- startup-only operational config lives in `DeckRuntimeConfig`
- render composition lives in `DeckPresentation`
- behavioral add-ons live in `DeckExtension`
- advanced runtime control lives in `SuperDeckHandle` and `SuperDeck.of(context)`
- runtime owns local build/watch for local sources
- the preferred v2 workflow is runtime-first plus `publish`, while `build` remains public as a transitional `v2.0` command

Any older references in this umbrella plan that still discuss:
- `SuperDeckApp(options: ..., configuration: ...)`
- `DeckOptions.watchForChanges`
- `DeckConfiguration.watch`

should be treated as superseded intermediate planning, not the approved v2 API.

## Current Implementation Context

### What exists today
The current system is split across:
- `packages/core`
  - contracts, models, configuration, filesystem deck service, YAML helpers
- `packages/builder`
  - markdown/frontmatter parsing, task pipeline, Mermaid asset generation
- `packages/superdeck`
  - Flutter runtime, controller, rendering, navigation, templates, styles, watcher
- `packages/cli`
  - setup, build, watch, publish
- `packages/genui`
  - AI-assisted authoring/editor flows, deck/style tooling, preview, and thumbnail helpers
- `demo`
  - runtime-first example app plus integration/e2e validation surface

### What is good in the current implementation
The current codebase already has strong foundations worth preserving:
- clear top-level product shape: markdown -> build artifacts -> Flutter runtime
- reasonable package-level separation
- useful contract export tooling
- a task-based build pipeline
- a good custom-widget extension model
- template and style abstractions that are conceptually right
- solid targeted tests in several areas

### Current feature baseline that v2 must preserve
The rewrite only makes sense if it preserves the real product surface that exists today.

#### Authoring and parsing baseline
- slide splitting driven by top-level `---`
- per-slide YAML frontmatter with `title`, `style`, `template`, and free-form extra args
- layout directives `@section`, `@column`/`@block`, `@widget`, plus shorthand widget aliases
- escaped directives via `_@`
- HTML comments captured as speaker notes/comments
- fenced `mermaid` blocks rendered to images at build time
- fenced `dart` blocks formatted during build
- runtime markdown features built on GitHub-flavored markdown:
  - alerts
  - tables
  - task lists
  - footnotes
  - hero markers on headers, images, and fenced code
  - standalone markdown image lines promoted to block images

#### Build and artifact baseline
- `.superdeck/superdeck.json` as canonical runtime contract
- `.superdeck/superdeck_full.json` as the debug/tooling artifact with markdown AST expansion
- `.superdeck/generated_assets.json` manifest with timestamp + generated file list
- `.superdeck/build_status.json` for `unknown/building/success/failure`
- deterministic asset naming for mermaid images and slide thumbnails
- one-shot build, watch rebuild, and force rebuild flows

#### Runtime baseline
- file-backed loading on debug IO runtimes (`kCanRunProcess`) and bundled-asset loading on web/test/release-like runtimes
- route-driven navigation at `/slides/:index`
- keyboard navigation, touch tap navigation, and swipe navigation
- slide parts (header/footer/background), styles, templates, and `template: none`
- built-in widgets `image`, `dartpad`, `qrcode`, with user override by name
- `StyleConfigLoader` support for merging `styles.yaml` with code-defined presentation styles
- notes/comments panel, thumbnail panel, plugin actions, floating action slot, rebuild indicator
- runtime asset caching and thumbnail generation
- PDF export through slide capture
- desktop/runtime bootstrapping for syntax highlighting and window manager setup

#### CLI baseline
- `setup` creates sample slides, patches `pubspec.yaml`, writes custom `web/index.html`, and updates macOS entitlements
- `build` supports watch and force rebuild behavior
- `publish` builds web with GitHub Pages base-href, uses git worktree flow, writes `.nojekyll`, supports dry-run, and restores temporary mutations
- `superdeck.yaml` is currently read by the CLI only; runtime configuration is explicit and does not implicitly resolve local YAML

### Why a rewrite makes sense
The rewrite is warranted because the current implementation carries structural complexity that is now shaping behavior:

1. Parsing rules are fragmented
- frontmatter handling, directive tokenization, comment extraction, hero syntax, and fence-aware parsing still span multiple components
- fence opener/closer handling is partly shared today, but source interpretation is still not single-owned
- result: valid markdown constructs can behave differently depending on which layer sees them first

2. Orchestration is duplicated
- standard builder creation and CI browser setup are duplicated in CLI and runtime watcher
- result: drift risk whenever tasks or environment behavior changes

3. Runtime state is too implicit
- thumbnails and rebuild states depend on UI timing and cached closures
- result: behavior is correct in the common path but brittle under updates

4. Command classes are doing too much
- build and publish mix domain logic, filesystem mutation, subprocesses, interactive control flow, and error reporting
- result: harder testing, weaker guarantees, and more cleanup edge cases

5. Validation policy is not strict enough where correctness matters
- frontmatter and some parsing helpers tolerate malformed inputs by degrading quietly
- result: authors can get "successful" builds with incorrect metadata

The rewrite should therefore focus on simplification, not novelty.

## Rewrite Goals

### Primary goals
- make invalid states unrepresentable wherever practical
- make parsing rules single-sourced and deterministic
- make every package boundary explicit
- reduce side effects inside domain logic
- replace hidden coordination with typed state machines and typed results
- preserve user-facing capabilities while simplifying the implementation model

### Non-goals
- no net-new AI authoring system beyond migrating the existing `genui` consumer to the v2 runtime/contracts
- no new slide DSL beyond what is needed to normalize existing features
- no attempt to preserve all internal APIs
- no dual architecture with old and new systems sharing core internals

## Scope

### In scope
- markdown authoring pipeline
- frontmatter and block parsing
- contract/schema layer
- deck artifact generation
- build tasks and asset generation
- runtime deck loading and rendering
- runtime markdown rendering and syntax extensions
- thumbnails
- PDF export and slide capture
- navigation
- templates and styles
- runtime bootstrapping and operational config/style loading
- public extension APIs for widgets, slide parts, and plugins
- CLI setup/build/watch/publish
- migration tooling from v1 to v2
- `packages/genui` migration off internal/v1 runtime entrypoints

### Out of scope
- new AI authoring workflows beyond the current `genui` product surface
- live slide editing UI
- remote collaboration or cloud sync
- headless/build-time Flutter thumbnail rendering

## Protected Surfaces And Audit Gates

### Protected surfaces
These areas are stability-critical and should not be deeply modified unless a failing validation gate or an approved contract change makes the need obvious:
- block widget rendering/layout internals
- hero parsing/rendering behavior
- export-mode behavior tied to hero and interaction suppression

Rewrite rule:
- prefer changing contracts, adapters, orchestration, and public seams around these surfaces
- when a change must touch them, keep it localized and pair it with targeted runtime/widget validation

### Required audit gates
1. Pre-migration drift audit
- compare approved v2 docs against the live codebase before each major slice
- explicitly review parser/schema/runtime/bootstrap/CLI/genui/demo/artifact/public-barrel drift

2. Mid-migration protected-surface review
- confirm block widget and hero behavior were not changed incidentally while surrounding systems moved
- require focused tests when those surfaces are touched at all

3. Post-migration consumer removal audit
- after each migration slice, audit old consumers and legacy entrypoints before deleting them
- explicitly review `DeckOptions`, `DeckControllerBuilder`, `SuperDeckPlugin`, direct controller access, `package:superdeck/src/...` imports, legacy artifact names, and legacy serialized field names

4. Final full-rewrite audit
- run a full review after migration to confirm no hidden v1 primary surfaces or stale consumers remain

## Rewrite Principles

### Principle 1: one parser authority per concept
Current issue:
- multiple regex- and line-based parsers partially overlap

Rewrite rule:
- one fence parser
- one slide delimiter parser
- one directive parser
- one frontmatter parser

No duplicated syntax interpretation across packages.

### Principle 2: domain logic returns typed outcomes
Current issue:
- many important flows throw generic exceptions

Rewrite rule:
- expected failures are represented as sealed result types
- exceptions are reserved for programming faults or unexpected platform failures

### Principle 3: orchestration layers do not implement domain rules
Current issue:
- CLI and runtime watcher know too much about task wiring and environment configuration

Rewrite rule:
- CLI orchestrates
- build engine builds
- runtime renders
- contracts validate
- authoring parses

### Principle 4: simplify by removing hidden coupling
Current issue:
- cached closures capture old slide configs
- UI state triggers domain work indirectly

Rewrite rule:
- explicit invalidation and recomputation boundaries
- no stale configuration captured inside long-lived cache objects

### Principle 5: schema versioning is a first-class feature
Current issue:
- schema export exists, but contract evolution is not central enough

Rewrite rule:
- every artifact has explicit version identity
- migrations are built alongside schema changes

## Target Package Layout

### 1. `packages/contracts`
Responsibility:
- canonical data contracts
- schema definitions
- schema export
- migration interfaces
- shared value objects
- typed contract validation errors

Contains:
- `DeckV2`, `SlideV2`, `SlideOptionsV2`
- `BlockV2` sealed hierarchy
- `GeneratedAssetV2`, `BuildStatusV2`
- JSON Schema generation
- `ContractVersion`, `MigrationStep`

Must not depend on:
- Flutter
- filesystem
- process execution

### 2. `packages/authoring`
Responsibility:
- parse markdown source into normalized semantic deck structures

Contains:
- slide splitter
- frontmatter parser
- directive parser
- fenced code parser
- speaker note extraction
- markdown normalization helpers

Must depend only on:
- `contracts`
- markdown/yaml/parser utilities

Key rule:
- `authoring` owns source interpretation
- no other package re-parses author intent

### 3. `packages/build_engine`
Responsibility:
- transform parsed deck input into generated runtime artifacts

Contains:
- build orchestrator
- task pipeline
- asset generation
- cache policy
- reusable builder factory
- watch coordinator primitives
- artifact writing

Depends on:
- `contracts`
- `authoring`

Key rule:
- this package is the only place that knows task order

### 4. `packages/runtime_flutter`
Responsibility:
- render deck artifacts in Flutter
- render markdown with SuperDeck-specific syntax extensions
- navigation
- thumbnails
- export/PDF capture
- templates/styles
- runtime bootstrapping
- runtime plugins

Contains:
- repositories for bundled and file-backed loading
- bootstrap/config/style loaders
- `DeckControllerV2`
- markdown render pipeline
- rendering widgets
- thumbnail subsystem
- export subsystem
- runtime asset store
- template/style resolvers
- runtime plugin API

Depends on:
- `contracts`
- Flutter

Key rule:
- runtime consumes already-built artifacts
- runtime only renders markdown block content; it does not interpret raw `slides.md` deck structure

### 5. `packages/cli`
Responsibility:
- user command entrypoints only

Contains:
- `setup`
- `build`
- `watch`
- `publish`
- `migrate`

Depends on:
- `contracts`
- `authoring`
- `build_engine`

Key rule:
- no duplicated builder wiring
- no embedded domain parsing logic

### 6. `packages/migration_tools`
Responsibility:
- migrate inputs and artifacts from v1 to v2
- dry-run analysis and reporting

Contains:
- markdown rewrite helpers
- artifact migration
- compatibility scanners

## Public API and Contract Design

### Canonical runtime artifact
Primary runtime artifact:
- `.superdeck/superdeck.v2.json`

Optional expanded debug artifact:
- `.superdeck/superdeck_full.v2.json`

Supporting artifacts:
- `.superdeck/generated_assets.v2.json`
- `.superdeck/build_status.v2.json`

### Artifact semantics
- `.superdeck/superdeck.v2.json` remains the canonical runtime contract
- `.superdeck/superdeck_full.v2.json` preserves the deck shape but expands markdown blocks into a markdown AST using the same GitHub-flavored extension set that tooling/debug flows expect today
- `.superdeck/generated_assets.v2.json` remains a manifest of generated file paths plus last-modified metadata
- `.superdeck/build_status.v2.json` remains the machine-readable build lifecycle artifact
- runtime thumbnails remain runtime cache entries, not build artifacts

### Root contract
```dart
final class DeckV2 {
  final int schemaVersion;
  final List<SlideV2> slides;
  final DeckConfigurationV2 configuration;
  final DeckMetaV2 meta;
}
```

Defaults:
- `schemaVersion = 2`
- `configuration = const DeckConfigurationV2()`
- `meta = const DeckMetaV2()`

### Slide contract
```dart
final class SlideV2 {
  final SlideId id;
  final SlideOptionsV2 options;
  final List<SectionBlockV2> sections;
  final List<SpeakerNote> notes;
}
```

### Slide identity and note compatibility
- `SlideId` remains deterministic and duplicate-safe because routes, thumbnails, and plugin integrations depend on stable keys
- current v1 `comments` migrate to canonical v2 `notes`; migration tooling must report that rename explicitly

### Slide options
```dart
final class SlideOptionsV2 {
  final String? title;
  final StyleName? style;
  final TemplateName? template;
  final Map<String, Object?> args;
}
```

### Block hierarchy
```dart
sealed class BlockV2 {}

final class SectionBlockV2 extends BlockV2 {
  final List<BlockV2> blocks;
  final ContentAlignment? align;
  final int flex;
  final bool scrollable;
}

final class MarkdownBlockV2 extends BlockV2 {
  final String markdown;
  final ContentAlignment? align;
  final int flex;
  final bool scrollable;
}

final class WidgetBlockV2 extends BlockV2 {
  final String name;
  final Map<String, Object?> args;
  final ContentAlignment? align;
  final int flex;
  final bool scrollable;
}
```

### Build status contract
```dart
sealed class BuildStatusV2 {
  const BuildStatusV2();
}

final class BuildIdle extends BuildStatusV2 {}
final class BuildRunning extends BuildStatusV2 {}
final class BuildSucceeded extends BuildStatusV2 {
  final int slideCount;
}
final class BuildFailed extends BuildStatusV2 {
  final BuildFailure failure;
}
```

### Generated asset manifest contract
```dart
final class GeneratedAssetsManifestV2 {
  final DateTime lastModified;
  final List<String> files;
}
```

### Typed failure model
Every major layer exposes sealed failures.

Examples:
- `FrontmatterFailure`
- `FenceParsingFailure`
- `DirectiveParsingFailure`
- `SchemaValidationFailure`
- `AssetGenerationFailure`
- `BuildWriteFailure`
- `WatchFailure`
- `PublishFailure`

## Authoring Model

### Supported authoring syntax
Keep feature parity, but normalize semantics.

#### Slide identity
Rule:
- every slide gets a stable deterministic id derived from source content plus deterministic duplicate disambiguation
- migration preserves existing route/thumbnail stability wherever possible

#### Slide separation
Rule:
- `---` outside fenced code blocks is a slide separator
- frontmatter is only recognized at the start of a slide
- frontmatter must be a strict YAML map

This replaces the current ambiguous "toggle frontmatter" model.

#### Frontmatter
Rule:
- a slide may begin with:
  - opening `---`
  - strict YAML map
  - closing `---`
- invalid YAML is a hard parse error
- scalar or list YAML at the top is invalid frontmatter

#### Block directives
Canonical directives in v2:
- `@section`
- `@block`
- `@widget`

Migration-only accepted aliases:
- `@column -> @block`

Directive options remain:
- balanced-brace YAML maps
- nested object and list values
- source-located parse failures when braces or YAML are invalid

#### Fenced code
Rule:
- both backtick and tilde fences are supported
- one shared fence parser is reused everywhere
- fence info parsing is normalized once

#### Notes
Rule:
- HTML comments become speaker notes
- notes are extracted during authoring parse, not later in unrelated layers

#### Escaped directives
Rule:
- `_@foo` remains literal `@foo` content

#### Mixed markdown and directive aggregation
Rule:
- slides with no directives still become one section containing one markdown block
- free markdown before, between, and after directives remains part of the slide
- adjacent markdown fragments merge into the nearest markdown block inside the current section

#### Widget shorthand and built-in parity
Rule:
- `@widget { name: "foo" }` and `@foo { ... }` remain equivalent
- built-in shorthands `@image`, `@dartpad`, and `@qrcode` remain first-class
- user widget registrations can still override built-ins by name

#### Markdown behavior preserved at runtime
Rule:
- runtime continues to render GitHub-flavored markdown, not pre-rendered HTML
- alert syntax, task lists, tables, footnotes, hero markers, and syntax highlighting remain supported
- standalone markdown image lines remain promoted to block images
- inline image-in-text behavior is not expanded as part of this rewrite unless explicitly scoped later

## Parsing Pipeline

### Stage A: lexical scan
Produce:
- fence ranges
- line map
- slide boundaries

### Stage B: slide parse
For each slide:
- detect frontmatter
- validate frontmatter
- keep remaining markdown body

### Stage C: semantic block parse
For each slide body:
- tokenize directives
- group into sections
- normalize legacy aliases
- extract notes
- produce `SlideV2`

### Stage D: validation
Validate:
- block shape
- known enum values
- args contract shape
- no explicit invalid nulls

### Stage E: debug artifact preparation
Produce:
- markdown AST payloads for `superdeck_full.v2.json`
- source-located metadata needed for diagnostics and tooling

## Simplification Strategy Relative to Current Code

### Simplification 1: replace fragmented parsing with a single syntax pipeline
Current:
- `MarkdownParser`
- `TagTokenizer`
- `FencedCodeParser`
- `FrontmatterParser`
- markdown hero helpers
all implement their own syntax assumptions.

Rewrite:
- create `FenceScanner`
- create `SlideBoundaryParser`
- create `FrontmatterMapParser`
- create `DirectiveParser`

All reuse a shared source map abstraction.

Benefit:
- fixes current inconsistency bugs
- makes tests shorter and more meaningful

### Simplification 2: extract one standard build factory
Current:
- duplicated builder wiring in CLI and runtime watcher

Rewrite:
- `StandardBuildPipelineFactory` lives in `build_engine`

Benefit:
- one task list
- one CI browser configuration policy
- one place to change future build behavior

### Simplification 3: make watch mode serialized, not poll-based
Current:
- `_runBuild()` uses polling for mutual exclusion
- interactive stdin paths launch `unawaited` work
- quit path hard-exits the process

Rewrite:
- `BuildQueue` with single-flight execution
- `WatchSession` owns lifecycle and exit signal
- `build`, `rebuild`, `force rebuild`, and `quit` are serialized commands

Benefit:
- deterministic watch behavior
- simpler tests
- no process lifecycle escape hatch

### Simplification 4: separate runtime invalidation from UI timing
Current:
- opening the menu triggers thumbnail generation
- thumbnails capture old slide config via closure

Rewrite:
- thumbnail cache keyed by `slideId + renderSignature`
- render signature includes style/template/debug/export-affecting config
- menu visibility only controls whether thumbnails are displayed, not cache correctness

Benefit:
- correct cache invalidation
- simpler reasoning
- less UI-domain coupling

### Simplification 5: strict validation at authoring boundaries
Current:
- malformed frontmatter may quietly degrade

Rewrite:
- parsing either succeeds structurally or returns a typed failure with source location

Benefit:
- authors get deterministic feedback
- contract layer is trustworthy

### Simplification 6: centralize runtime bootstrap and operational config
Current:
- CLI `superdeck.yaml` loading, `styles.yaml` loading, syntax highlighter init, window setup, and plugin initialization live in separate utilities

Rewrite:
- `RuntimeBootstrap` owns operational config loading, style merge, syntax-highlighter init, desktop window init, and plugin initialization

Benefit:
- one startup policy
- shared strictness rules for configuration handling
- fewer platform-specific surprises

### Simplification 7: formalize markdown rendering and host extension surfaces
Current:
- image, alert, hero, and markdown builder behavior is split across several runtime helpers
- custom widgets and slide parts depend on implicit ambient inherited contexts

Rewrite:
- `MarkdownRenderPipeline` becomes the single runtime markdown integration point
- explicit `SlideRenderContext` and `BlockRenderContext` become first-class host APIs

Benefit:
- parser/renderer parity is testable
- custom widget and slide-part APIs become clearer and harder to accidentally break

## Build Engine Design

### Core types
```dart
final class BuildRequest {
  final DeckConfigurationV2 configuration;
  final BuildMode mode;
  final bool forceRebuild;
}

enum BuildMode { oneShot, watch }

final class BuildOutput {
  final DeckV2 deck;
  final GeneratedAssetsManifestV2 assets;
  final BuildStatusV2 status;
}
```

### Core services
- `ConfigurationLoader`
- `DeckSourceLoader`
- `DeckAuthoringCompiler`
- `AssetPipeline`
- `ArtifactWriter`
- `BuildOrchestrator`
- `WatchSession`
- `StandardBuildPipelineFactory`

### Inputs and operational config
Inputs:
- `slides.md` authoring source
- local runtime configuration as frozen in `.planning/rewrite-v2-build-watch-runtime.md`
- external config sources such as `superdeck.yaml` and `styles.yaml` remain explicit planning decisions, not fixed assumptions in this umbrella doc

### Task pipeline order
1. load source
2. parse source into semantic deck
3. normalize legacy syntax
4. format code fences where configured
5. generate assets
6. validate final deck contract
7. emit debug AST artifact
8. write deck artifacts
9. write build status
10. clean orphaned generated assets

### Asset pipeline
Initial generators:
- Mermaid

Build-time transforms preserved from v1:
- `dart` fenced code formatting remains a first-class transform
- mermaid blocks still become deterministic generated image assets
- asset replacements remain relative project paths so the runtime markdown layer continues to see standard image syntax

Generator interface:
```dart
abstract interface class AssetGeneratorV2 {
  String get type;
  bool supports(FencedBlock block);
  Future<AssetGenerationResult> generate(AssetGenerationRequest request);
}
```

### Watch mode
Rules:
- one active build at a time
- subsequent triggers coalesce into one pending rebuild
- `force rebuild` marks the next build request as clean-start
- `quit` completes the session gracefully
- no `exit()` inside command handlers

### Configuration loading policy
- External config-source policy is still open.
- Do not treat one shared strict `superdeck.yaml` policy as frozen in this umbrella plan.
- Final `superdeck.yaml` / `styles.yaml` behavior belongs in `.planning/rewrite-v2-feature-matrix.md`, `.planning/rewrite-v2-build-watch-runtime.md`, and `.planning/rewrite-v2-contract-migration-matrix.md`.

## Runtime Flutter Design

### Repository model
```dart
abstract interface class DeckRepository {
  Future<LoadDeckResult> loadCurrent();
  Stream<LoadDeckResult> watch();
}
```

Implementations:
- `FileDeckRepository`
- `BundledDeckRepository`

### Bootstrap and initialization
`SuperDeckRuntime.create(...)` is the canonical host entry point. v2 bootstrap must:
- initialize syntax highlighting grammars
- initialize desktop window management on supported non-web platforms
- initialize extensions with typed success/failure reporting
- follow `.planning/rewrite-v2-api-surface.md` as the canonical runtime/bootstrap contract
- keep external config-source behavior explicit rather than assuming automatic `styles.yaml` merge or shared `superdeck.yaml` resolution

### Controller model
`DeckControllerV2` owns:
- load state
- navigation state
- UI toggles
- rebuild indicator state
- thumbnail registry
- plugin route/action exposure

### Controller state
```dart
sealed class DeckControllerState {
  const DeckControllerState();
}

final class DeckLoading extends DeckControllerState {}
final class DeckReady extends DeckControllerState {
  final List<SlideRenderModel> slides;
  final int currentIndex;
}
final class DeckLoadError extends DeckControllerState {
  final LoadFailure failure;
}
```

### Slide render model
`SlideRenderModel` is runtime-only and derived from `SlideV2`.

Includes:
- resolved style
- resolved parts
- widget registry subset
- thumbnail key
- export mode flag

### Markdown rendering pipeline
- runtime continues to own markdown-to-widget rendering
- one `MarkdownRenderPipeline` preserves GitHub-flavored markdown behavior
- alert blocks, hero markers, task lists, tables, footnotes, code highlighting, and standalone image block parsing remain part of parity scope
- the same hero/tag helper rules must be shared across authoring/debug tooling and runtime rendering

### Public host integration surfaces
Custom widgets and slide parts remain first-class host APIs. v2 must preserve:
- slide-level context access for slide parts and custom widgets
- block-level size/alignment/style context for custom widgets and markdown builders
- built-in widget registry order where `image`, `dartpad`, and `qrcode` are present by default and user widgets may override them by name

### Templates and styles
Retain concept, simplify ownership.

#### Deck presentation
```dart
final class DeckPresentation {
  final SlideStyle? baseStyle;
  final Map<String, SlideStyle> styles;
  final Map<String, WidgetDefinition<Object?>> widgets;
  final Map<String, SlideTemplate> templates;
  final SlideTemplate? defaultTemplate;
  final SlideParts parts;
  final bool debug;
  final List<DeckExtension> extensions;
}
```

Policy:
- watch/build is removed from the render composition surface and belongs to `DeckSource.local(watch: ...)`
- external YAML config such as `styles.yaml` remains deferred from the current runtime-local contract

#### Style resolution
Rules:
- no template:
  - `defaultSlideStyle -> baseStyle -> named deck style`
- with template:
  - `defaultSlideStyle -> template.baseStyle -> template.named style`
- `template: none` remains reserved opt-out

#### YAML styles
Split into:
- `StyleConfigLoader`
- `StyleSchemaValidator`
- `StyleMergePolicy`

Keep YAML merge behavior:
- code-defined styles override YAML styles

### Runtime asset and thumbnail storage
- one `RuntimeAssetStore` abstraction backs bundled assets, generated assets, and dev-mode thumbnail cache lifecycles
- runtime thumbnails are dev-mode preview snapshots, not required build artifacts
- bundled web/release-like runtimes use canonical bundled v2 paths only and do not generate thumbnails locally
- when bundled thumbnails are absent, bundled runtimes show placeholder/fallback UI
- IO backends preserve the current “prefer fresher bundled asset over cache entry” behavior where runtime cache is in use
- web backends preserve the current `rootBundle` + in-memory/data-URI behavior for runtime-generated bytes

### Shell features that remain in scope
- responsive thumbnail panel + notes/comments panel
- bottom bar with notes toggle, PDF export, regenerate thumbnails, navigation, plugin actions, and close menu action
- floating action slot when the menu is closed
- rebuilding overlay during watch-driven rebuilds

### Export subsystem
- PDF export remains a first-class runtime feature
- export flow keeps a slide-capture service plus export controller/session with progress, cancellation, and platform-specific save adapters
- export mode continues to suppress interaction-only behaviors such as hero flights and scroll interactions while capturing

## Extension Design
Keep the behavior surface, rename and simplify expectations.

```dart
abstract class DeckExtension {
  String get name;
  Future<ExtensionInitResult> initialize(DeckRuntimeContext context);
  List<RouteBase> buildRoutes(DeckRuntimeContext context);
  List<DeckAction> buildActions(DeckRuntimeContext context);
  Widget? buildFloatingAction(DeckRuntimeContext context);
}
```

Rule:
- extension lifecycle must not mutate core deck state directly
- extensions extend runtime shell, not parser/build engine internals

## CLI Design

### Command responsibilities
- `setup`
  - create sample files
  - patch pubspec assets
  - optional web template bootstrap
  - optional platform entitlements
- `publish`
  - invoke the shared build pipeline as needed
  - build web
  - resolve base-href from repository identity
  - stage worktree
  - copy site
  - write `.nojekyll`
  - commit and push
  - restore temporary mutations
- `migrate`
  - v1 to v2 dry run or apply

### Important CLI simplifications
- local day-to-day dev should be runtime-first (`flutter run` + embedded app watch/build)
- `publish` should use a scoped `IndexHtmlOverrideSession`
- all temporary filesystem changes must live inside scoped cleanup objects
- migrate legacy `DeckOptions.watchForChanges` usage to `DeckSource.local(watch: ...)`

### Publish lifecycle object
```dart
final class PublishSession {
  Future<PublishResult> run(PublishRequest request);
}
```

Subservices:
- `GitRepositoryProbe`
- `BaseHrefResolver`
- `WebBuildRunner`
- `IndexHtmlOverrideSession`
- `GitWorktreePublisher`

This replaces today’s single large command-object approach.

## Migration Plan
Detailed row-by-row compatibility and public-surface rename tracking belong in `.planning/rewrite-v2-contract-migration-matrix.md`.

### Migration command
`superdeck migrate --to-v2`

Modes:
- `--dry-run`
- `--apply`

### Migration responsibilities
- convert `@column` to `@block`
- rename slide `comments` to canonical slide `notes`
- validate frontmatter as strict YAML map
- flag unsupported ambiguous constructs
- rename artifact expectations
- replace legacy `DeckOptions.watchForChanges` usage with `DeckSource.local(watch: ...)`
- preserve built-in widget shorthands and `template: none`
- produce migration report

### Compatibility policy
- Treat the contract-migration matrix as the canonical place for unresolved compatibility details.
- v2 runtime only reads v2 artifacts
- migration tools handle v1 inputs
- no permanent dual-read runtime support

## Documentation Plan

### Canonical planning docs after reconciliation
- `.planning/rewrite-v2-full-plan.md`
- `.planning/rewrite-v2-api-surface.md`
- `.planning/rewrite-v2-feature-matrix.md`
- `.planning/rewrite-v2-parser-semantics.md`
- `.planning/rewrite-v2-build-watch-runtime.md`
- `.planning/rewrite-v2-contract-migration-matrix.md`

### Additional planning docs still useful before implementation
- `.planning/rewrite-v2-package-map.md`
- `.planning/rewrite-v2-migration-plan.md`
- `.planning/rewrite-v2-test-matrix.md`

### Required content
Each doc must include:
- current implementation context
- simplification rationale
- target architecture
- migration/rollout detail
- risks and acceptance criteria

## Implementation Phases

### Phase 0: freeze the spec
Deliverables:
- approve this plan as canonical
- snapshot current public API and artifact format
- list migration assumptions explicitly

Acceptance criteria:
- rewrite scope and contract boundaries are locked
- no unresolved package ownership questions remain

### Phase 1: contracts package
Build:
- `DeckV2` contracts
- schema export
- typed failure/result model
- contract tests
- migration interfaces

Acceptance criteria:
- schema artifacts generated deterministically
- all contract round-trip tests pass
- v2 artifact format is frozen

### Phase 2: authoring package
Build:
- shared fence scanner
- slide boundary parser
- strict frontmatter map parser
- directive parser
- section aggregator
- note extractor

Acceptance criteria:
- backtick and tilde fence behavior is identical across parsing stages
- invalid frontmatter fails deterministically
- legacy alias normalization works

### Phase 3: build engine package
Build:
- standard build pipeline factory
- asset pipeline
- build queue
- watch session
- artifact writer
- orphan cleanup

Acceptance criteria:
- CLI and runtime watcher use the same build factory
- force rebuild and regular rebuild follow one cleanup path
- watch mode has no polling loop and no hard exit path

### Phase 4: runtime Flutter package
Build:
- repository abstractions
- `DeckControllerV2`
- runtime bootstrap
- render models
- markdown render pipeline
- template/style resolution
- runtime asset store
- thumbnail invalidation redesign
- export subsystem
- route shell and actions

Acceptance criteria:
- thumbnails invalidate when slide render signature changes
- menu visibility no longer determines cache correctness
- runtime can load both file-backed and bundled v2 artifacts
- markdown rendering preserves alert/hero/standalone-image behavior
- custom widgets and slide parts receive explicit runtime context
- PDF export works through the v2 export subsystem

### Phase 5: CLI rewrite
Build:
- command thin layer
- setup/build/watch/publish/migrate
- scoped cleanup utilities
- non-interactive safe flows

Acceptance criteria:
- publish always restores temporary index state
- watch session exits cleanly without `exit()`
- command tests cover success and cleanup failures

### Phase 6: migration and rollout
Build:
- v1 scanner
- migration report
- migration apply mode
- docs and examples

Acceptance criteria:
- sample v1 decks migrate cleanly
- migration failures are source-located and actionable

## Test Plan

### Contracts tests
- JSON round-trip for all contracts
- schema export drift detection
- nullability validation
- schema version enforcement

### Authoring tests
- slide splitting with backtick fences
- slide splitting with tilde fences
- directives inside fences ignored
- `---` inside fences ignored
- strict invalid frontmatter failure
- notes extraction
- legacy alias normalization
- escaped directives
- shorthand widget parsing
- mixed markdown/directive aggregation
- hero markers on headers, images, and fenced code
- standalone markdown image lines
- alert syntax parity

### Build engine tests
- one-shot build success
- watch coalescing
- force rebuild cleanup
- build failure status persistence
- orphan asset removal
- generator failure propagation
- `superdeck_full.v2.json` AST emission
- config loading behavior once the external config policy is frozen
- deterministic mermaid asset naming and reuse

### Runtime tests
- controller load success/error states
- route clamping
- template/style resolution
- plugin route/action registration
- thumbnail invalidation on option changes
- thumbnail invalidation on slide signature changes
- runtime asset-store freshness rules
- built-in widget override behavior
- slide-part and custom-widget context availability
- notes/menu shell state transitions
- PDF export/capture lifecycle

### CLI tests
- setup idempotency
- build one-shot
- optional CLI watch/manual orchestration behavior if that surface is retained
- publish dry-run
- publish cleanup on pre-worktree failure
- migrate dry-run and apply
- setup pubspec/index.html/entitlements changes
- publish base-href and `.nojekyll` behavior

### Golden/widget tests
- base slide layouts
- multi-section layouts
- alert rendering
- code/image rendering
- template variants

## Acceptance Criteria for the Rewrite
The rewrite is complete only when all are true:
- one shared parsing model handles fences, directives, and frontmatter
- one shared markdown rendering pipeline preserves alert, hero, and standalone-image behavior
- one standard build factory is reused everywhere
- runtime thumbnail correctness does not depend on menu toggles
- PDF export remains supported through an explicit export subsystem
- publish has no cleanup gap
- any retained watch orchestration has no polling serialization and no hard exit
- malformed frontmatter is a deterministic authoring error
- setup and publish preserve current project bootstrapping responsibilities
- public widget/slide-part/plugin extension surfaces remain explicit and tested
- migration tool converts representative v1 decks
- docs explain both the current pain points and the simplification rationale

## Risks and Mitigations

### Risk: rewrite overreaches and loses feature parity
Mitigation:
- lock feature parity list up front
- no new syntax unless replacing ambiguity

### Risk: migration becomes harder than expected
Mitigation:
- build migration tooling alongside contracts, not at the end

### Risk: runtime and build drift again
Mitigation:
- build engine owns task wiring, not CLI/runtime

### Risk: style system remains too large and opaque
Mitigation:
- split schema validation, loading, and merging into separate modules from day one

## Explicit Assumptions and Defaults
- breaking `v2` is accepted
- current top-level package layout stays for `v2.0`
- `packages/genui` is in scope and must migrate with the rewrite
- `@column` is legacy-only and migrated to `@block`
- frontmatter must be a strict YAML map in v2
- backtick and tilde fences are both supported uniformly
- code-defined style config overrides YAML-defined style config
- runtime-first local development uses embedded app watch/build
- any retained CLI watch surface is optional/manual orchestration only
- `DeckSource.local(watch: ...)` is the canonical v2 embedded watch surface
- `superdeck_full` remains a debug/tooling artifact with markdown AST expansion
- standalone markdown image behavior is preserved; inline-image expansion is not part of the rewrite baseline
- runtime bootstrap remains a first-class surface, but the final bootstrap/config API should not be inferred from stale assumptions in this umbrella plan
- runtime thumbnails remain dev-mode runtime snapshots, and headless/build-time thumbnail generation stays out of the current rewrite scope
- bundled runtimes use canonical bundled v2 artifact paths only and remain consume-only
- external config-source policy for `superdeck.yaml` / `styles.yaml` remains explicitly deferred until the detailed docs freeze it
- block widget rendering and hero behavior are protected surfaces and should only receive localized, validation-backed changes
- the rewrite plan document should ultimately be stored at `.planning/rewrite-v2-full-plan.md`
