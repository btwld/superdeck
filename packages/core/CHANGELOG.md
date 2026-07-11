## Unreleased

- Add `SlideLayout` and the `SlideOptions.layout` field to the slide contract.
- Add optional section `spacing`, normalized block `padding`, and inherited
  section/block alignment resolution to the layout contract.
- **Breaking:** require positive integer flex values in schemas and public Dart
  constructors; zero and negative flex values are no longer accepted.

## 1.0.0

- First stable release of superdeck_core
- Remove provisional setext hero syntax so core and Flutter stay scoped to ATX headings
- Fix image hero parsing by delegating to the shared helper for safe marker consumption

## 0.0.1

- Initial version.
