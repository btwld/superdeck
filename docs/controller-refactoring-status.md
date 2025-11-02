# Controller Refactoring - Implementation Status

**Last Updated:** 2025-11-02
**Current Phase:** Phase 2 - Extract DeckService (Ready to Start)
**Overall Progress:** 1/7 phases complete (14%)

## Executive Summary

Converting Superdeck's controller architecture from ChangeNotifier-based pattern to a Signals-based facade pattern with service extraction. The refactoring follows a 7-phase incremental approach to minimize regressions and maintain test coverage throughout.

### Goal Architecture

```
DeckController (facade with signals)
├── DeckService (deck loading, file operations)
├── NavigationService (routing, slide navigation)
└── ThumbnailService (thumbnail generation)
```

### Current Architecture

```
DeckController (signals-based, ChangeNotifier removed) ✅
NavigationController (ChangeNotifier) - Phase 3-4
ThumbnailController (ChangeNotifier) - Phase 5
DeckRepository (file operations) - Phase 2
```

---

## Phase 1: Signals in DeckController ✅ COMPLETE

**Duration:** 45 minutes
**Status:** ✅ Complete
**Date Completed:** 2025-11-02

### Objectives

- Convert DeckController from `extends ChangeNotifier` to Signals-based reactive state
- Replace `notifyListeners()` with signal mutations
- Update all UI widgets to use `Watch` instead of `ListenableBuilder`
- Replace listener management with `effect()` pattern
- Expose all signals as `ReadonlySignal<T>` to prevent external mutation

### What Was Changed

#### 1. Added Signals Dependency

**File:** `packages/superdeck/pubspec.yaml`

```yaml
dependencies:
  signals_flutter: ^6.2.0
```

#### 2. Converted DeckController to Signals

**File:** `packages/superdeck/lib/src/deck/deck_controller.dart`

**Before (ChangeNotifier pattern):**
```dart
class DeckController extends ChangeNotifier {
  bool _isMenuOpen = false;
  bool get isMenuOpen => _isMenuOpen;

  void openMenu() {
    _isMenuOpen = true;
    notifyListeners();  // Manual notification
  }

  @override
  void dispose() {
    super.dispose();
  }
}
```

**After (Signals pattern):**
```dart
class DeckController {
  // Private mutable signals
  final _isMenuOpen = signal<bool>(false);
  final _isNotesOpen = signal<bool>(false);
  final _isRebuilding = signal<bool>(false);
  final _loadingState = signal<DeckLoadingState>(DeckLoadingState.idle);
  final _currentDeck = signal<Deck?>(null);
  final _error = signal<Object?>(null);
  final _options = signal<DeckOptions>(DeckOptions());

  // Public readonly getters - prevents external mutation
  ReadonlySignal<DeckLoadingState> get loadingState => _loadingState;
  ReadonlySignal<Object?> get error => _error;
  ReadonlySignal<DeckOptions> get options => _options;
  ReadonlySignal<bool> get isMenuOpen => _isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _isNotesOpen;
  ReadonlySignal<bool> get isRebuilding => _isRebuilding;

  // Computed signals - automatically derived, always readonly
  late final ReadonlySignal<List<SlideConfiguration>> slides = computed(() {
    final deck = _currentDeck.value;
    if (deck == null) return <SlideConfiguration>[];
    return _slideBuilder.buildConfigurations(deck.slides, _options.value);
  });

  late final ReadonlySignal<int> totalSlides = computed(() => slides.value.length);
  late final ReadonlySignal<bool> isLoading = computed(
    () => _loadingState.value == DeckLoadingState.loading,
  );
  late final ReadonlySignal<bool> hasError = computed(
    () => _loadingState.value == DeckLoadingState.error,
  );

  // Methods now just mutate signals - automatic reactivity
  void openMenu() => _isMenuOpen.value = true;
  void closeMenu() => _isMenuOpen.value = false;
  void toggleNotes() => _isNotesOpen.value = !_isNotesOpen.value;

  // Dispose all signals
  void dispose() {
    _loadingState.dispose();
    _currentDeck.dispose();
    _error.dispose();
    _options.dispose();
    _isMenuOpen.dispose();
    _isNotesOpen.dispose();
    _isRebuilding.dispose();
    slides.dispose();
    totalSlides.dispose();
    isLoading.dispose();
    hasError.dispose();
  }
}
```

