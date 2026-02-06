# superdeck_builder

Build logic and asset generation for SuperDeck presentations.

Most projects should use `superdeck_cli` to run builds. Use `superdeck_builder` directly when you need programmatic access to the build pipeline.

## What it provides

- Markdown-to-JSON slide processing
- Asset generation pipeline (Mermaid diagrams, thumbnails)
- Schema code generation via `build_runner`

## Related packages

- `superdeck` - Flutter slide runtime
- `superdeck_core` - data models and utilities
- `superdeck_cli` - CLI wrapper (installs the `superdeck` command)

## License

BSD 3-Clause. See `LICENSE`.
