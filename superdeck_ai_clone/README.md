# SuperDeck AI - GenUI Reference Application

A Flutter reference application demonstrating **GenUI** integration with Google's Gemini models. This app showcases how to build AI-powered, dynamic user interfaces that adapt based on conversational context.

## Overview

SuperDeck AI is an interactive presentation generator that guides users through a 7-step wizard workflow. The AI dynamically renders custom UI components (cards, sliders, forms) based on the conversation state, showcasing GenUI's ability to create adaptive, context-aware interfaces.

## Key Features

- **Dynamic UI Generation**: AI decides which UI components to render based on conversation context
- **Custom Catalog Components**: 2 specialized GenUI components for the wizard flow
- **Structured Output**: Uses Gemini's structured output for type-safe AI responses
- **Reactive State Management**: Built with Signals for efficient state updates
- **AI Image Generation**: Generates presentation backgrounds using Gemini 2.5 Flash Image

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter 3.10.1+ | Cross-platform UI framework |
| Dart 3.10.1+ | Programming language |
| GenUI 0.6.0 | Dynamic AI-powered UI framework |
| Signals | Reactive state management |
| Google Generative AI | Gemini models for AI responses |
| ACK | Schema validation with generated types |
| Mix/Remix | Functional styling system |
| SuperDeck | Presentation rendering engine |

## Quick Start

### Platform Support

- Supported for this release: macOS, Linux, Windows
- Not supported for this release: Web

### Prerequisites

- Flutter SDK 3.10.1 or higher
- Dart SDK 3.10.1 or higher
- Google AI API key (Gemini access)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd superdeck_ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate ACK types** (if schema files changed)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure API key**

   Create a `.env` file in the project root:
   ```
   GOOGLE_AI_API_KEY=your_api_key_here
   ```

5. **Run the application**
   ```bash
   flutter run -d macos --dart-define=GOOGLE_AI_API_KEY=your_api_key_here
   ```

## Architecture

```
lib/
├── main.dart                 # App entry point
├── core/                     # Shared infrastructure
│   ├── ai/                   # AI integration layer
│   │   ├── catalog/          # GenUI component definitions
│   │   ├── prompts/          # System instructions & enums
│   │   ├── schemas/          # JSON schema definitions
│   │   └── services/         # AI service classes
│   ├── router/               # GoRouter configuration
│   ├── ui/                   # Shared UI components
│   └── utils/                # Utility functions
├── chat/                     # Chat feature module
│   ├── viewmodel/            # ChatViewModel (Signals-based)
│   └── view/                 # Screens and widgets
└── presentation/             # Presentation feature module
    └── view/                 # Presentation screens
```

## GenUI Integration

### How It Works

1. **Catalog Registration**: Custom UI components are registered in a `Catalog`
2. **Schema Definition**: Each component has a JSON schema defining its data structure
3. **AI Response**: Gemini returns structured JSON matching component schemas
4. **Dynamic Rendering**: GenUI renders the appropriate widget based on AI response

### Catalog Components

| Component | Purpose | File |
|-----------|---------|------|
| `AskUserQuestion` | Unified question component (radio, checkbox, slider, text, style, image_style) | `ask_user_question.dart` |
| `SummaryCard` | Recap of selections + generate trigger | `summary_card.dart` |

### Creating a Catalog Component

```dart
// 1. Define schema with ACK (uses unified input with type discriminator)
@AckType(name: 'AskUserQuestion')
final _askUserQuestionSchema = Ack.object({
  'question': Ack.string().describe('The question to display'),
  'description': Ack.string().optional().describe('Additional context'),
  'input': _inputSchema.describe('Input config with type'),
  'action': actionSchema,
}).describe('Unified question component');

// 2. Create CatalogItem with schema and widget builder
final askUserQuestion = CatalogItem(
  name: 'AskUserQuestion',
  dataSchema: _askUserQuestionSchema.toJsonSchemaBuilder(),
  exampleData: [/* JSON examples for few-shot prompting */],
  widgetBuilder: (itemContext) {
    final data = AskUserQuestionType.parse(itemContext.data);
    return _AskUserQuestionContent(data: data, itemContext: itemContext);
  },
);

// 3. Register in catalog
final chatCatalog = Catalog([
  _withErrorHandling(askUserQuestion),
  _withErrorHandling(summaryCard),
], catalogId: 'com.superdeck.ai.chat');
```

### Action Dispatch Pattern

Components use a component-level action with context:

```dart
void _submitAction() {
  final action = ActionType.parse(widget.data.action);
  final resolvedContext = resolveContext(
    widget.itemContext.dataContext,
    action.context ?? [],
  );

  // Add selection data to context
  resolvedContext.addAll(_buildActionContext());

  widget.itemContext.dispatchEvent(
    UserActionEvent(
      name: action.name,
      sourceComponentId: widget.itemContext.id,
      context: resolvedContext,
    ),
  );
}
```

## 8-Step Wizard Workflow

