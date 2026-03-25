# superdeck

SuperDeck renders Markdown slides in Flutter.

- Live demo: https://superdeck-dev.web.app
- Documentation: https://github.com/leoafarias/superdeck/tree/main/docs

## Install

In your Flutter project:

```bash
dart pub global activate superdeck_cli
flutter create my_presentation
cd my_presentation
superdeck setup
flutter pub get
dart run superdeck_cli:main build
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
dart run superdeck_cli:main build --watch
flutter run
```

SuperDeck reads slide content from `slides.md` and build output from `.superdeck/`.

## Write slides

Separate slides with frontmatter fences. Use blocks to control layout:

- `@section` groups blocks horizontally.
- `@block` renders Markdown content.
- `@widget` renders a registered Flutter widget.

```md
---
title: Welcome
---

@section

@block
# Title

@block
- Point one
- Point two

---
---
```

## Custom widgets

1. Register the widget in `DeckOptions.widgets`.
2. Reference it by name in Markdown.

See the custom widgets guide:
https://github.com/leoafarias/superdeck/blob/main/docs/guides/custom-widgets.mdx

## License

BSD 3-Clause. See `LICENSE`.
