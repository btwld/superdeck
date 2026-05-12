import 'package:flutter/widgets.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:super_editor/super_editor.dart';

class TextEditor extends StatefulWidget {
  const TextEditor({super.key, required this.initialText, this.onChanged});

  final String initialText;
  final ValueChanged<String>? onChanged;

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
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText(widget.initialText),
        ),
      ],
    );

    _document.addListener(_onDocumentChanged);

    _composer = MutableDocumentComposer();
    _editor = Editor(
      editables: {
        Editor.documentKey: _document,
        Editor.composerKey: _composer,
      },
      requestHandlers: List.from(defaultRequestHandlers),
      reactionPipeline: [
        UpdateComposerTextStylesReaction(),
        // Intentionally omitting content-conversion reactions
        // (HorizontalRuleConversionReaction, HeaderConversionReaction, etc.)
        // so raw markdown characters like --- and # are kept as-is.
      ],
    );
  }

  void _onDocumentChanged(DocumentChangeLog changeLog) {
    final text = _extractText();
    widget.onChanged?.call(text);
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
          stylesheet: Stylesheet(
            rules: [
              StyleRule(const BlockSelector("header1"), (doc, docNode) {
                return {
                  "textStyle": const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                };
              }),
            ],
            inlineTextStyler: (_, textStyle) =>
                const TextStyle(fontSize: 16).merge(textStyle),
            documentPadding: const EdgeInsets.all(32),
          ),
        ),
      ),
    );
  }
}
