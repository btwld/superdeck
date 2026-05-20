# SuperDeck Studio (playground)

> This package is currently named `playground` but is evolving toward **SuperDeck Studio** — a rename is planned in a future PR.

SuperDeck Studio is a standalone editor and presentation environment built on the SuperDeck framework. It lets users author Markdown slides in a rich text editor, see a live preview as they type, and present directly from the app — all without the CLI pipeline or external file setup.

## How it differs from `demo/`

The root-level `demo/` app exists to test the CLI and custom extension points (styles, templates, widgets). Studio is the product: a self-contained SuperDeck environment for authoring and presenting slides using the base framework implementation.

## Current Features

| Feature | Description |
|---------|-------------|
| **Rich text editor** | Markdown editing with syntax highlighting for headers, `---` separators, and `@block` directives. |
| **Live preview** | Slide thumbnails update in real time as you type. |
| **Presentation mode** | Full-screen takeover route with keyboard navigation (arrows, space, escape). |
| **Theme support** | Follows the system light/dark theme automatically. |

## Planned Features

- Visual controls in the customization sidebar for adjusting slide style, layout, and content options
- Text scaling for previews

## Running

From the repository root:

```bash
cd packages/playground
fvm flutter run -d macos    # macOS desktop
fvm flutter run -d chrome   # Web
```

## Note

This package is not published (`publish_to: none`). It depends on local `superdeck`, `superdeck_core`, and `superdeck_builder` packages from the monorepo.
