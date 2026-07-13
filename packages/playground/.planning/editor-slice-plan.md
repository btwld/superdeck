# Editor → Presentation Slice Plan (no AI)

> First implementation slice of `playground_refactor`. Ports the **editor** and
> **presentation** features from `playground` onto the Provider + Command +
> `ChangeNotifier` architecture, **without signals** and **without any AI code**.
>
> Decisions below were resolved in a design review; each row of the table is a
> settled branch, not an open question.

## Scope

**In:** editor (text editing, live preview sidebar, customization sidebar,
thumbnails) and presentation (full-screen slide playback with hero transitions
and keyboard nav).

**Out (deferred):** everything under `features/ai/` — the GenUI wizard, deck-edit
flow, AI generate panel, `applyFromAiStyle`, and the `deck_schemas` /
`style_builder` couplings.

## Load-bearing fact

The playground's data model is **`DeckController`** (from the `superdeck`
package), which is **signals-based**: `controller.slides`, `controller.options`,
and per-slide `presentation.getThumbnail(key).status` are all signals consumed
today via `Watch(...)`. We are **not** refactoring `superdeck`, so those signals
stay. The slice's core job is to **bridge** them behind `ChangeNotifier` so the
new package authors zero signals.

## Resolved decisions

| # | Branch | Decision |
|---|--------|----------|
| 1 | `DeckController` signals under "no signals" | **Bridge at the boundary.** `ChangeNotifier` stores in `core/` `.subscribe()` to superdeck's signals and `notifyListeners()`. Zero `Watch`/`Signal`/`computed`/`effect` authored in `playground_refactor`; `signals_flutter` is imported only inside the bridge stores. |
| 2 | AI entanglement in the editor | **Strip AI-specific code.** Drop `applyFromAiStyle` + `deck_schemas`/`style_builder` imports from the customization store (font/weight/color resolution stays — it's generic). Move `color_utils.dart` → `core/utils/`. Port `TextEditorController` **without** AI-handoff methods. Toolbar keeps only the **play** button. Result: **no `features/ai/` imports**. |
| 3 | Data-layer shape | **Stores-only.** No `Command`/`Result`/`Repository` in this slice — editing is a reactive stream, not request/response. Those folders + `result.dart`/`command.dart` stay as scaffolding, unused until the AI slice. `ThumbnailRefresher` ports as a `ChangeNotifier`-driven **coordinator**, not a Command (`generateThumbnails` returns `void`). |
| 4 | `DeckCustomizationStore` placement | **`core/domain/stores/`.** It writes `DeckController.options`, the deck-wide render config presentation also renders — genuinely deck-global, not editor-local. |
| 5 | Per-slide thumbnail status | **Dedicated `ThumbnailStore`** bridge. On every `slides` change it (re)subscribes to each thumbnail's `status` signal and exposes a `Map<SlideKey, ThumbnailStatus>`; previews read via `context.select` per key. Isolated from `DeckStore`. |
| 6 | Provider scoping | **Globals at app root:** `MemoryDeckLoader`, `MemoryAssetCacheStore`, `DeckController`, `DeckStore`, `DeckCustomizationStore`. **Editor-route-scoped** (`MultiProvider` in the route builder): `EditorStore`, `ThumbnailStore`, `TextEditorController`. Presentation is pushed on top, so the editor route stays mounted and scoped stores survive the round-trip. |
| 7 | Verification bar | **Unit-test the 3 bridge stores** (notification contract) + smoke widget tests. Rewrite — don't port — the old signal-based tests against the `ChangeNotifier` surface. |

### Minor defaults taken

- Drop the `dotenv` load from `main.dart` — it only supplies the AI key (`GOOGLE_AI_API_KEY`).
- `DeckCustomizationStore` seeds `DeckController.options` once in its constructor, replacing the old startup `effect`.

## Target store topology

```
App root (global, in app/providers.dart)
  MemoryDeckLoader                 data source (markdown -> parsed slides stream)
  MemoryAssetCacheStore            data source (thumbnail/asset cache)
  DeckController                   superdeck; reactive deck — NEVER read by widgets directly
  DeckStore            (core)      bridges controller.slides -> List<SlideConfiguration>
  DeckCustomizationStore (core)    background + per-TextLevel typography; writes controller.options

Editor route (scoped, MultiProvider in editorRoutes())
  EditorStore          (editor)    activeSlideIndex
  ThumbnailStore       (core)      bridges per-slide thumbnail status -> Map<key, status>
  TextEditorController (editor)    markdown in/out (AI-handoff removed)

Widget-ephemeral (StatefulWidget, disposed locally)
  Presentation: HeroController, FocusNode, _slideIndex
  Sidebar fields: TextEditingController / FocusNode (size, color, family)
```

> `ThumbnailStore` lives in `core/` by folder (reusable bridge) but is *provided*
> at the editor route — folder placement and provider scope are independent.

## Bridge contracts (the risky, novel code)

- **`DeckStore`** — subscribe to `controller.slides`; expose `List<SlideConfiguration> slides`; `notifyListeners()` on change. Single read-surface for slides (replaces scattered `controller.slides.value` reads and the unused `SlideConfigurationStore`).
- **`ThumbnailStore`** — on each `slides` change, reconcile subscriptions to every current `getThumbnail(key).status` signal (subscribe new keys, drop removed); expose `ThumbnailStatus statusFor(SlideKey)`; `notifyListeners()` on any status transition. Owns the dynamic subscription lifecycle.
- **`DeckCustomizationStore`** — `ChangeNotifier`; owns `background` + per-`TextLevel` `{color,size,weight,family}`; on any setter, recompute `SlideStyler` and write `controller.options.value = DeckOptions(...)`, then `notifyListeners()`. Seeds options in constructor. `applyFromAiStyle` removed.

## Status

- ✅ **Steps 1–3 + wiring done.** Core bridges (`DeckStore`, `ThumbnailStore`, `DeckCustomizationStore`), editor state/utils, editor UI (text editor, preview + customization sidebars, thumbnail coordinator, `EditorPage` + `editorRoutes()`), and app wiring (`providers.dart`, `router.dart`, `main.dart`) are implemented. `dart analyze lib test` is clean; 9 tests pass (6 bridge unit + 1 thumbnail + 1 editor smoke, +tearDown). Guardrails verified: no signals authored in app code, no `features/ai/` imports.
- ⏳ **Step 4 (presentation) is next.** `/present` is currently a placeholder route.

### Implementation deviations from the plan (all deliberate)

- **`signals` is a direct dependency** (bridge-only). `.subscribe()`/`effect()` are needed to translate `DeckController`'s signals; usage is confined to `core/domain/stores/{deck_store,thumbnail_store}.dart`. Consistent with decision 1.
- **Theme colors resolved at construction.** `DeckCustomizationStore` takes concrete seed `Color`s (resolved from `$background`/`$foreground` in `AppProviders.build`) instead of storing `ColorRef`s — `ColorRef.resolveProp` is a mix-internal member. Trade-off: seed colors are fixed to the brightness at startup (the app doesn't switch brightness at runtime).
- **`lazy: false`** on `DeckController`/`DeckStore`/`DeckCustomizationStore` so the loader→slides pipeline is subscribed before the editor writes its first markdown.

## Build order

1. **`core/` bridges (test-first):**
   `DeckStore` → `ThumbnailStore` → `DeckCustomizationStore`, each unit-tested against a real/fake `DeckController` (assert notifications fire + values match).
2. **Editor state + utils:** `EditorStore`; trimmed `TextEditorController`; move `color_utils` → `core/utils/`.
3. **Editor UI:** `TextEditor`, `PreviewSidebar`, `CustomizationSidebar` (play-only toolbar), `ThumbnailCoordinator`, `EditorPage` + `editorRoutes()`. Replace every `Watch`/signal read with `context.watch`/`select` on the bridges.
4. **Presentation:** `PresentationPage` + `presentationRoutes()`, wired to `DeckStore`.
5. **Wiring:** `app/router.dart` composes `editorRoutes()` + `presentationRoutes()`; `app/providers.dart` holds the globals; delete the placeholder home route.

## Definition of done

Functional parity with the current editor + presentation:
- App runs; typing updates previews live.
- Customization edits (background, per-level color/size/weight/family) re-render the deck.
- Thumbnails appear and refresh on deck-wide style change; active slide renders live.
- Presentation plays: arrow/space advance, arrow-left back, esc exits, hero flights animate.

Guardrails (gate the slice):
- **No signals authored** — `Signal`/`computed`/`effect`/`Watch` appear only inside `core/` bridge stores.
- **No `features/ai/` imports** anywhere in the slice.
- `dart analyze lib test` clean; bridge unit tests + smoke widget tests green.

## Test plan

- **Unit (bridge contract):** `DeckStore`, `ThumbnailStore`, `DeckCustomizationStore` — drive a fake `DeckController`, assert `notifyListeners` timing and exposed values; for `ThumbnailStore` assert subscribe/unsubscribe as slides are added/removed and status transitions propagate.
- **Widget (smoke):** `EditorPage` builds from seeded markdown and previews reflect an edit; `PresentationPage` renders slides and advances on key events.
- Rewrite `text_editor_load_test` / `text_editor_repaint_test` / thumbnail tests against the `ChangeNotifier` surface rather than porting signal assertions.
