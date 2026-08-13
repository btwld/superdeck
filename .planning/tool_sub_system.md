# AI Deck Editing — Implemented Architecture

> **Status:** Implemented in the playground. This document describes the live
> architecture and is the single owner of that description.

## Purpose

The playground has a dedicated, ephemeral “Edit deck with AI” session. It is
separate from the one-shot generation wizard. During the session, the model can
inspect and mutate the exact Markdown document owned by `TextEditorController`,
apply deck-wide customization, and capture a rendered slide for visual feedback.

The feature is in-memory and web-safe. It does not persist a chat session, slide
IDs, or document state across refreshes.

## Runtime architecture

```text
/ editor route (remains mounted)
  └─ TextEditorController — canonical Markdown document
       └─ MemoryDeckLoader → DeckController.slides → live preview

/ai/edit pushed route
  └─ DeckEditSessionController
       ├─ EditorDeckStore
       │    ├─ DeckMarkdownCodec
       │    ├─ TextEditorController.replaceMarkdown
       │    └─ reactive DeckController preview barrier
       ├─ DeckToolsService — one error-recovering FIFO queue
       │    ├─ five slide operations
       │    ├─ DeckStyleApplier
       │    └─ DeckSlideReader
       ├─ DeckToolsAdapter — seven dartantic.Tool objects
       └─ AiConversationViewModel
            └─ GenUiConversationSession → SuperdeckA2uiTransport
```

`AiConversationProfile.tools` is the only tool wiring seam. The deck-edit
profile carries seven Dartantic tools; the wizard profile carries none. The
shared session and transport forward the profile tools to the injected
Dartantic agent client.

## Canonical document boundary

The editor Markdown is the source of truth. `DeckController.slides` is the
rendered observation of that document, not the input to the next mutation.

`DeckMarkdownCodec` owns the shared conversion pipeline:

- Decode: `MarkdownParser` + `SectionParser` + `CommentParser`.
- Encode: `SlideSerializer`.

Every queued mutation:

1. Decodes `TextEditorController.markdown` when it reaches the queue front.
2. Resolves and validates indices against that live document.
3. Replaces the editor document synchronously with canonical Markdown.
4. Waits on the reactive `DeckController` signal path until the preview
   serializes to the same canonical Markdown.
5. Builds its result from the observed post-write document.

The barrier has a bounded timeout and reports `deck_write_failed`; it does not
use fixed sleeps. A failed queue item is isolated so later items still run.

## Tool contract

The profile exposes exactly these zero-based tools:

| Tool | Arguments | Result |
|---|---|---|
| `getDeck` | `{}` | `{ totalSlides, slides: [{ index, title? }] }` |
| `createSlide` | `{ slide, atIndex? }` | `{ index, slide, deck }` |
| `updateSlide` | `{ index, slide }` | `{ index, slide, deck }` |
| `deleteSlide` | `{ index }` | `deck` |
| `moveSlide` | `{ fromIndex, toIndex }` | `{ fromIndex, toIndex, deck }` |
| `readSlide` | `{ index }` | `{ index, title?, slide, thumbnailBase64, deck }` |
| `updateStyle` | `{ style }` | `{ style, deck }` |

All seven operations use one FIFO queue, including reads, style, and capture.
`moveSlide.toIndex` is the final index. Omitting `createSlide.atIndex` appends.

## Keyless slide boundary

The model-facing slide schema is a strict Ack object composed from the current
core schemas:

```dart
Ack.object({
  'options': slideOptionsSchema.optional(),
  'comments': Ack.list(Ack.string()).optional(),
  'sections': Ack.list(sectionBlockSchema),
}, additionalProperties: false)
```

It deliberately rejects `key`. A private transient key exists only long enough
to construct a core `Slide`. Tool results remove the runtime key again. The
contract retains full core options, section fields, content blocks, widget
names, and arbitrary widget arguments.

The Ack schemas are converted with `toJsonSchemaBuilder()` for provider-facing
tool definitions and parsed again inside `onCall`, allowing validation failures
to use the stable tool error shape.

## Errors

Expected failures return:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "..."
  }
}
```

Supported codes are `validation_failed`, `slide_index_out_of_range`,
`deck_parse_failed`, `deck_write_failed`, `capture_failed`,
`context_unavailable`, and `internal_error`. Unexpected exceptions are reduced
to a generic message so raw provider errors, stack traces, and secrets do not
reach the model.

## Style and capture

`DeckCustomizationStore` owns a deep immutable
`DeckCustomizationSnapshot`. Restoring it applies every background and text
field, pushes one `DeckOptions` value, and notifies once.

`DeckStyleApplier` is feature-local. It parses the existing `DeckStyleType`,
validates all hex colors, applies heading values to h1–h6 and body values to
paragraph text, and preserves sizes and weights. It uses the declared Google
Fonts family names rather than enum IDs. The manual font picker contains every
AI-selectable headline and body family.

`DeckSlideReader` copies the live `SlideConfiguration` list once, selects and
describes the same item from that immutable snapshot, and captures it with
`SlideCaptureQuality.thumbnail`. Because it uses the live configuration, the
shared asset cache remains attached. Capture is injectable for deterministic
tests; production uses `SlideCaptureService.capture`.

## Session boundary

The editor toolbar captures, synchronously before navigation:

- Exact raw Markdown.
- Deep customization snapshot.
- Active slide index.
- Live `TextEditorController` and `EditorStore` references.

It then pushes `/ai/edit`; the editor route and controller remain mounted
beneath it. Missing route args (including browser refresh/direct navigation)
redirect to `/`.

The route disables chat and exit actions until entry synchronization succeeds.
Its own `requestInFlight` flag wraps the entire awaited `sendMessage` future, so
prompt loading, session startup, transport streaming, and tool execution share
one busy boundary.

- **Apply:** closes tool admission, keeps the already-live edits, restores the
  entry slide index clamped to the edited deck, and pops.
- **Discard:** closes tool admission, restores exact raw Markdown through the
  same preview barrier, restores customization and the exact entry index, then
  pops.
- **Restore failure:** remains on the route with Retry / Keep Changes.
- **Back:** uses `PopScope`; dirty sessions must choose Apply or Discard, and no
  pop is admitted while a request is in flight.

## Key implementation files

- `core/data/mappers/deck_markdown_codec.dart`
- `features/ai/deck_editor/domain/deck_tools_service.dart`
- `features/ai/deck_editor/data/editor_deck_store.dart`
- `features/ai/deck_editor/ai/deck_tool_schemas.dart`
- `features/ai/deck_editor/ai/deck_tools_adapter.dart`
- `features/ai/deck_editor/ai/deck_style_applier.dart`
- `features/ai/deck_editor/data/deck_slide_reader.dart`
- `features/ai/deck_editor/presentation/deck_edit_session_controller.dart`
- `features/ai/deck_editor/presentation/deck_edit_screen.dart`
- `features/ai/deck_editor/routes/routes.dart`

## Verification coverage

The test suite covers codec parity and typed parse errors, exact editor reads,
strict keyless schemas, all index boundaries, queue ordering/recovery, real
loader/controller write observation, arbitrary args, all adapter errors,
profile tool forwarding, prompt loading, deep style restoration, live capture
identity/quality/errors, pushed route lifetime, readiness, Apply/Discard,
active-index restoration, dirty Back, full-request busy gating, invalid route
entry, wizard regression, and end-to-end Apply and Discard paths after two
mutations and capture.
