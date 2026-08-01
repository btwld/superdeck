# AI Deck Editing — Current-Architecture Implementation Plan (v3)

> **Verdict: Redesign.** The previous plan is not executable against the current
> codebase. It targets classes, routes, provider topology, and GenUI APIs that were
> removed or replaced. This plan keeps the useful product contract and rebuilds the
> implementation around the code on `origin/main`.
>
> Reviewed against `origin/main` at `042ae4ea`. This document supersedes the previous
> contents of `plan.md` and is the implementation successor to
> `.planning/tool_sub_system.md`.

## 1. Objective

Add a dedicated “edit this deck with AI” session to the playground. During the
session, the model can inspect and mutate the current editor document through seven
tools, update the deck-wide style, and capture a rendered slide for visual feedback.

Success means:

- The AI edits the exact Markdown document currently owned by
  `TextEditorController`.
- Every successful slide mutation updates both the Markdown editor and the live
  preview before the tool returns.
- The existing wizard and quick-generation flow remain behaviorally unchanged.
- The user can Apply the live AI edits or Discard them and restore the exact
  pre-session Markdown and customization state.
- The feature remains in-memory and web-safe.

Out of scope for v1:

- Persisted slide IDs or frontmatter keys.
- Simultaneous manual and AI editing.
- Deep-linking or restoring an in-progress AI edit session after browser refresh.
- Per-operation undo, merge/OT, or multi-user editing.
- Disk persistence.
- Changing the one-shot generation schemas or prompt flow.
- Refactoring the entire generic AI runtime out of its current `wizard` directory.

## 2. Why the previous plan must be replaced

The earlier plan made several claims that are no longer true on the target branch:

| Previous assumption | Verified current state | Consequence |
|---|---|---|
| The app uses `MaterialApp.onGenerateRoute` | `packages/playground/lib/main.dart` uses `MaterialApp.router` and `packages/playground/lib/app/router.dart` composes GoRouter feature routes | Add a GoRouter route; do not add `onGenerateRoute` |
| Tools must be threaded into a removed `GenUiConversationViewModel` | `AiConversationProfile` already accepts `List<dartantic.Tool>`, and `GenUiConversationSession` passes them through the transport to the Dartantic agent | Create a deck-edit profile and Dartantic tools; do not change the base view model just to support tools |
| The adapter should restore GenUI `DynamicAiTool` code | The current runtime uses `dartantic.Tool` and GenUI 0.9.2 | Historical adapter code is reference-only |
| The editor controller is app-scoped and needs a pending Markdown handoff | `TextEditorController` is created inside the `/` editor route and already owns `replaceMarkdown` | Replacing the editor route would dispose the document owner; push the AI route above it instead |
| `DeckCustomizationStore.applyFromAiStyle` exists | The current store explicitly documents that the AI-style entry point was omitted | Add a current-layer style adapter and snapshot/restore support |
| The deck-edit prompt and prompt retry fix must be added | `packages/playground/assets/ai_prompts/deck_edit_system.prompt` already exists, and `PromptRegistry.load()` already clears a failed in-flight load | Reuse and test them; do not reimplement them |
| The old 636-line service test can be restored as the baseline | Those tests target deleted GenUI, schema, store, and style APIs | Reuse only pure mutation cases; write tests against the current architecture |

The content-hash key finding remains correct:
`MarkdownParser` generates `Slide.key` from slide content, and `SlideSerializer`
does not persist it. Tool-facing slide identity therefore remains index-only.

## 3. Recommended design

### 3.1 Session shape

Add `/ai/edit` as a **pushed** route above the editor, following the existing
`/present/:index` pattern. Do not replace `/`.

The entry handler must:

1. Unfocus the Markdown editor.
2. Read the exact current source from a new read-only
   `TextEditorController.markdown` getter.
3. Capture a deep `DeckCustomizationSnapshot`.
4. Capture `EditorStore.activeSlideIndex`.
5. Push `/ai/edit` with a `DeckEditRouteArgs` object containing the still-live
   `TextEditorController`, `EditorStore`, and the baselines.

Because the editor route remains below the AI route, its route-scoped controller is
not disposed and cannot receive pointer or keyboard input. Direct navigation or a
browser refresh without valid route args redirects to `/`; an in-progress AI session
is intentionally not restorable.

### 3.2 Runtime flow

