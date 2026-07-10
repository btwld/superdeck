# AI Deck-Editing Tools — Reimplementation Plan (v2, index-based)

> **Supersedes** `.planning/tool_sub_system.md`. That document described the subsystem as
> ported-but-removed and listed gaps G1–G6. This plan corrects two factual errors in it,
> adds two **blocker-severity** correctness fixes it missed, and commits to the
> **index-based contract** (slide keys dropped). The prior implementation is recoverable from
> `git show 3484ee51:<path>` (parent of the removal commit `492a9bc9`) and is a clean starting
> point — the redesign is in the **store/key/style layer**, not the tool surface.

## 0. Decision of record

**Drop slide keys from the deck-edit tool contract. The model addresses slides purely by index.**

Why: `Slide.key` is a content hash recomputed on every parse (`markdown_parser.dart:157
generateValueHash(rawSlide)`), and `SlideSerializer` never writes `key` to frontmatter. So every
`serialize → updateMarkdown → reparse` round-trip reassigns all keys. Any key the service hands the
model is stale the instant a write lands. Rather than teach the parser/serializer to persist an
explicit frontmatter key (larger change, changes the on-disk markdown format), v1 removes keys from
the contract entirely. Index-based ops are correct **because each op re-reads live state** before
mutating — provided we close the read-after-write gap (§3, Fix B).

The deck-edit tools get their own keyless DTO, `DeckToolSlide`, shaped as
`{ options?, comments?, sections }`. The existing wizard `slideSchema` / `createSlideSchema` stay
unchanged. If constructing an internal `Slide` still requires a key, the service creates a private
transient key only for that construction path; it is never returned, serialized, or included in tool
prompts.

## 1. Purpose

A dedicated "**edit my deck with AI**" route where the model can create / read / update / delete /
move slides and update the deck style via GenUI tool-calls, and read a slide back **with a rendered
screenshot** so it can see the result and iterate. This is a slide-first editing mode, not a live
extension of the Markdown text editor. Entering AI edit mode replaces/unmounts the Markdown editor
route; the AI tools mutate the live deck/preview state directly. The app already uses
`MaterialApp.onGenerateRoute`, so v1 adds a concrete `/ai/edit` route. When entering from the
editor, the entry handler synchronously captures `TextEditorController.latestMarkdown` while
`TextEditor` is still mounted, synchronously suspends outbound editor writes to `MemoryDeckLoader`,
then immediately calls `Navigator.pushReplacementNamed('/ai/edit', arguments: capturedSource)`.
The AI route starts in an entry-loading state with deck-edit tools and conversation creation
disabled, verifies the editor is either disposed or still write-suspended, writes the captured source
through the shared raw-markdown canonical write/observation path, and only then captures
`baselineCanonicalMarkdown` via `SlideSerializer` and `baselineCustomizationSnapshot` from
`DeckCustomizationStore`. If the entry barrier fails, the route does not create a tool session or
model conversation; it reports the error, stages `capturedSource` with the non-notifying
next-editor-mount handoff, keeps the editor-write suspension active until that next mount consumes the
handoff, and replaces back to the editor route. If the route is entered from a non-editor source, it
still observes the already-live canonical deck before capturing the baseline.
On exit, the user is prompted to Apply or Discard. Apply serializes the current live deck to final
canonical markdown, keeps the current AI-applied customization/style, and hands the markdown to the
editor once. Discard restores `baselineCanonicalMarkdown` via the awaitable canonical write path and
restores `baselineCustomizationSnapshot` before returning, so both preview and editor return to
pre-AI state. This is distinct from the existing **wizard** (`AiStore.generate`, `ai_generate_panel`),
which only does one-shot initial generation by replacing the whole markdown.

## 2. Corrected baseline facts (what the old spec got wrong)

- ❌ **"Wiring is a single line"** (old §4) — **false.** `buildConversation()` lives in the abstract
  `GenUiConversationViewModel`
  (`packages/playground/lib/features/ai/core/ai/services/genui_conversation_viewmodel.dart:107`,
  `additionalTools: []`),
  which is shared by **both** `ChatViewModel` (wizard) and `RemixViewModel`. `ChatViewModel` is
  constructed argument-free (`packages/playground/lib/features/ai/chat/view/chat_screen.dart`). Real
  wiring = a new ctor param threaded through the base, a new VM subclass for the edit surface, a
  constructed `DeckToolsService`, re-declared capture/provider typedefs (the old `SlideCaptureFn`
  lived in the removed `packages/playground/lib/features/ai/presentation/thumbnail_preview_service.dart`),
  and adding `_readSlideTool` (old G3). See §6.
- ❌ **NFR1's "the old disk `DeckDocumentStore` was never built"** — **false.** It was a real
  174-line `dart:io` store, removed in commit `0f330e19` ("remove dead disk layer"). The
  *guidance* (stay in-memory, web-safe, no `dart:io`) is correct and we keep it; only the history was
  wrong.
- ✅ Everything else in the old spec checks out: "never wired" is true (`additionalTools: []`),
  the genui seam is real (genui 0.7.0 `DynamicAiTool`/`AiTool` +
  `GoogleGenerativeAiContentGenerator.additionalTools`), `ackSchema.toJsonSchemaBuilder()` exists,
  and all reuse building blocks (§7 of the old spec) exist at HEAD with the claimed signatures.

## 3. The two blocker fixes the old spec missed

### Fix A — Key instability → **drop keys** (Decision §0)
Already decided. Concrete surgery in §5. Net effect: no code path depends on key stability anymore;
indices are the only addressing primitive, and they are always resolved against live state.

### Fix B — Read-after-write lag → **`writeCanonical` awaits the reactive round-trip**
`MemoryDeckLoader.updateMarkdown` parses synchronously but emits `SlidesLoadedEvent` on a **broadcast
`StreamController`** (`memory_deck_loader.dart:8,29`) — delivery is async. `DeckController.session`
consumes that event and sets `loadedSlides`; `DeckController.slides` is a `computed` over it
(`deck_controller.dart:43-51`). So immediately after `updateMarkdown`, `controller.slides.value` is
**stale** for a microtask. The old serialized mutation queue ordered service *calls* but never
awaited the controller catching up, so two consecutive mutations could both read the same pre-write
`slides.value` and the second would clobber the first.

**Fix:** make `InMemoryDeckStore.writeCanonical` `async` and await the round-trip:
1. Arm a one-shot listener on `loader.load()` for the next `SlidesLoadedEvent` / `SlidesErrorEvent`
   **before** calling `updateMarkdown`.
2. Serialize the target slide list to canonical markdown and call `loader.updateMarkdown(...)`.
3. `await` the loader event only as a parse/write success-or-error signal. A `SlidesErrorEvent`,
   timeout, disposed loader/session, or cancelled subscription becomes
   `DeckToolException.deckWriteFailed` rather than a hang.
4. Within the same timeout budget, wait/poll/observe until the live `DeckController`/`slidesProvider`
   reflects the written canonical markdown before returning. The verification should compare
   `SlideSerializer().serialize(slidesProvider())` with the canonical markdown just written, or an
   equivalent structural canonical comparison. Timeout or mismatch throws `deckWriteFailed`.

Do not rely on Dart broadcast listener ordering for freshness. The loader event only tells us the
write was parsed/emitted; the explicit canonical post-write observation is what guarantees
`controller.slides.value` is fresh by the time the next queued mutation reads it. The serialized
service side-effect queue then provides correct read-mutate-write ordering against live state and
style application state, and read-only deck tools must await/drain the current queue before reading so
concurrent tool calls do not observe pre-write, mid-write, or mid-style state.

> This is the load-bearing fix that makes the index-based contract correct. It must be covered by an
> integration test against the **real** `InMemoryDeckStore` + a live `DeckController` (§10) — the gap
> that hid both blockers, since every old test swapped in a synchronous in-place store.

