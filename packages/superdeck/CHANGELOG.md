## Unreleased

- **BREAKING**: Generate the Mix styling layer with `mix_generator` instead of
  hand-writing it. Styler classes are now canonically named `*Styler`
  (`SlideStyler`, `MarkdownAlertStyler`, ...) following the Mix 2.x convention;
  the previous `*Style` names remain available as typedef aliases.
- **BREAKING**: Styler constructor parameters for `TextStyle`-typed fields now
  take `TextStyleMix` (e.g. `SlideStyler(strong:)`,
  `MarkdownCodeblockStyler(textStyle:)`). Wrap existing values with
  `TextStyleMix.value(...)`. These fields also gain Mix merge semantics:
  merging styles now combines text-style properties field-wise instead of
  replacing the whole `TextStyle`.
- Stylers gain the full generated fluent API: per-field setter methods
  (`SlideStyler().h1(...)`, `.strong(...)`), field factories, and widget-state
  variant helpers (`onHovered`, `onFocused`, ...).
- Deprecate `MarkdownTextSpec`/`MarkdownTextStyle`: they are not wired into
  rendering. Use `SlideStyler` / Mix `TextStyler` (`p`, `h1`–`h6`, `strong`,
  `em`, `del`, `link`) instead.
- Add `BlockVariant` for opt-in, name-based `WidgetBlock` styling in Dart
  stylesheets.
- Render `@webview` blocks edge-to-edge (zero padding and margin) by default.
- Always paint an opaque slide background so background-less slides no longer
  bleed adjacent slides through during transitions.
- Export `FileDeckLoader` and `BundledDeckLoader` from the public barrel so
  apps can use `SuperDeckApp.deckLoader` without importing from `src/`.
- Fall back to bundled deck assets when auto-selection cannot discover a
  project root at runtime.
- Improve missing build output diagnostics with checked paths and desktop app
  guidance.

## 1.0.0

- First stable release of `superdeck`.
- Roll back experimental setext-heading hero parsing; ATX headers continue to use the shared helper.
- Fix image hero-tag parsing to avoid inline parser overruns and keep Flutter/core paths aligned.
- Document the shared `{.hero}` helper and scope so future contributions stay consistent.

## 0.0.4

- Fix better error handling when external asset tooling is not installed.
- Improve the asset generation pipeline.

## 0.0.3

- Clean up dependencies.
- Update example code.
- Improve logging.
- Fix and improve asset generation.

## 0.0.2

- Add demo and example code.

## 0.0.1

- Initial version.
