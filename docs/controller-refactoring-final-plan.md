# Controller Refactoring - Final Implementation Plan

**Date**: 2025-01-01
**Architecture**: Facade Pattern with Dart Signals
**Approach**: DeckController as unified facade over stateless services

---

## Executive Summary

This plan consolidates all controller responsibilities into a single `DeckController` facade that uses **Dart Signals** for fine-grained reactivity. Internal services (`DeckService`, `NavigationService`, `ThumbnailService`) handle stateless operations while the controller manages all reactive state.

**Key Benefits**:
- ✅ Single provider (no nested provider hierarchy)
- ✅ Fine-grained reactivity with signals (surgical rebuilds)
- ✅ Unified API surface (`deck.nextSlide()` instead of `navigation.nextSlide()`)
- ✅ Proper encapsulation (options never exposed, internal APIs hidden)
- ✅ Testable (services can be mocked)

**Breaking Changes**:
- `NavigationProvider.of(context)` → `DeckController.of(context)`
- `ThumbnailController.of(context)` → `DeckController.of(context)`
- `DeckRepository` → `DeckService`

---

## Architecture Overview

### **Pattern: Facade + Composition**

```
┌─────────────────────────────────────────────┐
│          DeckController (Facade)            │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │   Signals (Reactive State)          │   │
│  │   - slides, currentIndex, isMenuOpen│   │
│  │   - Computed: totalSlides, canGoNext│   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │   Services (Stateless Operations)   │   │
│  │   - DeckService (file I/O)          │   │
│  │   - NavigationService (routing)     │   │
│  │   - ThumbnailService (generation)   │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
              ↓
        InheritedData
        (Simple, non-reactive)
              ↓
          Widget Tree
```

---

## Public API Design

### **Read-Only State (Computed Signals)**

Based on usage analysis, these are **actually needed** by consumers:

```dart
class DeckController {
  // === DECK STATE (read-only via computed) ===
  ReadonlySignal<List<SlideConfiguration>> get slides;
  ReadonlySignal<bool> get isLoading;
  ReadonlySignal<bool> get hasError;
  ReadonlySignal<Object?> get error;
  ReadonlySignal<int> get totalSlides;

  // === UI STATE (read-only via computed) ===
  ReadonlySignal<bool> get isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen;
  ReadonlySignal<bool> get isRebuilding;

  // === NAVIGATION STATE (read-only via computed) ===
  ReadonlySignal<int> get currentIndex;
  ReadonlySignal<bool> get isTransitioning;
  ReadonlySignal<bool> get canGoNext;
  ReadonlySignal<bool> get canGoPrevious;
  ReadonlySignal<SlideConfiguration?> get currentSlide;

  // === ROUTER (required by MaterialApp.router) ===
  GoRouter get router;
}
```

**Key insight**: All state is exposed as **ReadonlySignal** (computed), preventing external mutation.

### **Actions (Public Methods)**

```dart
class DeckController {
  // === DECK ACTIONS ===
  void updateOptions(DeckOptions options);  // Internal: called by DeckControllerBuilder
  void setRebuilding(bool value);           // Internal: called by CliWatcher

  // === UI ACTIONS ===
  void openMenu();
  void closeMenu();
  void toggleNotes();

  // === NAVIGATION ACTIONS ===
  Future<void> goToSlide(int index);
  Future<void> nextSlide();
  Future<void> previousSlide();

  // === THUMBNAIL ACTIONS ===
  void generateThumbnails(BuildContext context, {bool force = false});
  AsyncThumbnail? getThumbnail(String slideKey);

  // === LIFECYCLE ===
  void dispose();

  // === ACCESS ===
  static DeckController of(BuildContext context);
}
```

### **Private/Internal APIs (Not Exposed)**

