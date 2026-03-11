# superdeck_core

Shared domain models and core utilities for SuperDeck.

Most projects should use `superdeck` for runtime and `superdeck_cli` for builds.
Use `superdeck_core` when you need SuperDeck contracts and storage primitives in custom tooling.

## What It Includes

- Deck and slide models
- Deck contract schema
- Project path/configuration helpers (`DeckConfiguration`)
- Runtime deck loader contracts (`DeckLoader`, `DeckEvent`)
- Build-side storage primitives (`DeckBuildStore`)
- Markdown parsing helpers

## When To Use

- Use this package directly for integrations, tooling, and non-Flutter workflows.
- For app development, prefer `superdeck` + `superdeck_cli`.

## Documentation

For contract details, see `/docs/reference/contracts.mdx` in this repository.

## License

BSD 3-Clause. See `LICENSE`.