**Key Changes:**
- ❌ Removed `extends ChangeNotifier`
- ❌ Removed all `notifyListeners()` calls
- ✅ Added private `signal<T>()` fields with `_` prefix
- ✅ Added public `ReadonlySignal<T>` getters
- ✅ Added `computed()` signals for derived state
- ✅ Simplified methods to direct signal mutation
- ✅ Updated dispose to dispose all signals

#### 3. Updated UI Widgets

**Pattern Change:** `ListenableBuilder` → `Watch`

##### File: `packages/superdeck/lib/src/ui/panels/bottom_bar.dart`

**Before:**
```dart
Widget build(BuildContext context) {
  final deckController = DeckController.of(context);

  return FlexBox(
    children: [
      SDIconButton(
        onPressed: deckController.toggleNotes,
        icon: deckController.isNotesOpen  // Direct access
          ? Icons.comment
          : Icons.comments_disabled,
      ),
      Text(
        '${navigationController.currentIndex + 1} of ${deckController.totalSlides}',
        style: const TextStyle(color: Colors.white),
      ),
    ],
  );
}
```

**After:**
```dart
import 'package:signals_flutter/signals_flutter.dart';

Widget build(BuildContext context) {
  final deckController = DeckController.of(context);

  return FlexBox(
    children: [
      // Wrap each reactive widget in Watch
      Watch((context) => SDIconButton(
        onPressed: deckController.toggleNotes,
        icon: deckController.isNotesOpen.value  // Access .value
          ? Icons.comment
          : Icons.comments_disabled,
      )),

      Watch((context) => Text(
        '${navigationController.currentIndex + 1} of ${deckController.totalSlides.value}',
        style: const TextStyle(color: Colors.white),
      )),
    ],
  );
}
```

##### File: `packages/superdeck/lib/src/ui/app_shell.dart`

**Before (Listener management):**
```dart
class _AppShellState extends State<AppShell> {
  DeckController? _deckController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = DeckController.of(context);

    if (_deckController != newController) {
      _deckController?.removeListener(_onMenuStateChanged);
      _deckController = newController;
      _deckController!.addListener(_onMenuStateChanged);
    }
  }

  void _onMenuStateChanged() {
    if (!mounted) return;
    final isMenuOpen = _deckController!.isMenuOpen;
    if (isMenuOpen && _animationController.value != 1.0) {
      _animationController.forward();
    } else if (!isMenuOpen && _animationController.value != 0.0) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _deckController?.removeListener(_onMenuStateChanged);
    super.dispose();
  }
}
```

**After (Effect pattern):**
```dart
import 'package:signals_flutter/signals_flutter.dart';

class _AppShellState extends State<AppShell> {
  EffectCleanup? _menuEffectCleanup;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deckController = DeckController.of(context);

    // Clean up previous effect
    _menuEffectCleanup?.call();

    // Create new effect that reacts to menu state changes
    _menuEffectCleanup = effect(() {
      if (!mounted) return;

      // Read the signal - this establishes the dependency
      final isMenuOpen = deckController.isMenuOpen.value;

      // React to changes
      if (isMenuOpen && _animationController.value != 1.0) {
        _animationController.forward();
      } else if (!isMenuOpen && _animationController.value != 0.0) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _menuEffectCleanup?.call();  // Clean up effect
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deckController = DeckController.of(context);

    // Replace ListenableBuilder with Watch
    return Watch((context) {
      final isMenuOpen = deckController.isMenuOpen.value;
      final isRebuilding = deckController.isRebuilding.value;

      return Scaffold(
        floatingActionButton: !isMenuOpen
          ? SDIconButton(icon: Icons.menu, onPressed: deckController.openMenu)
          : null,
        body: Stack(
          children: [
            // ... layout code ...
            if (isRebuilding)
              Positioned(/* rebuilding indicator */),
          ],
        ),
      );
    });
  }
}
```

##### File: `packages/superdeck/lib/src/deck/slide_page_content.dart`

