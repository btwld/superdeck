import 'package:flutter/foundation.dart';

/// The playground's sole logical Markdown document.
///
/// Generation publishes whole documents into it, and the preview and the saved
/// deck both read from it. Identical content is intentionally ignored so a
/// republished but unchanged document does not trigger redundant work.
class DeckDocumentStore extends ChangeNotifier {
  String _markdown;

  DeckDocumentStore({required String markdown}) : _markdown = markdown;

  /// The current full Markdown document.
  String get markdown => _markdown;

  /// Replaces the document and notifies listeners when its text changed.
  void replaceMarkdown(String markdown) {
    if (markdown == _markdown) return;
    _markdown = markdown;
    notifyListeners();
  }
}
