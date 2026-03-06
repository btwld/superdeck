# SuperDeck demo

This app is the SuperDeck demo and is used to validate the slide runtime and CLI.

## Run locally

From the repo root:

```bash
fvm use --force
dart pub global activate melos
melos bootstrap
```

Terminal 1 (run the app with runtime-owned watch):

```bash
cd demo
fvm flutter run
```

Optional transitional CLI watch flow:

```bash
cd demo
dart run superdeck_cli:main build --watch
```

Edit `demo/slides.md` and hot reload to see changes.
