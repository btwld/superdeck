# macOS Integration Test Disposal Race Condition

## Status
**Pre-existing infrastructure issue** - Not introduced by custom widgets feature (PR #16)

## Symptoms
- ❌ macOS integration tests fail with `SemanticsHandle` disposal errors
- ❌ "Looking up a deactivated widget's ancestor is unsafe" errors
- ✅ Unit tests pass
- ✅ Web integration tests pass
- ❌ Affects both `main` branch and feature branches

## Error Messages

### Primary Error
```
Looking up a deactivated widget's ancestor is unsafe.
At this point the state of the widget's element tree is no longer stable.
To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by
calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.
```

### Stack Trace Pattern
```
#3  DeckController.of (package:superdeck/src/deck/deck_controller.dart:126:30)
#4  _SplitViewState._onMenuStateChanged (package:superdeck/src/ui/app_shell.dart:98:43)
#5  ChangeNotifier.notifyListeners (package:flutter/src/foundation/change_notifier.dart:435:24)
#6  DeckController.setRebuilding (package:superdeck/src/deck/deck_controller.dart:120:7)
#7  _DeckControllerBuilderState._onCliWatcherChanged (package:superdeck/src/deck/deck_provider.dart:168:23)
#8  ChangeNotifier.notifyListeners (package:flutter/src/foundation/change_notifier.dart:435:24)
#9  CliWatcher._refreshBuildStatus (package:superdeck/src/utils/cli_watcher.dart:322:9)
```

## Root Cause Analysis

### The Problem Chain

This is a **widget lifecycle race condition** during test teardown caused by async operations continuing during widget disposal.

#### 1. Test Teardown Sequence
```
Test ends → Widget tree disposal begins → Widgets call dispose() in order
```

#### 2. The Race Condition

**Step A:** `_SplitViewState.dispose()` is called
- Removes listener from `_deckController`
- Widget is now **deactivated** (no longer in tree)

**Step B:** Async operations are still running:
- `CliWatcher` is monitoring file changes via `FileWatcher`
- `DeckController` is listening to deck stream updates
- These are **background async tasks** that don't stop immediately

**Step C:** Background task triggers notification:
```dart
// In CliWatcher._refreshBuildStatus() (line 331)
notifyListeners();  // ← Triggers DeckController listeners

// In DeckController (line 78)
notifyListeners();  // ← Triggers _SplitViewState._onMenuStateChanged

// In _SplitViewState._onMenuStateChanged() (line 99)
final deckController = DeckController.of(context);  // ❌ CRASH!
```

**Step D:** The crash happens because:
- `_SplitViewState` is already **deactivated** (removed from widget tree)
- But it's still registered as a listener on `DeckController`
- When `DeckController.notifyListeners()` fires, it calls `_onMenuStateChanged()`
- `_onMenuStateChanged()` tries to call `DeckController.of(context)`
- This calls `context.dependOnInheritedWidgetOfExactType<DeckProvider>()`
- Flutter throws: **"Looking up a deactivated widget's ancestor is unsafe"**

### Why the `mounted` Check Isn't Enough

```dart
void _onMenuStateChanged() {
  if (!mounted) return;  // ← This check is NOT enough!
  
  final deckController = DeckController.of(context);  // ← CRASHES if widget is deactivated
  ...
}
```

**The `mounted` check doesn't help** because:
- Widget can be **deactivated** but still have `mounted == true` briefly
- The listener is removed in `dispose()`, but notifications can fire **during** the disposal cascade
- Async operations (file watching, stream updates) continue running during teardown

### Full Error Chain

```
1. Test ends
2. Widget tree disposal starts
3. _DeckControllerBuilderState.dispose() called
   ├─ Removes CliWatcher listener ✓
   └─ Calls _deckController.dispose()
   
4. DeckController.dispose() called
   └─ Cancels deck subscription
   
5. _SplitViewState.dispose() called
   └─ Removes _onMenuStateChanged listener ✓
   
6. BUT MEANWHILE (async race):
   ├─ FileWatcher detects file change
   ├─ Calls CliWatcher._refreshBuildStatus()
   ├─ CliWatcher.notifyListeners() fires
   ├─ DeckController._onCliWatcherChanged() called
   ├─ DeckController.setRebuilding() called
   ├─ DeckController.notifyListeners() fires
   └─ _SplitViewState._onMenuStateChanged() called ❌
       └─ Tries DeckController.of(context) on deactivated widget
       └─ CRASH: "Looking up a deactivated widget's ancestor is unsafe"
```

## Why It's macOS-Specific

The issue is **more pronounced on macOS** because:

1. **File system watching is more aggressive** on macOS (FSEvents API)
2. **Timing differences** in how macOS handles process cleanup vs Web
3. **Integration test binding** on macOS has stricter semantics checking
4. **SemanticsHandle** disposal is enforced more strictly on macOS

## Affected Files

- `packages/superdeck/lib/src/ui/app_shell.dart` - `_SplitViewState._onMenuStateChanged()`
- `packages/superdeck/lib/src/deck/deck_controller.dart` - `DeckController.of()`
- `packages/superdeck/lib/src/deck/deck_provider.dart` - `_DeckControllerBuilderState._onCliWatcherChanged()`
- `packages/superdeck/lib/src/utils/cli_watcher.dart` - `CliWatcher._refreshBuildStatus()`
- `packages/superdeck_core/src/utils/file_watcher.dart` - File watching async operations

## Proposed Solutions

### Solution 1: Save Controller Reference Early (Recommended)

**File:** `packages/superdeck/lib/src/ui/app_shell.dart`

```dart
class _SplitViewState extends State<SplitView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _curvedAnimation;
  DeckController? _deckController;
  DeckController? _savedDeckController;  // ← Add saved reference
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Save controller reference early
    _savedDeckController = DeckController.of(context);
    
    if (!_isInitialized) {
      _isInitialized = true;
      _deckController = _savedDeckController;
      
      final initialMenuState = _deckController!.isMenuOpen;
      if (initialMenuState) {
        _animationController.value = 1.0;
      }
      
      _deckController!.addListener(_onMenuStateChanged);
      
      // ... rest of initialization
    }
  }

  void _onMenuStateChanged() {
    if (!mounted || _savedDeckController == null) return;
    
    // Use saved reference instead of looking up
    final isMenuOpen = _savedDeckController!.isMenuOpen;

    if (isMenuOpen && _animationController.value != 1.0) {
      _animationController.forward();
    } else if (!isMenuOpen && _animationController.value != 0.0) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _deckController?.removeListener(_onMenuStateChanged);
    _animationController.dispose();
    _savedDeckController = null;  // ← Clear reference
    super.dispose();
  }
}
```

### Solution 2: Cancel Async Operations Before Removing Listeners

**File:** `packages/superdeck/lib/src/deck/deck_provider.dart`

```dart
@override
void dispose() {
  // Stop async operations FIRST
  _cliWatcher?.stop();  // ← Stop file watching
  
  // THEN remove listeners
  _cliWatcher?.removeListener(_onCliWatcherChanged);
  _cliWatcher?.dispose();
  
  _navigationController.dispose();
  _deckController.dispose();
  _thumbnailController.dispose();
  super.dispose();
}
```

### Solution 3: Add Disposal Guards in Callbacks

**File:** `packages/superdeck/lib/src/deck/deck_provider.dart`

```dart
void _onCliWatcherChanged() {
  // Guard against disposal race
  if (!mounted) return;
  if (_cliWatcher == null) return;
  if (_cliWatcher!.status == CliWatcherStatus.stopped) return;
  
  _deckController.setRebuilding(_cliWatcher!.isRebuilding);
}
```

**File:** `packages/superdeck/lib/src/utils/cli_watcher.dart`

```dart
Future<void> _refreshBuildStatus() async {
  if (_isReadingBuildStatus) return;
  
  // Check if disposed before starting
  if (_status == CliWatcherStatus.stopped) return;
  
  // ... existing code ...
  
  // Only notify if not disposed
  if (_status != CliWatcherStatus.stopped && mounted) {  // ← Add mounted check
    notifyListeners();
  }
}
```

## Recommended Action Plan

1. **Immediate:** Implement Solution 1 (save controller reference) in `app_shell.dart`
2. **Short-term:** Add disposal guards (Solution 3) to all notification callbacks
3. **Medium-term:** Ensure async operations are cancelled before listener removal (Solution 2)
4. **Long-term:** Review all `ChangeNotifier` usage patterns for similar race conditions

## Testing Strategy

After implementing fixes:

1. Run macOS integration tests locally: `cd demo && fvm flutter test integration_test/app_test.dart -d macos`
2. Verify tests pass consistently (run 5+ times)
3. Verify Web integration tests still pass
4. Verify unit tests still pass
5. Test on CI to ensure macOS runners pass

## References

- PR #16: Custom widgets feature (not the cause, but exposed the issue)
- Flutter issue: Widget disposal during async operations
- Related pattern: https://api.flutter.dev/flutter/widgets/State/dispose.html

