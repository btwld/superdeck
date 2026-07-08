---
name: superdeck-presentations
description: Create, review, or edit SuperDeck presentations and presentation apps. Use when working with `slides.md`, SuperDeck Markdown syntax, `@section`/`@block`/`@widget` layout, built-in widgets such as `@image`, `@dartpad`, and `@qrcode`, custom Flutter widgets, `DeckOptions`, slide parts, templates, styles, images/assets, CLI builds, plugins, or validation of SuperDeck deck behavior.
---

# SuperDeck Presentations

## Overview

Use this skill to build accurate SuperDeck presentations: Markdown slide content, Flutter runtime wiring, assets, custom widgets, styling, templates, and verification.

## Reference Routing

Load only the reference needed for the task:

- Read `references/authoring.md` when creating or reviewing `slides.md`, block syntax, layouts, slide notes, built-in widgets, Markdown images, alerts, code, or hero markers.
- Read `references/runtime-customization.md` when wiring a Flutter app, registering custom widgets, configuring `DeckOptions`, slide parts, styles, templates, assets, or plugins.
- Read `references/verification.md` before claiming a deck/app works, when choosing commands, or when diagnosing build/render issues.

## Workflow

1. Inspect the existing `slides.md`, `lib/main.dart`, `pubspec.yaml`, and any registered widgets/parts/templates before editing.
2. Decide whether the task is authoring-only, runtime customization, plugin/build setup, or verification/debugging; load the matching reference.
3. Prefer the repository's documented syntax and implementation behavior over generic presentation assumptions.
4. Keep slides readable in Markdown: use frontmatter for metadata, `@section` for vertical rows, child blocks/widgets for horizontal columns, and `flex` ratios for sizing.
5. Verify with a real SuperDeck build or targeted tests before reporting success.

## Ground Truths

- SuperDeck renders a 1280x720 logical slide into a 16:9 scaled viewport.
- A slide contains vertical sections. Each `@section` starts a new vertical row; blocks inside that section are laid out horizontally.
- `@block` renders Markdown. `@widget` and any unrecognized `@name` render a `WidgetBlock`.
- Images have two authoring paths. Prefer standalone Markdown `![alt](src)` when the image belongs in the Markdown content flow; use `@image { src: ... }` when the image needs block-level layout control such as `fit`, fixed size, `flex`, `align`, `scrollable`, or `data:` source support.
- Markdown class markers such as `{.heading}` or `{.title}` drive Hero transitions for supported Markdown elements; the class does not need a `hero-` prefix. Use the same tag on matching elements across adjacent slides, and do not duplicate the same tag on one slide.
- `@column` is intentionally unsupported; use `@block`.
- Block and widget `align` controls visible content alignment. Current renderer stores `section.align` but does not apply it to child layout; set `align` on child blocks/widgets when visual placement matters.
- `scrollable` is valid on `@block` and widget blocks, not on `@section`.
- Built-ins `image`, `dartpad`, and `qrcode` are always registered and can be overridden by user widgets with the same name.
- `@dartpad` is the built-in WebView-backed widget; there is no separate built-in `@webview` authoring tag.
- Custom widgets must be registered in `DeckOptions.widgets`; use shorthand `@widgetName { ... }` in `slides.md` for registered widget names.
- Styles, templates, widgets, slide parts, and plugins are configured in Dart through `DeckOptions`/`SuperDeckApp`, not through a separate `styles.yaml`.
- The CLI reads `slides.md`, writes `.superdeck/superdeck.json`, and ensures `.superdeck/` is listed in Flutter assets unless `--skip-pubspec` is used.

## Source Map

Use these files to resolve disputes or update this skill:

- `docs/guides/markdown-authoring.mdx`
- `docs/reference/markdown-syntax.mdx`
- `docs/reference/block-types.mdx`
- `docs/reference/deck-options.mdx`
- `docs/guides/custom-widgets.mdx`
- `docs/guides/slide-parts.mdx`
- `docs/guides/cli-reference.mdx`
- `packages/builder/lib/src/parsers/markdown_parser.dart`
- `packages/builder/lib/src/parsers/section_parser.dart`
- `packages/core/lib/src/deck/block_model.dart`
- `packages/superdeck/lib/src/rendering/slides/slide_view.dart`
- `packages/superdeck/lib/src/rendering/blocks/block_widget.dart`
- `packages/superdeck/lib/src/builtins/`
- `packages/superdeck/lib/src/ui/widgets/webview_wrapper.dart`
- `packages/playground/lib/features/ai/quick_agent/core/engine/schemas/deck_schemas.dart`