~~~text
DeckEditScreen
  ├─ AiConversationViewModel
  │    └─ AiConversationProfile.tools
  │         └─ List<dartantic.Tool>
  │              └─ DeckToolsAdapter
  │                   └─ DeckToolsService (one FIFO operation queue)
  │                        ├─ EditorDeckStore
  │                        │    └─ TextEditorController.replaceMarkdown
  │                        │         └─ MemoryDeckLoader
  │                        │              └─ DeckController.slides
  │                        ├─ DeckCustomizationStore
  │                        └─ SlideCaptureService using a live SlideConfiguration
  └─ Apply / Discard session boundary
~~~

Use the current generic conversation runtime as-is:

- `AiConversationProfile` carries the seven Dartantic tools.
- `AiConversationViewModel.isThinking` covers the complete transport request.
- `AiConversationViewModel.sendMessage` does not complete until conversation
  startup and the queued transport request complete.
- `SuperdeckA2uiTransport` awaits the Dartantic agent stream, including tool
  execution.
- `GenUiConversationSession` already loads the named prompt and enables tool-call
  instructions when a profile has tools.

Create a deck-edit catalog from the existing input-oriented catalog items, but
exclude the wizard-only `summaryCard`. That component resolves
`GenerateDeckCommand` from the widget tree and would be invalid on the AI edit
route. Give the reduced catalog its own ID and test that it cannot expose the
one-shot generation action.

The deck-edit screen must wrap each awaited `sendMessage` call in a route-owned
`requestInFlight` flag. This covers prompt/session startup, which `isThinking` does
not currently cover, as well as the later transport/tool phase. Gate input, Apply,
Discard, and back navigation on that one flag. Do not add adapter invocation
counters or a multi-source composite busy state unless a failing test proves the
awaited request lifetime does not cover tool execution.

### 3.3 Canonical document boundary

The Markdown editor—not `DeckController.slides`—is the source of truth.

Add a small pure `DeckMarkdownCodec` under
`packages/playground/lib/core/data/mappers/deck_markdown_codec.dart`:

- `decode(String markdown) -> List<Slide>` using the same
  `MarkdownParser` + `SectionParser` + `CommentParser` pipeline currently embedded
  in `MemoryDeckLoader`.
- `encode(List<Slide> slides) -> String` using `SlideSerializer`.

Refactor `MemoryDeckLoader` to use this codec without changing its observable
behavior. `EditorDeckStore` then uses the same codec to:

1. Read and decode `TextEditorController.markdown` at the start of each queued
   operation.
2. Encode the updated slides.
3. Call `TextEditorController.replaceMarkdown` synchronously.
4. Await a bounded reactive barrier until the live
   `DeckController.slides` serializes to the expected canonical Markdown.
5. Fail with `deck_write_failed` on timeout, loader/session error, disposal, or
   mismatch.

The barrier must observe the signal/event path; do not use an arbitrary fixed sleep.
The integration test with the real loader and controller defines this contract.

This design removes the old read-after-write bug without making the delayed
`DeckController.slides` value the next operation’s source. The next operation always
re-decodes the editor’s already-updated document.

### 3.4 Operation ordering and session lifetime

`DeckToolsService` owns one error-recovering FIFO queue for **all seven operations**,
including reads and capture. This is simpler and stronger than separate mutation,
read-drain, and adapter-busy mechanisms.

Invariants:

- Each operation resolves indices only after it reaches the front of the queue.
- No operation has an async gap between reading the current document and replacing
  it.
- A write does not complete until the preview barrier observes it.
- Mutation results and deck snapshots are rebuilt from the post-write editor
  document, not echoed from request payloads.
- `readSlide` captures and returns data from one immutable live-configuration
  snapshot.
- A route-scoped closed flag is checked when an operation enters the queue and
  immediately before write, style, or capture side effects.
- Closing is allowed only while the route-owned `requestInFlight` flag is false.
- The queue continues after an operation fails.

## 4. Tool contract

Expose exactly these seven tools through the deck-edit profile:

| Tool | Arguments | Result |
|---|---|---|
| `getDeck` | `{}` | `{ totalSlides, slides: [{ index, title? }] }` |
| `createSlide` | `{ slide, atIndex? }` | `{ index, slide, deck }` |
| `updateSlide` | `{ index, slide }` | `{ index, slide, deck }` |
| `deleteSlide` | `{ index }` | `deck` |
| `moveSlide` | `{ fromIndex, toIndex }` | `{ fromIndex, toIndex, deck }` |
| `readSlide` | `{ index }` | `{ index, title?, slide, thumbnailBase64, deck }` |
| `updateStyle` | `{ style }` | `{ style, deck }` |

