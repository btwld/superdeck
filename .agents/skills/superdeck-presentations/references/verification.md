# Verification

Use this reference before claiming a SuperDeck deck, runtime change, or skill update is complete.

## For Presentation Authoring

Run a real SuperDeck build from the target Flutter app root:

```bash
dart run superdeck_cli:main build
```

For active editing:

```bash
dart run superdeck_cli:main build --watch
flutter run
```

Check generated output:

- `.superdeck/superdeck.json` exists.
- `.superdeck/build_status.json` records success.
- `pubspec.yaml` includes `.superdeck/` under `flutter.assets`, unless the project intentionally uses `--skip-pubspec`.

If the deck uses local images, verify the paths work in the intended target:

- Native debug: relative filesystem paths may work.
- Web/release: project assets must be declared in `pubspec.yaml`.
- Remote URLs require network access at runtime.

Visually inspect slides when changing layout, alignment, images, custom widgets, templates, or chrome. Enable `DeckOptions(debug: true)` during layout debugging to see section/block boundaries.

## For SuperDeck Repo Changes

Follow the repo's FVM/Melos workflow:

```bash
melos run build_runner:build
melos run analyze
melos run test
```

Use targeted tests when the change is scoped:

```bash
cd packages/builder
fvm dart test test/src/parsers/markdown_parser_test.dart
fvm dart test test/src/parsers/section_parser_test.dart
fvm dart test test/src/parsers/block_parser_test.dart

cd packages/superdeck
fvm flutter test test/src/rendering/slide_view_test.dart
fvm flutter test test/src/rendering/block_widget_test.dart
fvm flutter test test/src/builtins/image_widget_test.dart
fvm flutter test test/src/markdown/image_element_rendering_test.dart
```

Run builder/parser tests for syntax, slide splitting, comments, directives, or serialization changes. Run Flutter widget tests for rendering, alignment, image loading, slide parts, templates, and custom widget behavior.

Regenerate generated files after model/schema changes:

```bash
melos run build_runner:build
```

## For Skill Updates

Validate the skill folder:

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py" .agents/skills/superdeck-presentations
```

Also check for stale template markers:

```bash
rg -n "TO[D]O|FIX[M]E|\\[TO[D]O" .agents/skills/superdeck-presentations
```

Confirm the trigger description mentions the concrete contexts that should load this skill: `slides.md`, SuperDeck Markdown, block layout, widgets, assets/images, `DeckOptions`, styles/templates, slide parts, CLI builds, and plugins.

## Common Failure Checks

Build cannot find slides:

- Ensure `slides.md` is at the project root.
- Run `superdeck setup` if `.superdeck/` assets or macOS entitlements are missing.

Invalid directive options:

- Use strict YAML inside braces.
- Prefer multiline options for multiple keys.
- Quote strings with punctuation or YAML keywords.
- Check braces are balanced.

Unexpected layout:

- Remember: sections stack vertically; blocks inside a section are horizontal.
- Alignment resolves from child block to section to `centerLeft`.
- Use section `spacing` for gaps between blocks, block/widget `margin` for
  inset inside a block's own frame (outside its decoration), and block/widget
  `padding` for inset inside the decorated container (between border and
  content).
- Use block/widget `scrollable: true`; do not set `scrollable` on sections.
- Use positive `flex` integers; invalid values throw during parse/model validation.
- For `layout: fullscreen`, verify that header/footer are absent while the intended background and style remain.

Widget does not render:

- Verify the widget name is registered in `DeckOptions.widgets`.
- Built-ins are `image`, `dartpad`, `webview`, and `qrcode`.
- Check that widget arguments do not collide with reserved block keys: `name`, `align`, `flex`, `margin`, `padding`, `scrollable`.
- Remember that reserved block keys are consumed by SuperDeck and are not passed to custom widget args.
- If using shorthand, verify the directive name exactly matches the registered widget name.
- If using Ack-generated args models, confirm the schema is a top-level
  `@AckInfer()` declaration, both `.ack.dart` and `.ack.g.dart` part directives
  are present, generator dependencies are installed, and `build_runner` has
  regenerated both files.
- Let the on-slide error guide factory parse/build failures.

DartPad fails:

- Confirm `id` is only the gist ID, not the full DartPad or GitHub URL.
- Confirm the gist contains `main.dart`.
- Test the snippet directly at `https://dartpad.dev/?id=<gist-id>`.
- Check WebView support on the target platform.
- Check network access to `dartpad.dev`; offline decks should not depend on `@dartpad`.
- For macOS, run `superdeck setup` so required network entitlements are patched.
- Remember the embedded WebView blocks navigation away from `dartpad.dev`; external-domain links inside DartPad will not navigate in the embedded view.
- If the WebView stays blank, check whether `onPageFinished` fires and whether the target platform's `webview_flutter` implementation is available.

WebView fails:

- Confirm `url` is an absolute `http` or `https` URL.
- Check network access to the source page and target platform WebView support.
- Use `cacheKey` only for sequential reuse; two live blocks with the same key receive separate local controllers.
- On Flutter web, do not rely on `allowedHosts`, JavaScript injection, or page-finished callbacks: the iframe implementation does not support those controller APIs.

QR code fails:

- Confirm the widget tag is `@qrcode`, not `@qr` or `@qrCode`.
- Confirm `text` is present, non-empty, and no more than 1000 characters.
- Use `size` from 1 to 1000; integers and doubles are accepted.
- Use `errorCorrection` values `low`, `medium`, `high`, `highest`, or aliases `l`, `m`, `q`, `h`.
- Use valid hex colors for `backgroundColor` and `foregroundColor`.
- Scan the QR code on the target display/projector; build success does not prove scan distance.

Images fail:

- Confirm which image path is being used: Markdown `![Alt](src)` inside content or widget-block `@image { src: ... }`.
- If the image should behave like normal slide content, use a standalone Markdown image. If it needs `fit`, fixed dimensions, column sizing, alignment, scrolling, or `data:` URI support, use `@image`.
- Use `scale` only for painting within an image frame; it must be finite and
  greater than zero and does not change block allocation.
- For Markdown images, reject `asset:` URLs and `..` traversal.
- For Markdown images, do not use `data:` URIs; use `@image` for `data:` sources.
- For web/release, declare project asset directories in `pubspec.yaml`.
- Prefer portable relative asset paths or URLs over absolute local paths for shared decks.

Style/template errors:

- Verify style names exist in the correct namespace. Template slides use `SlideTemplate.styles`; non-template slides use `DeckOptions.styles`.
- Use `template: none` only to opt out of `defaultTemplate`.
- Do not register a template named `none`; it is reserved.
- `BlockVariant('name')` matches only widget blocks with that exact, case-sensitive name; it does not select Markdown `@block` content.