## 4. Tool contract (index-based)

Pin the v1 JSON contract exactly:

| Tool | Args | Result |
|---|---|---|
| `getDeck` | — | `{ totalSlides, slides: [{ index, title? }] }` |
| `createSlide` | `{ slide, atIndex? }` | `{ index, slide, deck }` |
| `updateSlide` | `{ index, slide }` | `{ index, slide, deck }` |
| `deleteSlide` | `{ index }` | `deck` |
| `moveSlide` | `{ fromIndex, toIndex }` | `{ fromIndex, toIndex, deck }` |
| `readSlide` | `{ index }` | `{ index, title?, slide, thumbnailBase64, deck }` |
| `updateStyle` | `{ style }` | `{ style, deck }` |

These are the **7 deck-edit additional tools** exposed by `DeckToolsAdapter` and passed through
`additionalTools`. Do not treat this as the total GenUI/model tool registry size; GenUI surface tools
may also be registered unless the implementation explicitly suppresses them.

Definitions:
- `createSlide.atIndex` is optional. When omitted, the service resolves the insertion index to the
  current `totalSlides`, so the new slide appends to the end of the live deck.
- `DeckSnapshot` is exactly `{ totalSlides, slides: [{ index, title? }] }`. It does **not** include
  `style`.
- `slide` in deck-edit tool args and results is `DeckToolSlide`: `{ options?, comments?, sections }`.
  It is based on the core SuperDeck slide model minus `key`, not the narrower wizard generation
  schema. It has no `key`; keyless tool schemas reject an incoming `key` before service logic.
- `DeckToolSlide.options` must preserve core `SlideOptions` data, including `title`, `style`,
  `template`, and arbitrary option args supported by core `SlideOptions`.
- `DeckToolSlide.sections` and nested blocks must preserve core section/block fields and widget args,
  including arbitrary widget args, so round-tripping through `SlideSerializer` does not drop
  core-supported data.
- Existing wizard `slideSchema` / `createSlideSchema` remain unchanged and continue serving the
  one-shot generation flow. Do not reuse them for `DeckToolSlide` if they would drop core-supported
  slide option args, section/block fields, or widget args.
- The deck edit prompt must not include "Slide Keys" guidance. Indexes are the only model-facing
  addressing primitive.
- `readSlide` is **exposed as a live tool** (old G3), returns the keyless `slide`, and captures at
  `SlideCaptureQuality.thumbnail`.
- `updateStyle` returns the applied `style` at the top level, but the nested `deck` snapshot still
  omits style.

All args are Ack-validated; tool `parameters` come from `ackSchema.toJsonSchemaBuilder()` (NFR3
unchanged). For deck-edit index fields (`index`, `fromIndex`, `toIndex`, `atIndex`), Ack validates
integer type only. Range validation lives in the service/mutation helpers so integer range errors map
to `DeckToolException.slideIndexOutOfRange` / `slide_index_out_of_range`; non-integer or malformed
payloads still map to adapter `validation_failed`.

## 5. Per-file changes (recover from `3484ee51`, then edit)

**`packages/playground/lib/features/ai/core/tools/deck_store.dart`**
- `writeCanonical(List<Slide> slides)` → returns `Future<void>` (now async, awaits the loader event
  and verifies the live slides provider reflects the canonical markdown before returning).
- Add `writeCanonicalMarkdown(String markdown)` / `flushMarkdownToCanonical(String markdown)` as the
  shared raw-markdown boundary helper. It parses the input markdown to slides, serializes those slides
  back to canonical markdown, arms the loader listener before writing, writes that canonical markdown,
  waits for the loader event, verifies the live slides provider canonicalizes to the same markdown,
  and returns the canonical markdown it observed. `writeCanonical(List<Slide>)` should serialize the
  slides and delegate to the same internal write-and-observe path.
- Drop the `style` param and `DeckDocument.style`; style no longer flows through the store.

**`packages/playground/lib/features/ai/core/tools/in_memory_deck_store.dart`**
- Implement Fix B in `writeCanonical`: listen before writing, await the next loader event as the
  parse/write signal, then wait/poll/observe within the same timeout until `slidesProvider`
  canonicalizes to the written markdown. Throw `deckWriteFailed` on loader errors, timeout, disposal,
  cancellation, or canonical mismatch.
- Implement the raw-markdown helper with the same listener-before-write and canonical observation
  behavior. Entry, Discard, and any optional Apply loader sync must use this helper instead of direct
  fire-and-forget `MemoryDeckLoader.updateMarkdown`.
- Remove `_currentStyle` and the `path: '<in-memory>'` sentinel.

**`packages/playground/lib/features/ai/core/tools/deck_mutation_helpers.dart`**
- Remove `ensureUniqueSlideKeyForCreate/Update`, `_generateUniqueSlideKey`, `isSafeSlideKey`, and all
  key-conflict logic.
- `buildDeckSnapshot` emits exactly `{ totalSlides, slides: [{ index, title? }] }`; no `style`, no
  `key`.
- For create mutations, resolve omitted `atIndex` to `slides.length` before insertion. Valid create
  insertion range is inclusive `0..totalSlides`, with `totalSlides` meaning append.
- Keep range validation + list `insert/replace/remove/move`. Negative and too-large deck-edit
  indices for create/update/delete/move/read map to `DeckToolException.slideIndexOutOfRange`, not Ack
  validation errors.

**`packages/playground/lib/features/ai/core/tools/deck_tools_service.dart`**
- Keep throwing typed `DeckToolException`; do not translate errors into model-facing payloads here.
- Add a route-scoped closed-session guard. All seven tool methods (`getDeck`, `createSlide`,
  `updateSlide`, `deleteSlide`, `moveSlide`, `readSlide`, `updateStyle`) check it before reads,
  mutations, capture, or style application and throw `DeckToolException.contextUnavailable` after
  closure.
- Check the closed-session guard at invocation start and immediately before every write, style apply,
  capture, or editor handoff side effect.
- Expose only the service-owned side-effect queue state to the route/session controller (`idle` vs.
  pending/running, or equivalent pending/running counts). The queue includes slide mutations and
  `updateStyle` style applications. Do **not** make `DeckToolsService` expose a composite busy state
  that includes adapter invocations or conversation state.
- `getDeck` and `readSlide` are tracked as adapter active invocations and must await/drain the
  service side-effect queue before reading live slide/configuration state. They are not counted as
  side effects, but they must not observe a slide write that is queued/running/still awaiting
  canonical observation or an `updateStyle` that is queued/running/still propagating to
  `DeckController.options` / `DeckController.slides`.
- Parse `createSlide` / `updateSlide` payloads as `DeckToolSlide`, not wizard slides.
- Internally add a private transient key only when constructing a `Slide`; never return it in
  `slide`, summaries, snapshots, prompts, or serialized markdown.
- `createSlide`: insert at `atIndex ?? totalSlides`; omitted `atIndex` appends at the current
  `totalSlides`; `await store.writeCanonical(...)`; build `{ index, slide, deck }` from the
  **post-write live** slides.
- `createSlide`: map invalid insertion indices (`atIndex < 0` or `atIndex > totalSlides`) to
  `DeckToolException.slideIndexOutOfRange` so the adapter returns `slide_index_out_of_range`. There
  is no separate `slide_insert_index_invalid` code in v1.
- `updateSlide`: replace at `index`; `await store.writeCanonical(...)`; build
  `{ index, slide, deck }` from the **post-write live** slides.
- `updateSlide`, `deleteSlide`, `moveSlide`, and `readSlide`: map negative or too-large integer
  indices (`index`, `fromIndex`, `toIndex`) to `DeckToolException.slideIndexOutOfRange` so the
  adapter returns `slide_index_out_of_range` and no mutation/capture occurs.
