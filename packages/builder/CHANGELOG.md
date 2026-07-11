## Unreleased

- Round-trip the `layout` slide frontmatter option in Markdown serialization.
- Parse and round-trip section `spacing` plus all supported block `padding`
  and `margin` authoring forms, serializing insets as four normalized physical
  edges in clockwise order.
- Serialize nested directive maps in canonical multiline flow-map braces
  (comma-separated entries, one key per line); scalar-only options stay
  inline. Serializer output is idempotent.
- **Breaking:** reject non-positive flex values during Markdown compilation.
- Add build-plugin `beginBuild` and `finishBuild` lifecycle hooks.
- Make `DeckBuilder.dispose()` wait for queued builds before disposing plugins
  and reject new builds after disposal.

## 1.0.0

- First stable release of superdeck_builder
