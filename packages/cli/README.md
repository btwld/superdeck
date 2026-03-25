# superdeck_cli

Command-line workflow for SuperDeck projects.

Use `superdeck_cli` to configure a Flutter app for SuperDeck, build deck artifacts, and publish web output.

## Main Commands

- `superdeck setup` - Configures the current Flutter app for SuperDeck
- `superdeck build` - Builds deck output from `slides.md`
- `superdeck build --watch` - Rebuilds on slide changes during development
- `superdeck publish` - Publishes web builds (for example, GitHub Pages)

## Typical Workflow

```bash
flutter create my_presentation
cd my_presentation
superdeck setup
flutter pub get
dart run superdeck_cli:main build --watch
flutter run
```

Then:
- Add `slides.md` in the project root
- Update `lib/main.dart` to initialize and run `SuperDeckApp`

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
- `superdeck_builder` - build pipeline and asset generation

## License

BSD 3-Clause. See `LICENSE`.