- `updateStyle`: replace the dead `DeckStyleService.setStyle` + markdown round-trip with
  `_applyStyle(parsedStyle)` → `DeckCustomizationStore.applyFromAiStyle(parsedStyle)`
  (`deck_customization_store.dart:224`); return `{ style, deck }`; **do not** serialize style to
  markdown and do not put style inside `DeckSnapshot`. Run `updateStyle` through the same service
  side-effect queue as slide mutations, and do not let `getDeck` / `readSlide` observe state until the
  style application has propagated to `DeckController.options` / derived slide configurations.
- `readSlide`: after draining pending mutations, copy the fresh live `SlideConfiguration` list into a
  local immutable post-drain snapshot, revalidate `index` against that snapshot, and pass
  `snapshot[index]` (already carries the shared `MemoryAssetCacheStore` — fixes G1, see below) to
  `SlideCaptureService.capture(quality: thumbnail, ...)`. Build `title`, keyless `slide`, and
  `deck` from the same snapshot, not from a later `deckController.slides.value` read; `base64Encode`
  in the service and return `{ index, title?, slide, thumbnailBase64, deck }`.
- `readSlide`: check the closed-session guard and route-owned `BuildContextProvider` before capture,
  after every async gap, and immediately before returning capture-dependent output. If the session is
  closed or the context is cleared, missing, or unmounted before or during capture, throw
  `DeckToolException.contextUnavailable`. Catch real capture/render failures from the capture
  callback / `SlideCaptureService` and throw `DeckToolException.captureFailed`; do not classify
  route disposal during capture as `captureFailed`.
- Do **not** call `TextEditorController.loadMarkdown` from per-tool mutations. The AI edit surface
  owns the live slide-editing loop; if the user returns to the Markdown editor, perform a one-shot
  handoff of the final canonical markdown at the mode boundary.

**`packages/playground/lib/features/ai/core/tools/deck_tools_schemas.dart` (+ `.g`)**
- Add the dedicated `DeckToolSlide` DTO/schema: `options?`, `comments?`, `sections`; no `key`.
- Base `DeckToolSlide` on the core SuperDeck slide model minus `key`, preserving arbitrary
  core-supported `SlideOptions` args and section/block/widget args. Do not reuse wizard schemas if
  they would narrow or drop those fields.
- Wire `createSlide`, `updateSlide`, and `readSlide` results to use `DeckToolSlide`.
- Remove `key` from the deck-edit slide request payloads and from the slide-summary schema.
- Leave existing wizard `slideSchema` / `createSlideSchema` untouched.
- Add `index` to `SlideMutationResult`; keep `fromIndex` / `toIndex` in `SlideMoveResult`.
- For `index`, `fromIndex`, `toIndex`, and `atIndex`, validate integer type only. Do not encode deck
  size or non-negative range constraints in Ack; those belong in service/mutation helpers to preserve
  `slide_index_out_of_range` for integer range errors.
- Ensure keyless tool schemas reject incoming `key` with an Ack validation error before service
  mutation, and lock that behavior in tests.
- Regenerate via `melos run build_runner:build`.

**`packages/playground/lib/utils/text_editor_controller.dart`**
- Make markdown handoff one-shot. `loadMarkdown(markdown)` stores pending markdown and notifies, and
  `String? takePendingMarkdown()` returns and clears pending markdown exactly once.
- Apply/Discard use `loadMarkdown(...)`; the subsequent editor mount consumes via
  `takePendingMarkdown()` so stale pending markdown cannot replay on later mounts.
- Add a non-notifying next-editor-mount handoff for AI-entry aborts, for example
  `stageMarkdownForNextEditorMount(markdown)` plus init-only consumption. This stores markdown for the
  next editor route mount without notifying currently mounted `TextEditor` listeners, so an outgoing
  editor route delayed by `Navigator.pushReplacementNamed` cannot consume the abort handoff. The
  mounted external-load listener must consume only `loadMarkdown(...)` notifications, not this
  mount-only staged value.
- Track the latest outbound editor markdown as `latestMarkdown` (or equivalent). `TextEditor` records
  its initialized markdown and every subsequent document change here so the AI route can read the
  current editor source before replacing/unmounting the editor route.
- Add an AI-entry handoff guard such as `suspendOutboundWritesForAiEntry()` /
  `resumeOutboundWritesForEditorMount()` (exact names flexible). The entry handler captures
  `latestMarkdown`, then synchronously enables this guard before navigation. While enabled,
  `TextEditor` must not call `MemoryDeckLoader.updateMarkdown`; the guard is cleared only from
  `TextEditor` init after the next editor mount consumes either a normal pending handoff or the
  non-notifying staged abort handoff. Abort/error handling must not clear the guard while an outgoing
  editor route may still be mounted.

**`packages/playground/lib/features/editor/text_editor.dart`**
- On init, check `TextEditorController.takePendingMarkdown()` before creating or emitting starter
  content. If pending markdown exists, initialize the editor from it and do **not** emit default
  starter markdown.
- Continue listening for later `loadMarkdown(...)` notifications while mounted. The mounted external
  load listener must also consume with `takePendingMarkdown()`, apply that markdown to the document,
  update `TextEditorController.latestMarkdown`, and thereby clear pending state so the same markdown
  cannot replay on a later mount. If the notification has no pending markdown, the listener is a
  no-op.
- Use `TextEditor.onChanged`, direct controller calls from `_onDocumentChanged`, and init-time
  recording to keep `TextEditorController.latestMarkdown` current with the editor's latest markdown
  source.
- Before any `_onDocumentChanged` / `onChanged` path writes to `MemoryDeckLoader`, check the
  AI-entry outbound-write suspension guard. If suspended, keep `latestMarkdown` current for local
  state but skip the loader write so route replacement transitions cannot race the AI entry
  canonicalization barrier.

**`packages/playground/lib/features/editor/customization_sidebar.dart`**
- Add the concrete editor entry control for deck editing with AI (or move this exact handler to
  `editor_page.dart` if that is where the editor toolbar is consolidated). Its handler synchronously
  reads `TextEditorController.latestMarkdown`, calls the outbound-write suspension guard, and then
  calls `Navigator.pushReplacementNamed('/ai/edit', arguments: capturedSource)`. Do not route this
  entry through the existing wizard/remix side-panel buttons.

**`packages/playground/lib/stores/deck_customization_store.dart`**
- Add a small snapshot/restore API if needed:
  `DeckCustomizationSnapshot captureSnapshot()` and
  `restoreSnapshot(DeckCustomizationSnapshot snapshot)`.
- The snapshot must capture complete playground customization state: background and each text level's
  color, size, weight, and family, or an equivalent complete state representation that fully restores
  the `DeckOptions` pushed to `DeckController`.
- `restoreSnapshot` updates store signals so the existing effect updates `controller.options`.

**`packages/playground/lib/features/ai/core/tools/errors.dart`**
- Remove `deckFileNotFound`, `deckJsonInvalid`, `slideKeyConflict`, and all `path:` params (old G4 +
  key drop). Keep `slideIndexOutOfRange`, `invalidArgument`, `captureFailed`, `contextUnavailable`,
  and a `deckWriteFailed` (no path) for reactive write failures, including loader errors, timeouts,
  disposal, and post-write verification mismatch. Use `contextUnavailable` for disposed route context
  and closed-session late tool calls.

**`packages/playground/lib/features/ai/core/tools/deck_tools_adapter.dart`**
- Add `_readSlideTool` to the deck-edit `tools` list → **7 deck-edit additional tools** (old G3).
- Add adapter-level closed-session preflight before Ack parsing/validation in every
  `invokeFunction` wrapper. If the route-scoped tool session is closed, return
  `{ error: { code: 'context_unavailable', message } }` before attempting to parse args, even for
  malformed payloads. The service closed-session guard remains as a second line of defense.
