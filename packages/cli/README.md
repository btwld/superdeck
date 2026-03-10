# superdeck_cli

Command-line workflow for SuperDeck projects.

Use `superdeck_cli` to set up a project, build deck artifacts, and publish web output.

## Main Commands

- `superdeck setup` - Initializes SuperDeck files and project configuration
- `superdeck build` - Builds deck output from `slides.md`
- `superdeck build --watch` - Rebuilds on slide changes during development
- `superdeck publish` - Publishes web builds (for example, GitHub Pages)

## Typical Workflow

Run `superdeck build --watch` in one terminal and `flutter run` in another.

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
