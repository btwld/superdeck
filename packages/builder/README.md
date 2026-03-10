# superdeck_builder

Build-time engine for SuperDeck presentations.

Most projects should run builds through `superdeck_cli`.
Use `superdeck_builder` directly only when you need programmatic control of the build pipeline.

## What It Does

- Parses `slides.md` into deck output
- Runs build tasks and asset generation (for example Mermaid)
- Writes build artifacts consumed by the runtime

## Typical Workflow

Use `superdeck build --watch` in one terminal and `flutter run` in another.

## Related packages

- `superdeck` - Flutter slide runtime
- `superdeck_core` - data models and utilities
- `superdeck_cli` - CLI wrapper (installs the `superdeck` command)

## License

BSD 3-Clause. See `LICENSE`.
