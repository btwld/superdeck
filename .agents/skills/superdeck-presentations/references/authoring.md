# Authoring SuperDeck Slides

Use this reference when editing `slides.md` or explaining SuperDeck Markdown behavior.

## Slide Document Structure

Create `slides.md` at the Flutter project root. SuperDeck splits slides on standalone `---` lines outside fenced code blocks.

Prefer frontmatter for every slide:

```markdown
---
title: Product Vision
style: hero
template: keynote
owner: Platform Team
---

@block { align: center }

# Product Vision

---
title: Next Slide
---

# Plain Markdown also works
```

Supported frontmatter keys:

- `title`: Used by navigation/export/chrome.
- `style`: Named style from `DeckOptions.styles`, or from the active template's `styles`.
- `template`: Named `DeckOptions.templates` entry. Use `template: none` to opt out of `defaultTemplate`.
- Any other key: Preserved in `SlideOptions.args`.

Plain slides without frontmatter are valid:

```markdown
# Slide 1

---

# Slide 2
```

HTML comments become speaker notes in `Slide.comments`:

```markdown
<!-- Slow down here and show the demo. -->
```

Multiline comments are normalized into a single note string. Comments also remain embedded in the slide content, where Markdown rendering keeps them invisible.

## Directive Syntax

Directives are line-starting tags outside fenced code blocks:

```markdown
@block

@image { src: assets/logo.png }

@widget {
  name: "metricCard"
  value: 42
}
```

Options are strict YAML inside balanced braces. Prefer multiline options when there is more than one key:

```markdown
@block {
  flex: 2
  align: topLeft
  scrollable: true
}
```

Values can be strings, numbers, booleans, lists, or objects. Quote strings that contain punctuation, spaces, `#`, `:`, or YAML keywords such as `on`, `off`, `true`, `false`, or `null`.

If visible Markdown content must begin with `@`, write `_@channel`; the parser restores it to `@channel` without treating it as a directive.

Do not use `@column`; it throws a format error. Use `@block`.

## Layout Model

SuperDeck renders slides at a logical `1280 x 720` resolution and scales to the viewport.

Sections stack vertically:

```markdown
@section { flex: 1 }
@block
Header row

@section { flex: 3 }
@block
Main left
@block
Main right

@section { flex: 1 }
@block
Footer row
```

Blocks inside each section are laid out horizontally. `flex` controls relative width for blocks and relative height for sections.

If a slide has no directives, the full slide content becomes one default content block in one default section.

If `@block` directives appear without an explicit `@section`, SuperDeck creates a default section and places the blocks side by side:

```markdown
@block { flex: 2 }
Left content

@block { flex: 1 }
Right content
```

Use `align` on child blocks or widget blocks for visible alignment:

```markdown
@block { align: center }

# Centered title
```

Valid alignments are `topLeft`, `topCenter`, `topRight`, `centerLeft`, `center`, `centerRight`, `bottomLeft`, `bottomCenter`, `bottomRight`.

Current renderer note: `@section { align: ... }` is accepted and stored, but visible content placement is driven by each child block/widget's `align`.

Use `scrollable: true` on overflowing blocks/widgets, not on sections:

```markdown
@block {
  scrollable: true
}

Long content...
```

## Built-In Widgets

Built-ins use widget block behavior, so `flex`, `align`, and `scrollable` can be used alongside widget-specific arguments.

### Images

Choose image syntax by intent:

- Prefer standalone Markdown image syntax when the image is part of the slide's written content, for example an illustration after a paragraph, a small diagram in a text-heavy block, or an image that should stay near surrounding Markdown.
- Prefer `@image` when the image is a designed slide element, for example a hero visual, a dedicated column, a screenshot that must use `cover`/`contain`, a fixed-size logo, or a source that needs `data:` URI support.
- Do not place Markdown images inline inside a text sentence; the current renderer supports standalone Markdown images.

Use Markdown image syntax when the image belongs inside Markdown content:

