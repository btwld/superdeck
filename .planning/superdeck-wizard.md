# SuperDeck Wizard — Feature Spec

Status: **Draft / pre-implementation**
Branch: `feat/superdeck-wizard`
Target package: `packages/playground_refactor`
Source of truth for behavior: `packages/playground` (old, to be superseded)

---

## 1. What "the wizard" is

The **wizard** is an **AI-driven conversational flow** that interviews the user to
gather everything needed to generate a presentation, then hands the collected
answers to the existing deck-generation pipeline.

Instead of a single free-text box ("describe your presentation"), the model asks
one focused question at a time and renders an **interactive UI surface** for each
answer (radio, checkbox, slider, text field, visual style picker, image-style
picker). As answers accumulate they build up a typed **`WizardContext`**. When the
model has enough, it renders a **summary card**; confirming it triggers generation.

It is a **GenUI** experience: the model does not just emit text — it drives the UI
by choosing which catalog component to render next (server-driven UI over the
`genui` + `dartantic_ai` stack).

### Why it exists
- Lowers the blank-page problem — users answer simple prompts rather than authoring
  one dense description.
- Produces a richer, structured context (audience, approach, emphasis, slide count,
  visual style, fonts, image style) than free text, improving generation quality.
- Lets the model adapt follow-up questions to earlier answers.

---

## 2. End-to-end UX flow

```
Entry (button in editor)
      │
      ▼
Chat screen ── AI greets, asks Q1 ──► renders a catalog surface
      │                                    (e.g. ask_user_radio "Who's the audience?")
      │  user selects / types
      ▼
UserActionEvent ──► sent back to model ──► AI asks next Q ──► next surface
      │  (topic → audience → approach → emphasis → slide count → visual style)
      ▼
AI renders SummaryCard (recap of all selections) with a "Generate" action
      │  user confirms
      ▼
Extract WizardContext from summary items ──► build prompt string
      │
      ▼
Deck generation pipeline (outline → deck → finalize)  [ALREADY EXISTS in refactor]
      │
      ▼
Markdown loaded into editor / preview  ──►  progress UI dismisses
```

Key behavioral notes carried over from old playground:
- The chat catalog itself has **no tools**; the model steers purely by choosing
  which surface to render. Generation is triggered by the **summary card's
  action**, not by a model tool call.
- The system prompt is `wizard_system` (asset already present in refactor at
  `assets/ai_prompts/wizard_system.prompt`).
- Generation is **fire-and-forget** from the summary card: kick off the command,
  show progress, dismiss on completion (success or error).

---

## 3. Reference architecture (old `playground`)

Located under `packages/playground/lib/features/ai/`. Relevant pieces:

| Concern | File(s) |
|---|---|
| Conversation state (signals ViewModel) | `core/ai/services/ai_conversation_viewmodel.dart` |
| GenUI session lifecycle (start/bind/queue) | `core/ai/services/genui_conversation_session.dart` |
| a2ui transport (dartantic ↔ genui) | `core/ai/services/superdeck_a2ui_transport.dart`, `superdeck_agent_client.dart` |
| Conversation profile (catalog + prompt + tools) | `core/ai/services/ai_conversation_profile.dart`, `chat/chat_conversation_profile.dart` |
| Catalog of question surfaces | `core/ai/catalog/*` (`ask_user_radio/checkbox/slider/text/style/image_style`, `summary_card`) |
| Typed wizard context | `core/ai/wizard_context.dart`, `core/ai/schemas/wizard_context_keys.dart` |
| Prompt → generation bridge | `core/ai/services/prompt_builder.dart`, `summary_card.dart` (`generateSlides`) |
| Chat UI | `chat/view/chat_screen.dart` + `chat/view/widgets/*` |
| Progress screen | `ai_progress_screen.dart` |
| Generation pipeline | `core/ai/services/deck_generator_*` (**already ported to refactor**) |

State management there uses a **signals `AiConversationViewModel`** and a global
`AiStore`.

---

## 4. Target architecture (refactor — "adapt to refactor patterns")

The refactor uses **Provider + Command pattern + ChangeNotifier stores** (see
`GenerateDeckCommand`, `EditorStore`, `AppProviders`). The wizard is rebuilt to
match, rather than copying the signals ViewModel.

### 4.1 Already in place (reuse as-is)
- Generation engine: `deck_generator_service`, `deck_generator_pipeline`,
  `deck_generator_workflow`, schemas, `prompt_registry`, `font_styles`,
  `generation_progress`, `error_classifier`, `retry_policy`.
- `GenerateDeckCommand` — already loads generated markdown into the editor.
- `env_config`, `gemini_models`, `paths`, `debug_logger`.
- Prompt assets incl. `wizard_system.prompt`.
- Deps: `genui`, `dartantic_ai`, `googleai_dart`, `ack*`.

