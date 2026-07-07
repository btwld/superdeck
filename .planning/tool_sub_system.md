# AI Deck-CRUD Tool Subsystem — Architecture & Requirements

> **Status:** Designed and ported during the `superdeck_ai → playground` migration, but
> **never wired into the running app** (reachable only from tests). It has been **removed**
> from the codebase to eliminate dead code; this document is the spec to **reimplement it in a
> dedicated PR**. The previous implementation is recoverable from git history (the commit
> immediately before the removal commit on `feat/playground-framework-support-v1`).

## 1. Purpose & intent

Let the AI **edit the current, in-memory deck** via GenUI tool-calls during a conversation —
an "edit my deck with AI" surface — as distinct from the existing **wizard**, which only does
*initial* generation. The model can create / read / update / delete / move slides, update the
deck style, and read a slide back **with a rendered screenshot** so it can "see" the result and
iterate.

It is the tool-calling counterpart to the generation pipeline: generation produces a deck;
these tools let the model *mutate* the deck it already produced (or the user is editing).

## 2. Architecture (as designed)

```
model (Gemini, tool-calling)
  │  calls a tool by name with JSON args
  ▼
DeckToolsAdapter            maps each op → genui DynamicAiTool
  │  (name, description, parameters: Ack schema → JSON Schema, invokeFunction)
  ▼
DeckToolsService            the operation surface (serialized mutation queue)
  │  validate (deck_mutation_helpers) → mutate List<Slide>
  ▼
DeckStore (InMemoryDeckStore)
  │  read: SlidesProvider() → live List<Slide>
  │  write: SlideSerializer.serialize(slides) → MemoryDeckLoader.updateMarkdown(md)
  ▼
DeckController.slides recomputes ──▶ editor + preview update (reactive loop closed)
  │
  └─ each op returns a DeckSnapshot token (totalSlides + per-slide summary + style)
     back to the model so it always has current state.
```

**Components** (all previously under `packages/playground/lib/features/ai/`):

| Component | Role |
|---|---|
| `core/tools/deck_tools_service.dart` | The 7 operations + a **serialized mutation queue** (writes run one-at-a-time); reads bypass the queue. Injection seams: `DeckStore`, `BuildContextProvider`, `SlideCaptureFn`, `ReadSlideConfigurationBuilder`. |
| `core/tools/deck_store.dart` | `DeckStore` interface (`readRequired()`, `writeCanonical({slides, style})`) + `DeckDocument` value (`slides`, `style`). |
| `core/tools/in_memory_deck_store.dart` | In-memory impl: reads the live `List<Slide>` via a `SlidesProvider` callback; writes by serializing to Markdown (`SlideSerializer`) and pushing into `MemoryDeckLoader` — closing the reactive loop. Web-safe. |
| `core/tools/deck_tools_schemas.dart` (+ `.g.dart`) | Ack `@AckType` request/result schemas — the **typed tool contract**. |
| `core/tools/deck_mutation_helpers.dart` | Pure helpers: index validation, unique-key checks, list insert/replace/remove/move, `buildDeckSnapshot`. |
| `core/tools/deck_tools_adapter.dart` | Maps each op → a genui `DynamicAiTool<Map<String,dynamic>>` (params via `ackSchema.toJsonSchemaBuilder()`, `invokeFunction` → service → encode result). |
| `core/tools/errors.dart` | `DeckToolException` + `DeckToolErrorCode` constants. |
| `core/superdeck_slide_configurations.dart` | `buildRuntimeSlideConfigurations(...)` — builds `SlideConfiguration`s for the `readSlide` screenshot. |
| `presentation/thumbnail_preview_service.dart` | Batch slide→thumbnail capture (same capture dependency). |
| `core/utils/deck_style_service.dart` | Global `Signal<DeckStyleType?>` intended as a style broadcast. |

## 3. The tool contract

| Tool | Args | Result |
|---|---|---|
| `getDeck` | — | `DeckSnapshot { totalSlides, slides:[{index,key,title?}], style? }` |
| `createSlide` | `{ schema: Slide, atIndex?: int }` | `SlideMutationResult { slide, deck }` |
| `updateSlide` | `{ index: int, schema: Slide }` | `SlideMutationResult` |
| `deleteSlide` | `{ index: int }` | `DeckSnapshot` |
| `moveSlide` | `{ fromIndex: int, toIndex: int }` | `SlideMoveResult { slide, deck }` |
| `updateStyle` | `{ style: DeckStyle }` | `StyleUpdateResult { style, deck }` |
| `readSlide` *(service-only; never exposed as a tool — see G3)* | `{ index: int }` | `ReadSlideResult { slide(+base64 thumbnail), deck }` |

Slide / style payloads reuse the generation schemas (`deck_schemas.dart`); args are Ack-validated.

## 4. GenUI tool-calling integration seam