**Before:**
```dart
return ListenableBuilder(
  listenable: Listenable.merge([deckController, navigationController]),
  builder: (context, child) {
    final isLoading = deckController.isLoading;
    final hasError = deckController.hasError;
    final slides = deckController.slides;

    if (hasError) return _ErrorScreen(error: deckController.error);
    if (isLoading) return const _LoadingScreen();
    if (slides.isEmpty) return const _NoSlidesScreen();

    return SlideScreen(slides[index]);
  },
);
```

**After:**
```dart
import 'package:signals_flutter/signals_flutter.dart';

return Watch((context) {
  final isLoading = deckController.isLoading.value;
  final hasError = deckController.hasError.value;
  final slides = deckController.slides.value;

  if (hasError) return _ErrorScreen(error: deckController.error.value);
  if (isLoading) return const _LoadingScreen();
  if (slides.isEmpty) return const _NoSlidesScreen();

  return SlideScreen(slides[index]);
});
```

##### File: `packages/superdeck/lib/src/deck/deck_provider.dart`

**ThumbnailSyncManager changes:**

**Before:**
```dart
@override
Widget build(BuildContext context) {
  final deckController = DeckProvider.of(context);
  final thumbnailController = ThumbnailController.of(context);

  return ListenableBuilder(
    listenable: deckController,
    builder: (context, child) {
      final slides = deckController.slides;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          thumbnailController.generateThumbnails(slides, context);
        }
      });

      return child!;
    },
    child: widget.child,
  );
}
```

**After:**
```dart
import 'package:signals_flutter/signals_flutter.dart';

@override
Widget build(BuildContext context) {
  final deckController = DeckProvider.of(context);
  final thumbnailController = ThumbnailController.of(context);

  return Watch((context) {
    final slides = deckController.slides.value;  // Access signal value

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        thumbnailController.generateThumbnails(slides, context);
      }
    });

    return widget.child;
  });
}

// Also updated callback in DeckControllerBuilder
_navigationController = NavigationController(
  getTotalSlides: () => _deckController.totalSlides.value,  // Access signal value
);
```

#### 4. Fixed Signal Access Sites

**File:** `packages/superdeck/lib/src/export/pdf_export_screen.dart`

**Before:**
```dart
static void show(BuildContext context) {
  final deckController = DeckController.of(context);
  showRemixDialog(
    context: context,
    builder: (context) => PdfExportDialogScreen(
      slides: deckController.slides,  // Signal passed directly
    ),
  );
}
```

**After:**
```dart
static void show(BuildContext context) {
  final deckController = DeckController.of(context);
  showRemixDialog(
    context: context,
    builder: (context) => PdfExportDialogScreen(
      slides: deckController.slides.value,  // Access signal value
    ),
  );
}
```

#### 5. Cleanup

- Removed unused import `package:collection/collection.dart` from `block_widget.dart`
- Removed redundant import `package:signals/signals.dart` from `app_shell.dart` (already imported via `signals_flutter`)

### Files Modified (8 files)

1. `packages/superdeck/pubspec.yaml` - Added signals_flutter dependency
2. `packages/superdeck/lib/src/deck/deck_controller.dart` - Complete signals conversion
3. `packages/superdeck/lib/src/ui/panels/bottom_bar.dart` - Uses Watch widget
4. `packages/superdeck/lib/src/ui/app_shell.dart` - Uses effect() and Watch
5. `packages/superdeck/lib/src/deck/slide_page_content.dart` - Uses Watch
6. `packages/superdeck/lib/src/deck/deck_provider.dart` - ThumbnailSyncManager uses Watch
7. `packages/superdeck/lib/src/export/pdf_export_screen.dart` - Accesses signal values
8. `packages/superdeck/lib/src/rendering/blocks/block_widget.dart` - Removed unused import

### Test Results

```
✅ All 119 tests passing
✅ Zero analyzer issues
✅ Zero runtime errors
```

### Key Learnings

1. **ReadonlySignal Pattern**: Use `ReadonlySignal<T>` return types for public getters to prevent external mutation
2. **Effect Pattern**: Replace listener management with `effect()` for side effects
3. **Watch Widget**: Wrap reactive UI in `Watch((context) { ... })` instead of `ListenableBuilder`
4. **Signal Access**: Always use `.value` to read signal values outside of computed signals
5. **Computed Signals**: Automatically track dependencies and return `ReadonlySignal<T>`

