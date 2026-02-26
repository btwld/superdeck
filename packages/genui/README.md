# superdeck_genui

AI-powered presentation wizard for SuperDeck using GenUI and Gemini.

This package provides a chat-based wizard that guides users through creating
presentations with AI assistance. It handles the full generation pipeline:
wizard conversation → outline → images → final deck.

## What it provides

- **Chat wizard UI** — 8-step GenUI conversation with radio, checkbox, slider, and style selectors
- **AI generation pipeline** — 3-phase deck generation (outline → images → final deck) using Gemini
- **Composable routes** — `genUiRoutes()` function for integration into any GoRouter setup
- **Presentation preview** — Thumbnail generation and deck hosting screens

## Configuration

Set your Gemini API key via either method:

1. **Build-time** (recommended): `--dart-define=GOOGLE_AI_API_KEY=xxx`
2. **Runtime** (dev only): Create a `.env` file with `GOOGLE_AI_API_KEY=xxx`

`genUiRoutes()` automatically initializes GenUI runtime dependencies
(paths, prompt assets, examples, and optional `.env` loading).

## Usage

```dart
import 'package:superdeck_genui/superdeck_genui.dart';

// Optional (recommended for custom/manual integration)
await initializeGenUi();

// Add routes to your GoRouter
final router = GoRouter(
  routes: [...genUiRoutes()],
);

// Optional: override default route screens (for custom host integration)
final customRouter = GoRouter(
  routes: [
    ...genUiRoutes(
      presentationBuilder: (context, state) {
        return PresentationDeckHost(
          deckAppBuilder: (options) => MyPresentationApp(options: options),
        );
      },
    ),
  ],
);

// Or use individual screens directly
const GenUiBootstrapScope(child: ChatScreen());
const GenUiBootstrapScope(child: CreatingPresentationScreen());
const GenUiBootstrapScope(child: PresentationDeckHost());
```

## Related packages

| Package | Description |
|---------|-------------|
| `superdeck` | Flutter presentation framework |
| `superdeck_core` | Core models and parsing |
| `superdeck_cli` | CLI tool for building decks |