### 4.2 To build (adapted)
| Layer | New artifact | Adapted from |
|---|---|---|
| Domain model | `WizardContext` + `WizardContextKeys` | port ~verbatim (pure Dart) |
| Catalog | `chat_catalog` + `ask_user_*` + `summary_card` surfaces (**no** `ask_user_image_style`) | port; swap store lookups |
| Session | `GenUiConversationSession` + a2ui transport + agent client | port (framework glue, low churn) |
| Profile | `AiConversationProfile` + `wizardConversationProfile()` | port |
| **State** | **`WizardStore` (ChangeNotifier)** replacing `AiConversationViewModel` (signals) | **rewrite** to Provider/ChangeNotifier |
| Prompt bridge | `prompt_builder` (WizardContext → prompt string) | port |
| Command | reuse/extend **`GenerateDeckCommand`** as the generation entry point | existing |
| UI | wizard chat screen + input + surface host + progress | port, restyle to refactor UI kit |
| Wiring | Provider scope for wizard, route/entry button in editor | new, follow `AppProviders`/router |

### 4.3 Key adaptation decisions
1. **Signals → ChangeNotifier.** `AiConversationViewModel` (signals) becomes
   `WizardStore extends ChangeNotifier`, exposed via `Provider`/`ChangeNotifierProvider`
   scoped to the wizard route, mirroring `EditorStore`. `GenUiConversationSession`
   internals stay stream-based (they already are) — only the outward state surface
   changes.
2. **Generation goes through `GenerateDeckCommand`.** The summary card's confirm
   builds a prompt from `WizardContext` and invokes the existing command, instead
   of the old global `AiStore.generate`. Any extra inputs the command doesn't yet
   accept (e.g. `imageStyleId`, `backgroundColor`) are added to the command
   signature — see open questions.
3. **Progress UI reuses the command's `phase`/running state** (already surfaced by
   `GenerateDeckCommand`) rather than a separate `AiStore`.
4. **Catalog surfaces read the wizard store via `context.read`/Provider**, not the
   old `prov.Provider.of<AiStore>`.

---

## 5. Scope

### In scope
- Conversational GenUI wizard end-to-end: entry → interview → summary → generate →
  editor.
- The full `ask_user_*` catalog + summary card.
- WizardContext accumulation and prompt building.
- Progress + error surfacing during generation.

### Out of scope (for this feature)
- **Deck editing tools** (`deck_tools_*`, `deck_edit_*`) — that's the separate
  "edit existing deck via AI" flow, not the creation wizard.
- **Image generation** (`image_generator_service`, `gemini_image_options`,
  `ask_user_image_style`). Dropped for v1 — decision #1.
- Persisting/resuming a wizard session across app restarts.

---

## 6. Decisions

Resolved:
1. **Image styles → OUT for v1.** Ship the wizard **text/style-only**. Do **not**
   port image generation (`image_generator_service`, `gemini_image_options`) or the
   `ask_user_image_style` surface. Drop the image-style question and the
   `imageStyle*` fields from the active flow. `WizardContext` may keep the fields
   (nullable, unused) to minimize churn, but nothing populates or consumes them.
2. **Entry point → KEEP BOTH.** The existing single-prompt `agent_generate_panel`
   modal stays (quick path). The wizard is added as a separate **guided** path with
   its own entry point/route. Both funnel into `GenerateDeckCommand`.

Defaults chosen (revisit only if they cause friction):
3. **Surface layout → single-column conversational** for v1: catalog surfaces
   render inline in the message thread (simpler than the old two-pane; fits a
   route/modal). The two-pane layout can come later.
4. **`GenerateDeckCommand` inputs → unchanged.** The built prompt string (with
   style/color hints from `WizardContext` via `prompt_builder`) is sufficient; the
   pipeline already extracts final style from the generated deck JSON. No new
   command parameters for v1.
5. **Model picker → hardcode default** (`GeminiModels.defaultValue`) for v1; no
   `model_select` UI.

---

## 7. Suggested build order (once questions are settled)

1. Port pure-Dart core: `WizardContext`, `WizardContextKeys`, `prompt_builder`.
2. Port session/transport/agent-client + `AiConversationProfile` +
   `wizardConversationProfile()`.
3. Build `WizardStore` (ChangeNotifier) over the session.
4. Port catalog surfaces one at a time (text → radio → checkbox → slider → style →
   summary), wiring each to `WizardStore`.
5. Bridge summary-card confirm → `GenerateDeckCommand`.
6. Wizard chat UI + entry point + Provider wiring.
7. Progress/error UI.
8. Tests mirroring `test/` structure; regenerate `*.g.dart` via build_runner.
```