Contract details:

- Indices are zero-based.
- Omitting `createSlide.atIndex` appends at the current slide count.
- A create insertion index is valid in `0..totalSlides`.
- Update, delete, read, `fromIndex`, and `toIndex` are valid in
  `0..<totalSlides`.
- `moveSlide.toIndex` is the final index after the move.
- `DeckSnapshot` never contains style or content-hash keys.
- `readSlide` uses `SlideCaptureQuality.thumbnail`.
- All result maps are JSON-encodable.

### 4.1 Keyless slide schema

Do not generate and maintain a second copy of the full SuperDeck slide model.

Define a strict tool-boundary schema from the current core schemas:

~~~dart
Ack.object({
  'options': slideOptionsSchema.optional(),
  'comments': Ack.list(Ack.string()).optional(),
  'sections': Ack.list(sectionBlockSchema),
});
~~~

This deliberately omits `key` and rejects it as an additional property. Reusing the
core schemas preserves:

- `SlideOptions.title`, `style`, `layout`, `template`, and arbitrary option args.
- Section alignment/flex fields.
- Content block fields.
- Widget names and arbitrary widget args.

At the boundary:

- Validate the keyless map.
- Add a private transient key only to construct a core `Slide`.
- Serialize results with `Slide.toMap()` and remove `key`.
- Never include a key in prompts, tool input, tool output, or snapshots.

Do not reuse the narrower quick-generation `slideSchema`, which omits current core
fields such as `layout`, `template`, and widget args.

### 4.2 Dartantic adapter and errors

Build each tool as `dartantic.Tool<Map<String, dynamic>>`. Pass the Ack-derived JSON
schema through `toJsonSchemaBuilder()` as `inputSchema`, but perform Ack parsing
inside `onCall` so validation failures can be returned with the stable tool error
shape.

Expected failures return:

~~~json
{
  "error": {
    "code": "validation_failed",
    "message": "..."
  }
}
~~~

Supported codes:

- `validation_failed` — malformed or schema-invalid arguments, including a supplied
  slide key.
- `slide_index_out_of_range` — an integer index is outside the live deck.
- `deck_parse_failed` — the current editor document cannot be decoded.
- `deck_write_failed` — the document/preview write barrier fails.
- `capture_failed` — rendering fails while the route and session remain valid.
- `context_unavailable` — the route context is gone or the tool session is closed.
- `internal_error` — sanitized fallback for an unexpected exception.

`DeckToolsService` throws typed internal exceptions. `DeckToolsAdapter` converts
every expected exception and `AckException` to the JSON error result; it must not
leak stack traces, API keys, or raw provider errors to the model.

## 5. Style and capture

### 5.1 Style

Keep AI schema types out of the core customization store.

Extend
`packages/playground/lib/core/domain/stores/deck_customization_store.dart` with:

- An immutable, deep `DeckCustomizationSnapshot`.
- A `copyWith` or equivalent immutable update operation.
- `captureSnapshot()`.
- `restoreSnapshot(snapshot)`, applying all fields and notifying once.

Add a feature-local style applier in the deck-editor feature. It parses the existing
`DeckStyleType`, transforms a captured snapshot, and restores the transformed
snapshot once:

- background -> deck background.
- heading color/font -> h1 through h6.
- body color/font -> paragraph.
- existing sizes and weights remain unchanged.

Use `parseHexColor` and reject an invalid color instead of silently applying its
fallback gray. Use `HeadlineFont.fontFamily` and `BodyFont.fontFamily` rather than
their enum IDs, so `playfairDisplay` becomes the actual Google Fonts family name
`Playfair Display`. Keep `playgroundFontFamilies` synchronized with the union of
the AI headline/body font families so an AI-applied font remains selectable and
visible in the manual customization UI.

`updateStyle` is queued with the other tools and returns the parsed style plus a
style-free deck snapshot.

### 5.2 Capture

`readSlide` must:

1. Reach the front of the service queue.
2. Await the editor/preview barrier.
3. Copy `DeckController.slides.value` into an unmodifiable local list.
4. Validate the index against that snapshot.
5. Capture exactly `snapshot[index]` with the mounted AI-route context.
6. Build title, keyless slide, and deck snapshot from that same list.
7. Return base64 PNG bytes.

The live `SlideConfiguration` already carries the shared asset cache from
`DeckController`, so AI-generated bare image keys resolve during capture. Do not
restore the historical throwaway configuration builder.

## 6. Session behavior

### Entry

