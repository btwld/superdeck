# superdeck_mermaid

Optional Mermaid diagram rendering support for SuperDeck presentations.

This package provides a standalone `MermaidGenerator` that converts Mermaid
syntax into PNG images via a headless browser (`puppeteer`). It keeps the
headless-browser dependency out of the default CLI install for presentations
that do not use Mermaid.

> Integration with the default `superdeck_cli` build pipeline is not wired up
> yet and will be provided by the plugin system in a future release.

## Usage

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

- `MermaidGenerator` – standalone class that renders Mermaid syntax to PNG
  bytes using `puppeteer`. Call `render(syntax)` to produce a `Uint8List`, and
  `dispose()` to close the browser when finished.
- `docs/mermaid_themes/` – reference Mermaid theme files.
- `docs/mermaid-diagrams.mdx` – user guide for authoring Mermaid diagrams.

## License

BSD 3-Clause. See the root `LICENSE`.
