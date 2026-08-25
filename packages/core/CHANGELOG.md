## 2.0.0

- **Breaking:** replace `dart_mappable` models and mapper APIs with Ack 2.0
  class-first models. Use the generated `*Schema` facades and model
  `fromJson`/`toJson` methods; unknown-field handling is now explicit per
  model, and generated `copyWith` treats `null` as unchanged.

- Add `SlideLayout` and the `SlideOptions.layout` field to the slide contract.
- Add optional section `spacing`, block `padding` and `margin`, and inherited
  section/block alignment resolution to the layout contract. `margin` is
  reserved from widget args alongside the other layout keys.
- **Breaking:** split inset authoring from the compiled contract. Compiled
  contracts accept only normalized four-edge `padding`/`margin` objects
  (`top`, `right`, `bottom`, `left`); scalar and symmetric shorthand is
  authoring-only and is normalized by the new `Block.parseAuthoring` entry
  point (`BlockInsets.parseAuthoring` reports the exact field and edge on
  invalid input).
- Add `aiSlideSchema`, a flattened structured-output projection of the slide
  contract for AI generation (JSON-Schema unions are not consumable by
  structured-output adapters).
- **Breaking:** require positive integer flex values in schemas and public Dart
  constructors; zero and negative flex values are no longer accepted.
- **Breaking:** remove `Block.resolvedAlign` and
  `SectionBlock.totalBlockFlex`. Renderers resolve alignment through
  `SectionBlock.resolveBlockAlign`; layout engines own flex distribution.
- Reject explicitly authored `null` inset edges with their full field path
  (for example, `padding.left`) while continuing to normalize omitted edges to
  zero.
- Add `fencedCodeLines`, the shared rule deciding which lines sit inside
  fenced code so `---` splits and `@` directives stay hidden there. Slide
  splitting, directive tokenization, and Markdown serialization now resolve
  fences through it instead of three separate regexes.
- Fix `TagTokenizer` skipping directives only in fences that start at column
  zero and close with exactly the opening run length. Indented fences and
  closing fences longer than their opener are now recognized.

## 1.0.0

- First stable release of superdeck_core
- Remove provisional setext hero syntax so core and Flutter stay scoped to ATX headings
- Fix image hero parsing by delegating to the shared helper for safe marker consumption

## 0.0.1

- Initial version.