- Add an explicit “Edit with AI” control in
  `packages/playground/lib/features/editor/presentation/widgets/customization_sidebar.dart`.
- Capture the exact raw Markdown and customization snapshot before navigation.
- Use `context.push('/ai/edit', extra: routeArgs)`, never
  `pushReplacementNamed` or a replacement route.
- Keep chat input and tools disabled until the current document decodes and the live
  preview matches its canonical structure.
- If entry validation fails, show the error in the AI screen and allow retry or Back;
  do not mutate the editor.

### Active session

- Create `EditorDeckStore`, `DeckToolsService`, `DeckToolsAdapter`, profile, and
  `AiConversationViewModel` inside the AI route.
- Use a dedicated catalog containing only safe question/input components; exclude
  the wizard `summaryCard` and its `GenerateDeckCommand` dependency.
- Reuse the existing generic chat input/surface widgets.
- Update `deck_edit_system.prompt` only if needed to clarify that deck mutations use
  the seven tools and UI surfaces are optional; keep its existing keyless contract.
- Mark the session dirty immediately when a document or style side effect occurs,
  before awaiting its observation barrier. A write that applies but times out must
  still require Apply or Discard.

### Apply

- Enabled only while `requestInFlight` is false.
- Close the tool service, dispose the route-owned conversation through its normal
  widget lifecycle, and pop to the still-mounted editor.
- Do not rewrite or hand off Markdown: successful tools already updated the live
  editor document.
- Restore the entry active-slide index, clamped to the post-edit slide count, so
  full-document replacement does not always return the author to slide 0.

### Discard

- Enabled only while `requestInFlight` is false.
- Stop admitting new tools.
- Restore the exact raw baseline through `TextEditorController.replaceMarkdown`.
- Await the same preview barrier.
- Restore `DeckCustomizationSnapshot`.
- Restore the exact entry active-slide index after the baseline deck is live.
- Pop only after all restores succeed.
- If restoration fails, remain on the AI route and present Retry / Keep Changes;
  never navigate away with an unknown partial restore.

### Back, refresh, and invalid entry

- Use `PopScope` so back navigation prompts Apply or Discard when dirty.
- While `requestInFlight` is true, block new submissions, Apply, Discard, and pop.
- A direct `/ai/edit` navigation or browser refresh without live
  `DeckEditRouteArgs` redirects to `/`.
- This route is an ephemeral editing session, not a bookmarkable document route.

## 7. File map

### Existing files to change

- `packages/playground/lib/core/data/data_sources/memory_deck_loader.dart` — use the
  shared codec.
- `packages/playground/lib/features/editor/utils/text_editor_controller.dart` —
  expose current Markdown read-only.
- `packages/playground/lib/core/domain/stores/deck_customization_store.dart` —
  snapshot/restore.
- `packages/playground/lib/features/editor/presentation/widgets/customization_sidebar.dart`
  — entry control.
- `packages/playground/lib/app/router.dart` — compose deck-editor routes.
- `packages/playground/assets/ai_prompts/deck_edit_system.prompt` — only small
  wording corrections if profile integration proves they are needed.

### New files

Use the repository’s feature/domain organization; exact private helper placement may
be adjusted during implementation without changing these boundaries.

- `packages/playground/lib/core/data/mappers/deck_markdown_codec.dart`.
- `packages/playground/lib/features/ai/deck_editor/domain/deck_store.dart`.
- `packages/playground/lib/features/ai/deck_editor/data/editor_deck_store.dart`.
- `packages/playground/lib/features/ai/deck_editor/domain/deck_tool_error.dart`.
- `packages/playground/lib/features/ai/deck_editor/domain/deck_tools_service.dart`.
- `packages/playground/lib/features/ai/deck_editor/ai/deck_tool_schemas.dart`.
- `packages/playground/lib/features/ai/deck_editor/ai/deck_tools_adapter.dart`.
- `packages/playground/lib/features/ai/deck_editor/ai/deck_edit_catalog.dart`.
- `packages/playground/lib/features/ai/deck_editor/ai/deck_edit_conversation_profile.dart`.
- `packages/playground/lib/features/ai/deck_editor/presentation/deck_edit_screen.dart`.
- `packages/playground/lib/features/ai/deck_editor/routes/routes.dart`.

No new Ack-generated `.g.dart` file is planned. The tool boundary uses direct Ack
schemas and core domain models.

## 8. Executable work breakdown

### Task 1 — Establish the document seam test-first

Dependencies: none.