```dart
// INTERNAL ONLY - not in public API
class DeckController {
  // Private fields
  final DeckService _deckService;
  final NavigationService _navigationService;
  final ThumbnailService _thumbnailService;

  // Private signals (implementation details)
  final Signal<DeckLoadingState> _loadingState;
  final Signal<DeckOptions> _options;  // NEVER exposed publicly
  final Signal<List<int>> _navigationHistory;  // Unused feature, removed

  // Internal methods
  void _startDeckStream();
  List<SlideConfiguration> _buildSlideConfigurations(Deck deck);

  // Internal navigation sync (called by SlidePageContent)
  @internal
  void updateCurrentIndex(int index);  // Marked internal

  // Internal event handling (called by NavigationManager)
  @internal
  void handleNavigationEvent(NavigationEvent event);  // Marked internal
}
```

---

## Implementation Phases

### **Phase 1: Add Signals & Create Services**

**Duration**: ~2 hours

#### 1.1 Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  signals: ^6.2.0
  signals_flutter: ^6.2.0
```

#### 1.2 Create DeckService

**File**: `packages/core/lib/src/deck_service.dart`

Rename `DeckRepository` → `DeckService`, keep implementation identical.

**Changes**:
- File rename: `deck_repository.dart` → `deck_service.dart`
- Class rename: `DeckRepository` → `DeckService`
- Update 35 import statements across 15 files

#### 1.3 Create NavigationService

**File**: `packages/superdeck/lib/src/deck/navigation_service.dart`

**New file** with stateless routing operations:

```dart
class NavigationService {
  static const _transitionDuration = Duration(seconds: 1);

  GoRouter createRouter({
    required void Function(int) onIndexChanged,
  }) {
    return GoRouter(
      initialLocation: '/slides/0',
      routes: [
        GoRoute(
          path: '/slides/:index',
          pageBuilder: (context, state) {
            final index = _parseIndex(state.pathParameters['index']);
            onIndexChanged(index); // Notify controller
            return CustomTransitionPage(
              key: ValueKey('slide-$index'),
              child: SlidePageContent(index: index),
              transitionDuration: _transitionDuration,
              transitionsBuilder: _fadeTransition,
            );
          },
        ),
      ],
    );
  }

  Future<void> goToSlide({
    required GoRouter router,
    required int targetIndex,
    required int totalSlides,
    required void Function() onTransitionStart,
    required void Function() onTransitionEnd,
  }) async {
    if (targetIndex >= 0 && targetIndex < totalSlides) {
      onTransitionStart();
      router.go('/slides/$targetIndex');
      await Future.delayed(_transitionDuration);
      onTransitionEnd();
    }
  }

  int _parseIndex(String? param) => int.tryParse(param ?? '0') ?? 0;

  Widget _fadeTransition(context, animation, secondaryAnimation, child) {
    return FadeTransition(opacity: animation, child: child);
  }
}
```

#### 1.4 Create ThumbnailService

**File**: `packages/superdeck/lib/src/export/thumbnail_service.dart`

**Extract from ThumbnailController**:

```dart
class ThumbnailService {
  final _slideCaptureService = SlideCaptureService();

  void generateThumbnails({
    required List<SlideConfiguration> slides,
    required BuildContext context,
    required Map<String, AsyncThumbnail> cache,
    required void Function(Map<String, AsyncThumbnail>) onCacheUpdate,
    bool force = false,
  }) {
    final updatedCache = Map<String, AsyncThumbnail>.from(cache);

    for (final slide in slides) {
      final thumbnail = updatedCache.putIfAbsent(
        slide.key,
        () => AsyncThumbnail(
          generator: (ctx, force) => _generateThumbnail(slide, ctx, force),
        ),
      );
      thumbnail.load(context, force);
    }

    onCacheUpdate(updatedCache);
  }

  Future<File> _generateThumbnail(
    SlideConfiguration slide,
    BuildContext context,
    bool force,
  ) async {
    final file = File(slide.thumbnailFile);

    if (!force && await file.exists() && await file.length() > 0) {
      return file;
    }

    final imageData = await _slideCaptureService.capture(
      slide: slide,
      context: context,
    );

    await file.writeAsBytes(imageData);
    return file;
  }
}
```

---

### **Phase 2: Create New DeckController with Signals**

**Duration**: ~3 hours

#### 2.1 New DeckController Implementation

**File**: `packages/superdeck/lib/src/deck/deck_controller.dart`

**Complete rewrite** using signals:

```dart
import 'package:signals/signals.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:meta/meta.dart';

