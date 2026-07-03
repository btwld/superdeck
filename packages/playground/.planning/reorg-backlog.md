# Playground Reorganization Backlog

Living backlog for the playground app reorganization. Add new items to
**Triage** as they come up; promote them into a section once scoped.

**Priority:** 🔴 P0 (blocking / broken) · 🟡 P1 (planned) · 🟢 P2 (nice-to-have)

---

## 1. Theming & Color 🟡 P1

Add custom/hex color input **everywhere colors are chosen** — the deck
background and every text level (h1/h2/h3/p). Today these are fixed 6-color
swatch rows (`playgroundBackgroundSwatches`, `playgroundTextSwatches`).

**Design (agreed):**
- One reusable **Color control** replaces every `_SwatchRow`:
  - A `Color` label above a rounded field.
  - Field = **color dot preview** + **inline editable hex text** (`#RRGGBB`).
  - **Preset swatches shown below** the field (one-tap, keep current presets).
- **Opaque only** for now — 6-digit hex, no alpha (revisit later if needed).
- **No HSV / popover picker** — dropped in favor of the inline hex field.
- Hex validation follows the existing `_FontSizeField` pattern: parse on
  commit, revert to last-good value on invalid input.

**Tasks:**
- [x] Build a reusable `ColorControl` widget (dot + hex field + preset row).
      → `lib/features/editor/color_control.dart`
- [x] Add hex parse/format helpers (`colorToHex` added next to the existing
      `parseHexColor`; revert-on-invalid handled in the widget's `_commit`).
- [x] Replace `_BackgroundSection`'s `_SwatchRow` with `ColorControl`.
- [x] Replace each `_LevelControls` `_SwatchRow` with `ColorControl`
      (old `_SwatchRow` deleted).
- [ ] Verify AI-applied colors still round-trip (`applyFromAiStyle` already
      writes arbitrary colors into the same signals — no swatch constraint).
      Code path unchanged; not yet runtime-verified.

**Follow-up:** `color_utils.dart` lives under `features/ai/core/utils` but is now
used by the editor — relocate to `lib/utils/` during the structure pass (item 5)
to avoid editor→ai coupling.

**Files:** `lib/features/editor/color_control.dart`,
`lib/features/editor/customization_sidebar.dart`,
`lib/features/ai/core/utils/color_utils.dart`,
`lib/stores/deck_customization_store.dart`

---

## 2. AI: Wizard & AI Edit crash on open 🔴 P0

The **Wizard** (`/ai/wizard` → `ChatScreen`) and **AI Edit**
(`/ai/edit` → `DeckEditScreen`) crash/fail to open. The quick **Generate
panel** (sparkles) and **Remix** (`/ai/remix`) still work.

**Captured error:**
```
Token "fortal.gray.1" not found in scope
```

**Analysis (lead, not yet fixed):**
- This is a **mix/remix theme-token resolution failure**, not an API-key or
  generic routing problem — a design token isn't resolvable in the widget scope.
- Both crashing screens share the GenUI/dartantic conversation stack
  (`AiConversationViewModel` / `DeckEditCoordinator` → `genui_conversation_session`
  → `dartantic_ai` + `genui`); the working surfaces do not. The regression most
  likely lives there or in a component it renders.
- Timing suspect: the recent `bc983a7 "Drop window manager and bump deps"`
  commit — a bumped `hero_ui`/`remix` may have renamed/removed the token.

**Tasks:**
- [ ] Reproduce and capture the full stack trace (which widget requests
      `fortal.gray.1`).
- [ ] Locate where `fortal.gray.1` is referenced vs. what the current theme
      scope actually provides (likely a typo/renamed token or a missing
      `HeroTheme`/token provider around the pushed AI routes).
- [ ] Fix token registration or wrap the AI routes in the correct theme scope.
- [ ] Add a smoke test that opens `/ai/wizard` and `/ai/edit` without crashing.

**Files:** `lib/features/ai/chat/view/chat_screen.dart`,
`lib/features/ai/deck_edit/deck_edit_screen.dart`,
`lib/features/ai/core/ai/services/*`, `lib/main.dart` (`_Theme`)

---

## 3. Routing: migrate to Go Router + web deep-linking 🟡 P1

Replace the `onGenerateRoute` switch in `main.dart` with **go_router**, and
make routes properly **URL-addressable / refresh-safe** for the web playground.

**Current routes (in `main.dart`):**
- `/` → `EditorPage` (default)
- `/present` → `PresentationPage` via custom `TakeoverRoute`
- `/ai/wizard` → `ChatScreen`
- `/ai/remix` → `RemixScreen`
- `/ai/edit` → `DeckEditScreen` (receives captured markdown as a `String` arg)

**Design (agreed):**
- Straight path parity first (keep the 5 paths above), then layer in
  deep-linking so each route is reachable/refreshable by URL.
- Preserve the **takeover transition** for `/present` (custom page/transition
  in go_router terms).
- **Rework in-memory arg passing:** `/ai/edit` currently receives the captured
  markdown via `Navigator.pushReplacementNamed(arguments:)`. That breaks on a
  hard reload — redesign how the captured source is handed off (e.g. via a
  shared store / provider rather than route args) so deep-linking is safe.

**Tasks:**
- [ ] Add `go_router` dependency and a `GoRouter` config.
- [ ] Port all 5 routes; keep `/present`'s takeover transition.
- [ ] Replace `Navigator.pushNamed`/`pushReplacementNamed` call sites
      (toolbar, `DeckEditScreen`, `ChatScreen` header actions).
- [ ] Move `/ai/edit`'s captured-markdown handoff off route args → store/provider.
- [ ] Confirm provider scope is intact for pushed routes (see item 5).

**Files:** `lib/main.dart`, `lib/utils/takeover_route.dart`,
`lib/features/editor/customization_sidebar.dart` (toolbar nav),
`lib/features/ai/**` (nav call sites)

---

## 4. Dead code & redesign leftovers 🟢 P2

- [ ] Remove the commented-out `_GenerateButton` block at the bottom of
      `ai_generate_panel.dart` (leftover from the AI panel redesign).
- [ ] Sweep for other commented-out widgets/imports left by the recent AI
      conversation-workflow redesign.

**Files:** `lib/features/ai/ai_generate_panel.dart`, `lib/features/ai/**`

---

## 5. AI feature folder structure 🟢 P2

The `lib/features/ai` tree is large and mixes concerns
(`core/ai/services`, `core/ai/catalog`, `chat`, `deck_edit`, `remix`,
`core/tools`, `core/ui`). Align it with the repo's domain-folder conventions
(group by domain, earned role suffixes, co-locate models) per `AGENTS.md`.

**Tasks:**
- [ ] Map the current `features/ai` layout and identify overlapping concerns.
- [ ] Propose a domain-oriented structure and migrate incrementally.
- [ ] Keep test paths mirroring `lib/` after the move.

**Related tech-debt (revisit during routing work):**
- `showAiGeneratePanel` must be handed an `AiStore` explicitly because the
  dialog route doesn't reliably inherit the editor's provider scope. Fold a
  proper fix into the Go Router migration (item 3).

---

## Triage (unscoped / new ideas)

- [ ] _(add new pending items here)_

---

### Notes
- `.env.example` currently holds a real-looking Google AI key — swap for a
  placeholder and rotate the key before pushing. (Flagged separately; not
  tracked as a backlog task per request.)
