![SuperDeck logo](./assets/logo-dark.png#gh-dark-mode-only)
![SuperDeck logo](./assets/logo-light.png#gh-light-mode-only)

# SuperDeck

SuperDeck is a Flutter presentation framework. You write slides in Markdown, and SuperDeck renders them with Flutter.

![Screenshot](https://github.com/leoafarias/superdeck/assets/435833/42ec88e9-d3d9-4c52-bbf9-5a2809cca257)

- Live demo: https://superdeck-dev.web.app
- Example deck: `demo/slides.md`
- Documentation (in this repo): `docs/`

## Quickstart

1. Install the CLI:

   ```bash
   dart pub global activate superdeck_cli
   ```

2. In your Flutter project, run setup and add the package:

   ```bash
   cd your_flutter_project
   superdeck setup
   flutter pub add superdeck
   ```

3. Initialize SuperDeck in `lib/main.dart`:

   ```dart
   import 'package:flutter/widgets.dart';
   import 'package:superdeck/superdeck.dart';

   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await SuperDeckApp.initialize();

     runApp(const SuperDeckApp(options: DeckOptions()));
   }
   ```

4. Build slides and run the app:

   ```bash
   superdeck build --watch
   flutter run
   ```

## Write slides

Create a `slides.md` file in your project root. Separate slides with `---`.

```md
---

@column
# Welcome

@column
- Write slides in Markdown
- Use blocks for layout

---
```

## Learn more

- `docs/getting-started.mdx`
- `docs/guides/cli-reference.mdx`
- `docs/reference/block-types.mdx`
- `docs/reference/deck-options.mdx`

## Contributing

SuperDeck is a Melos workspace pinned to Flutter stable via FVM.

```bash
fvm use stable --force
dart pub global activate melos
melos bootstrap
melos run analyze
melos run test
```