import 'deck_service.dart';
import 'navigation_service.dart';
import '../export/thumbnail_service.dart';
import 'deck_options.dart';
import 'slide_configuration.dart';
import 'navigation_events.dart';

/// Unified facade for all deck state and operations
///
/// Manages reactive state with signals and delegates operations to
/// stateless services. Consolidates deck, navigation, and thumbnail
/// concerns under a single controller.
class DeckController {
  // ========================================
  // DEPENDENCIES (Private Services)
  // ========================================

  final DeckService _deckService;
  final NavigationService _navigationService = NavigationService();
  final ThumbnailService _thumbnailService = ThumbnailService();
  final SlideConfigurationBuilder _slideBuilder;

  // ========================================
  // INTERNAL STATE (Private Signals)
  // ========================================

  // Deck state
  final _loadingState = signal<DeckLoadingState>(DeckLoadingState.idle);
  final _currentDeck = signal<Deck?>(null);
  final _error = signal<Object?>(null);
  final _options = signal<DeckOptions>(DeckOptions());  // NEVER exposed

  // UI state
  final _isMenuOpen = signal<bool>(false);
  final _isNotesOpen = signal<bool>(false);
  final _isRebuilding = signal<bool>(false);

  // Navigation state
  final _currentIndex = signal<int>(0);
  final _isTransitioning = signal<bool>(false);

  // Thumbnail state
  final _thumbnails = signal<Map<String, AsyncThumbnail>>({});

  // Router (required by MaterialApp)
  late final GoRouter router;

  // Stream subscription
  StreamSubscription<Deck>? _deckSubscription;

  // ========================================
  // COMPUTED STATE (Read-Only Public API)
  // ========================================

  // Deck computeds
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
  ReadonlySignal<Object?> get error => _error.toReadonly();

  // UI computeds
  ReadonlySignal<bool> get isMenuOpen => _isMenuOpen.toReadonly();
  ReadonlySignal<bool> get isNotesOpen => _isNotesOpen.toReadonly();
  ReadonlySignal<bool> get isRebuilding => _isRebuilding.toReadonly();

  // Navigation computeds
  ReadonlySignal<int> get currentIndex => _currentIndex.toReadonly();
  ReadonlySignal<bool> get isTransitioning => _isTransitioning.toReadonly();
  late final ReadonlySignal<bool> canGoNext = computed(
    () => _currentIndex.value < totalSlides.value - 1,
  );
  late final ReadonlySignal<bool> canGoPrevious = computed(
    () => _currentIndex.value > 0,
  );
  late final ReadonlySignal<SlideConfiguration?> currentSlide = computed(() {
    final index = _currentIndex.value;
    final slidesList = slides.value;
    return index >= 0 && index < slidesList.length ? slidesList[index] : null;
  });

  // ========================================
  // CONSTRUCTOR
  // ========================================

  DeckController({
    required DeckService deckService,
    required DeckOptions options,
  })  : _deckService = deckService,
        _slideBuilder = SlideConfigurationBuilder(
          configuration: deckService.configuration,
        ) {
    _options.value = options;

    // Create router with index change callback
    router = _navigationService.createRouter(
      onIndexChanged: (index) => _updateCurrentIndex(index),
    );

    // Start deck loading
    _startDeckStream();
  }

  // ========================================
  // DECK OPERATIONS
  // ========================================

  void _startDeckStream() {
    _loadingState.value = DeckLoadingState.loading;

    _deckSubscription = _deckService.loadDeckStream().listen(
      (deck) {
        _currentDeck.value = deck;
        _loadingState.value = DeckLoadingState.loaded;
        _error.value = null;
      },
      onError: (e) {
        _error.value = e;
        _loadingState.value = DeckLoadingState.error;
      },
    );
  }

  /// Updates deck options (called by DeckControllerBuilder)
  @internal
  void updateOptions(DeckOptions newOptions) {
    if (_options.value != newOptions) {
      _options.value = newOptions;
    }
  }

