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

## Usage

```dart
import 'package:superdeck_genui/superdeck_genui.dart';

// Add routes to your GoRouter
final router = GoRouter(
  routes: [...genUiRoutes()],
);

// Or use individual screens directly
const ChatScreen();
const CreatingPresentationScreen();
const PresentationDeckHost();
```

## Related packages

| Package | Description |
|---------|-------------|
| `superdeck` | Flutter presentation framework |
| `superdeck_core` | Core models and parsing |
| `superdeck_cli` | CLI tool for building decks |
