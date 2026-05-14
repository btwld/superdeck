import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import 'package:super_editor/super_editor.dart';

import '../../utils/edit_reaction.dart';
import '../../utils/memory_deck_loader.dart';

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
  }

  void _onDocumentChanged(DocumentChangeLog changeLog) {
    final text = _extractText();
    context.read<MemoryDeckLoader>().updateMarkdown(text);
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
                    fontSize: 18,
                    height: 1.4,
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