1. **Topic** - User enters presentation topic
2. **Audience** - Select target audience (AskUserQuestion input.type: "radio")
3. **Approach** - Choose presentation approach (AskUserQuestion input.type: "radio")
4. **Emphasis** - Multi-select key topics (AskUserQuestion input.type: "checkbox")
5. **Slide Count** - Select number of slides (AskUserQuestion input.type: "slider")
6. **Style** - Choose visual style with colors/fonts (AskUserQuestion input.type: "style")
7. **Image Style** - Select AI-generated background style (AskUserQuestion input.type: "image_style")
8. **Summary** - Review selections and generate (SummaryCard)

## State Management

The app uses **Signals** for reactive state management:

```dart
class ChatViewModel implements Disposable {
  final model = Signal<GeminiModels>(GeminiModels.defaultValue);
  final surfacesId = Signal<List<String>>([]);
  final _messages = signal<List<SuperdeckChatMessage>>([]);

  // Computed reactive properties
  late final Computed<bool> isThinking = computed(() {
    return _isProcessingBridge.value?.value ?? false;
  });

  Computed<List<SuperdeckChatMessage>> get messages => computed(() {
    if (debugMode.value) return _messages.value;
    return _messages.value.where((e) =>
      e is SuperdeckUserMessage || e is SuperdeckAiMessage
    ).toList();
  });
}
```

## AI Services

### DeckGeneratorService

Generates presentations using Gemini 2.5 Pro with structured output:

```dart
final service = DeckGeneratorService(apiKey: apiKey);
final result = await service.generate(prompt);

if (result.success) {
  // Presentation saved to .superdeck/superdeck.json
  print('Generated ${result.slideCount} slides');
}
```

### ImageGeneratorService

Generates background images using Gemini 2.5 Flash Image:

```dart
final service = ImageGeneratorService(apiKey: apiKey);
final result = await service.generateImage(prompt);
if (result.success) {
  // result.bytes contains image data
} else {
  // result.error contains error message
}
```

## Commands

```bash
# Run the app
flutter run --dart-define=GOOGLE_AI_API_KEY=your_key

# Run tests
flutter test

# Run specific test
flutter test test/chat/viewmodel/chat_viewmodel_test.dart

# Analyze code
flutter analyze

# Format code
dart format .

# Generate ACK types
flutter pub run build_runner build --delete-conflicting-outputs
```

## Project Structure Details

### Core AI Layer

- **`catalog/`** - GenUI component definitions with schemas
- **`prompts/`** - System instructions and enum definitions (fonts, image styles)
- **`schemas/`** - JSON schema definitions for structured output
- **`services/`** - AI service classes (DeckGeneratorService, ImageGeneratorService)

### Key Files

| File | Purpose |
|------|---------|
| `lib/chat/viewmodel/chat_viewmodel.dart` | Core conversation state management |
| `lib/core/ai/catalog/catalog.dart` | GenUI component registration |
| `lib/core/ai/services/deck_generator_service.dart` | Presentation generation |
| `lib/core/ai/prompts/prompt_registry.dart` | Asset-based prompt loading |
| `lib/core/ai/schemas/deck_schemas.dart` | Presentation output schemas |

## Testing

Tests are located in `/test/` mirroring the `lib/` structure:

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Test Patterns

- Use `setUp()` and `tearDown()` for ViewModel lifecycle
- Test Signals by accessing `.value` property
- Mock external dependencies (GenUI, API calls)

## Debugging

### Debug Mode

Toggle debug mode in the chat to see:
- Surface add/update/delete events
- JSON payloads from AI responses
- User action dispatches

### Debug Logging

Logs are written to `debug_log.txt` with timestamps and categories:

```dart
debugLog.log('GEN', 'Starting generation...');
debugLog.error('API', 'Request failed: $error');
debugLog.userAction('SEND_MESSAGE', {'message': text});
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GOOGLE_AI_API_KEY` | Google Generative AI API key | Yes |

## Routes

| Path | Screen | Description |
|------|--------|-------------|
| `/chat` | ChatScreen | Main chat interface (initial) |
| `/presentation/creating` | CreatingPresentationScreen | Generation loading state |
| `/presentation` | SuperDeckApp | Presentation viewer |

## Available Gemini Models

```dart
enum GeminiModels {
  gemini25Pro('models/gemini-2.5-pro'),
  gemini25Flash('models/gemini-2.5-flash'),
  gemini3FlashPreview('models/gemini-3-flash-preview');  // Default
}
```

## Documentation

- **CLAUDE.md** - Detailed project documentation for AI assistants
- **docs/gemini-structured-output-research.md** - Schema design best practices

## Dependencies

### Git Dependencies

| Package | Repository |
|---------|------------|
| remix | github.com/btwld/remix.git |
| superdeck | github.com/btwld/superdeck.git |
| ack | github.com/btwld/ack |

## Contributing

1. Follow the code patterns documented in `CLAUDE.md`
2. Use Signals for state management (not ChangeNotifier)
3. Add tests for new ViewModels and services
4. Run `flutter analyze` before committing

## License

[Add license information]