  /// Sets rebuilding state (called by CliWatcher)
  @internal
  void setRebuilding(bool value) {
    _isRebuilding.value = value;
  }

  // ========================================
  // UI ACTIONS
  // ========================================

  void openMenu() => _isMenuOpen.value = true;
  void closeMenu() => _isMenuOpen.value = false;
  void toggleNotes() => _isNotesOpen.value = !_isNotesOpen.value;

  // ========================================
  // NAVIGATION ACTIONS
  // ========================================

  Future<void> goToSlide(int index) async {
    await _navigationService.goToSlide(
      router: router,
      targetIndex: index,
      totalSlides: totalSlides.value,
      onTransitionStart: () => _isTransitioning.value = true,
      onTransitionEnd: () => _isTransitioning.value = false,
    );
  }

  Future<void> nextSlide() async {
    if (canGoNext.value) {
      await goToSlide(_currentIndex.value + 1);
    }
  }

  Future<void> previousSlide() async {
    if (canGoPrevious.value) {
      await goToSlide(_currentIndex.value - 1);
    }
  }

  /// Handles navigation events from input handlers (internal)
  @internal
  void handleNavigationEvent(NavigationEvent event) {
    switch (event) {
      case NextSlideEvent():
        nextSlide();
      case PreviousSlideEvent():
        previousSlide();
      case GoToSlideEvent(:final index):
        goToSlide(index);
    }
  }

  /// Updates current index from router (internal, called by NavigationService)
  @internal
  void _updateCurrentIndex(int index) {
    final maxIndex = totalSlides.value > 0 ? totalSlides.value - 1 : 0;
    final clampedIndex = index.clamp(0, maxIndex);

    if (_currentIndex.value != clampedIndex) {
      _currentIndex.value = clampedIndex;
    }
  }

  // ========================================
  // THUMBNAIL ACTIONS
  // ========================================

  void generateThumbnails(BuildContext context, {bool force = false}) {
    _thumbnailService.generateThumbnails(
      slides: slides.value,
      context: context,
      cache: _thumbnails.value,
      onCacheUpdate: (cache) => _thumbnails.value = cache,
      force: force,
    );
  }

  AsyncThumbnail? getThumbnail(String slideKey) {
    return _thumbnails.value[slideKey];
  }

  // ========================================
  // LIFECYCLE
  // ========================================

  void dispose() {
    _deckSubscription?.cancel();

    // Dispose thumbnails
    for (final thumbnail in _thumbnails.value.values) {
      thumbnail.dispose();
    }

    // Dispose signals
    _loadingState.dispose();
    _currentDeck.dispose();
    _error.dispose();
    _options.dispose();
    _isMenuOpen.dispose();
    _isNotesOpen.dispose();
    _isRebuilding.dispose();
    _currentIndex.dispose();
    _isTransitioning.dispose();
    _thumbnails.dispose();

    // Dispose computed signals
    slides.dispose();
    totalSlides.dispose();
    isLoading.dispose();
    hasError.dispose();
    canGoNext.dispose();
    canGoPrevious.dispose();
    currentSlide.dispose();
  }

  // ========================================
  // STATIC ACCESS
  // ========================================

  static DeckController of(BuildContext context) {
    return InheritedData.of<DeckController>(context);
  }
}
```

---

### **Phase 3: Update Provider Infrastructure**

**Duration**: ~1 hour

#### 3.1 Simplify deck_provider.dart

**File**: `packages/superdeck/lib/src/deck/deck_provider.dart`

**Major simplification** - remove all old providers:

```dart
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../ui/widgets/provider.dart';
import 'deck_controller.dart';
import 'deck_options.dart';
import '../utils/cli_watcher.dart';
import '../utils/constants.dart';

/// Widget that syncs thumbnail generation with deck slide changes
class ThumbnailSyncManager extends StatefulWidget {
  final Widget child;

  const ThumbnailSyncManager({super.key, required this.child});

