import 'package:flutter/foundation.dart';

/// Controller that allows external code to push new markdown into [TextEditor].
///
/// Callers invoke [loadMarkdown] with a full markdown string; [TextEditor]
/// subscribes via [addListener] and replaces its document content.
class TextEditorController {
  final ValueNotifier<String?> _pending = ValueNotifier(null);

  /// Requests the editor to load [markdown], replacing all existing content.
  ///
  /// The editor widget observes this notifier and applies the change on the
  /// next frame after it receives the callback.
  void loadMarkdown(String markdown) {
    _pending.value = markdown;
  }

  /// Adds a listener that fires whenever [loadMarkdown] is called.
  void addListener(VoidCallback listener) {
    _pending.addListener(listener);
  }

  /// Removes a previously registered listener.
  void removeListener(VoidCallback listener) {
    _pending.removeListener(listener);
  }

  /// Returns the most recently requested markdown, or null if none yet.
  String? get pendingMarkdown => _pending.value;

  /// Releases resources.
  void dispose() {
    _pending.dispose();
  }
}