- Track adapter active invocation count/idle state in `DeckToolsAdapter` with `try`/`finally` around
  each open-session `invokeFunction` path so validation errors, typed service errors, capture errors,
  and unexpected exceptions cannot leak busy state. This adapter-owned signal includes `getDeck`,
  `readSlide`, `updateStyle`, and slide mutations.
- `invokeFunction` catches `DeckToolException` and Ack parse/validation errors and returns
  `{ error: { code, message } }` with exact snake_case `error.code` values:
  - `DeckToolException.contextUnavailable` → `context_unavailable`
  - `DeckToolException.captureFailed` → `capture_failed`
  - `DeckToolException.deckWriteFailed` → `deck_write_failed`
  - `DeckToolException.slideIndexOutOfRange` → `slide_index_out_of_range`
  - `DeckToolException.invalidArgument` → `invalid_argument`
  - Ack parse/validation errors → `validation_failed`
  Other unexpected exceptions may still surface through the normal error path.

**`packages/playground/assets/ai_prompts/deck_edit_system.prompt`**
- Add the concrete deck-edit system prompt asset.
- `DeckEditViewModel.promptName` must be `deck_edit_system` (or the exact prompt registry key matching
  this asset).
- The prompt must describe index-based deck editing, the seven deck-edit additional tools, keyless
  `DeckToolSlide`, and `readSlide` returning both the keyless slide and screenshot. It must not
  include any "Slide Keys" guidance or instructions to create, preserve, or return slide keys.

**Delete** `packages/playground/lib/features/ai/core/utils/deck_style_service.dart` (G2 — replaced by
`applyFromAiStyle`) and
`packages/playground/lib/features/ai/core/superdeck_slide_configurations.dart` (G1 — replaced by live
configs).
**Re-declare** capture/provider typedefs in a live capture-seam file (the old `SlideCaptureFn` lived
in the removed `packages/playground/lib/features/ai/presentation/thumbnail_preview_service.dart`):
`typedef SlideConfigurationsProvider = List<SlideConfiguration> Function();` and
`typedef SlideCaptureFn = Future<Uint8List> Function(SlideConfiguration configuration);`. The
capture function must be pure over the passed configuration and must not reread
`controller.slides.value`.

### G1, G2, G4 status under this plan
- **G1 (capture store consistency):** solved by construction — `readSlide` snapshots
  `List<SlideConfiguration>.unmodifiable(slideConfigurationsProvider())` after draining the
  side-effect queue and captures `snapshot[index]`, whose configs already carry the shared
  `MemoryAssetCacheStore`
  (`deck_controller.dart:49`). Verified consumers: `image_widget.dart:129-134` /
  `image_element_builder.dart:72-79` resolve bare asset keys via `SlideConfiguration.assetCacheStore`,
  so AI-generated images now resolve. The throwaway controller is deleted.
- **G2 (style plumbing):** solved via `DeckCustomizationStore.applyFromAiStyle` → the store's effect
  pushes `DeckOptions` into `controller.options` (`deck_customization_store.dart:125-132`). No
  singleton, no markdown round-trip.
- **G4 (vestigial disk errors):** removed.

## 6. Wiring (the real scope — old §4/§5/G5/G6)

The provider topology already exists in `main.dart:75-105`: shared `MemoryDeckLoader`,
`MemoryAssetCacheStore`, `DeckController`, `DeckCustomizationStore`, and — crucially — `AiStore`
already takes `customizationStore:` (`main.dart:104`). Keep those shared stores/controllers
app-scoped, but do **not** make `DeckToolsService` app-scoped because it owns route context.

1. **App-level providers:** `main.dart` continues to expose shared `MemoryDeckLoader`,
   `MemoryAssetCacheStore`, `DeckController`, `DeckCustomizationStore`, and editor/controller state.
   It does not provide `DeckToolsService`, `DeckToolsAdapter`, or `DeckEditViewModel`.
2. **Route-scoped edit stack:** inside `DeckEditScreen` / the AI edit route, create
   `DeckToolsService`, `DeckToolsAdapter`, and `DeckEditViewModel` from the shared providers:
   - `InMemoryDeckStore(loader: memoryDeckLoader, slidesProvider: () =>
     controller.slides.value.map((c) => c.slide).toList())`
   - `SlideConfigurationsProvider`: `() => controller.slides.value`
   - `SlideCaptureFn`: `(configuration) => slideCaptureService.capture(
     slide: configuration,
     context: routeContext,
     quality: SlideCaptureQuality.thumbnail,
     )`; it captures only the passed configuration and does not index into or reread
     `controller.slides.value`
   - style applier: `(DeckStyleType s) => customizationStore.applyFromAiStyle(s)`
   - a route-owned `BuildContextProvider` yielding a mounted edit-route context.
3. **Context lifetime:** `BuildContextProvider` is owned by the edit route and cleared/disposed with
   that route. A `readSlide` call after route disposal must fail with
   `DeckToolException.contextUnavailable`, which the adapter returns as
   `{ error: { code: 'context_unavailable', message } }`.
4. **Idle-gated closed-session guard:** the route/session controller owns the composite idle
   decision. `DeckToolsService` exposes only side-effect queue idle/pending/running state (slide
   mutations plus `updateStyle` style applications).
   `DeckToolsAdapter` exposes adapter active invocation count/idle state tracked with
   `try`/`finally`. `DeckEditViewModel.isThinking` (or the equivalent conversation busy state)
   exposes conversation activity. Apply/Discard controls are disabled while any of those three
   signals is busy. Active adapter invocations include `getDeck`, `readSlide`, and `updateStyle`, not
   only mutations. Apply/Discard may only start once the conversation, adapter invocation count, and
   side-effect queue are all idle. On Apply or Discard start, close the route-scoped `DeckToolsService`
   session before navigating away or exposing the editor again. No accepted in-flight mutation is
   canceled mid-side-effect in v1; the UI waits for route-derived composite idle before allowing the
   boundary action. The closed-session guard is checked at invocation start and immediately before
   every write, style apply, capture, or editor handoff side effect. Any late `getDeck`,
   `createSlide`, `updateSlide`, `deleteSlide`, `moveSlide`, `updateStyle`, or `readSlide` call after
   closure must return structured `context_unavailable` and must not mutate deck, style, or capture
   state.
5. **Base VM gating:** add an optional generic `Iterable<AiTool> additionalTools = const []` (or the
   exact GenUI tool base type) to `GenUiConversationViewModel`. `buildConversation()` passes
   `additionalTools: additionalTools.toList(growable: false)` to `GoogleGenerativeAiContentGenerator`.
   Default-empty keeps **wizard (`ChatViewModel`) and `RemixViewModel` tool-free** — satisfies FR1's
   "separate surface" without leaking deck-CRUD tools into the other conversations.
6. **New `DeckEditViewModel extends GenUiConversationViewModel`** (old G5) — uses
   `promptName: 'deck_edit_system'` (or the exact registry key matching
   `packages/playground/assets/ai_prompts/deck_edit_system.prompt`) and the route-scoped
   `DeckToolsAdapter`, passing `adapter.tools` into the base VM's generic `additionalTools`. This is
   the only surface that gets the deck-edit additional tools. Its prompt must describe index-based
   editing, the seven deck-edit additional tools, keyless `DeckToolSlide`, and `readSlide`
   screenshot+slide behavior, and must not include any Slide Keys guidance.
