## Unreleased

- Add clamped gaps between sibling blocks with section `spacing`.
- Apply alignment with `block align → section align → centerLeft` precedence.
- Add per-block padding overrides that replace resolved Mix padding while
  preserving variants, margin, border, decoration, animation, and modifiers.
- Add image paint scaling with aligned clipping and an unchanged `scale: 1`
  rendering path.
- Add deduplicated debug overflow indicators for supported non-scrollable
  Markdown without changing wrapping or rebuilding custom widgets.
- **Breaking:** section alignment now affects children without an explicit block
  alignment, and non-positive flex values are invalid.
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
