## Unreleased

- Add build-plugin `beginBuild` and `finishBuild` lifecycle hooks.
- Make `DeckBuilder.dispose()` wait for queued builds before disposing plugins
  and reject new builds after disposal.

## 1.0.0

- First stable release of superdeck_builder
