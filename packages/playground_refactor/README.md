# playground_refactor

A layered rewrite of the `playground` app using **Provider + Command +
ChangeNotifier** instead of `signals`. The original `playground` package is left
untouched — this package is where the new architecture is built incrementally.

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

## Status

Base scaffold only — folder skeleton, `Result`/`Command` base classes, app
router + provider shells, and a placeholder home route. Feature migration has
not started yet.

## Run

```bash
fvm flutter run -t lib/main.dart
```