7. **Prompt readiness:** the AI edit route owns production prompt loading. During the entry-loading
   state, before creating or using `DeckEditViewModel.buildConversation()`, await
   `PromptRegistry.instance.load()` when `PromptRegistry.instance.isLoaded` is false. Conversation
   creation and all deck-edit tools remain disabled until the load succeeds. If loading fails, show
   route error UI and abort AI entry through the same non-notifying next-editor-mount handoff used for
   canonical barrier failure. Stage the freshest available canonical editor markdown (the canonical
   markdown returned by `writeCanonicalMarkdown(capturedSource)` when the barrier already succeeded,
   otherwise `capturedSource`), keep outbound editor writes suspended until the next editor mount
   consumes that staged handoff, replace back to `/`, and do not start a model conversation or
   deck-edit tool session from an unloaded prompt registry. Fix `PromptRegistry.load()` so failed asset
   loads do not poison future retries: clear `_loading` when `_loadInternal()` completes with an error
   (and keep `_loaded == false`), then cover re-entering `/ai/edit` after a failed prompt load.
8. **UX surface (G5):** a dedicated `/ai/edit` route in `MaterialApp.onGenerateRoute`, distinct from
   the wizard's `/ai/wizard` / `ai_generate_panel`. Entering from the editor uses exactly
   `Navigator.pushReplacementNamed('/ai/edit', arguments: capturedSource)` after synchronously
   capturing the latest editor source and enabling the `TextEditorController` outbound-write
   suspension guard. Do not rely on route replacement to dispose the outgoing `MaterialPageRoute`
   before the next async turn; the AI entry barrier may start only after the route verifies either
   `EditorPage` / `TextEditor` is disposed or editor loader writes are still suspended. Do not open
   AI edit as a side panel or overlay on top of the mounted Markdown editor. The route binds the live
   deck/preview, surfaces adapter error payloads to the user, and does not keep the text editor
   document in real-time sync. Apply and Discard replace back to the editor route with
   `Navigator.pushReplacementNamed('/')` after boundary work finishes.
   Browser/back/nav pop while AI edit is active must prompt Apply/Discard or route through the same
   boundary controller so the session close, canonical write/restore, customization handling, and
   one-shot editor handoff cannot be bypassed.
9. **Entry freshness, session baseline, and exit boundary:** when entering from the editor,
   synchronously read `TextEditorController.latestMarkdown` (or equivalent latest editor source)
   while `TextEditor` is still mounted, synchronously suspend outbound editor loader writes,
   immediately replace to `/ai/edit` with the captured source, and run the canonical
   write/observation barrier inside the AI route's entry-loading state with conversation creation,
   Apply/Discard, and all deck-edit tools disabled. Before starting the barrier, assert that the old
   editor is disposed or the suspension guard is still active so no editor write can reach the loader
   during the barrier. The barrier writes the captured source through
   `flushMarkdownToCanonical(capturedSource)` / `writeCanonicalMarkdown(capturedSource)` and waits
   until the live deck canonicalizes to the returned canonical markdown. Store that returned canonical
   markdown as the editor handoff source for any later prompt-load failure. If the barrier fails, abort
   AI entry: report the error, call
   `TextEditorController.stageMarkdownForNextEditorMount(capturedSource)` (or equivalent
   non-notifying mount-only handoff), keep outbound editor writes suspended until the next editor mount
   consumes that staged markdown, and `Navigator.pushReplacementNamed('/')` back to the editor. Do not
   call notifying `loadMarkdown(...)` while the outgoing editor route may still be mounted. Do not
   create `DeckEditViewModel`, call `buildConversation()`, or start a tool session from a stale or
   failed baseline. If prompt loading fails after the barrier succeeds, report the error, stage the
   returned canonical markdown with the same non-notifying next-editor-mount handoff, keep outbound
   editor writes suspended until the next editor mount consumes it, replace to `/`, and do not create
   `DeckEditViewModel` / start a tool session. If the latest editor markdown is unavailable because
   entry did not come from an editor route, observe that the already-live deck canonicalizes before
   capturing the baseline. After a successful barrier and prompt load, serialize the current live deck
   to `baselineCanonicalMarkdown` and capture
   `baselineCustomizationSnapshot` before any AI mutation. Leaving the route prompts **Apply**
   or **Discard**. The Apply/Discard controls remain disabled until the route/session controller
   observes derived composite idle from `DeckEditViewModel.isThinking` (or equivalent), adapter active
   invocation idle, and service side-effect queue idle; boundary work is then performed by the
   route/session controller, not by accepting late GenUI tool calls:
   - Apply serializes the current live deck to `finalCanonicalMarkdown`, calls
     `TextEditorController.loadMarkdown(finalCanonicalMarkdown)` once, and returns to the editor.
     Apply keeps the current AI-applied customization/style. The loader is already at final state from
     AI mutations; if the route performs an optional loader sync, it must use
     `writeCanonicalMarkdown(finalCanonicalMarkdown)` / the shared raw-markdown helper.
   - Discard restores `baselineCanonicalMarkdown` using
     `writeCanonicalMarkdown(baselineCanonicalMarkdown)` / the shared raw-markdown helper and waits
     until `slidesProvider` canonicalizes to the restored canonical markdown before returning to the
     editor. Then restore
     `baselineCustomizationSnapshot` so `DeckCustomizationStore` and `controller.options` return to
     pre-AI state. Finally call
     `TextEditorController.loadMarkdown(baselineCanonicalMarkdown)` once.
   - `TextEditor` must consume pending markdown with `takePendingMarkdown()` exactly once before
     emitting its default starter markdown. If pending markdown exists, it initializes from that
     markdown and does not emit starter content. Its mounted external-load listener must also consume
     pending markdown with `takePendingMarkdown()`, apply it, update `latestMarkdown`, and clear the
     pending state so it cannot replay on a later mount.

## 7. Concurrency policy — new **G7**

The Markdown editor also writes the shared `MemoryDeckLoader` directly (`text_editor.dart:65,120,125`),
but the AI edit surface must not run as a live overlay on that document. **v1 policy: separate route
with exclusive AI write ownership while active.** On entry from the editor, synchronously capture the
latest outbound editor markdown from `TextEditorController.latestMarkdown` (or equivalent) while
`TextEditor` is still mounted, synchronously suspend outbound editor writes to `MemoryDeckLoader`,
then immediately replace to `/ai/edit` with that captured source. The AI route, not the still-mounted
editor route, awaits the canonical write/observation barrier in an entry-loading state with
conversation creation and all deck-edit tools disabled, after verifying the old editor is disposed or
still write-suspended. Only after the barrier and prompt readiness succeed does it capture
`baselineCanonicalMarkdown` and
`baselineCustomizationSnapshot`; if the barrier fails, it hands the captured markdown back to the
editor once and replaces to `/` without starting an AI session. On entry from a non-editor source
where latest editor markdown is unavailable, it observes the already-live canonical deck before
capturing the baseline. During AI tool calls, the Markdown editor route is unmounted and
`TextEditorController` is not updated per mutation. On exit, prompt Apply or Discard, but keep those
controls disabled while `DeckEditViewModel.isThinking` (or equivalent conversation busy state) is
true, any adapter invocation is active, or the service side-effect queue is pending/running. Once the
route/session controller's derived composite idle state is idle, close the route-scoped tool session
before boundary state handoff. No accepted in-flight mutation is canceled mid-side-effect in v1. Apply
performs exactly one final canonical-markdown handoff back to the editor via one-shot
`loadMarkdown(...)` / `takePendingMarkdown()` and keeps current customization. Discard restores the
baseline markdown through the awaitable canonical write path, restores baseline customization, then
hands baseline markdown to the editor once via the same one-shot handoff. No merge/OT and no
optimistic-concurrency version stamp in v1 (note as future improvements).

## 8. Requirements

