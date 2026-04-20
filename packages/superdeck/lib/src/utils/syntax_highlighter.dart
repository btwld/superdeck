import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

class SyntaxHighlight {
  SyntaxHighlight._();

  static late HighlighterTheme _theme;
  static bool _isInitialized = false;
  static bool _warnedUninitialized = false;
  static Future<void>? _initializeFuture;

  static final List<String> _mainSupportedLanguages = ['dart', 'json', 'yaml'];

  static final List<String> _secondarySupportedLangs = [
    'markdown',
    'python',
  ];

  static Future<void> initialize() {
    if (_isInitialized) return Future.value();
    _initializeFuture ??= _initialize();
    return _initializeFuture!;
  }

  static Future<void> _initialize() async {
    try {
      await Highlighter.initialize(_mainSupportedLanguages);
      _theme = await HighlighterTheme.loadDarkTheme();

      // Load the markdown grammar and add it to the highlighter.
      for (var language in _secondarySupportedLangs) {
        final grammar = await rootBundle.loadString(
          'packages/superdeck/assets/grammars/$language.json',
        );
        Highlighter.addLanguage(language, grammar);
      }

      _isInitialized = true;
    } catch (_) {
      _initializeFuture = null;
      rethrow;
    }
  }

  static List<TextSpan> render(String source, String? language) {
    if (!_isInitialized) {
      if (!_warnedUninitialized) {
        debugPrint(
          '[SyntaxHighlighter] render() called before initialize(); '
          'returning plain text.',
        );
        _warnedUninitialized = true;
      }
      return [TextSpan(text: source)];
    }

    // Get all supported languages (main + secondary)
    final allSupportedLanguages = [
      ..._mainSupportedLanguages,
      ..._secondarySupportedLangs,
    ];

    // Use provided language if supported, otherwise default to 'dart'
    String effectiveLanguage = language ?? 'dart';
    if (!allSupportedLanguages.contains(language)) {
      effectiveLanguage = 'dart';
    }

    try {
      final highlighter = Highlighter(
        language: effectiveLanguage,
        theme: _theme,
      );
      final code = highlighter.highlight(source);
      return splitTextSpansByLines([code]);
    } catch (e, stackTrace) {
      // Log the failure for debugging, but gracefully return plain text
      debugPrint(
        '[SyntaxHighlighter] Failed to highlight $effectiveLanguage: $e',
      );
      debugPrint('[SyntaxHighlighter] Stack: $stackTrace');
      return [TextSpan(text: source)];
    }
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