```markdown
![Architecture](assets/architecture.png)
```

Use `@image` when the image should be its own widget block/column, or when you need fit, explicit sizing, flex, alignment, or scrolling controls:

```markdown
@image {
  src: assets/hero.png
  fit: cover
  height: 420
  align: center
}
```

`@image` arguments:

- `src` required: relative asset path, URL, absolute path, `file://`, `data:`, or Windows absolute path.
- `fit`: `fill`, `contain`, `cover`, `fitWidth`, `fitHeight`, `none`, `scaleDown`; default `contain`.
- `width`, `height`: positive logical pixels.

Key differences:

| Syntax | Where it lives | Best for | Source handling |
|---|---|---|---|
| `![Alt](src)` | Markdown/plain slide content or inside `@block` content, on its own line | Content-flow images, text-adjacent diagrams, simple standalone images, hero-marked Markdown images | Validates sources defensively: relative, `http`, `https`, and `file`; rejects path traversal |
| `@image { src: ... }` | Widget block (`WidgetBlock`) | Dedicated image columns, hero visuals, exact fit/size, `flex`, `align`, `scrollable`, `data:` images | Accepts author-controlled asset paths, URLs, absolute/file paths, `data:` URIs, and Windows absolute paths |

Markdown images can use hero markers:

```markdown
![Architecture](assets/architecture.png) {.hero-architecture}
```

### DartPad

Use `@dartpad` for live Dart or Flutter examples that the audience should run, edit, or inspect during the presentation.

```markdown
@dartpad {
  id: "d7b09149b0843f2b9d09e081e3cfd5a3"
  theme: dark
  run: true
}
```

Arguments:

- `id` required.
- `theme`: `light` or `dark`.
- `embed`: boolean, default `true`.
- `run`: boolean, default `true`.

DartPad renders through SuperDeck's internal `WebViewWrapper`; there is no separate built-in `@webview` tag. Verify the target platform supports WebViews and can reach `https://dartpad.dev`.

Share a DartPad snippet through a GitHub Gist:

1. Create a GitHub Gist containing a `main.dart` file.
2. Copy the gist ID from the gist URL, without the username.
3. Test it with `https://dartpad.dev/?id=<gist-id>`.
4. Put that same gist ID in the SuperDeck block:

```markdown
@dartpad {
  id: "5c0e154dd50af4a9ac856908061291bc"
  theme: dark
  embed: true
  run: true
}
```

Use `run: false` when you want the audience to read or edit before executing. Use `theme: dark` for dark slide styles and `theme: light` for lighter decks. Avoid relying on DartPad's old in-app share/update flow; current sharing is gist-based.

Runtime behavior to remember:

- SuperDeck builds `https://dartpad.dev/?id=<id>&theme=<theme>&embed=<embed>&run=<run>` from the `@dartpad` args.
- The WebView uses unrestricted JavaScript because DartPad needs it.
- The wrapper blocks navigation away from the original host, so links to other domains will not navigate inside the embedded view.
- The WebView is hidden until the page finishes loading, then fades in after a short delay.
- The wrapper overlays refresh and clear-editor controls.
- State is kept alive while the slide tree keeps the widget alive; changing the DartPad URL reloads the WebView.

### QR Code

Use `@qrcode` when a slide needs a scannable link or text payload, for example a demo URL, docs link, feedback form, repository, event page, or contact handoff. Keep QR slides visually simple: pair the QR code with a short label or URL in a nearby `@block`, and verify the code scans at presentation distance.

```markdown
@qrcode {
  text: "https://superdeck.dev"
  size: 220
  errorCorrection: high
  backgroundColor: "#ffffff"
  foregroundColor: "#000000"
}
```

Arguments:

- `text` required, max 1000 characters.
- `size`: 1 through 1000, default `200`.
- `errorCorrection`: `low`/`l`, `medium`/`m`, `high`/`q`, or `highest`/`h`; default `medium`.
- `backgroundColor`, `foregroundColor`: hex colors.