1. Add failing tests for decoding, encoding, parse errors, and structural
   round-tripping in
   `packages/playground/test/core/data/mappers/deck_markdown_codec_test.dart`.
2. Implement `DeckMarkdownCodec`.
3. Refactor `MemoryDeckLoader` to use it.
4. Add `TextEditorController.markdown` and tests proving initial, typed, and
   `replaceMarkdown` content are reported exactly.

Acceptance:

- Existing editor/preview behavior is unchanged.
- Codec output matches `SlideSerializer`.
- Invalid Markdown has a typed, testable failure.
- The controller getter always reflects the actual document.

Verification:

~~~bash
cd packages/playground
fvm flutter test \
  test/core/data/mappers/deck_markdown_codec_test.dart \
  test/features/editor
~~~

### Task 2 — Implement keyless contracts, store, and queued slide operations

Dependencies: Task 1.

Write failing tests first for the contract and each mutation, then add:

- Strict Ack request schemas built from core slide/section schemas.
- Keyless JSON conversion helpers.
- Typed deck-tool errors.
- Pure index validation and mutation helpers.
- `EditorDeckStore` read/write/restore and reactive preview barrier.
- One FIFO service queue covering `getDeck`, create, update, delete, and move.

Required regression cases:

- Incoming `slide.key` is rejected.
- Create without `atIndex` appends.
- Every invalid integer range maps to `slide_index_out_of_range`.
- Two immediate creates retain both slides.
- A failed queued operation does not poison the next operation.
- A real `MemoryDeckLoader` + `DeckController` observes each write before it
  completes.
- Arbitrary slide option and widget args survive read-mutate-write.

Checkpoint: all non-style, non-capture service tests pass before adapter or UI work.

### Task 3 — Adapt the tools to the current AI runtime

Dependencies: Task 2.

1. Build seven `dartantic.Tool<Map<String, dynamic>>` objects.
2. Convert Ack and service failures to structured error maps.
3. Add a deck-edit catalog that excludes the wizard-only `summaryCard`.
4. Add `deckEditConversationProfile` with that catalog,
   `promptName: 'deck_edit_system'`, and only the seven deck-edit tools.
5. Test that `GenUiConversationSession` forwards those tools to the injected agent
   client while the existing wizard profile forwards none.
6. Test the already-present prompt asset through `PromptRegistry`.

Acceptance:

- Exactly seven deck-edit tools are registered.
- The wizard remains tool-free.
- The deck-edit catalog cannot render the wizard generation action.
- Tool schemas convert successfully and reach the injected Dartantic client.
- No removed `DynamicAiTool` or `GoogleGenerativeAiContentGenerator` API returns.

### Task 4 — Add style, capture, and session restoration

Dependencies: Tasks 2–3.

1. Add failing snapshot/restore tests to
   `packages/playground/test/core/deck_customization_store_test.dart`.
2. Implement deep snapshot/restore with one notification.
3. Add the feature-local AI-style mapper and `updateStyle`.
4. Add `readSlide` using a live immutable `SlideConfiguration` snapshot and an
   injectable capture callback.
5. Add tests for shared asset-cache identity, thumbnail quality, base64 output,
   context disposal, capture failures, and discard restoration.

Acceptance:

- `updateStyle` changes live `DeckController.options` and Discard restores it.
- Invalid style colors are rejected, and enum font IDs map to their declared
  `fontFamily` values.
- Every AI-selectable font appears in `playgroundFontFamilies`.
- `readSlide` targets and describes the same live slide.
- Route disposal maps to `context_unavailable`; real render errors map to
  `capture_failed`.

Checkpoint: all seven tools pass service and adapter tests without UI.

### Task 5 — Build the pushed AI-edit route and UX

Dependencies: Tasks 1–4.

1. Add `DeckEditRouteArgs` and `/ai/edit`.
2. Add the editor entry control with synchronous baseline capture and unfocus.
3. Build the route-scoped service/profile/view-model stack.
4. Reuse the existing chat input/surface widgets in a dedicated deck-edit screen.
5. Implement entry readiness, dirty state, Apply, Discard, error UI, and
   `PopScope` behavior. Wrap the awaited `sendMessage` future so request startup,
   tool execution, and response streaming share one route-boundary busy flag.
6. Redirect missing/invalid route args to `/`.

Widget tests must prove:

