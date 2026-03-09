# SuperDeck V2 API Surface

## Purpose
This document is the canonical planning source for the implemented v2 public bootstrap API.

Use it for:
- the primary Flutter bootstrap surface
- deck source selection and watch semantics
- provider vs renderer ownership
- extension and advanced-control APIs
- public CLI/runtime language

Do not use older planning references to `SuperDeckRuntime`, `DeckSource`,
`DeckRuntimeConfig`, or `SuperDeckApp(runtime: ...)` as the current
implementation surface. Those were intermediate planning shapes and are now
historical only.

## Canonical Bootstrap

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSuperDeck(extensions: [presenterTools]);

  final config = kIsWeb
      ? const DeckConfig.bundle(
          projectDir: '.',
          outputDir: '.superdeck',
          assetsPath: 'assets',
        )
      : const DeckConfig.local(
          slidesPath: 'slides.md',
          watch: true,
          projectDir: '.',
          outputDir: '.superdeck',
          assetsPath: 'assets',
        );

  runApp(
    SuperDeckProvider(
      config: config,
      builder: (context, deck) => SuperDeckApp(
        deck: deck,
        theme: DeckTheme(
          baseStyle: baseStyle,
          styles: styles,
          templates: templates,
          defaultTemplate: defaultTemplate,
          widgets: widgets,
          frame: frame,
          debug: true,
        ),
        extensions: const [presenterTools],
      ),
    ),
  );
}
```

## Public Types

### `initializeSuperDeck`
- canonical async startup entrypoint before `runApp()`
- owns dependency initialization and `DeckExtension.initialize()`

### `DeckConfig`
- explicit deck origin and watch policy
- `DeckConfig.local(slidesPath, watch, projectDir, outputDir, assetsPath)`
- `DeckConfig.bundle(deckAssetPath, projectDir, outputDir, assetsPath)`
- local config is the only mode that can trigger source rebuild/watch behavior

### `SuperDeckProvider`
- canonical deck-loading lifecycle owner
- owns:
  - deck loading
  - rebuild/watch state
  - loading/error/rebuild UI
- calls `builder` only when a loaded `Deck` is available

### `SuperDeckApp`
- canonical render/runtime widget surface
- takes explicit `deck`, `theme`, and `extensions`
- owns:
  - controller creation
  - routing/navigation wiring
  - presentation shell

### `DeckTheme`
- render-time presentation composition
- owns:
  - `baseStyle`
  - `styles`
  - `templates`
  - `defaultTemplate`
  - `widgets`
  - `frame`
  - `debug`

### `DeckExtension`
- behavioral/runtime add-on surface
- owns:
  - async initialization
  - extra routes
  - action contributions
  - optional floating action contribution

### `DeckController`
- narrow advanced-control surface available from `SuperDeck.of(context)`
- supports:
  - navigation
  - readonly render state
  - export and thumbnail entrypoints

## Runtime Semantics

### Local config
- local config is explicit, not inferred from environment
- `SuperDeckProvider` owns the local parse/build/watch loop
- `watch: true` enables source rebuild/watch after startup
- the last good deck remains visible while rebuilds are in progress or fail

### Bundle config
- bundle config is explicit, not inferred from environment
- bundle mode is consume-only
- bundle mode loads bundled generated deck artifacts

### Deferred configuration
- do not implicitly read `superdeck.yaml`
- do not implicitly load `styles.yaml`
- external YAML policy remains deferred from this API surface

## CLI Scope
- public initial v2 CLI scope is:
  - `setup`
  - `publish`
- `build` / `build --watch` remain supported transitional commands through v2.0
- the preferred local development flow is app-owned watch via `DeckConfig.local(watch: true)`

## Migration Defaults
- `comments` becomes `notes`
- `@column` becomes `@block`
- `DeckOptions`, `SuperDeckPlugin`, `SuperDeckRuntime`, `DeckSource`, and `DeckRuntimeConfig` are not canonical public APIs
