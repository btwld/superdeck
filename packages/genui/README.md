# superdeck_genui

AI-powered presentation creation flow for SuperDeck.

This package provides chat-driven generation for outlines, assets, and final deck content.

## What It Includes

- Chat wizard screens and flow
- AI generation pipeline (outline, images, final deck)
- Route integration via `genUiRoutes()`
- Deck hosting and preview screens

## Configuration

Set the Gemini API key with `--dart-define=GOOGLE_AI_API_KEY=...`.

For local development, `.env` can be used when supported by the host integration.

## Usage

```dart
import 'package:superdeck_genui/superdeck_genui.dart';

final router = GoRouter(
  routes: [...genUiRoutes()],
);
```

## Related packages

- `superdeck` - Flutter presentation runtime
- `superdeck_core` - core models and contracts
- `superdeck_cli` - project setup and build workflow

## License

BSD 3-Clause. See `LICENSE`.
