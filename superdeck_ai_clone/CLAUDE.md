# SuperDeck AI

Flutter app for AI-powered presentation generation using GenUI + Google Gemini.

## Quick Reference

```bash
# Validation pipeline (run before commits)
dart format . && dart analyze --fatal-infos && flutter test

# Run app
flutter run --dart-define=GOOGLE_AI_API_KEY=your_key

# Run tests
flutter test
```

## Tech Stack

- **Framework**: Flutter + Dart 3.10.1+
- **State**: Signals (`Signal<T>`, `Computed<T>`) - not ChangeNotifier/Provider
- **AI**: GenUI + Google Generative AI (Gemini)
- **UI**: Mix/Remix with FortalTokens
- **Routing**: GoRouter

## Architecture

```
lib/
├── core/ai/catalog/     # GenUI components (AskUserRadio, AskUserCheckbox, etc.)
├── core/ai/prompts/     # System prompts, font/image style enums
├── core/ai/schemas/     # Deck generation schemas
├── core/ai/services/    # Deck & image generator services
├── chat/                # Chat feature (viewmodel, view, widgets)
└── presentation/        # Presentation viewer feature
```

## Key Files

| File | Purpose |
|------|---------|
| `lib/core/ai/catalog/catalog.dart` | GenUI component registration |
| `lib/core/ai/catalog/ask_user_radio.dart` | Radio selection component |
| `lib/chat/viewmodel/chat_viewmodel.dart` | Core conversation state |
| `assets/prompts/wizard_system.prompt` | Wizard flow instructions |
| `docs/gemini-structured-output-research.md` | Schema design guide |

## Wizard Flow (8 Steps)

1. Topic (user input) → 2. AskUserRadio → 3. AskUserRadio → 4. AskUserCheckbox → 5. AskUserSlider → 6. AskUserStyle → 7. AskUserImageStyle → 8. SummaryCard → 9. Generate

## GenUI Catalog (7 Components)

| Component | Purpose | Steps |
|-----------|---------|-------|
| AskUserRadio | Single selection with radio buttons | 2-3 |
| AskUserCheckbox | Multiple selection with checkboxes | 4 |
| AskUserSlider | Numeric input with slider | 5 |
| AskUserText | Free-form text input | (optional) |
| AskUserStyle | Visual style selection with colors/fonts | 6 |
| AskUserImageStyle | Image style selection with previews | 7 |
| SummaryCard | Aggregated selections recap | 8 |

## Patterns

- **Signals**: See `lib/chat/viewmodel/chat_viewmodel.dart`
- **Sealed classes**: See `lib/chat/models/chat_message.dart`
- **GenUI schemas**: See `lib/core/ai/catalog/ask_user_radio.dart`
- **Mix styling**: See `lib/core/ui/components/sd_components.dart`

## Naming

- UI components: `Sd*` prefix (SdButton, SdCard)
- Message classes: `Superdeck*` prefix
- Files: snake_case matching primary class

## Do

- Validate AI-generated data (hex colors, JSON)
- Add error handling around external I/O
- Write tests alongside code
- Use `const` constructors where possible
- Register catalog components in `catalog.dart`

## Don't

- Use ChangeNotifier/Provider (use Signals)
- Add abstractions before needed (YAGNI)
- Bypass pre-commit hooks
- Commit API keys
- Use `@immutable` on mutable classes

## Gotchas

- AI output is not guaranteed well-formed - always validate
- App sets `SignalsObserver.instance = null` to disable default observer
- Generated presentations write to `.superdeck/superdeck.json`
- Each AskUser* component has its own schema with proper required fields

## Environment

| Variable | Description |
|----------|-------------|
| `GOOGLE_AI_API_KEY` | Google Generative AI API key (required) |

## Routes

| Path | Screen |
|------|--------|
| `/chat` | Main chat interface (initial) |
| `/presentation/creating` | Loading state |
| `/presentation` | Presentation viewer |

## Claude Code Configuration

**Hooks** (`.claude/settings.json`):
- `SessionStart` - Auto-installs FVM/Flutter in remote environments
- `PostToolUse` (Write|Edit) - Auto-runs `dart format` + `dart analyze` on .dart files

**MCP Tools** (`.mcp.json`):
- Dart MCP server enabled - prefer `mcp__dart__run_tests` over `flutter test` bash
- Use `mcp__dart__analyze_files` for analysis, `mcp__dart__dart_format` for formatting

## Debug Logging

Full GenUI and app logs are written to `.superdeck/debug.log` (debug mode only, cleared on each app run). The log captures:
- All GenUI internal events at every level (FINEST through SEVERE): content generation, tool invocations, surface lifecycle, data model mutations
- App-level events: user actions, AI responses, surface tracking, errors with stack traces
- Timestamps (HH:mm:ss.SSS) and categories on every entry (e.g. `[GenUI:FINE]`, `[SURFACE]`, `[AI]`)

When debugging GenUI behavior, always check `.superdeck/debug.log` first — it contains the full timeline of what happened.

## Reference Docs

- `.skills/dart-flutter/references/` - Dart/Flutter patterns, testing, guardrails
- `docs/gemini-structured-output-research.md` - Gemini schema best practices
- `docs/automated_testing_guide.md` - Browser automation testing with Claude in Chrome