- `context.push` keeps the same `TextEditorController` alive beneath the route.
- Tools/chat are disabled until entry readiness succeeds.
- Apply returns with the AI-authored Markdown.
- Discard returns with byte-for-byte baseline Markdown and baseline customization.
- Apply and Discard restore the author’s entry slide position (clamped after Apply).
- Back cannot bypass the decision, and no exit is possible while a request is in
  flight, including prompt/session startup.
- The wizard still mounts and behaves as before.

### Task 6 — Integration, cleanup, and documentation

Dependencies: Task 5.

1. Run an end-to-end widget test: open editor -> enter AI edit -> run two mutations
   -> read/capture -> Apply -> verify editor and preview.
2. Add the equivalent Discard path.
3. Update `.planning/tool_sub_system.md` to point to the implemented architecture
   and remove claims about the deleted adapter/runtime.
4. Do not restore historical files wholesale. Use
   `git show 3484ee51:<path>` only to compare pure mutation semantics.
5. Run full analysis, tests, and web build.

## 9. Acceptance criteria

The feature is complete only when all are true:

- The dedicated profile exposes exactly the seven contract tools; the wizard exposes
  none.
- All tool arguments are Ack-validated and provider-facing schemas build.
- Keys are absent from every deck-edit input, result, snapshot, and prompt.
- Create/update/delete/move change the editor document and preview before returning.
- Every mutation result describes the post-write editor document.
- Two back-to-back mutations cannot clobber one another.
- `getDeck` and `readSlide` cannot observe a partial queued operation.
- Full core-supported slide fields and arbitrary args survive a tool round-trip.
- `readSlide` returns a non-empty base64 PNG from the same live configuration it
  describes.
- `updateStyle` visibly changes the preview.
- Apply preserves AI changes without a second Markdown handoff.
- Discard restores exact baseline Markdown and complete customization state.
- Closed/unmounted sessions cannot mutate, style, or capture.
- Invalid direct route entry safely returns to the editor.
- Existing wizard and quick-generation tests remain green.
- The playground builds for web with no `dart:io` dependency.
- A manual Gemini smoke test can call `getDeck`, mutate one slide, and call
  `readSlide` without schema rejection or an unstructured tool error.

## 10. Verification commands

Focused during implementation:

~~~bash
cd packages/playground
fvm flutter test test/features/ai/deck_editor
fvm flutter test test/features/editor
fvm flutter test test/core/deck_customization_store_test.dart
~~~

Repository gates before completion:

~~~bash
melos run analyze
melos run test
cd packages/playground
fvm flutter build web
~~~

Run `melos run build_runner:build` only if implementation introduces generated
annotations despite this plan’s direct-schema recommendation; if it does, generated
files must be committed with their sources.

## 11. Compatibility, rollout, and rollback

Compatibility:

- Additive playground feature; no public package API or stored data migration.
- Existing wizard and quick generator stay unchanged.
- First successful slide mutation canonicalizes the whole Markdown document through
  `SlideSerializer`. Apply keeps that canonical formatting; Discard restores the
  exact original source.

Rollout:

- Land Tasks 1–2 as a behavior-neutral codec seam plus tested core.
- Land Tasks 3–4 with the feature still unreachable.
- Expose the entry control only with Task 5.
- No feature flag is required for the playground, but keeping the entry control as
  the final change provides a clean rollout boundary.

Rollback:

- Remove the route and entry control to make the feature unreachable.
- Remove the deck-editor feature directory.
- Keep the shared codec refactor if its parity tests remain green.
- No persisted state or data conversion needs reversal.

## 12. Risks and stop conditions

- **GoRouter route lifetime:** if a widget test shows `context.push` does not retain
  the route-scoped editor controller on any supported platform, stop. Move the
  document owner to an app-scoped store; do not revive pending handoff flags.
- **Provider schema limits:** if the Google/Dartantic provider rejects core schemas
  with arbitrary properties, stop and explicitly choose either a finite v1 widget
  arg schema or a Markdown-per-slide contract. Do not silently drop fields.
- **Preview observation:** if the real integration test cannot deterministically
  observe the written revision, add a monotonically increasing revision to the
  in-memory loader event/store contract. Do not replace the barrier with sleeps.
- **Discard failure:** never pop after a partial restore. Keep the route open and
  offer retry or keep-changes.
- **Capture payload:** if thumbnail base64 exceeds provider limits in a real tool
  call, reduce capture dimensions/quality or introduce an asset reference; do not
  remove visual verification without an explicit product decision.
- **Scope pressure:** do not mix the generic AI-runtime directory refactor into this
  feature. That cleanup can follow once both wizard and deck editor exercise the
  shared APIs.
