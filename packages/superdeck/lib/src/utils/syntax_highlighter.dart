import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

class SyntaxHighlight {
  SyntaxHighlight._();

  static late HighlighterTheme _darkTheme;
  static late HighlighterTheme _lightTheme;
  static bool _isInitialized = false;
  static bool _warnedUninitialized = false;
  static Future<void>? _initializeFuture;

  static final List<String> _mainSupportedLanguages = ['dart', 'json', 'yaml'];

  static final List<String> _secondarySupportedLangs = ['markdown', 'python'];

  static Future<void> initialize() {
    if (_isInitialized) return Future.value();
    _initializeFuture ??= _initialize();
    return _initializeFuture!;
  }

  static Future<void> _initialize() async {
    try {
      await Highlighter.initialize(_mainSupportedLanguages);
      final themes = await Future.wait([
        HighlighterTheme.loadDarkTheme(),
        HighlighterTheme.loadLightTheme(),
      ]);
      _darkTheme = themes.first;
      _lightTheme = themes.last;

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

  static List<TextSpan> render(
    String source,
    String? language, {
    Color? backgroundColor,
  }) {
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
      final brightness =
          backgroundColor != null && backgroundColor.computeLuminance() > 0.5
          ? Brightness.light
          : Brightness.dark;
      final highlighter = Highlighter(
        language: effectiveLanguage,
        theme: brightness == Brightness.light ? _lightTheme : _darkTheme,
      );
      var code = highlighter.highlight(source);
      if (backgroundColor != null) {
        code = _ensureSpanContrast(code, backgroundColor);
      }
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

TextSpan _ensureSpanContrast(TextSpan span, Color background) {
  final style = span.style;
  final color = style?.color;
  final adjustedStyle = color == null
      ? style
      : style?.copyWith(color: _ensureColorContrast(color, background));

  return TextSpan(
    text: span.text,
    style: adjustedStyle,
    children: span.children
        ?.whereType<TextSpan>()
        .map((child) => _ensureSpanContrast(child, background))
        .toList(growable: false),
  );
}

Color _ensureColorContrast(Color foreground, Color background) {
  if (_contrastRatio(foreground, background) >= 4.5) return foreground;
  final target = background.computeLuminance() > 0.5
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);
  for (var step = 1; step <= 20; step++) {
    final candidate = Color.lerp(foreground, target, step / 20)!;
    if (_contrastRatio(candidate, background) >= 4.5) return candidate;
  }

  return target;
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;

  return (lighter + 0.05) / (darker + 0.05);
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