### Why This Was Done First

Phase 1 establishes the **reactive foundation** before extracting services. This allows:
- DeckController to maintain its current responsibilities while switching state mechanism
- UI to adapt to signals pattern before facade consolidation
- Tests to verify signals work correctly with existing architecture
- Incremental validation at each step

---

## Phase 2: Extract DeckService 🔄 NEXT

**Duration:** 30 minutes (estimated)
**Status:** 🔄 Ready to Start
**Dependencies:** Phase 1 ✅

### Objectives

- Extract stateless deck operations from DeckController into new DeckService
- Keep DeckController as the reactive state container
- DeckController delegates file operations to DeckService
- Maintain all existing tests passing

### What Will Change

#### Create New File: `packages/superdeck/lib/src/deck/deck_service.dart`

```dart
/// Service for deck data operations (loading, file operations)
///
/// Stateless service that handles all deck data operations.
/// DeckController owns the reactive state and delegates to this service.
class DeckService {
  final DeckRepository _repository;
  final SlideConfigurationBuilder _slideBuilder;

  DeckService({
    required DeckRepository repository,
  }) : _repository = repository,
       _slideBuilder = SlideConfigurationBuilder(
         configuration: repository.configuration,
       );

  /// Load deck stream
  Stream<Deck> loadDeckStream() {
    return _repository.loadDeckStream();
  }

  /// Build slide configurations from deck
  List<SlideConfiguration> buildConfigurations(
    List<Slide> slides,
    DeckOptions options,
  ) {
    return _slideBuilder.buildConfigurations(slides, options);
  }

  /// Access to repository for error retry
  DeckRepository get repository => _repository;
}
```

#### Modify: `packages/superdeck/lib/src/deck/deck_controller.dart`

**Changes:**
- Remove `_repository` and `_slideBuilder` fields
- Add `_service` field of type `DeckService`
- Delegate `_startDeckStream()` to `_service.loadDeckStream()`
- Update `slides` computed signal to use `_service.buildConfigurations()`
- Update `repository` getter to return `_service.repository`

**Before:**
```dart
class DeckController {
  final DeckRepository _repository;
  final SlideConfigurationBuilder _slideBuilder;

  late final ReadonlySignal<List<SlideConfiguration>> slides = computed(() {
    final deck = _currentDeck.value;
    if (deck == null) return <SlideConfiguration>[];
    return _slideBuilder.buildConfigurations(deck.slides, _options.value);
  });

  DeckRepository get repository => _repository;

  DeckController({
    required DeckRepository repository,
    required DeckOptions options,
  }) : _repository = repository,
       _slideBuilder = SlideConfigurationBuilder(
         configuration: repository.configuration,
       ) {
    _options.value = options;
    _startDeckStream();
  }

  void _startDeckStream() {
    _loadingState.value = DeckLoadingState.loading;
    _deckSubscription = _repository.loadDeckStream().listen(
      // ...
    );
  }
}
```

**After:**
```dart
class DeckController {
  final DeckService _service;

  late final ReadonlySignal<List<SlideConfiguration>> slides = computed(() {
    final deck = _currentDeck.value;
    if (deck == null) return <SlideConfiguration>[];
    return _service.buildConfigurations(deck.slides, _options.value);
  });

  DeckRepository get repository => _service.repository;

  DeckController({
    required DeckService service,
    required DeckOptions options,
  }) : _service = service {
    _options.value = options;
    _startDeckStream();
  }

  void _startDeckStream() {
    _loadingState.value = DeckLoadingState.loading;
    _deckSubscription = _service.loadDeckStream().listen(
      // ...
    );
  }
}
```

#### Modify: `packages/superdeck/lib/src/deck/deck_provider.dart`

Update DeckControllerBuilder to create DeckService and pass to DeckController:

**Before:**
```dart
@override
void initState() {
  super.initState();

  final configuration = DeckConfiguration();
  final repository = DeckRepository(configuration: configuration);

  _deckController = DeckController(
    repository: repository,
    options: widget.options,
  );
  // ...
}
```

