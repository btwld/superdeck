# Playground Architecture — Provider + Command (no Signals)

> Proposed re-architecture of `packages/playground` following the layered
> approach from the `flutter-folder-architecture` and `flutter-state-management`
> skills — adapted to a **single package, folders only** (no nested packages).
>
> **Goal:** replace all `signals` / `Signal` / `Computed` state with
> `ChangeNotifier` **Stores**, the **Command** pattern for async actions, and
> **Provider** for dependency injection. `Result<T>` wraps every repository call.

---

## Guiding Principles

| Concern | Old (current) | New (proposed) |
|---|---|---|
| Reactive state | `Signal<T>` / `Computed<T>` | `ChangeNotifier` Store + `context.watch/select` |
| Async lifecycle (loading/error/success) | Manual `isProcessing`/`error` signals inside view-models | `Command0<T>` / `Command1<T, A>` |
| Dependency injection | Ad-hoc constructors + `ViewModelScope` | `Provider` / `MultiProvider` at route level |
| Error handling | thrown exceptions / nullable error signals | `Result<T>` (`Ok` / `Failure`) returned by repositories |
| Ephemeral state (text, focus, scroll) | mixed into stores | `StatefulWidget` + `dispose()` |

**Dependency rule (between folders):** `presentation → domain ← data`.
Domain depends on nothing. Enforced by convention + relative imports, not package
boundaries.

Copy the bundled base classes into the codebase first:
- `Result<T>` → `lib/core/result.dart`
- `Command<T>` / `Command0` / `Command1` → `lib/core/command.dart`

---

## Target Folder Layout (single package)

Keep everything inside `packages/playground/lib`. Instead of one `stores/` +
`utils/` dump and mixed feature files, give each feature the three layers plus
routes, and put cross-feature domain/data in `lib/core/`.

```
packages/playground/lib/
  main.dart
  app/
    router.dart                    # GoRouter combining feature routes
    providers.dart                 # app-root MultiProvider (global stores + repos)

  core/                            # shared, cross-feature domain + data
    result.dart                    # Result<T> base
    command.dart                   # Command / Command0 / Command1 base
    domain/
      models/                      # DeckDocument, SlideModel, TextLevel, GeminiModel...
      stores/                      # DeckDocumentStore, DeckCustomizationStore, SlideConfigurationStore
      repositories/                # DeckRepository, AssetCacheRepository (abstract)
    data/
      repositories/                # InMemoryDeckRepository, MemoryAssetCacheRepository
      data_sources/                # MemoryDeckLoader, asset cache source
      mappers/                     # markdown <-> DeckDocument

  features/
    ai/
      domain/
        models/                    # ConversationMessage, GenerationPhase, ImageGenerationProgress
        repositories/              # DeckGenerationRepository, ConversationRepository (abstract)
        stores/                    # ConversationStore, GenerationStore, DeckToolsStore
        commands/                  # GenerateDeckCommand, GenerateImageCommand, SendMessageCommand, ApplyDeckEditCommand
      data/
        repositories/              # DeckGenerationRepositoryImpl, ConversationRepositoryImpl
        data_sources/              # deck_generator_pipeline, image_generator_source, superdeck_agent_client, genui_conversation_session
        mappers/                   # deck_schema_mapper
      presentation/
        pages/                     # ai_progress_page, conversation_page, deck_edit_page
        widgets/                   # chat_bubble, chat_input, model_select, typing_indicator, ai_generate_panel, catalog/*
      routes/
        routes.dart

    editor/
      domain/
        stores/                    # EditorStore
        commands/                  # RefreshThumbnailsCommand
      presentation/
        pages/                     # editor_page
        widgets/                   # customization_sidebar, preview_sidebar, color_control, text_editor
      routes/
        routes.dart

    presentation/                  # the "play/preview" feature
      presentation/
        pages/                     # presentation_page
        widgets/                   # empty_state
      routes/
        routes.dart
```

> The three layers are **folders**, not packages. The dependency rule is upheld by
> discipline: nothing in `presentation/` imports from `data/`. Optionally enforce
> later with a lint (`import_lint` / custom_lint) rather than package boundaries.

---

## State Inventory Migration

Every state construct found today maps to exactly one new pattern.

