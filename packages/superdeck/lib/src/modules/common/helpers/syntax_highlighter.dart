import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

class SyntaxHighlight {
  SyntaxHighlight._();

  static late HighlighterTheme _theme;

  static final List<String> _mainSupportedLanguages = [
    'dart',
    'json',
    'yaml',
  ];

  static final List<String> _secondarySupportedLangs = [
    'markdown',
    'python',
    'mermaid',
  ];

  static Future<void> initialize() async {
    await Highlighter.initialize(_mainSupportedLanguages);
    _theme = await HighlighterTheme.loadDarkTheme();
    // Load the default light theme and create a highlightfer.

    // Load the markdown grammar and add it to the highlighter.
    for (var language in _secondarySupportedLangs) {
      final grammar = await rootBundle.loadString(
        'packages/superdeck/assets/grammars/$language.json',
      );
      Highlighter.addLanguage(language, grammar);
    }
  }

  static List<TextSpan> render(String source, String? language) {
    final highlighter = Highlighter(language: language!, theme: _theme);
    final code = highlighter.highlight(source);
    return splitTextSpansByLines([code]);
  }
}

/// Splits a list of TextSpans into separate lines based on line breaks.
/// Each returned TextSpan represents one line with preserved styling.
List<TextSpan> splitTextSpansByLines(List<TextSpan> spans) {
  // This will hold lists of TextSpans, each list representing a line.
  List<List<TextSpan>> lines = [[]];

  /// Recursively processes a TextSpan and splits it into lines.
  void processSpan(TextSpan span) {
    if (span.children != null && span.children!.isNotEmpty) {
      // If the span has children, create a new span with the same style.
      final newSpan = TextSpan(style: span.style, children: const []);
      // Add this new span to the current line.
      lines.last.add(newSpan);
      // Recursively process each child.
      for (var child in span.children!) {
        if (child is TextSpan) {
          processSpan(child);
        }
      }
    } else if (span.text != null) {
      // Split the text by line breaks.
      List<String> parts = span.text!.split('\n');
      for (int i = 0; i < parts.length; i++) {
        if (i > 0) {
          // For each new line after the first, add a new empty list.
          lines.add([]);
        }
        if (parts[i].isNotEmpty) {
          // Add the text part to the current line with the same style.
          lines.last.add(TextSpan(text: parts[i], style: span.style));
        }
      }
    }
  }

  // Process each top-level TextSpan.
  for (var span in spans) {
    processSpan(span);
  }

  // Convert each line's list of TextSpans into a single TextSpan.
  return lines.map((lineSpans) => TextSpan(children: lineSpans)).toList();
}

List<int> parseLineNumbers(String input) {
  // Regular expression to find the content within the curly braces
  final regExp = RegExp(r'\{(.*?)\}');
  final match = regExp.firstMatch(input);

  // If there's no match, return an empty list
  if (match == null) return [];

  // Extract the content within the curly braces
  var content = match.group(1) ?? '';

  // Initialize an empty set to hold the line numbers (avoids duplicates)
  var lineNumbers = <int>{};

  // Split the content by comma to separate the elements
  var elements = content.split(',');

  // Iterate over each element to process single numbers and ranges
  for (var element in elements) {
    element = element.trim(); // Trim whitespace
    if (element.isEmpty) {
      continue; // Skip empty elements (e.g., when there are spaces after commas
    }

    if (element.contains('-')) {
      // It's a range, split into start and end
      var rangeParts = element.split('-');
      var start = int.parse(rangeParts[0].trim());
      var end = int.parse(rangeParts[1].trim());

      // Add all numbers in the range to the set
      for (var i = start; i <= end; i++) {
        lineNumbers.add(i);
      }
    } else {
      // It's a single number, add it to the set
      lineNumbers.add(int.parse(element));
    }
  }

  // Convert the set to a list, sort it, and return
  var lineNumberList = lineNumbers.toList();
  lineNumberList.sort();
  return lineNumberList;
}

const vscodeDarkTheme = {
  'root':
      TextStyle(color: Color(0xffD4D4D4), backgroundColor: Color(0xff1E1E1E)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'section': TextStyle(color: Color(0xff569cd6), fontWeight: FontWeight.bold),
  'comment': TextStyle(color: Color(0xff608b4e)),
  'literal': TextStyle(color: Color(0xffb5cea8)),
  'regexp': TextStyle(color: Color(0xff646695)),
  'selector-tag': TextStyle(color: Color(0xff569cd6)),
  'selector-class': TextStyle(color: Color(0xffd7ba7d)),
  'selector-attr': TextStyle(color: Color(0xff9cdcfe)),
  'selector-pseudo': TextStyle(color: Color(0xffd7ba7d)),
  'built_in': TextStyle(color: Color(0xff569cd6)),
  'bullet': TextStyle(color: Color(0xff6796e6)),
  'code': TextStyle(color: Color(0xffce9178)),
  'formula': TextStyle(color: Color(0xff569cd6)),
  'keyword': TextStyle(color: Color(0xff569cd6)),
  'keyword.operator': TextStyle(color: Color(0xffd4d4d4)),
  'operator': TextStyle(color: Color(0xff569cd6)),
  'punctuation': TextStyle(color: Color(0xff808080)),
  'meta': TextStyle(color: Color(0xff569cd6)),
  'meta.string': TextStyle(color: Color(0xffce9178)),
  'number': TextStyle(color: Color(0xffb5cea8)),
  'string': TextStyle(color: Color(0xffce9178)),
  'string.regexp': TextStyle(color: Color(0xffd16969)),
  'symbol': TextStyle(color: Color(0xff569cd6)),
  'type': TextStyle(color: Color(0xff569cd6)),
  'variable': TextStyle(color: Color(0xff9cdcfe)),
};