**After:**
```dart
@override
void initState() {
  super.initState();

  final configuration = DeckConfiguration();
  final repository = DeckRepository(configuration: configuration);
  final deckService = DeckService(repository: repository);

  _deckController = DeckController(
    service: deckService,
    options: widget.options,
  );
  // ...
}
```

### Files to Modify (3 files)

1. **NEW** `packages/superdeck/lib/src/deck/deck_service.dart` - Create new service
2. `packages/superdeck/lib/src/deck/deck_controller.dart` - Delegate to service
3. `packages/superdeck/lib/src/deck/deck_provider.dart` - Instantiate service

### Validation

- ✅ Run `flutter analyze` - no issues
- ✅ Run `flutter test` - all 119 tests pass
- ✅ No behavior changes in UI
- ✅ DeckController still reactive with signals
- ✅ Service is stateless and testable

---

## Phase 3: Signals in NavigationController

**Duration:** 30 minutes (estimated)
**Status:** ⏳ Pending (Phase 2 must complete first)
**Dependencies:** Phase 2

### Objectives

- Convert NavigationController from ChangeNotifier to Signals
- Keep as separate controller (not yet merged into DeckController)
- Update UI widgets that use NavigationProvider.of()
- Maintain router ownership in NavigationController

### What Will Change

Similar pattern to Phase 1, but for NavigationController:

1. Remove `extends ChangeNotifier`
2. Convert state to signals:
   - `_currentIndex` → `signal<int>(0)`
   - `_history` → `signal<List<int>>([])`
3. Expose readonly signals
4. Update methods to mutate signals
5. Update UI widgets using NavigationProvider.of()

### Files to Modify (4 files estimated)

1. `packages/superdeck/lib/src/deck/navigation_controller.dart`
2. `packages/superdeck/lib/src/ui/panels/bottom_bar.dart`
3. `packages/superdeck/lib/src/ui/panels/thumbnail_panel.dart`
4. Any other widgets using NavigationProvider.of()

---

## Phase 4: Extract NavigationService

**Duration:** 30 minutes (estimated)
**Status:** ⏳ Pending (Phase 3 must complete first)
**Dependencies:** Phase 3

### Objectives

- Extract stateless navigation logic into NavigationService
- NavigationController keeps reactive state, delegates to service
- Service handles route building, index validation, history tracking

### What Will Change

Create `NavigationService` with:
- Route building logic
- Index validation (clamp to valid range)
- History management algorithms
- Keyboard navigation logic

NavigationController becomes thinner, just reactive state + delegation.

### Files to Create/Modify

1. **NEW** `packages/superdeck/lib/src/deck/navigation_service.dart`
2. `packages/superdeck/lib/src/deck/navigation_controller.dart` - Delegate to service
3. `packages/superdeck/lib/src/deck/deck_provider.dart` - Instantiate service

---

## Phase 5: Extract ThumbnailService

**Duration:** 30 minutes (estimated)
**Status:** ⏳ Pending (Phase 4 must complete first)
**Dependencies:** Phase 4

### Objectives

- Extract thumbnail generation logic into ThumbnailService
- ThumbnailController keeps reactive state, delegates to service
- Service handles async thumbnail generation

### What Will Change

Create `ThumbnailService` with:
- Thumbnail generation algorithm
- Slide capture coordination
- Async thumbnail processing

ThumbnailController becomes reactive state container + delegation.

### Files to Create/Modify

1. **NEW** `packages/superdeck/lib/src/export/thumbnail_service.dart`
2. `packages/superdeck/lib/src/export/thumbnail_controller.dart` - Delegate to service
3. `packages/superdeck/lib/src/deck/deck_provider.dart` - Instantiate service

---

## Phase 6: Consolidate into DeckController Facade

**Duration:** 45 minutes (estimated)
**Status:** ⏳ Pending (Phase 5 must complete first)
**Dependencies:** Phase 5

### Objectives

- Merge NavigationController and ThumbnailController state into DeckController
- DeckController becomes single facade with all signals
- DeckController owns router
- DeckController internally delegates to all three services
- Remove separate NavigationProvider and ThumbnailController.of() access
- All UI uses only DeckController.of()

