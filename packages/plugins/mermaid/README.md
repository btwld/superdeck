# superdeck_mermaid

Optional Mermaid diagram rendering support for SuperDeck presentations.

This package contains the Mermaid asset generator and puppeteer-backed rendering
pipeline that were split out of `superdeck_builder`. It keeps the heavy
headless-browser dependency out of the default CLI install for presentations
that do not use Mermaid.

> Integration with the default `superdeck_cli` build pipeline is not wired up
> yet and will be provided by the plugin system in a future release.

## Contents

- `MermaidGenerator` – implements `AssetGenerator` from `superdeck_core`, turns
  Mermaid syntax into PNG via `puppeteer`.
- `mermaidAsset(String syntax)` – helper that builds a `GeneratedAsset`
  reference for a Mermaid diagram (type `mermaid`, extension `png`).
- `assets/grammars/mermaid.json` – TextMate grammar for syntax highlighting
  mermaid fenced code blocks.
- `docs/mermaid_themes/` – reference Mermaid theme files.
- `docs/mermaid-diagrams.mdx` – user guide for authoring Mermaid diagrams.

## License

BSD 3-Clause. See the root `LICENSE`.