**Functional**
- FR1 — Expose exactly 7 deck-edit additional tools from `DeckToolsAdapter` through
  `additionalTools` on the dedicated `DeckEditViewModel` route: `getDeck`, `createSlide`,
  `updateSlide`, `deleteSlide`, `moveSlide`, `readSlide`, and `updateStyle`. This does not assert the
  total GenUI/model tool registry size because GenUI surface tools may also be registered.
- FR2 — Mutations flow `service → InMemoryDeckStore → SlideSerializer → MemoryDeckLoader →
  DeckController.slides`, reactively updating the live deck/preview, with `writeCanonical` awaiting
  and verifying the round-trip (Fix B). The Markdown text editor is not part of the per-tool update
  loop. `getDeck` and `readSlide` await the current service side-effect queue before reading live
  state, including queued/running `updateStyle`.
- FR3 — `readSlide` returns a base64 PNG via `SlideCaptureService` at **thumbnail** quality.
- FR4 — Tool results follow the exact v1 JSON contract in §4. Every returned `DeckSnapshot` is built
  from **post-write live** state and omits style.
- FR5 — `updateStyle` visibly changes the rendered preview via `applyFromAiStyle`.
- FR6 — AI editing is the concrete `/ai/edit` replacement route: per-tool writes do not call
  `TextEditorController`, and the Markdown-editor handoff happens only once at the route boundary
  after the user chooses Apply or Discard.
- FR7 — `TextEditor` initializes from pending markdown before emitting its default starter markdown,
  so Apply or Discard handoffs cannot be overwritten on route mount. Pending markdown is consumed and
  cleared exactly once. If `loadMarkdown(...)` fires while `TextEditor` is already mounted, the
  mounted listener also consumes via `takePendingMarkdown()`, applies the markdown, updates
  `latestMarkdown`, and clears pending state so it cannot replay later.
- FR8 — Route-scoped context is not reusable after the AI edit route is disposed; context-dependent
  tools fail with structured `context_unavailable` instead of reading a stale context. If context is
  missing, unmounted, or the session closes during an async `readSlide` capture, the result is
  `context_unavailable`; real render/capture failures remain `capture_failed`.
- FR9 — Discard restores both baseline markdown and baseline customization/style; Apply keeps the
  current AI-applied customization/style.
- FR10 — Apply/Discard controls are disabled while the conversation, any adapter invocation, or the
  serialized service side-effect queue is busy. The route/session controller derives this composite idle state
  from `DeckEditViewModel.isThinking` (or equivalent), `DeckToolsAdapter` active invocation idle, and
  `DeckToolsService` side-effect queue idle; `DeckToolsService` itself exposes only queue state. After
  the composite-idle boundary closes the session, late calls to any of the 7 deck-edit tools fail
  with structured `context_unavailable` before any deck, style, capture, or editor mutation.
- FR11 — AI route entry establishes a canonical freshness barrier before baseline capture without
  leaving the editor able to race the barrier: editor markdown is synchronously read from
  `TextEditorController.latestMarkdown` while `TextEditor` is mounted, outbound editor writes are
  synchronously suspended, `/ai/edit` immediately replaces the editor route, and the AI route's
  entry-loading state starts the flush only after verifying the editor is disposed or writes remain
  suspended. It flushes the captured source through the raw-markdown canonical helper. If that barrier
  fails, AI entry aborts back to `/` using the captured markdown via one-shot handoff and no
  stale/failed tool session starts.
- FR12 — `DeckEditViewModel.promptName` resolves to the `deck_edit_system` prompt asset, whose text
  describes the deck-edit tool contract and contains no slide-key guidance. The AI edit route awaits
  `PromptRegistry.instance.load()` if needed before creating/using `buildConversation()`; conversation
  creation is disabled until prompt loading succeeds.

**Non-functional**
- NFR1 — In-memory + web-safe (no `dart:io`). (Disk store was tried and removed in `0f330e19`; do
  not reintroduce.)
- NFR2 — Editor markdown stays clean (bare image refs, no theme); all slide writes go through
  `SlideSerializer`; style is applied out-of-band.
- NFR3 — Ack-validated args + typed results; tool params via `toJsonSchemaBuilder()`.
- NFR4 — `DeckToolsService` throws typed `DeckToolException`; `DeckToolsAdapter.invokeFunction`
  converts `DeckToolException` and Ack parse/validation errors to `{ error: { code, message } }`
  using exact snake_case `error.code` values: `context_unavailable`, `capture_failed`,
  `deck_write_failed`, `slide_index_out_of_range`, `invalid_argument`, and `validation_failed`.
  Adapter-level closed-session preflight runs before Ack parsing so closed sessions always return
  `context_unavailable`, even for malformed payloads.
- NFR5 — `DeckToolsService`, `DeckToolsAdapter`, and `DeckEditViewModel` are route-scoped to the AI
  edit route; app-level providers expose only the shared stores/controllers they depend on.
- NFR6 — Route-boundary entry/Apply/Discard raw-markdown loader writes use
  `writeCanonicalMarkdown` / `flushMarkdownToCanonical`, which shares the same awaitable canonical
  freshness rule as `writeCanonical`; no direct fire-and-forget `MemoryDeckLoader.updateMarkdown` at
  the boundary.
- NFR7 — Ack validates deck-edit index field types only; service/mutation helpers own range
  validation and map integer range failures to `slide_index_out_of_range`.

## 9. Acceptance criteria (per FR — executable)

- **createSlide:** `createSlide({slide, atIndex: 1})` on a 3-slide deck → `getDeck.totalSlides == 4`,
  new keyless slide at index 1, preview shows 4 slides, result is `{ index, slide, deck }`.
- **createSlide append default:** `createSlide({slide})` on a 3-slide deck resolves the omitted
  `atIndex` to `totalSlides`, appends the new keyless slide at index 3, preview shows 4 slides, and
  result is `{ index: 3, slide, deck }`.
- **createSlide invalid index:** `createSlide({slide, atIndex: totalSlides + 1})` and
  `createSlide({slide, atIndex: -1})` → structured `slide_index_out_of_range` error; service does
  not mutate the deck. There is no `slide_insert_index_invalid` code in v1.
- **updateSlide:** `updateSlide({index: 0, slide})` → slide 0 reflects new content in
  `controller.slides.value[0]`; total unchanged; result slide has no `key`.
- **Incoming key rejection:** `createSlide` / `updateSlide` with `slide.key` → structured
  `validation_failed` error from the adapter; service is not invoked and no mutation occurs.
- **Index validation:** non-integer or malformed `index`, `fromIndex`, `toIndex`, or `atIndex`
  payloads → structured `validation_failed` from the adapter. Integer range errors for
  `createSlide.atIndex`, `updateSlide.index`, `deleteSlide.index`, `moveSlide.fromIndex`,
  `moveSlide.toIndex`, and `readSlide.index` → structured `slide_index_out_of_range`; service does
  not mutate or capture. There is no `slide_insert_index_invalid` code in v1.
- **deleteSlide / moveSlide:** valid indices shift exactly; out-of-range integer indices → structured
  `slide_index_out_of_range` error, deck unchanged.
- **Read-after-write:** two `createSlide` calls back-to-back → `totalSlides == initial + 2` (proves
  Fix B; this fails against the old design) and
  `SlideSerializer().serialize(controller.slides.value.map((c) => c.slide).toList())` equals the
  canonical post-write state containing both new slides.
- **Read sequencing:** if `getDeck` or `readSlide` is invoked while a slide mutation or `updateStyle`
  is queued/running or still awaiting canonical/style propagation, the read waits for the service
  side-effect queue to idle before reading. `readSlide` revalidates `index` against the post-drain
  snapshot immediately before capture.
- **updateStyle:** changes `controller.options.value` (background/typography) — assert via
  `DeckCustomizationStore` state, not markdown; returned `deck` omits style.
