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

## Deck files

On first launch, choose a parent directory for deck storage. The app creates a
`SuperDeck` folder inside it and remembers access with a macOS security-scoped
bookmark. New decks are Markdown files in that folder; **Open** can load a
Markdown deck from another location.

If the active file is deleted or moved outside the app, the current Markdown
stays in memory. Create a new deck to recover it before opening another deck or
quitting.