`GoogleGenerativeAiContentGenerator(... additionalTools: List<AiTool>)`
(genui_google_generative_ai). A tool is a `DynamicAiTool<Map<String,dynamic>>` with
`name`, `description`, `parameters` (a `json_schema_builder` `Schema`, produced by
`ackSchema.toJsonSchemaBuilder()`), and `invokeFunction: (args) async => Map`.

Today `GenUiConversationViewModel.buildConversation()` passes `additionalTools: []`. Wiring is a
single line — `additionalTools: [...DeckToolsAdapter(service).tools]` — gated on the dependency
chain in §5.

## 5. Requirements for the reimplementation

**Functional**
- FR1 — Expose the 6 mutation tools **and `readSlide`** as live GenUI tools in a **dedicated
  "edit deck with AI" conversation surface** (separate from the generation wizard).
- FR2 — Mutations run through the serialized queue and flow `service → InMemoryDeckStore →
  SlideSerializer → MemoryDeckLoader → DeckController.slides`, reactively updating editor + preview.
- FR3 — `readSlide` returns a base64 PNG via `SlideCaptureService` so the model can see a slide.
- FR4 — Every op returns a `DeckSnapshot` so the model always has current deck state.

**Non-functional**
- NFR1 — **In-memory + web-safe** (no `dart:io`). The old disk `DeckDocumentStore` was never
  built — do not reintroduce it.
- NFR2 — Editor markdown stays clean (bare image refs); all writes go through `SlideSerializer`.
- NFR3 — Ack-validated args + typed results; tool params via `toJsonSchemaBuilder()`.

**Wiring requirements**
- `ChatViewModel` / `GenUiConversationViewModel` must accept a `DeckToolsService` and pass its
  adapter tools to `additionalTools`.
- `InMemoryDeckStore` built with the **live** `MemoryDeckLoader` and a
  `SlidesProvider = () => deckController.slides.value.map((c) => c.slide).toList()`.
- A `BuildContextProvider` returning a mounted `BuildContext` for `readSlide` capture.

## 6. Known gaps to fix when reimplementing

- **G1 — Store consistency (capture).** The old `buildRuntimeSlideConfigurations` built a
  *throwaway* `DeckController` **without** the shared `MemoryAssetCacheStore`, so `readSlide`/
  thumbnail captures couldn't resolve AI-generated images. Fix: capture using the **live**
  controller's `SlideConfiguration`s (which now carry `assetCacheStore` after the image-store
  refactor), or pass the shared store explicitly.
- **G2 — Style plumbing.** `DeckStyleService` was a standalone global written only by
  `updateStyle` and read by nobody (always null at runtime). Integrate style updates into the
  existing `DeckCustomizationStore` / `DeckController.options` instead of a disconnected singleton.
- **G3 — `readSlide` not exposed.** The service had `readSlide` but the adapter's `tools` list
  omitted it. Add `_readSlideTool`.
- **G4 — Vestigial disk errors.** `DeckToolErrorCode.deckFileNotFound` and the `path:` params are
  leftovers from an unbuilt disk store — drop them.
- **G5 — No UX surface.** The wizard is for initial generation; an explicit "edit with AI" chat
  surface needs to be designed and mounted.
- **G6 — Never constructed.** The whole dependency chain (`InMemoryDeckStore` → `DeckToolsService`
  → `DeckToolsAdapter` → `additionalTools`) was absent; wire it in `main.dart` / the chat VM.

## 7. Reuse — building blocks already in the codebase

- `SlideSerializer` (`packages/builder/lib/src/parsers/slide_serializer.dart`) — Slide→Markdown.
- `MemoryDeckLoader.updateMarkdown` (`packages/playground/lib/utils/memory_deck_loader.dart`) — reactive in-memory load.
- `DeckController.slides` — live deck; `SlideConfiguration` now carries `assetCacheStore` (capture-ready).
- `SlideCaptureService` (`packages/superdeck/lib/src/capture/slide_capture_service.dart`) — offscreen capture.
- `ack` + `ack_json_schema_builder` — schema → JSON Schema for tool params.
- `genui` `DynamicAiTool`/`AiTool` + `GoogleGenerativeAiContentGenerator.additionalTools` — the seam.

## 8. Files removed (recoverable from git history)

lib: `core/tools/` (deck_tools_service, deck_tools_adapter, deck_store, in_memory_deck_store,
deck_mutation_helpers, deck_tools_schemas[.g], errors), `core/utils/deck_style_service.dart`,
`presentation/thumbnail_preview_service.dart`, `core/superdeck_slide_configurations.dart`.

tests: `test/features/ai/core/tools/*`, `core/utils/deck_style_service_test.dart`,
`presentation/thumbnail_preview_service_test.dart`.

## 9. Decision log

- The unwired subsystem was removed to keep the migration free of dead code. Reimplementation is
  deferred to a dedicated PR using this document as the spec. Recover the prior code from the
  commit before the removal if it's a useful starting point.
