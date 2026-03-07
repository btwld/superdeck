# SuperDeck V2 API Surface

## Purpose
This document is the canonical planning source for the v2 public runtime/bootstrap API.

Use it for:
- the primary Flutter bootstrap surface
- source selection and watch semantics
- runtime vs presentation configuration boundaries
- extension and advanced-control APIs
- public CLI scope

Do not use older planning references to `SuperDeckApp(options, configuration?)`,
`DeckOptions.watchForChanges`, or `DeckWorkspace.watch` as the v2 source of truth.
Those were intermediate planning shapes and are superseded by this document.

## Canonical Bootstrap

```dart
Future<void> main() async {
  final runtime = await SuperDeckRuntime.create(
    source: DeckSource.local(
      slidesPath: 'slides.md',
      watch: true,
    ),
    runtimeConfig: const DeckRuntimeConfig(
      projectDir: '.',
      outputDir: '.superdeck',
      assetsPath: 'assets',
    ),
    presentation: DeckTheme(
      baseStyle: baseStyle,
      styles: styles,
      templates: templates,
      defaultTemplate: defaultTemplate,
      widgets: widgets,
      parts: parts,
      debug: true,
      extensions: [presenterTools],
    ),
  );

  runApp(SuperDeckApp(runtime: runtime));
}
```

## Public Types

### `SuperDeckRuntime`
- canonical async bootstrap result
- owns startup work before `runApp()`
- owns initial local build when using a local source
- exposes `handle` for advanced control

### `DeckSource`
- explicit content origin
- `DeckSource.local(slidesPath, watch)`
- `DeckSource.bundle(deckAssetPath)`
- local source is the only mode that can trigger source rebuild/watch behavior

### `DeckRuntimeConfig`
- startup-only operational paths and runtime policy
- owns:
  - `projectDir`
  - `outputDir`
  - `assetsPath`
- does not own styles, templates, widgets, or debug rendering
- does not implicitly read `superdeck.yaml`

### `DeckTheme`
- render-time presentation composition
- owns:
  - `baseStyle`
  - `styles`
  - `templates`
  - `defaultTemplate`
  - `widgets`
  - `parts`
  - `debug`
  - `extensions`

### `DeckExtension`
- behavioral/runtime add-on surface
- replaces plugins as the canonical v2 concept
- owns:
  - async initialization
  - extra routes
  - action contributions
  - optional floating action contribution

### `SuperDeckHandle`
- narrow advanced-control surface
- available as:
  - `runtime.handle`
  - `SuperDeck.of(context)`
- supports:
  - navigation
  - reload
  - export entrypoints
  - readonly runtime state access

## Runtime Semantics

### Local source
- local source is explicit, not inferred from environment
- runtime owns the primary local parse/build/watch loop
- runtime performs an initial one-shot build before `runApp()`
- `watch: true` enables source rebuild/watch after startup
- runtime keeps the last good deck visible on rebuild failures

### Bundle source
- bundle source is explicit, not inferred from environment
- bundle mode is consume-only
- bundle mode loads only versioned generated deck artifacts

### Deferred configuration
- do not implicitly read `superdeck.yaml`
- do not implicitly load `styles.yaml`
- external YAML policy remains deferred from this API surface

## CLI Scope
- public initial v2 CLI scope is:
  - `setup`
  - `publish`
- `setup` remains responsible for starter files and project wiring
- `publish` remains responsible for deployment-oriented flows
- build/watch survive as internal pipeline responsibilities, not as public day-to-day CLI commands

## Migration Defaults
- `comments` becomes `notes`
- `@column` becomes `@block`
- runtime/build artifacts use explicit `.v2.json` filenames
- `DeckOptions`, `SuperDeckPlugin`, and `SuperDeckApp.initialize()` are no longer canonical public APIs
