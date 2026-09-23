// Vendored from syntax_highlight 0.5.0 (pub.dev), file
// `lib/src/highlighter.dart`, at https://github.com/serverpod/syntax_highlight
// commit 7ac296c6 (2025-08-19). Copyright 2023 The Serverpod authors.
// BSD-3-Clause licensed; see the licence text reproduced in `LICENSE` beside
// this file.
//
// WHY THIS COPY EXISTS
// --------------------
// The package depends on super_clipboard for its CodeEditor widget, which
// SuperDeck does not use. That pulls in super_native_extensions and
// irondash_engine_context: native plugins without Swift Package Manager
// support (forcing a CocoaPods fallback on macOS and iOS) and with a known
// Android 16 KB page-size crash in 0.9.1. Only the highlighter is copied, so
// none of that ships with SuperDeck.
//
// Two places differ from upstream, both marked `SUPERDECK PATCH`:
//
//   1. The `span_parser.dart` import points at the copy beside this file.
//   2. Grammars and themes load from SuperDeck's own assets.
//
// TO RE-SYNC: diff this file against the same path in a newer
// syntax_highlight, re-apply the two patches, and run
// `test/src/utils/syntax_highlighter_output_test.dart`. Delete this copy once
// the published package no longer depends on super_clipboard.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// SUPERDECK PATCH: import the vendored copy.
import 'span_parser.dart';

const _bracketStyles = <TextStyle>[
  TextStyle(color: Color(0xFF5caeef)),
  TextStyle(color: Color(0xFFdfb976)),
  TextStyle(color: Color(0xFFc172d9)),
  TextStyle(color: Color(0xFF4fb1bc)),
  TextStyle(color: Color(0xFF97c26c)),
  TextStyle(color: Color(0xFFabb2c0)),
];

const _failedBracketStyle = TextStyle(color: Color(0xFFff0000));

// SUPERDECK PATCH: themes load from SuperDeck's assets.
const _defaultLightThemeFiles = [
  'packages/superdeck/assets/highlight_themes/light_vs.json',
  'packages/superdeck/assets/highlight_themes/light_plus.json',
];

// SUPERDECK PATCH: themes load from SuperDeck's assets.
const _defaultDarkThemeFiles = [
  'packages/superdeck/assets/highlight_themes/dark_vs.json',
  'packages/superdeck/assets/highlight_themes/dark_plus.json',
];

/// The [Highlighter] class can format a String of code and add syntax
/// highlighting in the form of a [TextSpan]. Currrently supports Dart and
/// YAML. Formatting style is similar to VS Code.
class Highlighter {
  static final _cache = <String, Grammar>{};

  /// Creates a [Highlighter] for the given [language] and [theme]. The
  /// [language] must be one of the languages supported by this package,
  /// unless it has been manually added. Before creating a [Highlighter],
  /// you must call [initialize] with a list of languages to load.
  Highlighter({
    required this.language,
    required this.theme,
  }) {
    _grammar = _cache[language]!;
  }

  /// Initializes the [Highlighter] with the given list of [languages]. This
  /// must be called before creating any [Highlighter]s. Supported languages
  /// are 'dart' and 'yaml'.
  static Future<void> initialize(List<String> languages) async {
    for (var language in languages) {
      // SUPERDECK PATCH: grammars load from SuperDeck's assets.
      var json = await rootBundle.loadString(
        'packages/superdeck/assets/grammars/$language.json',
      );
      _cache[language] = Grammar.fromJson(jsonDecode(json));
    }
  }

  /// Adds a custom language to the list of languages.
  /// Associates a language [name] with a TextMate formatted [json] definition.
  /// This must be called before creating any [Highlighter]s.
  static void addLanguage(String name, String json) {
    _cache.putIfAbsent(name, () => Grammar.fromJson(jsonDecode(json)));
  }

  /// The language of this [Highlighter].
  final String language;

  late final Grammar _grammar;

  /// The [HighlighterTheme] used to style the code.
  final HighlighterTheme theme;

  /// Formats the given [code] and returns a [TextSpan] with syntax
  /// highlighting.
  TextSpan highlight(String code) {
    var spans = SpanParser.parse(_grammar, code);
    var textSpans = <TextSpan>[];
    var bracketCounter = 0;

    int charPos = 0;
    for (var span in spans) {
      // Add any text before the span.
      if (span.start > charPos) {
        var text = code.substring(charPos, span.start);
        TextSpan? textSpan;
        (textSpan, bracketCounter) = _formatBrackets(text, bracketCounter);
        textSpans.add(
          textSpan,
        );

        charPos = span.start;
      }

      // Add the span.
      var segment = code.substring(span.start, span.end);
      var style = theme._getStyle(span.scopes);
      textSpans.add(
        TextSpan(
          text: segment,
          style: style,
        ),
      );

      charPos = span.end;
    }

    // Add any text after the last span.
    if (charPos < code.length) {
      var text = code.substring(charPos, code.length);
      TextSpan? textSpan;
      (textSpan, bracketCounter) = _formatBrackets(text, bracketCounter);
      textSpans.add(
        textSpan,
      );
    }

    return TextSpan(children: textSpans, style: theme._wrapper);
  }

