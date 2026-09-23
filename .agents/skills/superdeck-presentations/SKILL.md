---
name: superdeck-presentations
description: Create, review, or edit SuperDeck Markdown presentations and Flutter presentation apps. Use for slides.md layouts, images, custom widgets, DeckOptions styling and templates, or verifying a rendered deck.
---

# SuperDeck Presentations

Use Markdown to compose slides and Dart to configure presentation styles, parts, widgets, and templates. Inspect the existing deck and app before changing either.

## Read for the task

- [Authoring](references/authoring.md): `slides.md` syntax, layout, images, Markdown, and built-in widgets.
- [Runtime customization](references/runtime-customization.md): app setup, `DeckOptions`, styles, templates, parts, custom widgets, assets, and plugins.
- [Verification](references/verification.md): build and visual checks before claiming a deck works.

## Layout and styling model

- Slides use a logical 1280 × 720 canvas. `@section` rows stack vertically; their child blocks and widgets form horizontal columns. Positive integer `flex` values divide height between sections and width between children.
- Use standalone Markdown images in content flow and `@image` for a dedicated visual with `fit`, dimensions, or block layout controls. `scale` changes painting within the image frame, not its layout size.
- Effective content alignment is `block align → section align → centerLeft`.
- Section `spacing` creates gutters between child blocks. Block `margin` reduces space inside that block's allocated frame, outside its decoration; `padding` is inside the decoration. Use section `spacing` for shared gutters.
- `SlideStyler` controls headings, paragraphs, inline emphasis and links, and slide styling. Its `blockContainer` takes `BlockStyler`; `BlockVariant('name')` selects an exact, case-sensitive widget-block name, including built-ins such as `@image`, never Markdown `@block` content.
- `scrollable` is valid on `@block` and widget blocks, not on `@section`.
- Frontmatter `style` and `template` select named styles and templates registered in Dart. `layout: fullscreen` removes header and footer while preserving the resolved background and style.
- Register custom widgets in `DeckOptions.widgets` before using their names as Markdown directives.

## Examples and source of truth

For a complete visual example, see [the layout showcase deck](../../../demo/layout_showcase/slides.md) and [its Dart styles](../../../demo/lib/src/layout_showcase/showcase_style.dart). For exact syntax and behavior, consult `docs/tutorials/block-layouts.mdx`, `docs/reference/deck-options.mdx`, and the parser/rendering code.
