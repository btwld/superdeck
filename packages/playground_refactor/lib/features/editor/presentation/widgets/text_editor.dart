import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';
import 'package:super_editor/super_editor.dart';

import '../../domain/stores/editor_store.dart';
import 'edit_reaction.dart';

class TextEditor extends StatefulWidget {
  const TextEditor({super.key});

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;
  late final EditorStore _editorStore;
  bool _isUpdatingFromCursor = false;
  int _lastActiveSlide = 0;

  /// Bumped each time the editables are (re)installed. Used as the [SuperEditor]
  /// key so the pane mounts with a fresh layout presenter.
  // int _editorGeneration = 0;

  @override
  void initState() {
    super.initState();

    _editorStore = context.read<EditorStore>();
    _lastActiveSlide = _editorStore.activeSlideIndex;

    // The store owns the current text and has already seeded the deck loader;
    // build the document from it.
    _installEditables(_editorStore.currentText);

    _editorStore.addListener(_onActiveSlideChanged);
  }

  /// Reacts to the active slide changing (e.g. a preview tap) by scrolling the
  /// caret to that slide.
  ///
  /// [EditorStore] notifies on text edits too, so ignore notifications where the
  /// index is unchanged — otherwise every keystroke would reset the caret to the
  /// slide's start. Also skip when the change originated from the caret itself.
  void _onActiveSlideChanged() {
    final index = _editorStore.activeSlideIndex;
    if (index == _lastActiveSlide) return;
    _lastActiveSlide = index;
    if (_isUpdatingFromCursor) return;
    _scrollToSlide(index);
  }

  /// Builds a fresh document, composer, and editor from [markdown] and wires
  /// the change listeners. Runs the reaction pipeline once so syntax
  /// highlighting applies to the loaded content.
  void _installEditables(String markdown) {
    final nodes = _nodesFromMarkdown(markdown);
    _document = MutableDocument(nodes: nodes);
    _composer = MutableDocumentComposer();
    _editor = Editor(
      editables: {Editor.documentKey: _document, Editor.composerKey: _composer},
      requestHandlers: List.from(defaultRequestHandlers),
      reactionPipeline: [
        UpdateComposerTextStylesReaction(),
        SeparatorColorReaction(),
        HeaderHighlightReaction(),
        BlockHighlightReaction(),
      ],
    );

    // Reactions only fire on editor changes, and the document was constructed
    // directly from markdown. Place the caret at the start to trigger the
    // pipeline so separator/header/block highlighting is applied on load.
    if (nodes.isNotEmpty) {
      _editor.execute([
        ChangeSelectionRequest(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: nodes.first.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
          SelectionChangeType.placeCaret,
          SelectionReason.contentChange,
        ),
      ]);
    }

    _document.addListener(_onDocumentChanged);
    _composer.selectionNotifier.addListener(_onSelectionChanged);
    // _editorGeneration++;
  }

  void _disposeEditables() {
    _composer.selectionNotifier.removeListener(_onSelectionChanged);
    _document.removeListener(_onDocumentChanged);
    _editor.dispose();
  }

  void _onDocumentChanged(DocumentChangeLog changeLog) {
    _editorStore.updateText(_extractText());
  }

  List<DocumentNode> _nodesFromMarkdown(String markdown) {
    final lines = markdown.isEmpty ? const [''] : markdown.split('\n');
    return [
      for (final line in lines)
        ParagraphNode(id: Editor.createNodeId(), text: AttributedText(line)),
    ];
  }

  void _onSelectionChanged() {
    final selection = _composer.selection;
    if (selection == null) return;

    final index = _slideIndexForNode(selection.extent.nodeId);
    if (_editorStore.activeSlideIndex != index) {
      _isUpdatingFromCursor = true;
      _editorStore.activeSlideIndex = index;
      _isUpdatingFromCursor = false;
    }
  }

  void _scrollToSlide(int targetIndex) {
    final targetNodeId = _firstNodeOfSlide(targetIndex);
    if (targetNodeId == null) return;

    _editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: targetNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
  }

  bool _isSeparator(DocumentNode node) =>
      node is TextNode && node.text.toPlainText().trim() == '---';

  /// The 0-based slide the caret node [nodeId] falls in. The first `---` is the
  /// frontmatter separator, so anything before/at it maps to slide 0.
  int _slideIndexForNode(String nodeId) {
    var separatorCount = 0;
    for (final node in _document) {
      if (node.id == nodeId) break;
      if (_isSeparator(node)) separatorCount++;
    }
    return (separatorCount - 1).clamp(0, separatorCount);
  }

  /// The node id that starts slide [index]'s content — the node just after the
  /// (index+1)th `---` separator, or the separator itself when the slide is
  /// still empty. Null if that separator doesn't exist yet.
  String? _firstNodeOfSlide(int index) {
    var separatorCount = 0;
    for (final node in _document) {
      if (!_isSeparator(node)) continue;
      if (++separatorCount != index + 1) continue;
      final nodeIndex = _document.getNodeIndexById(node.id);
      if (nodeIndex + 1 < _document.length) {
        return _document.getNodeAt(nodeIndex + 1)!.id;
      }
      return node.id;
    }
    return null;
  }

  String _extractText() {
    final buffer = StringBuffer();
    var first = true;
    for (final node in _document) {
      if (!first) buffer.write('\n');
      first = false;
      if (node is TextNode) {
        buffer.write(node.text.toPlainText());
      }
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _editorStore.removeListener(_onActiveSlideChanged);
    _disposeEditables();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: HeroCard(
        child: SuperEditor(
          editor: _editor,
          keyboardActions: [...defaultKeyboardActions],
          documentOverlayBuilders: [
            DefaultCaretOverlayBuilder(
              caretStyle: CaretStyle(color: $accent.resolve(context)),
            ),
          ],
          stylesheet: Stylesheet(
            rules: [
              StyleRule(BlockSelector.all, (doc, docNode) {
                return {
                  Styles.textStyle: TextStyle(
                    color: $muted.resolve(context),
                    fontSize: 16,
                    height: 1.4,
                    fontFamily: GoogleFonts.googleSansCode().fontFamily,
                  ),
                };
              }),
            ],
            inlineTextStyler: (attributions, textStyle) {
              var style = const TextStyle(fontSize: 16).merge(textStyle);

              for (final attribution in attributions) {
                switch (attribution) {
                  case separatorAttribution:
                    style = style.copyWith(
                      color: $separatorTertiary.resolve(context),
                    );
                    break;
                  case headerAttribution:
                    style = style.copyWith(
                      fontWeight: FontWeight.bold,
                      color: $foreground.resolve(context),
                    );
                    break;
                  case blockAttribution:
                    style = style.copyWith(color: $danger.resolve(context));
                    break;
                  case blockKeyAttribution:
                    style = style.copyWith(color: $warning.resolve(context));
                    break;
                  case blockValueAttribution:
                    style = style.copyWith(color: $foreground.resolve(context));
                    break;
                }
              }
              return style;
            },
            documentPadding: const .all(32),
          ),
        ),
      ),
    );
  }
}
