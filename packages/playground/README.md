# playground

A playground app for experimenting with Mix, Remix, and Hero UI, built on a
layered architecture using **Provider + Command + ChangeNotifier**.

See [`.planning/architecture.md`](.planning/architecture.md) for the full design.

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

Set `GOOGLE_AI_API_KEY` in the ignored repository-root `.env` file. Flutter
does not load `.env` automatically; the define-file flag injects it at build
time. The Wizard shows a configuration error immediately when the key is
missing.

## AI generation smoke lab

Generation uses a plan-first pipeline: one model request creates the shared
narrative/style plan, then the Flash slide model composes and validates each
slide sequentially with previous/next context. Neither request configures a
thinking budget. Both default to the existing `gemini-3-flash-preview`
configuration, keeping live prompt iteration fast while model selection remains
injectable for comparisons.

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
request, brief, deck plan, per-slide prompts and responses, canonical JSON,
Markdown, validation/timing metadata, slide PNGs, a contact sheet, and a
machine-readable `quality_report.json`. Metadata records total, outline, and
slide request counts separately. Captures load the actual selected Google font
families; they do not register Roboto bytes under aliases.

Replay and recapture a saved artifact without making another model request:

```bash
fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
  --dart-define=LIVE_ARTIFACT=test_live/ai_generation/artifacts/<artifact-directory> \
  --reporter expanded
```

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
