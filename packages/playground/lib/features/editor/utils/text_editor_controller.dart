import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart';

import '../../../core/data/data_sources/memory_deck_loader.dart';
import 'markdown_editor.dart';
import '../domain/stores/editor_store.dart';
import 'edit_reaction.dart';
import 'slide_navigation.dart';

/// Owns the super_editor [Editor] — the single source of truth for the editor's
/// text — and all super_editor coupling for the editor feature.
///
/// It keeps two things in sync with the document:
/// - the live preview: document edits are forwarded to [MemoryDeckLoader];
/// - the shared nav state: the caret's slide is written to [EditorStore], and
///   when that index is set from outside (e.g. a preview tap) the caret scrolls
///   to match.
///
/// External full-document writes arrive through [replaceMarkdown] (the
/// [MarkdownEditor] port the AI command drives) and are applied in place, so the
/// view observes them like any other edit.
class TextEditorController implements MarkdownEditor {
  TextEditorController({
    required EditorStore editorStore,
    required MemoryDeckLoader deckLoader,
    required String initialText,
    ValueChanged<String>? onMarkdownChanged,
  }) : _editorStore = editorStore,
       _deckLoader = deckLoader,
       _onMarkdownChanged = onMarkdownChanged {
    _install(initialText);
    // Seed the live preview with the initial document.
    _pushMarkdown(initialText);
    _editorStore.addListener(_onStoreChanged);
  }

  final EditorStore _editorStore;
  final MemoryDeckLoader _deckLoader;

  /// Notified with the document's plain-text markdown on every real change
  /// (deduped like the preview). The file controller uses it to auto-save.
  final ValueChanged<String>? _onMarkdownChanged;

  late final MutableDocument _document;
  late final MutableDocumentComposer _composer;
  late final Editor _editor;

  /// The last markdown pushed to the deck loader, so attribution-only document
  /// changes (the highlight reactions fire on every keystroke) don't re-parse
  /// the preview when the plain text is unchanged.
  String? _lastMarkdown;

  /// True while writing the caret's slide into [EditorStore], so the store
  /// notification that triggers doesn't bounce back and re-scroll the caret.
  bool _syncingFromCaret = false;

  /// The editor consumed by the `TextEditor` view.
  Editor get editor => _editor;

  @override
  void replaceMarkdown(String markdown) {
    final nodes = _nodesFromMarkdown(markdown);
    // A single transaction: the document and selection listeners each fire once
    // at its end, pushing the new markdown and setting the caret's slide (0) —
    // so there's nothing to do after the execute.
    _editor.execute([
      ReplaceDocumentRequest(nodes),
      _caretAtStart(nodes.first.id),
    ]);
  }

  void dispose() {
    _editorStore.removeListener(_onStoreChanged);
    _composer.selectionNotifier.removeListener(_onSelectionChanged);
    _document.removeListener(_onDocumentChanged);
    _editor.dispose();
  }

  void _install(String markdown) {
    final nodes = _nodesFromMarkdown(markdown);
    _document = MutableDocument(nodes: nodes);
    _composer = MutableDocumentComposer();
    _editor = Editor(
      editables: {Editor.documentKey: _document, Editor.composerKey: _composer},
      // `ReplaceDocumentRequest` isn't wired in `defaultRequestHandlers`, so map
      // it to its command here for `replaceMarkdown`.
      requestHandlers: [
        (editor, request) => request is ReplaceDocumentRequest
            ? ReplaceDocumentCommand(request.nodes)
            : null,
        ...defaultRequestHandlers,
      ],
      reactionPipeline: [
        UpdateComposerTextStylesReaction(),
        SeparatorColorReaction(),
        HeaderHighlightReaction(),
        BlockHighlightReaction(),
      ],
    );

    // Place the caret at the start so the reaction pipeline applies
    // separator/header/block highlighting to the initial content.
    if (nodes.isNotEmpty) {
      _editor.execute([_caretAtStart(nodes.first.id)]);
    }

    _document.addListener(_onDocumentChanged);
    _composer.selectionNotifier.addListener(_onSelectionChanged);
  }

  /// External navigation (e.g. a preview tap set [EditorStore.activeSlideIndex])
  /// scrolls the caret to that slide. Caret-driven updates set
  /// [_syncingFromCaret], so this ignores the notification they cause.
  void _onStoreChanged() {
    if (_syncingFromCaret) return;
    _moveCaretToSlide(_editorStore.activeSlideIndex);
  }

  void _onSelectionChanged() {
    final selection = _composer.selection;
    if (selection == null) return;
    _setActiveSlideFromCaret(
      slideIndexForNode(_document, selection.extent.nodeId),
    );
  }

  /// Writes the caret's slide into the store without triggering a re-scroll.
  void _setActiveSlideFromCaret(int index) {
    _syncingFromCaret = true;
    _editorStore.activeSlideIndex = index;
    _syncingFromCaret = false;
  }

  void _onDocumentChanged(DocumentChangeLog _) {
    _pushMarkdown(_extractText());
  }

  void _pushMarkdown(String markdown) {
    if (markdown == _lastMarkdown) return;
    _lastMarkdown = markdown;
    _deckLoader.updateMarkdown(markdown);
    _onMarkdownChanged?.call(markdown);
  }

  void _moveCaretToSlide(int index) {
    final targetNodeId = firstNodeOfSlide(_document, index);
    if (targetNodeId == null) return;
    _editor.execute([_caretAtStart(targetNodeId)]);
  }

  ChangeSelectionRequest _caretAtStart(String nodeId) {
    return ChangeSelectionRequest(
      DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: nodeId,
          nodePosition: const TextNodePosition(offset: 0),
        ),
      ),
      SelectionChangeType.placeCaret,
      SelectionReason.contentChange,
    );
  }

  List<DocumentNode> _nodesFromMarkdown(String markdown) {
    final lines = markdown.isEmpty ? const [''] : markdown.split('\n');
    return [
      for (final line in lines)
        ParagraphNode(id: Editor.createNodeId(), text: AttributedText(line)),
    ];
  }

  String _extractText() => _document
      .map((n) => n is TextNode ? n.text.toPlainText() : '')
      .join('\n');
}
