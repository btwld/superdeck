# superdeck_cli

Command-line workflow for SuperDeck projects.

Use `superdeck_cli` to create a project, refresh managed SuperDeck files, build deck artifacts, and publish web output.

## Main Commands

- `superdeck create` - Scaffolds a starter app or refreshes managed SuperDeck files
- `superdeck build` - Builds deck output from `slides.md`
- `superdeck build --watch` - Rebuilds on slide changes during development
- `superdeck publish` - Publishes web builds (for example, GitHub Pages)

## Typical Workflow

```bash
superdeck create my_presentation
cd my_presentation
flutter pub get
dart run superdeck_cli:main build --watch
flutter run
```

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
