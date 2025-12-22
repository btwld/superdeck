# superdeck

SuperDeck renders Markdown slides in Flutter.

- Live demo: https://superdeck-dev.web.app
- Documentation: https://github.com/leoafarias/superdeck/tree/main/docs

## Install

In your Flutter project:

```bash
flutter pub add superdeck
dart pub global activate superdeck_cli
superdeck setup
```

## Initialize

In `lib/main.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SuperDeckApp.initialize();

  runApp(const SuperDeckApp(options: DeckOptions()));
}
```

## Build slides

```bash
superdeck build --watch
flutter run
```

SuperDeck reads slide content from `slides.md` and build output from `.superdeck/`.

## Write slides

Separate slides with `---`. Use blocks to control layout:

- `@section` groups blocks horizontally.
- `@column` renders Markdown content.
- `@widget` renders a registered Flutter widget.

```md
---

@section

@column
# Title

@column
- Point one
- Point two

---
```

## Custom widgets

1. Register the widget in `DeckOptions.widgets`.
2. Reference it by name in Markdown.

See the custom widgets guide:
https://github.com/leoafarias/superdeck/blob/main/docs/guides/custom-widgets.mdx

## License

BSD 3-Clause. See `LICENSE` in the repository root.
