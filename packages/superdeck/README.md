# superdeck

SuperDeck renders Markdown slides in Flutter.

- Live demo: https://superdeck-dev.web.app
- Documentation: https://github.com/leoafarias/superdeck/tree/main/docs

## Install

In your Flutter project:

```bash
dart pub global activate superdeck_cli
superdeck setup
flutter pub add superdeck
```

## Initialize

In `lib/main.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final runtime = await SuperDeckRuntime.create(
    source: const DeckSource.local(
      slidesPath: 'slides.md',
      watch: true,
    ),
    runtimeConfig: const DeckRuntimeConfig(),
    presentation: const DeckPresentation(),
  );

  runApp(SuperDeckApp(runtime: runtime));
}
```

## Run slides

```bash
flutter run
```

With `DeckSource.local(watch: true)`, SuperDeck builds `slides.md` before the
first frame and rebuilds it on changes.

## Write slides

Separate slides with `---`. Use blocks to control layout:

- `@section` groups blocks horizontally.
- `@block` renders Markdown content.
- `@widget` renders a registered Flutter widget.

```md
---

@section

@block
# Title

@block
- Point one
- Point two

---
```

## Custom widgets

1. Register the widget in `DeckPresentation.widgets`.
2. Reference it by name in Markdown.

See the custom widgets guide:
https://github.com/leoafarias/superdeck/blob/main/docs/guides/custom-widgets.mdx

## License

BSD 3-Clause. See `LICENSE`.
