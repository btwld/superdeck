# superdeck_mermaid

Optional Mermaid diagram rendering support for SuperDeck presentations.

This package provides a standalone `MermaidGenerator` that converts Mermaid
syntax into PNG images via a headless browser (`puppeteer`). It keeps the
headless-browser dependency out of the default CLI install for presentations
that do not use Mermaid.

## Usage

Register the Mermaid build plugin with a custom SuperDeck runner:

```dart
import 'dart:io';

import 'package:superdeck_cli/runner.dart';
import 'package:superdeck_mermaid/superdeck_mermaid.dart';

Future<void> main(List<String> args) async {
  final exitCode = await SuperDeckRunner(
    plugins: [
      MermaidBuildPlugin(),
    ],
  ).run(args);

  exit(exitCode);
}
```

The build plugin replaces fenced Mermaid blocks in `slides.md` with generated
PNG image references under the active SuperDeck build output directory.

To customize Mermaid rendering, pass Mermaid configuration to the plugin:

```dart
SuperDeckRunner(
  plugins: [
    MermaidBuildPlugin(
      configuration: {
        'theme': 'forest',
        'viewportWidth': 1280,
        'viewportHeight': 780,
      },
    ),
  ],
);
```

For custom browser launch options or tests, pass a `MermaidGenerator` directly.
Do not pass both `configuration` and `generator`; the generator owns its own
configuration. `MermaidBuildPlugin.dispose()` disposes the generator it uses.

You can also use the renderer directly:

```dart
import 'package:superdeck_mermaid/superdeck_mermaid.dart';

final generator = MermaidGenerator();
try {
  final pngBytes = await generator.render('''
    graph TD;
      A-->B;
      A-->C;
  ''');
  // persist or embed pngBytes
} finally {
  await generator.dispose();
}
```

## Contents

- `MermaidBuildPlugin` – build-time SuperDeck plugin that renders fenced
  Mermaid blocks into generated PNG assets.
- `MermaidGenerator` – standalone class that renders Mermaid syntax to PNG
  bytes using `puppeteer`. Call `render(syntax)` to produce a `Uint8List`, and
  `dispose()` to close the browser when finished.

For full setup guidance and plugin authoring patterns, see the SuperDeck
[plugin guide](https://docs.page/btwld/superdeck/guides/plugins),
[plugin API reference](https://docs.page/btwld/superdeck/reference/plugin-api),
and [Mermaid diagrams guide](https://docs.page/btwld/superdeck/guides/mermaid-diagrams).

## License

BSD 3-Clause. See `LICENSE`.
