import 'package:flutter/foundation.dart';

/// Controller that allows external code to push new markdown into `TextEditor`.
///
/// Callers invoke [loadMarkdown] with a full markdown string; `TextEditor`
/// subscribes via [addListener] and replaces its document content.
class TextEditorController extends ChangeNotifier {
  String? _pendingMarkdown;
  String? _stagedMarkdownForNextEditorMount;
  String? _latestMarkdown;
  bool _outboundWritesSuspended = false;

  /// The most recently requested markdown, or null if none yet.
  String? get pendingMarkdown => _pendingMarkdown;

  /// The latest markdown known from the mounted editor or handoff boundary.
  String get latestMarkdown => _latestMarkdown ?? _pendingMarkdown ?? '';

  bool get outboundWritesSuspended => _outboundWritesSuspended;

  /// Requests the editor to load [markdown], replacing all existing content.
  ///
  /// Always notifies listeners — even when [markdown] is byte-for-byte identical
  /// to the previous request — so a repeated generation that produces the same
  /// output still refreshes the editor.
  void loadMarkdown(String markdown) {
    _pendingMarkdown = markdown;
    _latestMarkdown = markdown;
    notifyListeners();
  }

  /// Returns pending markdown exactly once.
  String? takePendingMarkdown() {
    final markdown = _pendingMarkdown;
    _pendingMarkdown = null;
    return markdown;
  }

  /// Stages markdown for the next editor mount without notifying listeners.
  void stageMarkdownForNextEditorMount(String markdown) {
    _stagedMarkdownForNextEditorMount = markdown;
    _latestMarkdown = markdown;
  }

  /// Returns the non-notifying next-mount handoff exactly once.
  String? takeStagedMarkdownForNextEditorMount() {
    final markdown = _stagedMarkdownForNextEditorMount;
    _stagedMarkdownForNextEditorMount = null;
    return markdown;
  }

  void recordLatestMarkdown(String markdown) {
    _latestMarkdown = markdown;
  }

  void suspendOutboundWritesForAiEntry() {
    _outboundWritesSuspended = true;
  }

  void resumeOutboundWritesForEditorMount() {
    _outboundWritesSuspended = false;
  }
}
