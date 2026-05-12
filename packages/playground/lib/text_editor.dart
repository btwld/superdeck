import 'package:flutter/widgets.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:super_editor/super_editor.dart';

class TextEditor extends StatefulWidget {
  const TextEditor({super.key});

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late final MutableDocument _document;
  late final DocumentComposer _composer;
  late final DocumentEditor _editor;

  @override
  void initState() {
    super.initState();

    // A MutableDocument is an in-memory Document. Create the starting
    // content that you want your editor to display.
    //
    // To start with an empty document, create a MutableDocument with a
    // single ParagraphNode that holds an empty string.
    _document = MutableDocument(
      nodes: [
        ParagraphNode(
          id: DocumentEditor.createNodeId(),
          text: AttributedText('---\n\nSlide #1\n\n---'),
        ),
        ParagraphNode(
          id: DocumentEditor.createNodeId(),
          text: AttributedText('\nSlide #2\n\n---'),
        ),
      ],
    );

    // A DocumentComposer holds the user's selection. Your editor will likely want
    // to observe, and possibly change the user's selection. Therefore, you should
    // hold onto your own DocumentComposer and pass it to your Editor.
    _composer = DocumentComposer();

    // With a MutableDocument, create an Editor, which knows how to apply changes
    // to the MutableDocument.
    _editor = DocumentEditor(document: _document);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .all(16.0),
      child: HeroCard(
        child: SuperEditor(
          editor: _editor,
          composer: _composer,
          stylesheet: .new(
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
                TextStyle(fontSize: 16).merge(textStyle),
            documentPadding: .all(32),
          ),
        ),
      ),
    );
  }
}
