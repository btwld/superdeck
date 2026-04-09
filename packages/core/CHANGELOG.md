## 1.0.0

- First stable release of superdeck_core
- Define the compiled slide contract as a raw JSON slide array.
- Remove legacy `@column`; use `@section` for horizontal layout and `@block` for content blocks.
- Flatten widget block arguments into top-level widget keys in the generated slide JSON.
- Remove provisional setext hero syntax so core and Flutter stay scoped to ATX headings
- Fix image hero parsing by delegating to the shared helper for safe marker consumption

## 0.0.1

- Initial version.