  @override
  State<ThumbnailSyncManager> createState() => _ThumbnailSyncManagerState();
}

class _ThumbnailSyncManagerState extends State<ThumbnailSyncManager> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final deck = DeckController.of(context);

    // Initial thumbnail generation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        deck.generateThumbnails(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deck = DeckController.of(context);

    // Listen to slide changes and regenerate thumbnails
    return Watch((context) {
      final slides = deck.slides.value;

      // Regenerate after frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          deck.generateThumbnails(context);
        }
      });

      return widget.child;
    });
  }
}

/// Builder widget that creates and manages the DeckController
class DeckControllerBuilder extends StatefulWidget {
  final DeckOptions options;
  final Widget Function(BuildContext context, GoRouter router) builder;

  const DeckControllerBuilder({
    super.key,
    required this.options,
    required this.builder,
  });

  @override
  State<DeckControllerBuilder> createState() => _DeckControllerBuilderState();
}

class _DeckControllerBuilderState extends State<DeckControllerBuilder> {
  late final DeckController _deckController;
  CliWatcher? _cliWatcher;
  final _logger = getLogger('DeckControllerBuilder');

  @override
  void initState() {
    super.initState();

    final configuration = DeckConfiguration();
    final deckService = DeckService(configuration: configuration);

    _deckController = DeckController(
      deckService: deckService,
      options: widget.options,
    );

    // Start CLI watcher in debug mode
    if (kCanRunProcess) {
      try {
        _cliWatcher = CliWatcher(
          projectRoot: Directory.current,
          configuration: configuration,
        );
        _cliWatcher!.start();
        _logger.info('CLI watcher started');

        _cliWatcher!.addListener(_onCliWatcherChanged);
      } catch (e) {
        _logger.warning('CLI watcher failed to start: $e');
      }
    }
  }

  void _onCliWatcherChanged() {
    if (_cliWatcher != null) {
      _deckController.setRebuilding(_cliWatcher!.isRebuilding);
    }
  }

  @override
  void didUpdateWidget(DeckControllerBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options != oldWidget.options) {
      _deckController.updateOptions(widget.options);
    }
  }

  @override
  void dispose() {
    _cliWatcher?.removeListener(_onCliWatcherChanged);
    _cliWatcher?.dispose();
    _deckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedData(
      data: _deckController,
      child: ThumbnailSyncManager(
        child: Builder(
          builder: (context) {
            return widget.builder(context, _deckController.router);
          },
        ),
      ),
    );
  }
}
```

**Removed**:
- `DeckProvider` class (use `InheritedData` directly)
- `NavigationProvider` class (consolidated into DeckController)
- All `InheritedNotifierData` usage (signals handle reactivity)

---

### **Phase 4: Update All Consumers**

**Duration**: ~2 hours

#### 4.1 Update Widget Access Patterns

**Files to modify**: 8 consumer files

**Pattern**:
```dart
// OLD
final deckController = DeckController.of(context);
final navigationController = NavigationProvider.of(context);
final thumbnailController = ThumbnailController.of(context);

// NEW
final deck = DeckController.of(context);
```

**Replace ListenableBuilder with Watch**:
```dart
// OLD
ListenableBuilder(
  listenable: Listenable.merge([deckController, navigationController]),
  builder: (context, _) {
    return Text('${navigationController.currentIndex + 1} of ${deckController.totalSlides}');
  },
)

// NEW
Watch((context) => Text(
  '${deck.currentIndex.value + 1} of ${deck.totalSlides.value}'
))
```

#### 4.2 File-by-File Changes

**File 1**: `packages/superdeck/lib/src/ui/panels/bottom_bar.dart`

**Before**:
```dart
final deckController = DeckController.of(context);
final navigationController = NavigationProvider.of(context);
final thumbnail = ThumbnailController.of(context);

final currentPage = navigationController.currentIndex + 1;
final totalPages = deckController.totalSlides;
final isNotesOpen = deckController.isNotesOpen;
```

**After**:
```dart
final deck = DeckController.of(context);

