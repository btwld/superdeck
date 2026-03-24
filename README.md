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

2. Create a starter presentation app and install dependencies:

   ```bash
   superdeck create your_presentation
   cd your_presentation
   flutter pub get
   ```

3. Build slides and run the app:

   ```bash
   dart run superdeck_cli:main build --watch
   flutter run
   ```

## Write slides

The starter app already includes `lib/main.dart` and a sample `slides.md`.
Use paired frontmatter fences to separate slides.

```md
---
title: Welcome
---

@block
# Welcome

@block
- Write slides in Markdown
- Use blocks for layout

---
---
```

## Learn more

- `docs/getting-started.mdx`
- `docs/guides/cli-reference.mdx`
- `docs/reference/block-types.mdx`
- `docs/reference/deck-options.mdx`

## Contributing

SuperDeck is a Melos workspace pinned via FVM in `.fvmrc`.

```bash
fvm use --force
dart pub global activate melos
melos bootstrap
melos run analyze
melos run test
```
