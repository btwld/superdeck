import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import 'package:super_editor/super_editor.dart';

import '../../stores/editor_state.dart';
import '../../utils/edit_reaction.dart';
import '../../utils/memory_deck_loader.dart';
import '../../utils/text_editor_controller.dart';

class TextEditor extends StatefulWidget {
  const TextEditor({super.key, this.onChanged, this.onInit});

  final ValueChanged<String>? onChanged;
  final VoidCallback? onInit;

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late final MutableDocument _document;
  late final MutableDocumentComposer _composer;
  late final Editor _editor;
  late final void Function() _unsubscribeActiveIndex;
  TextEditorController? _textEditorController;
  bool _isUpdatingFromCursor = false;

  @override
  void initState() {
    super.initState();

    _document = MutableDocument(
      nodes: [
        ParagraphNode(id: Editor.createNodeId(), text: AttributedText('---\n')),
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('# Title'),
        ),
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('## Subtitle\n'),
        ),
        ParagraphNode(id: Editor.createNodeId(), text: AttributedText('---\n')),
      ],
    );

    _document.addListener(_onDocumentChanged);

    _composer = MutableDocumentComposer();
    _composer.selectionNotifier.addListener(_onSelectionChanged);
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

    context.read<MemoryDeckLoader>().updateMarkdown(_extractText());

    // Subscribe to external markdown injection via TextEditorController.
    try {
      _textEditorController = context.read<TextEditorController>();
      _textEditorController!.addListener(_onExternalMarkdown);
    } catch (_) {
      // TextEditorController not provided — editor works standalone.
    }

    final editorState = context.read<EditorState>();
    _unsubscribeActiveIndex = editorState.activeSlideIndex.subscribe((index) {
      if (_isUpdatingFromCursor) return;
      _scrollToSlide(index);
    });
  }

  /// Called when [TextEditorController.loadMarkdown] is invoked externally.
  ///
  /// Replaces the document content with [markdown] and notifies the deck
  /// loader. The [_onDocumentChanged] listener is temporarily suppressed to
  /// avoid double-notifying.
  void _onExternalMarkdown() {
    final markdown = _textEditorController?.pendingMarkdown;
    if (markdown == null) return;

    // One paragraph node per markdown line, matching the init structure.
    // Always keep at least one node — SuperEditor requires a non-empty document.
    final lines = markdown.isEmpty ? const [''] : markdown.split('\n');
    final newNodes = <DocumentNode>[
      for (final line in lines)
        ParagraphNode(id: Editor.createNodeId(), text: AttributedText(line)),
    ];

    // Suppress the listener to avoid a re-entrant deck-loader update while we
    // swap all existing nodes for the new ones.
    _document.removeListener(_onDocumentChanged);
    try {
      final existingIds = _document.map((node) => node.id).toList();
      // Insert the new content first so the document is never momentarily
      // empty (which would violate SuperEditor's single-node invariant), then
      // remove the now-trailing original nodes.
      for (var i = 0; i < newNodes.length; i++) {
        _editor.execute([
          InsertNodeAtIndexRequest(nodeIndex: i, newNode: newNodes[i]),
        ]);
      }
      for (final id in existingIds) {
        _editor.execute([DeleteNodeRequest(nodeId: id)]);
      }
    } finally {
      _document.addListener(_onDocumentChanged);
    }

    // Push new markdown to the deck loader.
    context.read<MemoryDeckLoader>().updateMarkdown(markdown);
  }

  void _onDocumentChanged(DocumentChangeLog changeLog) {
    final text = _extractText();
    context.read<MemoryDeckLoader>().updateMarkdown(text);
  }

  void _onSelectionChanged() {
    final selection = _composer.selection;

    if (selection == null) return;

    final caretNodeId = selection.extent.nodeId;
    var slideIndex = 0;

    for (final node in _document) {
      if (node.id == caretNodeId) break;
      if (node is TextNode && node.text.toPlainText().trim() == '---') {
        slideIndex++;
      }
    }

    final editorState = context.read<EditorState>();
    // The first --- is the frontmatter separator, so slide 0 content
    // appears after the first ---. Subtract 1 to convert separator count
    // to 0-based slide index.
    final adjustedIndex = (slideIndex - 1).clamp(0, slideIndex);
    if (editorState.activeSlideIndex.value != adjustedIndex) {
      _isUpdatingFromCursor = true;
      editorState.activeSlideIndex.value = adjustedIndex;
      _isUpdatingFromCursor = false;
    }
  }

  void _scrollToSlide(int targetIndex) {
    // Find the node that starts the target slide's content.
    // Slide N starts after the (N+1)th --- separator.
    var separatorCount = 0;
    String? targetNodeId;

    for (final node in _document) {
      if (node is TextNode && node.text.toPlainText().trim() == '---') {
        separatorCount++;
        if (separatorCount == targetIndex + 1) {
          // The next node after this separator is the slide's content.
          // For now, place caret at the separator itself — the content
          // node may not exist yet if the slide is empty.
          final nodeIndex = _document.getNodeIndexById(node.id);
          if (nodeIndex + 1 < _document.length) {
            targetNodeId = _document.getNodeAt(nodeIndex + 1)!.id;
          } else {
            targetNodeId = node.id;
          }
          break;
        }
      }
    }

    // For slide 0, target the first content node after the first ---
    if (targetIndex == 0 && targetNodeId == null) {
      for (final node in _document) {
        if (node is TextNode && node.text.toPlainText().trim() == '---') {
          final nodeIndex = _document.getNodeIndexById(node.id);
          if (nodeIndex + 1 < _document.length) {
            targetNodeId = _document.getNodeAt(nodeIndex + 1)!.id;
          }
          break;
        }
      }
    }

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
    _textEditorController?.removeListener(_onExternalMarkdown);
    _unsubscribeActiveIndex();
    _composer.selectionNotifier.removeListener(_onSelectionChanged);
    _document.removeListener(_onDocumentChanged);
    _editor.dispose();
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