return FlexBox(
  children: [
    Watch((context) => SDIconButton(
      onPressed: deck.toggleNotes,
      icon: deck.isNotesOpen.value ? Icons.comment : Icons.comments_disabled,
    )),

    SDIconButton(
      icon: Icons.replay_circle_filled_rounded,
      onPressed: () => deck.generateThumbnails(context, force: true),
    ),

    const Spacer(),

    SDIconButton(icon: Icons.arrow_back, onPressed: deck.previousSlide),
    SDIconButton(icon: Icons.arrow_forward, onPressed: deck.nextSlide),

    const Spacer(),

    Watch((context) => Text(
      '${deck.currentIndex.value + 1} of ${deck.totalSlides.value}',
      style: const TextStyle(color: Colors.white),
    )),

    SDIconButton(icon: Icons.close, onPressed: deck.closeMenu),
  ],
);
```

**File 2**: `packages/superdeck/lib/src/ui/app_shell.dart`

Replace all controller access with single `deck` reference, update ListenableBuilder to Watch, remove listener management pattern (signals handle this automatically).

**File 3**: `packages/superdeck/lib/src/deck/slide_page_content.dart`

Update to use signals:
```dart
final deck = DeckController.of(context);

// Sync route index (internal API)
WidgetsBinding.instance.addPostFrameCallback((_) {
  deck._updateCurrentIndex(index);  // Access internal method
});

return Watch((context) {
  if (deck.hasError.value) return ErrorScreen();
  if (deck.isLoading.value) return LoadingScreen();

  final slides = deck.slides.value;
  if (slides.isEmpty) return NoSlidesScreen();

  final safeIndex = index.clamp(0, slides.length - 1);
  return SlideScreen(slides[safeIndex]);
});
```

**File 4**: `packages/superdeck/lib/src/deck/navigation_manager.dart`

Update event handling:
```dart
final deck = DeckController.of(context);
deck.handleNavigationEvent(event);
```

**File 5**: `packages/superdeck/lib/src/rendering/slides/slide_thumbnail.dart`

Update thumbnail access:
```dart
final deck = DeckController.of(context);
_asyncThumbnail = deck.getThumbnail(widget.slide.key);
```

**File 6**: `packages/superdeck/lib/src/export/pdf_export_screen.dart`

Update slides access:
```dart
final deck = DeckController.of(context);
// Use deck.slides.value in dialog
```

**File 7**: `demo/integration_test/test_helpers.dart`

Update test helpers:
```dart
final deck = DeckController.of(context);
await deck.nextSlide();
await deck.previousSlide();
```

---

### **Phase 5: Remove Old Files**

**Duration**: ~30 minutes

#### 5.1 Delete Obsolete Files

- `packages/superdeck/lib/src/deck/navigation_controller.dart` - Functionality moved to DeckController
- `packages/superdeck/lib/src/export/thumbnail_controller.dart` - Functionality moved to DeckController

#### 5.2 Update Exports

**File**: `packages/superdeck/lib/superdeck.dart`

Remove old exports:
```dart
// DELETE these
export 'src/deck/navigation_controller.dart';
export 'src/export/thumbnail_controller.dart';
```

---

### **Phase 6: Testing & Verification**

**Duration**: ~1 hour

#### 6.1 Run Tests

```bash
# Run all tests
melos test

# Run specific packages
melos run test:superdeck
melos run test:core
```

#### 6.2 Manual Testing

1. Start demo app: `cd demo && flutter run`
2. Verify navigation (arrow keys, click thumbnails)
3. Verify menu open/close
4. Verify notes toggle
5. Verify thumbnail regeneration
6. Verify loading states
7. Verify error handling
8. Verify hot reload with CLI watcher

#### 6.3 Integration Tests

```bash
# Run integration tests
cd demo
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

---

### **Phase 6 Outcome Snapshot (2025-11-02)**

- ✅ `melos exec --scope superdeck -- dart analyze`
- ✅ `melos exec --scope superdeck -- flutter test` (material-icon warnings acknowledged)
- ⚠️ `melos run test` (requires non-interactive package selection script)
- ⚠️ Manual demo walkthrough (navigation/menu/thumbnail/CLI watcher) – still recommended before release cut

