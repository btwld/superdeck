# superdeck_pdf

Optional PDF export support for SuperDeck presentations.

This package provides a `PdfPlugin` runtime plugin that adds PDF export to the
SuperDeck app shell. It depends on SuperDeck public rendering and capture APIs,
so apps can add PDF output without pulling PDF dependencies into every SuperDeck
installation.

## Install

In a Flutter project that already uses `superdeck`, add:

```yaml
dependencies:
  superdeck: ^1.0.0
  superdeck_pdf: ^1.0.0
```

## Usage

Register the PDF plugin with `SuperDeckApp`:

```dart
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_pdf/superdeck_pdf.dart';

SuperDeckApp(
  options: DeckOptions(),
  plugins: const [
    PdfPlugin(),
  ],
);
```

For custom save behavior, pass a `PdfSaver`:

```dart
SuperDeckApp(
  options: DeckOptions(),
  plugins: [
    PdfPlugin(
      options: PdfExportOptions(
        pdfSaver: (bytes) async {
          // Persist or upload bytes.
          return true;
        },
      ),
    ),
  ],
);
```

Use `PdfExportOptions.fileName` to change the default save/download name when
you are using the built-in saver.

For full setup guidance and plugin authoring patterns, see the SuperDeck
[plugin guide](https://docs.page/btwld/superdeck/guides/plugins) and
[plugin API reference](https://docs.page/btwld/superdeck/reference/plugin-api).

## License

BSD 3-Clause. See `LICENSE`.