### Target Architecture

```dart
class DeckController {
  // Services (private)
  final DeckService _deckService;
  final NavigationService _navigationService;
  final ThumbnailService _thumbnailService;

  // Router (owned by controller)
  late final GoRouter router;

  // Deck state signals
  ReadonlySignal<List<SlideConfiguration>> get slides;
  ReadonlySignal<bool> get isLoading;
  ReadonlySignal<bool> get hasError;
  // ...

  // Navigation state signals (merged from NavigationController)
  ReadonlySignal<int> get currentSlideIndex;
  ReadonlySignal<int> get totalSlides;

  // Thumbnail state signals (merged from ThumbnailController)
  ReadonlySignal<List<Uint8List?>> get thumbnails;
  ReadonlySignal<bool> get isGenerating;

  // UI state signals
  ReadonlySignal<bool> get isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen;

  // Navigation methods (delegate to NavigationService)
  void goToSlide(int index);
  void nextSlide();
  void previousSlide();
  void goBack();

  // Deck methods (delegate to DeckService)
  Future<void> reload();
  void updateOptions(DeckOptions options);

  // Thumbnail methods (delegate to ThumbnailService)
  Future<void> regenerateThumbnails();

  // UI methods
  void openMenu();
  void closeMenu();
  void toggleNotes();
}
```

### What Will Change

1. **Move navigation state into DeckController**
   - `currentSlideIndex` signal
   - `totalSlides` computed signal (already exists)
   - Navigation methods delegate to NavigationService

2. **Move thumbnail state into DeckController**
   - `thumbnails` signal
   - `isGenerating` signal
   - Thumbnail methods delegate to ThumbnailService

3. **Move router ownership to DeckController**
   - DeckController creates and owns GoRouter
   - NavigationService builds routes but doesn't own router

4. **Update all UI access patterns**
   - Remove `NavigationProvider.of(context)`
   - Remove `ThumbnailController.of(context)`
   - Everything uses `DeckController.of(context)`

5. **Simplify provider hierarchy**
   - Remove InheritedNotifierData for NavigationController
   - Remove InheritedNotifierData for ThumbnailController
   - Keep only DeckProvider

### Files to Modify (10+ files estimated)

1. `packages/superdeck/lib/src/deck/deck_controller.dart` - Add all state
2. `packages/superdeck/lib/src/deck/deck_provider.dart` - Simplify providers
3. `packages/superdeck/lib/src/deck/navigation_controller.dart` - DELETE
4. `packages/superdeck/lib/src/export/thumbnail_controller.dart` - DELETE
5. All UI files using NavigationProvider.of()
6. All UI files using ThumbnailController.of()

---

## Phase 7: Cleanup and Documentation

**Duration:** 30 minutes (estimated)
**Status:** ⏳ Pending (Phase 6 must complete first)
**Dependencies:** Phase 6

### Objectives

- Remove unused APIs (navigation history if not needed)
- Update documentation and comments
- Final test verification
- Performance check
- Update CLAUDE.md or AGENTS.md if needed

### Tasks

1. **Code Cleanup**
   - Remove navigation history APIs if unused
   - Remove any dead code paths
   - Verify all dispose() methods are correct
   - Check for any lingering ChangeNotifier references

2. **Documentation**
   - Update class documentation
   - Add examples of signals usage
   - Document facade pattern
   - Update README if needed

3. **Testing**
   - Verify all 119+ tests pass
   - Add integration tests if needed
   - Performance smoke test
   - Memory leak check (signal disposal)

4. **Final Validation**
   - Run analyzer
   - Run formatter
   - Visual regression test (manual)
   - Verify no console errors

### Files to Update

- Class documentation across all controller/service files
- This status document (mark as complete)
- Potentially AGENTS.md or README.md

---

## Technical Decisions

### Why Signals Instead of ChangeNotifier?

1. **Fine-grained reactivity**: Only widgets reading changed signals rebuild
2. **Automatic dependency tracking**: Computed signals track dependencies
3. **Immutable by default**: ReadonlySignal prevents external mutation
4. **Better composition**: Signals compose better than Listenable.merge()
5. **Cleaner code**: No manual notifyListeners() calls

