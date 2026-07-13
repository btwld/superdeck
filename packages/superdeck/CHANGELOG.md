## Unreleased

- Add clamped gaps between sibling blocks with section `spacing`.
- Replace manual `Stack`/`Positioned` geometry with constraint-driven
  `Column`/`Row`/`Expanded` layout. Slide-container insets and constraints now
  define the real content frame, and oversized header/footer chrome is reduced
  proportionally.
- Make each allocated block cell the sizing source: decoration fills the frame,
  margin sits outside decoration, padding sits inside it, and alignment moves
  only content. `BlockConfiguration.size` now comes from the resolved inner
  constraints.
- Apply alignment with `block align → section align → centerLeft` precedence.
- Add per-block `margin` and `padding` overrides that replace only the
  matching resolved inset after variants resolve, preserving decoration,
  foreground decoration, clipping, and animation. Margin is consumed inside a
  block's allocated frame and never changes section spacing or flex ratios.
- **Breaking:** `SlideStyler.blockContainer` now takes a `BlockStyler` instead
  of a `BoxStyler`. `BlockStyler` exposes only padding, margin, decoration,
  foreground decoration, clipping, variants, and animation — widget modifiers,
  constraints, transforms, and box alignment are unrepresentable for the
  framework-owned block frame. Raw variant lists reject non-`BlockStyler`
  values eagerly and are snapshotted to preserve that invariant; low-level
  low-level `SlideStyler.create` input is reduced to the same allow-list at the
  render boundary.
- Add image paint scaling with aligned clipping and an unchanged `scale: 1`
  rendering path. Image `width`, `height`, and `scale` accept integers or
  doubles through one finite-positive rule.
- Add deduplicated debug overflow diagnostics for non-scrollable Markdown and
  custom widgets without changing wrapping or rebuilding content; the visual
  indicator outlines the overflowing frame instead of covering its corner.
- Preserve live unbounded child layout for scrollable custom widgets during
  static capture, then clip the natural-height result to the block frame.
- Make WebView and DartPad surfaces, including static placeholders, fill their
  received constraints without a copied `Size` parameter.
- **Breaking:** remove `Block.resolvedAlign`, `SectionBlock.totalBlockFlex`,
  and internal redundant geometry helpers. `SectionBlock.resolveBlockAlign`
  remains the alignment-resolution contract.
- **Breaking:** section alignment now affects children without an explicit block
  alignment, and non-positive flex values are invalid.
- **BREAKING**: Generate the Mix styling layer with `mix_generator` instead of
  hand-writing it. Styler classes are now canonically named `*Styler`
  (`SlideStyler`, `MarkdownAlertStyler`, ...) following the Mix 2.x convention;
  the previous `*Style` names are no longer exported.
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
