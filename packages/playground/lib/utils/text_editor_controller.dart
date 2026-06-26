import 'package:flutter/foundation.dart';

/// Controller that allows external code to push new markdown into `TextEditor`.
///
/// Callers invoke [loadMarkdown] with a full markdown string; `TextEditor`
/// subscribes via [addListener] and replaces its document content.
class TextEditorController extends ChangeNotifier {
  String? _pendingMarkdown;

  /// The most recently requested markdown, or null if none yet.
  String? get pendingMarkdown => _pendingMarkdown;

  /// Requests the editor to load [markdown], replacing all existing content.
  ///
  /// Always notifies listeners — even when [markdown] is byte-for-byte identical
  /// to the previous request — so a repeated generation that produces the same
  /// output still refreshes the editor.
  void loadMarkdown(String markdown) {
    _pendingMarkdown = markdown;
    notifyListeners();
  }
}
