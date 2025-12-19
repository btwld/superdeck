# superdeck_core

Core models and utilities for SuperDeck.

Most projects should depend on `superdeck` (Flutter) and use `superdeck_cli` for builds. Use `superdeck_core` when you want to read or write deck data outside the Flutter runtime.

## What it provides

- Deck data models (`Deck`, `Slide`, `SlideOptions`, block models)
- File layout helpers (`DeckConfiguration` for `slides.md` and `.superdeck/`)
- Local storage and file watching (`DeckService`)
- Markdown extensions and parsing helpers

## Example (Dart VM)

```dart
import 'dart:io';

import 'package:superdeck_core/superdeck_core.dart';

Future<void> main() async {
  final config = DeckConfiguration(projectDir: Directory.current.path);
  final service = DeckService(configuration: config);

  await service.initialize();
  final deck = await service.loadDeck();

  print('Slides: ${deck.slides.length}');
}
```

## Related packages

- `superdeck` - Flutter slide runtime
- `superdeck_builder` - asset generation and build pipeline
- `superdeck_cli` - CLI wrapper (installs the `superdeck` command)

## License

BSD 3-Clause. See `LICENSE` in the repository root.