Document any additional verification in future updates to keep this section current.

---

## Migration Guide (for Team)

### **Breaking Changes**

1. **Controller Access**
   ```dart
   // OLD
   NavigationProvider.of(context)
   ThumbnailController.of(context)

   // NEW
   DeckController.of(context)
   ```

2. **State Access**
   ```dart
   // OLD
   navigationController.currentIndex

   // NEW
   deck.currentIndex.value  // Signal value
   ```

3. **Reactive Widgets**
   ```dart
   // OLD
   ListenableBuilder(
     listenable: controller,
     builder: (context, _) { ... },
   )

   // NEW
   Watch((context) { ... })
   ```

### **Non-Breaking Changes**

- `DeckController.of(context)` still works (now returns unified controller)
- All navigation/thumbnail methods still available on DeckController
- Provider setup in `SuperDeckApp` unchanged (internal refactoring only)

---

## Rollback Plan

If critical issues arise:

1. **Git revert** to before Phase 1
2. All changes are in feature branch - merge can be delayed
3. No database migrations or external API changes
4. Tests guard against regressions

---

## Success Metrics

- ✅ All existing tests pass
- ✅ Manual testing shows no behavioral changes
- ✅ Integration tests pass
- ✅ Hot reload works correctly
- ✅ No performance regressions (measured with DevTools)
- ✅ Reduced LOC (~200 lines removed from boilerplate)
- ✅ Simplified provider hierarchy (3 providers → 1)

---

## Future Enhancements

After this refactoring, consider:

1. **Add flutter_hooks** for even cleaner widget code:
   ```dart
   final currentIndex = useSignal(deck.currentIndex);
   ```

2. **Extract keyboard/mouse navigation** into separate service

3. **Add undo/redo** using signal history

4. **Performance optimization** with signal effects for side effects

---

## Questions & Answers

**Q: Why remove navigation history feature?**
A: Usage analysis shows 0 production uses of `goBack()`, `history`, `canGoBack`. Only test code uses it. Can be re-added if needed.

**Q: Why not expose `options` publicly?**
A: Usage analysis shows 0 external reads. Only used internally by `slides` computed signal. Options should be controlled by parent widget, not mutated by consumers.

**Q: Why consolidate into one controller?**
A: Simplifies mental model for Superdeck - "the deck knows everything". Services keep internal separation, but external API is unified.

**Q: What about testing?**
A: Services are mockable. DeckController can be tested by passing mock services. Signals are easier to test than ChangeNotifier (just read `.value`).

---

## Appendix A: Detailed API Surface

### Before (3 controllers)

- **DeckController**: 14 public members
- **NavigationController**: 11 public members
- **ThumbnailController**: 4 public members
- **Total**: 29 public members across 3 providers

### After (1 controller)

- **DeckController**: 24 public members (10 readonly signals, 9 actions, 5 lifecycle/access)
- **Total**: 24 public members in 1 provider

**Reduction**: 29 → 24 members, 3 → 1 providers

---

## Appendix B: File Change Summary

| File | Type | Lines Changed |
|------|------|---------------|
| `deck_service.dart` | Rename | 2 (class name) |
| `navigation_service.dart` | New | +80 |
| `thumbnail_service.dart` | New | +60 |
| `deck_controller.dart` | Rewrite | +280, -138 |
| `deck_provider.dart` | Simplify | +80, -150 |
| `app_shell.dart` | Update | ±50 |
| `bottom_bar.dart` | Update | ±20 |
| `slide_page_content.dart` | Update | ±15 |
| `navigation_manager.dart` | Update | ±5 |
| `slide_thumbnail.dart` | Update | ±5 |
| `pdf_export_screen.dart` | Update | ±5 |
| `test_helpers.dart` | Update | ±10 |
| `navigation_controller.dart` | Delete | -175 |
| `thumbnail_controller.dart` | Delete | -233 |
| **Total** | | **+515, -766 = -251 net LOC** |

---

**End of Plan**
