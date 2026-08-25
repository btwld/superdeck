## 2.0.0

- **Breaking:** consume the Ack 2.0 JSON APIs from `superdeck_core` and require
  `superdeck_core` 2.0.0.

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
- Fix slide splitting treating `---` as a separator inside tilde fences and
  inside fences carrying an info string (for example, ` ```dart {.hero}`).
  A fence closed with an info string such as ` ```{.code}` still closes.
- Fix Markdown serialization letting a `~~~` line close a ` ``` ` fence, which
  escaped `@` directives that were really inside code.
- Share one reserved directive-name set between `@column` rejection and
  widget-shorthand escaping, so a `WidgetBlock` named `section`, `block`,
  `widget`, or `column` always serializes as `@widget`.

## 1.0.0

- First stable release of superdeck_builder
