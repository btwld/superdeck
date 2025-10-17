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

/// Converts a single markdown AST node to a Map.
///
/// Supports three node types from the markdown package:
/// - [md.Element]: Named tags that can contain other nodes (e.g., paragraphs, headings)
/// - [md.Text]: Plain text nodes
/// - [md.UnparsedContent]: Inline content not yet parsed into nodes
///
/// For Element nodes, the returned Map includes:
/// - `type`: Always 'element'
/// - `tag`: The HTML tag name (e.g., 'p', 'h1', 'strong')
/// - `children`: (optional) List of child nodes
/// - `attributes`: (optional) Map of HTML attributes
/// - `generatedId`: (optional) Auto-generated ID for headings
/// - `footnoteLabel`: (optional) Footnote label
/// - `isEmpty`: (optional) true for self-closing elements like `<br/>` or `<hr/>`
///
/// For Text nodes:
/// - `type`: Always 'text'
/// - `text`: The text content
///
/// For UnparsedContent nodes:
/// - `type`: Always 'unparsed'
/// - `text`: The unparsed text content
///
/// Throws [UnimplementedError] if the node type is not one of the above.
///
/// Example:
/// ```dart
/// final element = md.Element('p', [md.Text('Hello')]);
/// final map = nodeToMap(element);
/// // Returns: {type: 'element', tag: 'p', children: [{type: 'text', text: 'Hello'}]}
/// ```
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
