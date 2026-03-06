# SuperDeck Domain Naming Changes

## Status: Approved for implementation

This document captures all naming and abstraction changes agreed during the
DX-focused domain review. Changes are ordered by priority (DX impact).

## Guiding Principles

- Names should map to the user's mental model of a presentation tool
- Types named after what they ARE, not how they're accessed
- No forced naming symmetry between types that serve different roles
- Qualify names only when there is real ambiguity, not preemptively

## Naming Rules by Layer

- `SuperDeck*` for top-level host/runtime entrypoints exposed to Flutter apps
- `Deck*` for deck-domain concepts and user-facing deck options
- No prefix needed for slide/block types within the domain

## Changes

### 1. `SlideConfiguration` -> `SlideData`

**Priority**: Highest — touches the most code, causes the most confusion.

**Rationale**: `SlideConfiguration` is not configuration. It is a resolved,
render-ready slide produced by merging a parsed `Slide` with presentation
config (style, parts, widgets, debug flags, thumbnail path, export state).

`SlideData` parallels Flutter's `ThemeData` — a resolved data object provided
via `InheritedWidget` that also lives outside the widget tree (stored in
controller signals, used by export/thumbnails).

**Access pattern after rename**:
```dart
final slide = SlideData.of(context);
slide.style;
slide.sections;
slide.notes;
```

**Also renames**:
- `SlideConfigurationBuilder` -> `SlideDataBuilder`

**Files**: `packages/superdeck/lib/src/slides/slide_configuration.dart`,
`packages/superdeck/lib/src/slides/slide_configuration_builder.dart`, and
all consumers.

### 2. `DeckPresentation` -> `DeckTheme`

**Priority**: High — biggest public API clarity win.

**Rationale**: A "deck" already IS a "presentation" in plain English. The
current name reads like "the presentation itself" when it actually means
"how do I customize my deck's appearance and behavior."

`DeckTheme` parallels `ThemeData` in Flutter. Users immediately understand:
"this is where I configure how my deck looks."

**Fields stay the same**: `baseStyle`, `styles`, `templates`, `widgets`,
`parts`, `debug`, `defaultTemplate`, `extensions`.

**Access pattern after rename**:
```dart
final runtime = await SuperDeckRuntime.create(
  source: const DeckSource.local(watch: true),
  theme: const DeckTheme(
    styles: { ... },
    templates: { ... },
    widgets: { ... },
  ),
);
```

**Files**: `packages/superdeck/lib/src/presentation/deck_presentation.dart`
and all consumers. The `presentation` parameter on `SuperDeckRuntime.create`
becomes `theme`.

### 3. `SlideParts` -> `SlideFrame`

**Priority**: Medium — small rename, immediate clarity.

**Rationale**: `SlideParts` holds `header`, `footer`, `background`. In
presentation software this is the slide chrome/frame — the stuff around
the content. "Parts" is too vague to communicate this.

**Access pattern after rename**:
```dart
DeckTheme(
  frame: SlideFrame(
    header: MyHeader(),
    footer: MyFooter(),
    background: MyBackground(),
  ),
)
```

**Note**: The parameter name on `DeckTheme` also changes from `parts` to
`frame`.

**Files**: `packages/superdeck/lib/src/presentation/slide_parts.dart` and
all consumers.

### 4. `WidgetDefinition` -> `BlockDefinition`

**Priority**: Medium — vocabulary alignment with the block system.

**Rationale**: The block system uses `Block` vocabulary throughout
(`ContentBlock`, `WidgetBlock`, `SectionBlock`). A `WidgetDefinition`
defines a new custom block type, not a Flutter widget. The `Widget` prefix
creates confusion between Flutter and SuperDeck concepts.

`BlockDefinition<T>` makes the relationship clear: you define a block type
by specifying how it parses args (`parse()`) and renders (`build()`).

**Access pattern after rename**:
```dart
DeckTheme(
  widgets: {
    'qrcode': QrCodeBlock(),  // extends BlockDefinition<QrCodeArgs>
  },
)
```

**Note**: The parameter name `widgets` on `DeckTheme` stays as-is. Changing
it to `blocks` risks confusion with the `Block` sealed class hierarchy.

**Files**: `packages/superdeck/lib/src/presentation/widget_definition.dart`
and all consumers.

### 5. `DeckConfiguration` -> `DeckWorkspace`

**Priority**: Medium — fixes the strongest internal naming collision.

**Rationale**: `DeckConfiguration` and `DeckRuntimeConfig` are too similar
while describing different things. `DeckConfiguration` resolves filesystem
paths (`superdeckDir`, `deckJson`, `slidesFile`, `assetsDir`, `pubspecFile`)
and validates against directory traversal. It is a workspace/layout object,
not a generic configuration.

`DeckWorkspace` communicates: root directory + source inputs + generated
outputs + file layout helpers.

