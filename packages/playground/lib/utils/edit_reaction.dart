import 'package:super_editor/super_editor.dart';

const separatorAttribution = NamedAttribution('separator');

class SeparatorColorReaction extends EditReaction {
  @override
  void modifyContent(
    EditContext editorContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    final document = editorContext.document;

    for (final node in document) {
      if (node is! TextNode) continue;

      final text = node.text.toPlainText();
      if (text.isEmpty) continue;

      final nodeRange = DocumentRange(
        start: DocumentPosition(
          nodeId: node.id,
          nodePosition: const TextNodePosition(offset: 0),
        ),
        end: DocumentPosition(
          nodeId: node.id,
          nodePosition: TextNodePosition(offset: text.length),
        ),
      );

      // Remove any existing separator color attribution first.
      requestDispatcher.execute([
        RemoveTextAttributionsRequest(
          documentRange: nodeRange,
          attributions: {separatorAttribution},
        ),
      ]);

      if (text.trim() == '---') {
        requestDispatcher.execute([
          AddTextAttributionsRequest(
            documentRange: nodeRange,
            attributions: {separatorAttribution},
          ),
        ]);
      }
    }
  }
}