- **readSlide:** returns non-empty base64; a slide containing an AI-generated image (written to
  `MemoryAssetCacheStore`) renders the image (proves G1); result is `{ index, title?, slide,
  thumbnailBase64, deck }`. The captured slide configuration, returned keyless slide, title, and
  returned deck are all built from the same immutable post-drain snapshot.
- **readSlide failures:** capture callback / `SlideCaptureService` render failure → structured
  `capture_failed` error; closed session or disposed/missing/unmounted edit-route context before or
  during async capture → structured `context_unavailable` error, including a route disposal that
  happens after capture starts but before it returns.
- **Editor isolation:** while the AI edit surface is active, tool mutations update the live
  deck/preview without calling `TextEditorController.loadMarkdown`; Apply calls it once with the final
  canonical markdown; Discard restores the original preview via the awaitable canonical write path,
  restores `DeckCustomizationStore` / `controller.options` from `baselineCustomizationSnapshot`, and
  calls `TextEditorController.loadMarkdown(baselineCanonicalMarkdown)` once.
- **AI route replacement:** `MaterialApp.onGenerateRoute` registers `/ai/edit`; entering AI edit
  from the editor calls `Navigator.pushReplacementNamed('/ai/edit', arguments: capturedSource)` after
  synchronous source capture and synchronous editor outbound-write suspension. Before the AI entry
  barrier awaits, assert either the `TextEditor` widget/state is unmounted or the suspension guard
  prevents all editor writes to `MemoryDeckLoader`. Apply and Discard return with
  `Navigator.pushReplacementNamed('/')` after boundary work. Browser/back/nav pop prompts
  Apply/Discard or routes through the same boundary controller.
- **DeckToolSlide fidelity:** keyless slide payloads preserve core `SlideOptions` args and widget
  args through service parse/serialize/readback without introducing or returning `key`.
- **Idle-gated boundary:** Apply/Discard buttons are disabled while a conversation response is
  processing, `readSlide` or any other adapter invocation is active, or a tool mutation is
  running/queued. The route/session controller derives this composite state from conversation busy,
  adapter active invocation idle, and service side-effect queue idle. After the composite busy state is
  idle, starting Apply/Discard closes the route-scoped tool session.
- **Boundary freshness:** Discard returns to the editor only after the preview has been observed at
  the restored canonical markdown via `writeCanonicalMarkdown` / the raw-markdown helper. Apply's
  optional loader sync, if used, also waits for canonical observation through the same helper.
- **Entry freshness:** entering AI edit from the editor synchronously captures
  `TextEditorController.latestMarkdown` while `TextEditor` is still mounted, suspends outbound editor
  writes, immediately replaces to `/ai/edit`, and only then awaits
  `writeCanonicalMarkdown(capturedSource)` / the raw-markdown canonical barrier in AI-entry loading UI
  with deck-edit tools and conversation creation disabled. The barrier starts only after verified
  disposal or continued write suspension. `baselineCanonicalMarkdown` is captured only after the live
  deck canonicalizes. If the barrier fails, the route reports the error, keeps the editor write
  suspension active, stages `capturedSource` with the non-notifying next-editor-mount handoff,
  replaces to `/`, and never starts an AI tool session from that failed baseline. The outgoing editor
  route, if still mounted during replacement, must not be notified and cannot consume the staged
  handoff; the next editor mount consumes it before starter markdown. Entering from a non-editor
  source observes the already-live canonical deck before baseline capture.
- **One-shot handoff:** Apply/Discard call `TextEditorController.loadMarkdown(...)`; the next
  `TextEditor` mount consumes it with `takePendingMarkdown()` exactly once. When pending markdown
  exists, `TextEditor` initializes from it and does not emit starter markdown; later mounts do not
  replay stale pending markdown. If `loadMarkdown(...)` notifies while `TextEditor` is mounted, the
  mounted listener consumes via `takePendingMarkdown()`, applies the markdown, updates
  `latestMarkdown`, clears pending state, and a later remount does not replay it. AI-entry abort uses
  a separate non-notifying next-editor-mount staged handoff that mounted listeners cannot consume.
- **Prompt readiness:** on a cold app where `PromptRegistry.instance.isLoaded == false`, `/ai/edit`
  awaits `PromptRegistry.instance.load()` before `DeckEditViewModel.buildConversation()` is created or
  used. While loading, conversation creation and deck-edit tools are disabled. If loading fails after
  the canonical entry barrier succeeded, the route reports the error, stages the returned canonical
  markdown with the non-notifying next-editor-mount handoff, keeps outbound editor writes suspended
  until the next editor mount consumes it, replaces to `/`, and does not start a conversation or tool
  session.
- **Late tool calls:** after Apply or Discard starts and closes the session, late `getDeck`,
  `createSlide`, `updateSlide`, `deleteSlide`, `moveSlide`, `updateStyle`, and `readSlide` calls
  return structured `context_unavailable` and do not mutate deck, style, capture, or editor state.
- **Post-closure precedence:** after closure, valid and malformed calls to all seven deck-edit
  additional tools return `context_unavailable`, not `validation_failed`, because adapter preflight
  checks the closed session before Ack parsing.
- **Late guard before side effects:** a tool accepted before closure but reaching a write, style
  apply, capture, or editor handoff side effect after closure re-checks the guard, returns
  `context_unavailable`, and does not perform the side effect.

## 10. Test plan

- **Recover** the 636-line `deck_tools_service_test.dart` from `3484ee51` as the unit baseline;
  delete the key/uniqueness tests and adapt mutation tests to index-based, keyless results.
- **Schema tests:** keyless deck-tool schemas reject incoming `key`; wizard `slideSchema` /
  `createSlideSchema` remain unchanged. Incoming `key` returns structured validation error from the
  adapter with code `validation_failed`; service is not invoked and no mutation occurs. Deck-edit
  index schemas validate integer type only: non-integer/malformed `index`, `fromIndex`, `toIndex`,
  or `atIndex` returns `validation_failed`, while integer range validation is left to service helpers.
- **Schema fidelity tests:** `DeckToolSlide` is based on the core SuperDeck slide model minus `key`;
  it round-trips slide option args (`title`, `style`, `template`, and arbitrary supported option
  args) and section/block/widget args, including arbitrary widget args, without dropping data.
- **Service tests:** `createSlide`, `updateSlide`, and `readSlide` return keyless slides preserving
  core `options`, `comments`, `sections`, section/block fields, and widget args; `DeckSnapshot` omits
  style. Include `createSlide({slide})` without `atIndex` and assert it appends at `totalSlides` and
  returns the appended index from post-write live state.
- **Index range tests:** negative and too-large integer indices for `createSlide.atIndex`,
  `updateSlide.index`, `deleteSlide.index`, `moveSlide.fromIndex`, `moveSlide.toIndex`, and
  `readSlide.index` return `slide_index_out_of_range`; service does not mutate or capture. Assert
  there is no `slide_insert_index_invalid` code in v1.
- **Integration test:** two back-to-back mutations against the real `InMemoryDeckStore` + live
  `DeckController` update `controller.slides` without clobbering. Drive `updateMarkdown`, await
  `writeCanonical`, and assert the canonical post-write serialized state after each op.
- **Read sequencing tests:** with a delayed `writeCanonical` / canonical observation fake and a
  delayed `updateStyle` propagation fake, invoke `getDeck` and `readSlide` while service side effects
  are pending and assert they wait for side-effect queue idle before reading. For `readSlide`, assert
  the index is revalidated after the drain and before capture, and use a delayed capture plus
  concurrent mutation/style update to assert the thumbnail target, returned keyless slide/title, and
  returned deck all come from the same immutable post-drain snapshot.
