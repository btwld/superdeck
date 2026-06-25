import 'package:super_editor/super_editor.dart';

const separatorAttribution = NamedAttribution('separator');
const headerAttribution = NamedAttribution('header');
const blockAttribution = NamedAttribution('block');
const blockKeyAttribution = NamedAttribution('block-key');
const blockValueAttribution = NamedAttribution('block-value');

/// Toggles a set of [attributions] across the full range of every [TextNode]
/// whose plain text matches [matches].
abstract class TextNodeAttributionReaction extends EditReaction {
  Set<Attribution> get attributions;

  bool matches(String text);

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

      requestDispatcher.execute([
        RemoveTextAttributionsRequest(
          documentRange: nodeRange,
          attributions: attributions,
        ),
      ]);

      if (matches(text)) {
        requestDispatcher.execute([
          AddTextAttributionsRequest(
            documentRange: nodeRange,
            attributions: attributions,
          ),
        ]);
      }
    }
  }
}

class SeparatorColorReaction extends TextNodeAttributionReaction {
  @override
  Set<Attribution> get attributions => {separatorAttribution};

  @override
  bool matches(String text) => text.trim() == '---';
}

final _headerPattern = RegExp(r'^#{1,6} ');

class HeaderHighlightReaction extends TextNodeAttributionReaction {
  @override
  Set<Attribution> get attributions => {headerAttribution};

  @override
  bool matches(String text) => _headerPattern.hasMatch(text.trimLeft());
}

final _blockPattern = RegExp(r'@block\s*\{([^}]*)\}', dotAll: true);
final _blockKeyValuePattern = RegExp(
  r'(\w[\w-]*\s*:)\s*([^,]*?)(?=\s*(?:,|$))',
  dotAll: true,
);

const _blockKeyword = '@block';

/// Highlights `@block { key: value }` directives within each text node:
/// the `@block` keyword and braces use [blockAttribution], keys use
/// [blockKeyAttribution], and values use [blockValueAttribution].
class BlockHighlightReaction extends EditReaction {
  @override
  void modifyContent(
    EditContext editorContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    final document = editorContext.document;
    final attributions = <Attribution>{
      blockAttribution,
      blockKeyAttribution,
      blockValueAttribution,
    };

    for (final node in document) {
      if (node is! TextNode) continue;

      final text = node.text.toPlainText();
      if (text.isEmpty) continue;

      requestDispatcher.execute([
        RemoveTextAttributionsRequest(
          documentRange: DocumentRange(
            start: DocumentPosition(
              nodeId: node.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
            end: DocumentPosition(
              nodeId: node.id,
              nodePosition: TextNodePosition(offset: text.length),
            ),
          ),
          attributions: attributions,
        ),
      ]);

      for (final match in _blockPattern.allMatches(text)) {
        _highlightDirective(node.id, text, match, requestDispatcher);
      }
    }
  }

  void _addAttribution(
    String nodeId,
    int start,
    int end,
    Attribution attribution,
    RequestDispatcher requestDispatcher,
  ) {
    if (end <= start) return;
    requestDispatcher.execute([
      AddTextAttributionsRequest(
        documentRange: DocumentRange(
          start: DocumentPosition(
            nodeId: nodeId,
            nodePosition: TextNodePosition(offset: start),
          ),
          end: DocumentPosition(
            nodeId: nodeId,
            nodePosition: TextNodePosition(offset: end),
          ),
        ),
        attributions: {attribution},
      ),
    ]);
  }

  void _highlightDirective(
    String nodeId,
    String text,
    RegExpMatch match,
    RequestDispatcher requestDispatcher,
  ) {
    final keywordStart = match.start;
    final braceOpen = text.indexOf('{', keywordStart);
    final braceClose = match.end - 1;

    _addAttribution(
      nodeId,
      keywordStart,
      keywordStart + _blockKeyword.length,
      blockAttribution,
      requestDispatcher,
    );
    _addAttribution(
      nodeId,
      braceOpen,
      braceOpen + 1,
      blockAttribution,
      requestDispatcher,
    );
    _addAttribution(
      nodeId,
      braceClose,
      braceClose + 1,
      blockAttribution,
      requestDispatcher,
    );

    final innerStart = braceOpen + 1;
    final inner = text.substring(innerStart, braceClose);
    for (final kv in _blockKeyValuePattern.allMatches(inner)) {
      final keyStart = innerStart + kv.start;
      final keyEnd = keyStart + kv.group(1)!.length;
      _addAttribution(
        nodeId,
        keyStart,
        keyEnd,
        blockKeyAttribution,
        requestDispatcher,
      );

      final value = kv.group(2)!;
      if (value.isEmpty) continue;
      final valueStart = innerStart + kv.start + kv.group(0)!.indexOf(value, kv.group(1)!.length);
      _addAttribution(
        nodeId,
        valueStart,
        valueStart + value.length,
        blockValueAttribution,
        requestDispatcher,
      );
    }
  }
}
