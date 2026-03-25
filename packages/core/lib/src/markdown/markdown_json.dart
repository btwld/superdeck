import 'dart:convert';

import 'package:markdown/markdown.dart' as md;

/// Helper for converting Markdown into Dart map or JSON representations.
///
/// Configure an instance with the desired [extensionSet], [blockSyntaxes],
/// and [inlineSyntaxes], then call [toMap] or [toJson].
///
/// ```dart
/// const converter = MarkdownAstConverter(
///   extensionSet: md.ExtensionSet.gitHubWeb,
/// );
///
/// final ast = converter.toMap('# Hello', includeMetadata: true);
/// final json = converter.toJson('# Hello', prettyPrint: true);
/// ```
class MarkdownAstConverter {
  const MarkdownAstConverter({
    this.extensionSet,
    this.blockSyntaxes,
    this.inlineSyntaxes,
  });

  final md.ExtensionSet? extensionSet;
  final List<md.BlockSyntax>? blockSyntaxes;
  final List<md.InlineSyntax>? inlineSyntaxes;

  /// Returns a Map representation of the Markdown AST.
  Map<String, Object?> toMap(
    String markdown, {
    bool includeMetadata = false,
    md.ExtensionSet? extensionSet,
    List<md.BlockSyntax>? blockSyntaxes,
    List<md.InlineSyntax>? inlineSyntaxes,
  }) {
    final document = md.Document(
      extensionSet: extensionSet ?? this.extensionSet,
      blockSyntaxes: blockSyntaxes ?? this.blockSyntaxes,
      inlineSyntaxes: inlineSyntaxes ?? this.inlineSyntaxes,
    );

    final nodes = document.parse(markdown);

    final result = <String, Object?>{
      'type': 'document',
      'children': nodes.map(nodeToMap).toList(growable: false),
    };

    if (includeMetadata) {
      result['linkReferences'] = document.linkReferences.map(
        (key, value) => MapEntry(key, <String, Object?>{
          'destination': value.destination,
          if (value.title != null) 'title': value.title,
        }),
      );
      result['footnoteLabels'] = List<String>.of(document.footnoteLabels);
      result['footnoteReferences'] = Map<String, int>.of(
        document.footnoteReferences,
      );
    }

    return result;
  }

  /// Returns a JSON representation of the Markdown AST.
  String toJson(
    String markdown, {
    bool prettyPrint = false,
    bool includeMetadata = false,
    md.ExtensionSet? extensionSet,
    List<md.BlockSyntax>? blockSyntaxes,
    List<md.InlineSyntax>? inlineSyntaxes,
  }) {
    final map = toMap(
      markdown,
      includeMetadata: includeMetadata,
      extensionSet: extensionSet,
      blockSyntaxes: blockSyntaxes,
      inlineSyntaxes: inlineSyntaxes,
    );

    return prettyPrint
        ? const JsonEncoder.withIndent('  ').convert(map)
        : json.encode(map);
  }
}

/// Converts a markdown AST [md.Node] into a `Map<String, Object?>`.
///
/// Handles [md.Element], [md.Text], and [md.UnparsedContent] node types.
/// Throws [UnimplementedError] for unrecognized node types.
Map<String, Object?> nodeToMap(md.Node node) {
  if (node is md.Element) {
    return _elementToMap(node);
  }

  if (node is md.Text) {
    return {'type': 'text', 'text': node.text};
  }

  if (node is md.UnparsedContent) {
    return {'type': 'unparsed', 'text': node.textContent};
  }

  throw UnimplementedError('Unknown markdown node type: ${node.runtimeType}');
}

/// Converts an Element node to a Map.
///
/// Internal helper function for [nodeToMap].
Map<String, Object?> _elementToMap(md.Element element) {
  final json = <String, Object?>{'type': 'element', 'tag': element.tag};

  final attrs = element.attributes;
  if (attrs.isNotEmpty) {
    json['attributes'] = Map<String, String>.of(attrs);
  }

  final children = element.children;
  if (children != null) {
    json['children'] = children.map(nodeToMap).toList(growable: false);
  }

  if (element.generatedId != null) {
    json['generatedId'] = element.generatedId;
  }

  if (element.footnoteLabel != null) {
    json['footnoteLabel'] = element.footnoteLabel;
  }

  if (element.isEmpty) {
    json['isEmpty'] = true;
  }

  return json;
}
