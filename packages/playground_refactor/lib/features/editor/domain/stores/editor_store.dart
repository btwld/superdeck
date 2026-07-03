import 'package:flutter/foundation.dart';

import '../../../../core/data/data_sources/memory_deck_loader.dart';

/// The markdown shown when the editor first opens.
const starterMarkdown = '''---\n
# Title
## Subtitle\n
---
''';

/// Editor-local state: the markdown currently shown in the editor, and which
/// slide the caret is in.
///
/// This is the single source of truth for the editor's text. On every edit the
/// `TextEditor` reports the new markdown via [updateText]; the store records it
/// and forwards it to the [MemoryDeckLoader] so the live preview re-parses. The
/// active slide index is the editor's own navigation state, distinct from
/// presentation-mode routing.
///
/// Listeners are notified on both text and active-slide changes — consumers that
/// only care about one should read via `context.select` (or diff the value
/// themselves) so a keystroke doesn't trigger slide-driven work.
class EditorStore extends ChangeNotifier {
  EditorStore(this._deckLoader, {String initialText = starterMarkdown})
    : _currentText = initialText {
    // Seed the live preview with the initial document.
    _deckLoader.updateMarkdown(initialText);
  }

  final MemoryDeckLoader _deckLoader;

  String _currentText;
  int _activeSlideIndex = 0;

  /// The markdown currently exhibited in the editor.
  String get currentText => _currentText;

  int get activeSlideIndex => _activeSlideIndex;

  set activeSlideIndex(int value) {
    if (_activeSlideIndex == value) return;
    _activeSlideIndex = value;
    notifyListeners();
  }

  /// Records the markdown now shown in the editor and forwards it to the deck
  /// loader for live preview. No-ops when [text] is unchanged.
  void updateText(String text) {
    if (_currentText == text) return;
    _currentText = text;
    _deckLoader.updateMarkdown(text);
    notifyListeners();
  }
}