QR examples:

```markdown
@section

@block {
  flex: 2
  align: center
}

## Try the demo
https://superdeck-dev.web.app

@qrcode {
  text: "https://superdeck-dev.web.app"
  size: 260
  errorCorrection: high
  backgroundColor: "#ffffff"
  foregroundColor: "#111827"
  flex: 1
  align: center
}
```

Use `errorCorrection: high` or `highest` when the QR code may be printed, projected, or placed near visual noise. Avoid very long text payloads; the widget rejects text over 1000 characters and dense QR codes are harder to scan.

## Custom Widgets in Markdown

Use custom widgets when the slide needs something Markdown cannot express cleanly: live app UI, charts, counters, embeds, animations, product screenshots with interaction, domain-specific cards, or reusable branded components.

In `slides.md`, use shorthand for registered widgets:

```markdown
@metricCard {
  label: Activation
  value: "72%"
  trend: up
}
```

Or explicit form:

```markdown
@widget {
  name: "metricCard"
  label: Activation
  value: "72%"
}
```

All properties become the widget factory's `Map<String, Object?>` arguments. Block-level controls such as `flex`, `align`, and `scrollable` are consumed by SuperDeck and are not passed as custom widget args.

Custom widget authoring rules:

- Register the widget name in `DeckOptions.widgets` before using it.
- Prefer shorthand `@metricCard { ... }` for normal widgets.
- Use explicit `@widget { name: "metricCard" ... }` when generating generic widget blocks or when the widget name is dynamic.
- Quote strings with punctuation, spaces, or YAML-sensitive values.
- Parse and validate args in the Flutter widget/factory; SuperDeck does not know your custom schema.
- Use `scrollable: true` on the widget block when the rendered widget may exceed its block height.
- Use `LayoutBuilder` inside the widget to adapt to the block's constraints.

Any unrecognized `@name` becomes a `WidgetBlock` with `name: name`. `section`, `block`, `widget`, and `column` are reserved directive names.

Custom widget layout example:

```markdown
@section

@block { flex: 2 }
## Activation
The north-star metric improved after onboarding changes.

@metricCard {
  label: Activation
  value: "72%"
  trend: up
  flex: 1
  align: center
}
```

## Markdown Features

SuperDeck uses GitHub-flavored Markdown plus custom builders:

- Headings, paragraphs, emphasis, lists, task lists, tables, blockquotes, links.
- Code blocks with highlighting for `dart`, `json`, `yaml`, `markdown`, `python`, and `mermaid`; unknown languages fall back to Dart highlighting.
- GitHub alerts:

```markdown
> [!NOTE]
> Useful context.

> [!WARNING]
> Important risk.
```

Supported alert labels include `NOTE`, `TIP`, `IMPORTANT`, `WARNING`, and `CAUTION`.

Hero markers can be attached to headings, images, and fenced code blocks:

````markdown
# Roadmap {.hero-title}
![Diagram](assets/roadmap.png) {.hero-visual}

```dart {.hero-code}
void main() {}
```
````

The first valid class name is used as the hero tag. Do not rely on classes beginning with `--`; they are rejected.

## Authoring Patterns

Title slide:

```markdown
---
title: Launch Plan
style: hero
---

@block { align: center }

# Launch Plan
## Q3 execution narrative
```

Text plus visual:

```markdown
---
title: Why Now
---

@block { flex: 2 }
## Market pressure
- Buyers expect immediate insight
- Competitors are bundling workflows
- Internal data quality is now sufficient

@image {
  src: assets/market-map.png
  fit: contain
  flex: 3
}
```

Three columns:

```markdown
@section

@block
### Problem
Fragmented workflows

@block
### Move
Unified deck authoring

@block
### Proof
Live Flutter components
```

Vertical rows:

```markdown
@section { flex: 1 }
@block { align: center }
## Executive summary

@section { flex: 4 }
@block
Main content

@section { flex: 1 }
@block { align: bottomRight }
Footer note
```
