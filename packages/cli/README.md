# superdeck_cli

Command-line workflow for SuperDeck projects.

Use `superdeck_cli` to configure a Flutter app for SuperDeck and build deck artifacts.

## Main Commands

- `superdeck setup` - Configures the current Flutter app for SuperDeck
- `superdeck build` - Builds deck output from `slides.md`
- `superdeck build --watch` - Rebuilds on slide changes during development
- `superdeck run` - Builds slides, watches for changes, and launches `flutter run`

## Typical Workflow

```bash
flutter create my_presentation
cd my_presentation
superdeck setup
flutter pub add superdeck
flutter pub add --dev superdeck_cli

# Add slides.md in the project root and update lib/main.dart
# to initialize and run SuperDeckApp before building.

dart run superdeck_cli:main run
```

`superdeck build` requires `slides.md` to exist at the project root. Create it
(and wire up `SuperDeckApp` in `lib/main.dart`) before running the build
command.

`superdeck run` must be launched from the Flutter app directory. It is a
development convenience for `build --watch` plus `flutter run`; standalone
desktop release apps should bundle `.superdeck/` as Flutter assets.

## Install

```bash
dart pub global activate superdeck_cli
```

Or in a project:

```bash
dart pub add --dev superdeck_cli
```

## Related packages

- `superdeck` - Flutter slide runtime
- `superdeck_core` - core models and contracts
- `superdeck_builder` - Markdown build pipeline

## License

BSD 3-Clause. See `LICENSE`.
