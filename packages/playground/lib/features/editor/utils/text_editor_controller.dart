import 'package:super_editor/super_editor.dart';

import '../../../core/data/data_sources/memory_deck_loader.dart';
import '../domain/stores/deck_document_store.dart';
import '../domain/stores/editor_store.dart';
import 'edit_reaction.dart';
import 'slide_navigation.dart';

/// Owns the super_editor [Editor] and its coupling to the editor feature.
///
/// [DeckDocumentStore] is the Markdown authority. This controller adapts the
/// visual editor to that store, forwards store changes to [MemoryDeckLoader],
/// and synchronizes the caret with [EditorStore].
class TextEditorController {
  final EditorStore _editorStore;
  final MemoryDeckLoader _deckLoader;
  final DeckDocumentStore _documentStore;

  late final MutableDocument _document;
  late final MutableDocumentComposer _composer;
  late final Editor _editor;

  /// True while writing the caret's slide into [EditorStore], so the store
  /// notification that triggers does not bounce back and re-scroll the caret.
  bool _syncingFromCaret = false;

  TextEditorController({
    required EditorStore editorStore,
    required MemoryDeckLoader deckLoader,
    required DeckDocumentStore documentStore,
  }) : _editorStore = editorStore,
       _deckLoader = deckLoader,
       _documentStore = documentStore {
    _install(documentStore.markdown);
    _deckLoader.updateMarkdown(documentStore.markdown);
    _documentStore.addListener(_onDocumentStoreChanged);
    _editorStore.addListener(_onStoreChanged);
  }

  void _install(String markdown) {
    final nodes = _nodesFromMarkdown(markdown);
    _document = MutableDocument(nodes: nodes);
    _composer = MutableDocumentComposer();
    _editor = Editor(
      editables: {Editor.documentKey: _document, Editor.composerKey: _composer},
      // `ReplaceDocumentRequest` is not wired in `defaultRequestHandlers`, so
      // map it to its command for store-driven whole-document replacements.
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
    _editor.execute([_caretAtStart(nodes.first.id)]);
    _document.addListener(_onDocumentChanged);
    _composer.selectionNotifier.addListener(_onSelectionChanged);
  }

  /// External navigation (e.g. a preview tap setting
  /// [EditorStore.activeSlideIndex]) scrolls the caret to that slide.
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

  void _onDocumentChanged(DocumentChangeLog _) {
    _documentStore.replaceMarkdown(_extractText());
  }

  /// Applies store changes from AI generation, a file reload, or a deck switch
  /// to the visual document. Local editor changes already match the store and
  /// only update the preview.
  void _onDocumentStoreChanged() {
    final markdown = _documentStore.markdown;
    _deckLoader.updateMarkdown(markdown);
    if (markdown == _extractText()) return;

    final nodes = _nodesFromMarkdown(markdown);
    _editor.execute([
      ReplaceDocumentRequest(nodes),
      _caretAtStart(nodes.first.id),
    ]);
  }

  /// Writes the caret's slide into the store without triggering a re-scroll.
  void _setActiveSlideFromCaret(int index) {
    _syncingFromCaret = true;
    _editorStore.activeSlideIndex = index;
    _syncingFromCaret = false;
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
      .map((node) => node is TextNode ? node.text.toPlainText() : '')
      .join('\n');

  /// The editor consumed by the `TextEditor` view.
  Editor get editor => _editor;

  void dispose() {
    _editorStore.removeListener(_onStoreChanged);
    _documentStore.removeListener(_onDocumentStoreChanged);
    _composer.selectionNotifier.removeListener(_onSelectionChanged);
    _document.removeListener(_onDocumentChanged);
    _editor.dispose();
  }
}