- **Raw markdown helper tests:** `writeCanonicalMarkdown` / `flushMarkdownToCanonical` parses raw
  markdown, serializes canonical markdown, arms the loader listener before writing, waits for the
  loader event, verifies live canonical observation, returns the observed canonical markdown, and maps
  timeout/disposed/cancel/mismatch to `deck_write_failed`.
- **Adapter tests:** `DeckToolsAdapter(service).tools` exposes 7 deck-edit tools including
  `readSlide`; `DeckEditViewModel` passes those 7 as `additionalTools`. Do not assert total GenUI
  tool registry size unless the implementation explicitly suppresses GenUI surface tools. Invalid
  args and thrown `DeckToolException` return `{ error: { code, message } }` with exact snake_case
  codes: `context_unavailable`, `capture_failed`, `deck_write_failed`, `slide_index_out_of_range`,
  `invalid_argument`, and `validation_failed`. After Apply/Discard closure, both valid and malformed
  calls to all seven deck-edit additional tools return `context_unavailable` before parsing, and no
  service side effect, capture, style read/write, or deck read/write occurs.
- **Route lifetime tests:** `DeckToolsService`, `DeckToolsAdapter`, and `DeckEditViewModel` are
  created inside the edit route, the route-owned `BuildContextProvider` is cleared on dispose, and
  all 7 deck-edit tool calls after route closure return structured `context_unavailable`.
  `MaterialApp.onGenerateRoute` includes `/ai/edit`; the concrete editor entry control in
  `customization_sidebar.dart` (or consolidated `editor_page.dart` toolbar) captures
  `latestMarkdown`, enables the outbound-write suspension guard, and calls
  `Navigator.pushReplacementNamed('/ai/edit', arguments: capturedSource)`. Before the canonical entry
  barrier awaits, assert `EditorPage` / `TextEditor` is disposed or the guard prevents all editor
  writes to `MemoryDeckLoader`. Apply/Discard replace back to `/`, and browser/back/nav pop is
  intercepted into the same Apply/Discard boundary path.
- **Mode tests:** AI mutations do not notify `TextEditorController`; Apply notifies once with the
  final canonical markdown; Discard restores baseline preview state and notifies once with
  `baselineCanonicalMarkdown`. Apply/Discard buttons are disabled while a conversation response is
  processing, `readSlide` is in flight, any adapter invocation is active, or a tool side effect is
  running/queued; after route/session-controller-derived composite idle, boundary action closes the
  session. Assert `DeckToolsAdapter` active invocation count/idle toggles with `try`/`finally` and
  that `DeckToolsService` queue state does not include adapter-only invocations. Boundary preview
  restoration is asserted only after canonical observation completes.
- **Editor handoff tests:** `TextEditorController.loadMarkdown(markdown)` creates pending markdown;
  `takePendingMarkdown()` returns and clears it exactly once. `TextEditor` init consumes pending
  markdown before creating starter content; when pending exists, starter markdown is not emitted and
  stale pending markdown is not replayed on a later mount. A mounted `TextEditor` receiving
  `loadMarkdown(...)` consumes via `takePendingMarkdown()`, applies the markdown, updates
  `latestMarkdown`, clears pending state, and a later remount does not replay that markdown.
  `TextEditorController.latestMarkdown` (or equivalent) is recorded on editor init and every
  `_onDocumentChanged` / `onChanged` path. When the AI-entry outbound-write suspension guard is set,
  `_onDocumentChanged` / `onChanged` updates `latestMarkdown` but does not call
  `MemoryDeckLoader.updateMarkdown`. A staged next-editor-mount handoff does not notify mounted
  listeners, cannot be consumed by an outgoing delayed-disposal editor route, and is consumed by the
  next editor init before starter markdown.
- **Entry freshness tests:** entering AI edit from the editor synchronously captures latest editor
  markdown while `TextEditor` is mounted, synchronously enables the outbound-write suspension guard,
  immediately replaces to `/ai/edit`, disables AI tools and conversation creation in entry-loading UI,
  then flushes the captured markdown through `writeCanonicalMarkdown` / the raw-markdown helper and
  waits for canonical observation before capturing `baselineCanonicalMarkdown`. Use a delayed/failing
  canonical barrier fake to prove no editor write can reach `MemoryDeckLoader` during the barrier,
  and that barrier failure reports the error, stages a non-notifying next-editor-mount handoff,
  replaces to `/`, and does not create/use `DeckEditViewModel.buildConversation()` or a deck-edit tool
  session. Run this with the outgoing `TextEditor` still mounted/subscribed during the failure and
  assert the returned editor initializes from `capturedSource`, not starter markdown. Non-editor entry
  captures baseline only after observing the already-live canonical deck.
- **Prompt tests:** `PromptRegistry` loads `deck_edit_system`; `DeckEditViewModel.promptName` uses the
  same key; prompt text contains no slide-key guidance and no instruction to create or preserve slide
  keys. A cold-app `/ai/edit` start with `PromptRegistry.instance.isLoaded == false` awaits
  `PromptRegistry.instance.load()` before `DeckEditViewModel.buildConversation()` is created/used,
  keeps conversation/tools disabled while loading, and on load failure reports the error, stages the
  canonical entry markdown for the next editor mount without notifying an outgoing editor listener,
  replaces to `/`, and starts no conversation or tool session. A failed asset load clears
  `PromptRegistry`'s in-flight `_loading` future while leaving `isLoaded == false`, so a later
  `/ai/edit` entry can retry loading prompts.
- **Style test:** `updateStyle` changes preview via `DeckCustomizationStore`, while snapshots omit
  style. `updateStyle` followed by Discard restores both markdown and
  `controller.options`/customization state from `baselineCustomizationSnapshot`.
- **Closed-session mutation tests:** after Discard, late `getDeck`, `createSlide`, `updateSlide`,
  `deleteSlide`, `moveSlide`, `updateStyle`, and `readSlide` cannot mutate deck/style and return
  structured `context_unavailable`. A guard checked immediately before side effects prevents a late
  mutation after closure.
- **Capture test:** `readSlide` resolves an AI image via the shared `MemoryAssetCacheStore`. An
  in-flight route disposal during async capture clears/unmounts context and returns structured
  `context_unavailable`, while a real capture/render exception returns `capture_failed`.
- Keep `melos run analyze` green and `flutter build web` succeeding (web-safety regression guard).

## 11. Phasing

1. **Store + service core (no UI):** recover code, drop keys (§5), implement Fix B, switch style to
   `applyFromAiStyle`, add `_readSlideTool`, cap capture. Land with the new integration tests. *No
   user-visible change yet — fully testable.*
2. **VM + route-scoped wiring:** base-VM generic `Iterable<AiTool> additionalTools` parameter,
   route-scoped `DeckToolsService`/`DeckToolsAdapter`/`DeckEditViewModel`, route-owned context cleanup,
   closed-session guard, prompt readiness before conversation creation, and customization
   snapshot/restore API. Keep `main.dart` limited to shared stores/controllers.
3. **UX route (G5):** the separate `/ai/edit` route + `Navigator.pushReplacementNamed` entry point +
   error surfacing + explicit Apply/Discard prompt for the Markdown editor boundary, including
   synchronous latest-markdown capture, AI-entry loading for canonical freshness, awaitable Discard
   restoration, and one-shot pending-markdown consumption in `TextEditor`.

## 12. Out of scope for v1 (tracked, not built)

- Explicit persisted frontmatter keys / stable cross-turn slide identity (we chose index-based).
- Optimistic-concurrency version stamp on `DeckSnapshot`.
- Undo / transactional rollback on partial failure (e.g. write succeeds, capture throws).
- Real merge/OT for simultaneous human+AI edits (v1 avoids simultaneous editing with a separate
  AI edit mode).
- Adversarial-content sanitization beyond the serializer's existing `@`-escaping.