  (TextSpan, int) _formatBrackets(String text, int bracketCounter) {
    var spans = <TextSpan>[];
    var plainText = '';
    for (var char in text.characters) {
      if (_isStartingBracket(char)) {
        if (plainText.isNotEmpty) {
          spans.add(TextSpan(text: plainText));
          plainText = '';
        }

        spans.add(TextSpan(
          text: char,
          style: _getBracketStyle(bracketCounter),
        ));
        bracketCounter += 1;
        plainText = '';
      } else if (_isEndingBracket(char)) {
        if (plainText.isNotEmpty) {
          spans.add(TextSpan(text: plainText));
          plainText = '';
        }

        bracketCounter -= 1;
        spans.add(TextSpan(
          text: char,
          style: _getBracketStyle(bracketCounter),
        ));
        plainText = '';
      } else {
        plainText += char;
      }
    }
    if (plainText.isNotEmpty) {
      spans.add(TextSpan(text: plainText));
    }

    if (spans.length == 1) {
      return (spans[0], bracketCounter);
    } else {
      return (TextSpan(children: spans), bracketCounter);
    }
  }

  TextStyle _getBracketStyle(int bracketCounter) {
    if (bracketCounter < 0) {
      return _failedBracketStyle;
    }
    return _bracketStyles[bracketCounter % _bracketStyles.length];
  }

  bool _isStartingBracket(String bracket) {
    return bracket == '{' || bracket == '[' || bracket == '(';
  }

  bool _isEndingBracket(String bracket) {
    return bracket == '}' || bracket == ']' || bracket == ')';
  }
}

/// A [HighlighterTheme] which is used to style the code.
class HighlighterTheme {
  final TextStyle _wrapper;
  TextStyle? _fallback;
  final _scopes = <String, TextStyle>{};

  HighlighterTheme._({required TextStyle wrapper}) : _wrapper = wrapper;

  /// Load a [HighlighterTheme] from a JSON string.
  factory HighlighterTheme.fromConfiguration(
    String json,
    TextStyle defaultStyle,
  ) {
    final theme = HighlighterTheme._(wrapper: defaultStyle);
    theme._parseTheme(json);
    return theme;
  }

  /// Loads the default theme for the given [brightness].
  static Future<HighlighterTheme> loadForBrightness(
    Brightness brightness,
  ) async {
    if (brightness == Brightness.dark) {
      return loadDarkTheme();
    } else {
      return loadLightTheme();
    }
  }

  /// Loads the default theme for the given [BuildContext].
  static Future<HighlighterTheme> loadForContext(
    BuildContext context,
  ) async {
    return loadForBrightness(
      Theme.of(context).brightness,
    );
  }

  /// Loads the default dark theme.
  static Future<HighlighterTheme> loadDarkTheme() async {
    return loadFromAssets(
      _defaultDarkThemeFiles,
      const TextStyle(color: Color(0xFFB9EEFF)),
    );
  }

  /// Loads the default light theme.
  static Future<HighlighterTheme> loadLightTheme() async {
    return loadFromAssets(
      _defaultLightThemeFiles,
      const TextStyle(color: Color(0xFF000088)),
    );
  }

  /// Loads a custom theme from a (list of) [jsonFiles] and a [defaultStyle].
  /// Pass in multiple [jsonFiles] to merge multiple themes.
  static Future<HighlighterTheme> loadFromAssets(
    List<String> jsonFiles,
    TextStyle defaultStyle,
  ) async {
    var theme = HighlighterTheme._(wrapper: defaultStyle);
    await theme._load(jsonFiles);
    return theme;
  }

  Future<void> _load(List<String> definitions) async {
    for (var definition in definitions) {
      var json = await rootBundle.loadString(
        definition,
      );
      _parseTheme(json);
    }
  }

  void _parseTheme(String json) {
    var theme = jsonDecode(json);
    List settings = theme['settings'];
    for (Map setting in settings) {
      var style = _parseTextStyle(setting['settings']);

      var scopes = setting['scope'];
      if (scopes is String) {
        _addScope(scopes, style);
      } else if (scopes is List) {
        for (String scope in scopes) {
          _addScope(scope, style);
        }
      } else if (scopes == null) {
        _fallback = style;
      }
    }
  }

  TextStyle _parseTextStyle(Map setting) {
    Color? color;
    var foregroundSetting = setting['foreground'];
    if (foregroundSetting is String && foregroundSetting.startsWith('#')) {
      color = Color(
        int.parse(
              foregroundSetting.substring(1),
              radix: 16,
            ) |
            0xFF000000,
      );
    }

    FontStyle? fontStyle;
    FontWeight? fontWeight;
    TextDecoration? textDecoration;

    var fontStyleSetting = setting['fontStyle'];
    if (fontStyleSetting is String) {
      if (fontStyleSetting == 'italic') {
        fontStyle = FontStyle.italic;
      } else if (fontStyleSetting == 'bold') {
        fontWeight = FontWeight.bold;
      } else if (fontStyleSetting == 'underline') {
        textDecoration = TextDecoration.underline;
      } else {
        throw Exception('WARNING unknown style: $fontStyleSetting');
      }
    }

    return TextStyle(
      color: color,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      decoration: textDecoration,
    );
  }

  void _addScope(String scope, TextStyle style) {
    _scopes[scope] = style;
  }

  TextStyle? _getStyle(List<String> scope) {
    for (var s in scope) {
      var fallbacks = _fallbacks(s);
      for (var f in fallbacks) {
        var style = _scopes[f];
        if (style != null) {
          return style;
        }
      }
    }
    return _fallback;
  }

  List<String> _fallbacks(String scope) {
    var fallbacks = <String>[];
    var parts = scope.split('.');
    for (var i = 0; i < parts.length; i++) {
      var s = parts.sublist(0, i + 1).join('.');
      fallbacks.add(s);
    }
    return fallbacks.reversed.toList();
  }
}
