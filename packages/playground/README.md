# playground

A playground app for experimenting with Mix, Remix, and Hero UI, built on a
layered architecture using **Provider + Command + ChangeNotifier**.

## Layers (folders, single package)

```
lib/
  main.dart
  app/            # router.dart + providers.dart (app-root DI)
  core/           # shared cross-feature domain + data
    result.dart   # Result<T>
    command.dart  # Command / Command0 / Command1
    domain/       # models, stores, repositories (abstract)
    data/         # repositories (impl), data_sources, mappers
  features/
    ai/           # domain / data / presentation / routes
    editor/       # domain / data / presentation / routes
    presentation/ # domain / data / presentation / routes
```

**Dependency rule:** `presentation → domain ← data`. Domain depends on nothing.

## State patterns

| Need | Pattern | Lives in |
|------|---------|----------|
| Text input, focus, animation, scroll | Ephemeral `StatefulWidget` | the widget |
| Async action (loading/error/success) | `Command0<T>` / `Command1<T, A>` | `domain/commands/` |
| Shared state within a feature | `ChangeNotifier` store | `features/<name>/domain/stores/` |
| Shared state across features | `ChangeNotifier` store | `core/domain/stores/` |

## Run

```bash
fvm flutter run -d macos -t lib/main.dart --dart-define-from-file=../../.env
```

Add `--dart-define=SUPERDECK_DEBUG_LAYOUT=true` to show the slide layout
overlay: magenta sections, cyan block allocations, orange margin edges, and
green padding/content edges. The flag is preserved when Playground themes or
typography settings change.

Set `GOOGLE_AI_API_KEY` in the ignored repository-root `.env` file. Flutter
does not load `.env` automatically; the define-file flag injects it at build
time. The Wizard shows a configuration error immediately when the key is
missing.

## AI generation smoke lab

Generation uses a plan-first pipeline. `gemini-3.5-flash` creates the shared
narrative/style plan, then `gemini-3.1-flash-lite` composes each narrative
section concurrently. Every call uses the lowest thinking-budget compatibility
setting exposed by the pinned client. Gemini structured output constrains each
response to JSON and a response schema; Dart still performs semantic,
grounding, layout, density, and canonical parsing checks before accepting it.
Invalid slides remain isolated failures so valid slides and later sections can
continue.

Live AI checks are opt-in and live outside `test/`, so normal test runs never
spend API quota. Run all three versioned briefs with:

```bash
fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
  --dart-define-from-file=../../.env --reporter expanded
```

Set `--dart-define=LIVE_FIXTURE=narrative`, `comparison_table`, or
`visual_elements` to run one fast fixture. Run the larger quality matrix with:

```bash
fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
  --dart-define-from-file=../../.env \
  --dart-define=LIVE_FIXTURE=large_deck_matrix \
  --reporter expanded
```

The matrix generates editorial 10-slide, technical/data 15-slide, and bold
product 20-slide decks with three exact font pairings. Each run writes an ignored
artifact bundle under `test_live/ai_generation/artifacts/` containing the typed
request, brief, deck plan, section prompts and responses, canonical JSON,
Markdown, validation/timing metadata, slide PNGs, a contact sheet, and a
machine-readable `quality_report.json`. Metadata records total, outline, and
composition request counts separately. Captures load the actual selected Google font
families; they do not register Roboto bytes under aliases.

Run the deterministic ten-slide fake-model checkpoint without an API key:

```bash
fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
  --dart-define=LIVE_FAKE_CHECKPOINT=true \
  --reporter expanded
```

It verifies a zero-repair four-call run (one outline plus three concurrent
narrative sections), the ordered section plans and canonical layout examples,
the exact Flash/Lite model split and thinking configuration, resolved
theme/font/style snapshot, Markdown replay, ten full-size captures, a contact
sheet, and the machine quality report. Run the reviewed featured-theme goldens
separately with `--dart-define=LIVE_THEME_QUALIFICATION=true`; those render 30
slides with actual fonts and compare three exact contact-sheet baselines under
`test_live/ai_generation/goldens/`.

Replay and recapture a saved artifact without making another model request:

```bash
fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
  --dart-define=LIVE_ARTIFACT=test_live/ai_generation/artifacts/<artifact-directory> \
  --reporter expanded
```

Add `--dart-define=LIVE_DEBUG_LAYOUT=true` to include the section, block,
margin, and padding guides in the recaptured slide PNGs and contact sheet.
Normal captures remain clean by default.

In debug builds, open `/debug/generation` to exercise the same production
pipeline interactively with the three fixtures.

## Deck files

On first launch, choose a parent directory for deck storage. The app creates a
`SuperDeck` folder inside it and remembers access with a macOS security-scoped
bookmark. New decks are Markdown files in that folder; **Open** can load a
Markdown deck from another location.

If the active file is deleted or moved outside the app, the current Markdown
stays in memory. Create a new deck to recover it before opening another deck or
quitting.