| Current construct | File (today) | New pattern | New folder |
|---|---|---|---|
| `AiConversationViewModel` (signals: model, surfaceIds, messages, isThinking…) | `features/ai/core/ai/services/ai_conversation_viewmodel.dart` | Split: **ConversationStore** (state) + **SendMessageCommand** / **StartConversationCommand** | `features/ai/domain/{stores,commands}/` |
| `AiStore` (isGenerating, phase, prompt, error, imageProgress) | `stores/ai_store.dart` | **GenerationStore** (phase, prompt, imageProgress) + **GenerateDeckCommand** (owns running/error) | `features/ai/domain/{stores,commands}/` |
| `DeckToolsService` (`_outstandingSideEffects`, `isSideEffectQueueIdle`) | `features/ai/core/tools/deck_tools_service.dart` | **DeckToolsStore** (counter + idle getter) | `features/ai/domain/stores/` |
| `DeckToolsAdapter` (`_activeInvocations`, `isIdle`) | `features/ai/core/tools/deck_tools_adapter.dart` | fold into **DeckToolsStore** | `features/ai/domain/stores/` |
| `DeckStore` / `InMemoryDeckStore` (in-memory deck document) | `features/ai/core/tools/{deck_store,in_memory_deck_store}.dart` | **DeckRepository** interface + **InMemoryDeckRepository** impl (returns `Result<T>`) | `core/{domain/repositories,data/repositories}/` |
| `DeckEditCoordinator` (session orchestration) | `features/ai/deck_edit/deck_edit_coordinator.dart` | **ApplyDeckEditCommand** + reads DeckDocumentStore | `features/ai/domain/commands/` |
| `DeckCustomizationStore` (background, per-`TextLevel` signals, computed SlideStyler) | `stores/deck_customization_store.dart` | **DeckCustomizationStore** as `ChangeNotifier`; computed `slideStyle` → plain getter | `core/domain/stores/` (shared: editor + AI) |
| `EditorState` (`activeSlideIndex`) | `stores/editor_state.dart` | **EditorStore** (`activeSlideIndex`, setters) | `features/editor/domain/stores/` |
| `SlideConfigurationStore` (already `ChangeNotifier`) | `stores/slide_configuration_store.dart` | Keep as `ChangeNotifier`; move to core domain | `core/domain/stores/` |
| `TextEditorController` | `utils/text_editor_controller.dart` | **Ephemeral** — owned by editor `StatefulWidget`, disposed | `features/editor/presentation/widgets/` |
| `MemoryAssetCacheStore` | `utils/memory_asset_cache_store.dart` | **AssetCacheRepository** interface + **MemoryAssetCacheRepository** | `core/{domain/repositories,data/repositories}/` |
| `deck_generator_service` / `deck_generator_pipeline` / `image_generator_service` | `features/ai/core/ai/services/*` | **Data sources** behind `DeckGenerationRepository`; commands call the repo | `features/ai/data/data_sources/` + `features/ai/domain/repositories/` |
| `_ThumbnailRefresher` (effects) | `features/editor/thumbnail_refresher.dart` | **RefreshThumbnailsCommand** triggered via store listeners at the route | `features/editor/domain/commands/` |
| Widget `State<T>` (`_TextEditorState`, `_ColorControlState`, `_PresentationPageState`, typing indicators…) | various | Stay **ephemeral** `StatefulWidget` | respective `presentation/` |

**Rule of thumb applied:**
- Signal holding data → **Store** (`ChangeNotifier`).
- Signal tracking an in-flight async op (`isProcessing`, `isGenerating`, `error`) → folded into a **Command**'s `running` / `error` / `completed`.
- Anything wrapping external I/O (deck store, asset cache, generator services, gemini client) → **Repository + data source** returning `Result<T>`.
- `effect()` side-effects → **Commands** invoked from callbacks or `addListener` wiring at the route level.

---

## Feature: `features/ai`

### Example — GenerateDeckCommand (replaces `AiStore.isGenerating`/`error` + service call)

```dart
typedef GenerateParams = ({String prompt, GeminiModel model});

class GenerateDeckCommand extends Command1<DeckDocument, GenerateParams> {
  final DeckGenerationRepository _repository;
  final GenerationStore _generation;
  final DeckDocumentStore _document;

  GenerateDeckCommand(this._repository, this._generation, this._document);

  @override
  Future<Result<DeckDocument>> action(GenerateParams params) async {
    _generation.setPhase(GenerationPhase.outlining);
    final result = await _repository.generateDeck(params.prompt, params.model);
    if (result is Ok<DeckDocument>) {
      _document.setDeck(result.value);
      _generation.setPhase(GenerationPhase.done);
    }
    return result; // command exposes running/error/completed automatically
  }
}
```

Widgets no longer read an `isGenerating` signal — they watch the command:

```dart
final generate = context.watch<GenerateDeckCommand>();
if (generate.running) return const GenerationProgressView();
if (generate.error)   return const GenerationErrorView();
```

### Example — ConversationStore (pure state, no async)

```dart
class ConversationStore extends ChangeNotifier {
  final List<ConversationMessage> _messages = [];
  List<ConversationMessage> get messages => List.unmodifiable(_messages);

  GeminiModel _model = GeminiModel.flash;
  GeminiModel get model => _model;

  bool get hasStarted => _messages.isNotEmpty;

  void addMessage(ConversationMessage m) { _messages.add(m); notifyListeners(); }
  void setModel(GeminiModel m) { _model = m; notifyListeners(); }
}
```

---

## Feature: `features/editor`

- `DeckCustomizationStore` lives in `core/domain/stores/` (shared) because both the
  editor and the AI deck-edit flow mutate it.
