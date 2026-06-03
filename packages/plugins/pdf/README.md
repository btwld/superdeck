# superdeck_pdf

Optional PDF export support for SuperDeck presentations.

This package contains the PDF controller and dialog that were split out of the
base `superdeck` package. It depends on SuperDeck public rendering and capture
APIs, so apps can add PDF output without pulling PDF dependencies into every
SuperDeck installation.

## Install

In a Flutter project that already uses `superdeck`, add:

```yaml
dependencies:
  superdeck: ^1.0.0
  superdeck_pdf: ^1.0.0
```

## Usage

Register the PDF action with `SuperDeckApp`:

```dart
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_pdf/superdeck_pdf.dart';

SuperDeckApp(
  options: DeckOptions(),
  actions: [
    ...pdfActions(),
  ],
);
```

For custom save behavior, pass a `PdfSaver`:

```dart
SuperDeckApp(
  options: DeckOptions(),
  actions: [
    ...pdfActions(
      pdfSaver: (bytes) async {
        // Persist or upload bytes.
        return true;
      },
    ),
  ],
);
```

## License

BSD 3-Clause. See `LICENSE`.
