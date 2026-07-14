# Layout Showcase

A thirteen-slide editorial deck that demonstrates SuperDeck's predictable
layout primitives, built-in image controls, and GitHub-flavored Markdown with
a cohesive visual system.

The content deck is intentionally native-first: sections, blocks, images,
tables, alerts, checklists, and inline styling all use standard SuperDeck
authoring. Only the final comparison slide contains a registered Flutter
content widget, and it labels that extension point explicitly. The deck's
background, footer, and theme remain custom presentation chrome.

From the `demo/` directory, build the Markdown contract:

```bash
fvm dart run tool/build_layout_showcase.dart
```

Run the deck on macOS:

```bash
fvm flutter run -t lib/layout_showcase_main.dart -d macos
```

Capture clean 1280x720 review screenshots:

```bash
SUPERDECK_CAPTURE_SLIDES=1 \
SUPERDECK_SCREENSHOT_DIR=../.context/layout_showcase_screenshots \
fvm flutter test integration_test/layout_showcase_test.dart \
  -d macos --fail-fast --timeout 2m
```

The deck source is `slides.md`. Runtime styling, slide parts, and the single
metric widget live under `demo/lib/src/layout_showcase/`.

## Spacing controls

- `@section spacing` creates horizontal gutters between sibling blocks.
- Block or widget `margin` creates outer breathing room inside that block's
  allocated frame. It is also how adjacent vertical section rows are visually
  separated.
- Block or widget `padding` controls the inner distance between the decorated
  frame and its content.

The frame-size and treatment-matrix slides intentionally vary these controls
alongside `width`, `height`, `fit`, `scale`, and `align` so their effects can be
compared in captured output.

## Image assets

All three PNGs under `assets/` are original AI-generated images created for
this demo. Their prompts intentionally request landscape, crop-safe
compositions without text, logos, or watermarks:

- `momentum_ribbon.png`: a sculptural translucent ribbon with coral, violet,
  and teal light on a near-black field.
- `architectural_steps.png`: a monumental concrete stair and curved portal
  with restrained coral, ultraviolet, and cool teal lighting.
- `material_detail.png`: smoked glass, brushed black metal, and pale stone in a
  precise macro still life with coral, violet, and teal refractions.