**Files**: `packages/core/lib/src/deck_configuration.dart` and all
consumers across core, superdeck, builder, cli, and tests.

### 6. `BlockConfiguration` -> `BlockContext`

**Priority**: Low — internal clarity, fewer public consumers.

**Rationale**: `BlockConfiguration` holds `spec`, `size`, `align` — the
ephemeral render-time environment for a block during `build()`. It is not
configuration (settings); it is context (rendering conditions). Unlike
`SlideData`, it does not contain the block itself — it contains the
conditions within which a block draws itself.

**Access pattern after rename**:
```dart
final block = BlockContext.of(context);
block.spec;
block.size;
block.align;
```

**Files**: `packages/superdeck/lib/src/rendering/blocks/block_provider.dart`
and all consumers.

## Handle Surface Cleanup

`SuperDeckHandle` should split its surface into public and internal.

**Public surface** (what users see via `SuperDeck.of(context)`):
- Navigation: `nextSlide()`, `previousSlide()`, `goToSlide()`
- State signals: `slides`, `currentSlide`, `currentIndex`, `totalSlides`,
  `isLoading`, `hasError`, `error`, `canGoNext`, `canGoPrevious`
- UI toggles: `openMenu()`, `closeMenu()`, `toggleNotes()`, `isMenuOpen`,
  `isNotesOpen`, `isRebuilding`
- Reload: `reload()`

**Mark `@internal`**:
- `attach()`, `detach()` — lifecycle wiring
- `handleNavigationEvent()` — takes unexported `NavigationEvent` type
- `generateThumbnails()`, `getThumbnail()` — internal machinery
- `buildActions()`, `buildFloatingAction()` — widget building on a state handle
- `exportPdf()` — drives UI directly

**Delete**:
- `regenerateThumbnails()` — exact duplicate of `generateThumbnails`

**Symmetry fix**:
- Add `openNotes()` and `closeNotes()` to match `openMenu()` / `closeMenu()`.
- Keep `toggleNotes()` as a convenience alongside the explicit pair.

## Bootstrap DX Improvements

### Make `runtimeConfig` and `theme` optional on `SuperDeckRuntime.create()`

Both have all-optional fields and sensible defaults. A hello-world should be:

```dart
final runtime = await SuperDeckRuntime.create(
  source: const DeckSource.local(watch: true),
);
runApp(SuperDeckApp(runtime: runtime));
```

### Consider inlining `DeckRuntimeConfig`

3 optional strings (`projectDir`, `outputDir`, `assetsPath`) may not justify
a dedicated type. Could be named params on `create()`. If the type is kept,
it should at minimum be optional with a default.

## Barrel Export Cleanup

Stop exporting internal types from `packages/superdeck/lib/superdeck.dart`:
- `AppShell` — internal UI, not a user entry point
- `SlideDataBuilder` (formerly `SlideConfigurationBuilder`) — internal
  render-model assembly, not a user entry point
- `AsyncThumbnail`, `SlideCaptureService` — export internals
- `DeckWorkspace` (formerly `DeckConfiguration`) — internal, accessed via
  runtime only

Stop re-exporting all of `superdeck_core` — users see `DeckWorkspace`,
`DeckService`, `AssetCacheStore` in autocomplete when they shouldn't.

## Types That Stay Unchanged

| Type | Why |
|------|-----|
| `SuperDeckRuntime` | Correct — async init result for sync widget constructor |
| `SuperDeckApp` | Correct — the Flutter widget entry point |
| `SuperDeckHandle` | Correct name — surface needs cleanup, not rename |
| `SuperDeck.of(context)` | Correct — idiomatic Flutter context access |
| `DeckSource` | Correct — clean sealed union |
| `DeckExtension` | Correct — behavioral add-on surface |
| `DeckRuntimeConfig` | Acceptable if kept — may inline later |
| `Deck` | Correct — root parsed content model |
| `Slide` | Correct — single parsed slide |
| `SlideOptions` | Correct — per-slide frontmatter options |
| `Block` / `ContentBlock` / `WidgetBlock` / `SectionBlock` | Correct — solid hierarchy |
| `SlideTemplate` | Correct — reusable slide master |
| `SlideStyle` / `SlideSpec` | Correct — Mix framework types |

## Implementation Order

1. Make `runtimeConfig` / `presentation` optional on `create()` — free win
2. `SlideConfiguration` -> `SlideData` — highest code impact
3. `DeckPresentation` -> `DeckTheme` — highest public API impact
4. Handle surface cleanup (`@internal` annotations)
5. `SlideParts` -> `SlideFrame`
6. `WidgetDefinition` -> `BlockDefinition`
7. `DeckConfiguration` -> `DeckWorkspace`
8. `BlockConfiguration` -> `BlockContext`
9. Barrel export cleanup

Each rename should be a single focused commit with `refactor:` prefix.