### Why Service Extraction?

1. **Testability**: Services are stateless and easier to unit test
2. **Single Responsibility**: Controllers handle state, services handle logic
3. **Reusability**: Services can be used outside widget tree
4. **Clarity**: Clear separation of concerns

### Why Facade Pattern?

1. **Simplicity**: Single entry point for all deck state
2. **Cohesion**: All related state lives together
3. **Discoverability**: Easier to find what you need
4. **Type safety**: One controller type instead of three

### Why Incremental Phases?

1. **Risk mitigation**: Small changes are easier to validate
2. **Test coverage**: Tests verify each step works
3. **Rollback safety**: Can revert individual phases
4. **Team velocity**: Can pause/resume between phases

---

## Known Issues & Blockers

### Current (Phase 1)

None - Phase 1 complete ✅

### Anticipated (Future Phases)

1. **Router ownership handoff** (Phase 6)
   - GoRouter currently created in NavigationController
   - Need to carefully transfer to DeckController
   - May require BuildContext availability

2. **Thumbnail generation context** (Phase 6)
   - ThumbnailController.generateThumbnails() requires BuildContext
   - May need to refactor to not require context
   - Or pass context through DeckController methods

3. **Provider hierarchy simplification** (Phase 6)
   - Need to verify no hidden dependencies on nested providers
   - Test that single DeckProvider works for all use cases

---

## Testing Strategy

### Per-Phase Testing

After each phase:
1. Run `flutter analyze` - must show 0 issues
2. Run `flutter test` - all tests must pass
3. Manual smoke test - verify app runs without errors
4. Visual check - verify no UI regressions

### Integration Testing

After Phase 6 (consolidation):
1. Test all navigation flows
2. Test thumbnail generation
3. Test menu/notes toggling
4. Test error states
5. Test loading states
6. Test hot reload behavior

### Performance Testing

After Phase 7 (cleanup):
1. Verify signals dispose correctly (no memory leaks)
2. Check rebuild counts (should be lower than ChangeNotifier)
3. Verify computed signals don't over-compute
4. Test with large decks (100+ slides)

---

## Rollback Plan

If any phase fails:

1. **Immediate revert**: `git checkout packages/superdeck/`
2. **Document failure**: Add issue to Known Issues section
3. **Analyze root cause**: What went wrong?
4. **Adjust plan**: Update phase plan before retry
5. **Retry phase**: After plan adjustment

Each phase is small enough to revert individually.

---

## References

- [Dart Signals Documentation](https://dartsignals.dev)
- [Flutter Signals Package](https://pub.dev/packages/signals_flutter)
- [Original Refactoring Plan](./controller-refactoring-implementation-plan.md)
- [Final Architecture Plan](./controller-refactoring-final-plan.md)

---

## Appendix: Signals API Quick Reference

### Creating Signals

```dart
// Mutable signal (private)
final _count = signal<int>(0);

// Computed signal (automatically readonly)
late final total = computed(() => _count.value * 2);

// Batch updates (prevent multiple notifications)
batch(() {
  _count.value = 10;
  _name.value = 'new';
});
```

### Reading Signals

```dart
// In widgets - use Watch
Watch((context) => Text('Count: ${_count.value}'))

// In effects - auto-tracks dependencies
effect(() {
  print('Count changed: ${_count.value}');
});

// One-time read - use peek() to avoid tracking
final value = _count.peek();
```

### Exposing Signals

```dart
class MyController {
  // Private mutable
  final _count = signal<int>(0);

  // Public readonly
  ReadonlySignal<int> get count => _count;

  // Methods mutate
  void increment() => _count.value++;
}
```

### Disposing Signals

```dart
void dispose() {
  _count.dispose();
  total.dispose();  // Dispose computed signals too
}
```

### Effects

```dart
// Create effect
EffectCleanup? cleanup;

cleanup = effect(() {
  // Runs immediately and on signal changes
  print(_count.value);
});

// Cleanup
cleanup?.call();
```

---

**Document Version:** 1.0
**Maintained By:** Code Agent
**Project:** Superdeck Controller Refactoring