- `TextEditorController` stays **ephemeral** inside `_TextEditorState` — never a store.
- Thumbnail regeneration: instead of three `effect()`s, register listeners at the
  route and invoke `RefreshThumbnailsCommand` when `EditorStore` /
  `DeckDocumentStore` / `DeckCustomizationStore` notify.

## Feature: `features/presentation`

No feature-specific store — the page reads the shared `DeckDocumentStore` and
`EditorStore.activeSlideIndex`.

---

## Shared (core) Stores & Repositories

`lib/core/domain`:
- **`DeckDocumentStore`** (`ChangeNotifier`) — single source of truth for the live
  deck (slides/markdown). Replaces `InMemoryDeckStore` as *state*; IO becomes `DeckRepository`.
- **`DeckCustomizationStore`** (`ChangeNotifier`) — background color, per-`TextLevel`
  color/size/weight/family; `SlideStyler get slideStyle` becomes a computed getter.
- **`SlideConfigurationStore`** — already a `ChangeNotifier`, moved here as-is.

`lib/core/data`:
- **`DeckRepository`** / **`InMemoryDeckRepository`** — read/write deck document, return `Result<T>`.
- **`AssetCacheRepository`** / **`MemoryAssetCacheRepository`** — generated-image cache.

---

## Dependency Injection (Provider)

`lib/app/providers.dart` — app-root globals:

```dart
MultiProvider(
  providers: [
    // Repositories (data layer, single instances)
    Provider<DeckRepository>(create: (_) => InMemoryDeckRepository(...)),
    Provider<AssetCacheRepository>(create: (_) => MemoryAssetCacheRepository()),
    Provider<DeckGenerationRepository>(create: (_) =>
        DeckGenerationRepositoryImpl(DeckGeneratorPipeline(...))),

    // Global stores
    ChangeNotifierProvider(create: (_) => DeckDocumentStore()),
    ChangeNotifierProvider(create: (_) => DeckCustomizationStore()),
    ChangeNotifierProvider(create: (_) => SlideConfigurationStore()),
  ],
  child: const PlaygroundApp(),
);
```

Feature routes provide feature stores + commands, wiring dependencies from context:

```dart
GoRoute aiRoute() => GoRoute(
  path: '/ai',
  builder: (context, state) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ConversationStore()),
      ChangeNotifierProvider(create: (_) => GenerationStore()),
      ChangeNotifierProvider(create: (_) => DeckToolsStore()),
      ChangeNotifierProvider(create: (ctx) => GenerateDeckCommand(
        ctx.read<DeckGenerationRepository>(),
        ctx.read<GenerationStore>(),
        ctx.read<DeckDocumentStore>(),
      )),
      ChangeNotifierProvider(create: (ctx) => SendMessageCommand(
        ctx.read<ConversationRepository>(),
        ctx.read<ConversationStore>(),
      )),
    ],
    child: const ConversationPage(),
  ),
);
```

`ViewModelScope` is removed — Provider replaces its create/dispose lifecycle.

---

## Consumption Rules in Widgets

| Need | API |
|---|---|
| Rebuild on any store change | `context.watch<Store>()` in `build()` |
| Rebuild on one property only | `context.select<Store, R>((s) => s.prop)` |
| One-off read in a callback | `context.read<Command>()` |
| Trigger async action | `onPressed: () => context.read<GenerateDeckCommand>().call(params)` |
| React to loading/error | `context.watch<GenerateDeckCommand>().running / .error / .completed` |

---

## Migration Order (incremental, low-risk)

1. **Add base classes** — `Result<T>`, `Command` into `lib/core/` (no behavior change).
2. **Create the folder skeleton** — `app/`, `core/{domain,data}`, per-feature `{domain,data,presentation,routes}`. Move files without changing logic yet.
3. **Convert leaf stores first** — `EditorState` → `EditorStore`; `DeckCustomizationStore` signals → `ChangeNotifier` fields + getters. Swap call sites to `context.watch/select`.
4. **Introduce repositories** — wrap deck store, asset cache, generator services; return `Result<T>`.
5. **Extract Commands** — move async logic out of `AiConversationViewModel` / `AiStore` / `DeckEditCoordinator` into `Command0/1`; delete `isProcessing` / `isGenerating` / `error` signals.
6. **Wire Provider at routes** — replace `ViewModelScope` and manual constructors.
7. **Delete the `signals` dependency** once no `Signal`/`Computed`/`effect` remain.

---

## Common Mistakes to Avoid (from the skills)

- ❌ `TextEditingController` in a store → keep it ephemeral in a `StatefulWidget`, dispose it.
- ❌ Async logic inside a store → move to a Command.
- ❌ Command without a repository → commands call repositories, not raw services/clients directly.
- ❌ Presentation importing from `data/` → presentation uses only `domain/` (stores + commands).
- ❌ Repository not returning `Result<T>` → always wrap in `Ok`/`Failure`.
- ❌ Duplicating shared state per feature → `DeckDocumentStore` / `DeckCustomizationStore` live once in `core/`.
