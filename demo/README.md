# SuperDeck demo

This app is the SuperDeck demo and is used to validate the slide runtime and CLI.

## Run locally

From the repo root:

```bash
fvm use stable --force
dart pub global activate melos
melos bootstrap
```

Terminal 1 (build slides):

```bash
cd demo
dart run superdeck_cli:main build --watch
```

Terminal 2 (run the app):

```bash
cd demo
fvm flutter run
```

Edit `demo/slides.md` and hot reload to see changes.
