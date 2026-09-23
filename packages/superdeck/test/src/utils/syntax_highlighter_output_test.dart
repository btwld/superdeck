import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/utils/syntax_highlighter.dart';

/// Regenerates the fixture from the current highlighter instead of comparing.
const _update = bool.fromEnvironment('UPDATE_HIGHLIGHT_FIXTURE');

const _fixturePath = 'test/fixtures/syntax_highlight/rendered_spans.json';

const _samples = {
  'dart': '''
import 'dart:async';

/// A counter.
class Counter {
  int _value = 0;

  Future<void> increment({int by = 1}) async {
    _value += by; // bump
    print('value: \$_value');
  }
}
''',
  'json': '''
{"name": "superdeck", "version": 1, "tags": ["slides", true, null]}
''',
  'yaml': '''
# Deck options
title: Launch
style: dark
sections:
  - name: intro
    flex: 2
''',
  'markdown': '''
# Heading

Some *emphasis*, **strong**, and `code`.

- item one
- [link](https://superdeck.dev)
''',
  'python': '''
def greet(name: str) -> str:
    """Say hello."""
    return f"Hello, {name}!"  # done
''',
  // Unsupported languages fall back to the Dart grammar.
  'rust': '''
fn main() { println!("hi"); }
''',
};

const _backgrounds = {
  'light': Color(0xFFFFFFFF),
  'dark': Color(0xFF101010),
};

Object? _spanToJson(InlineSpan span) {
  if (span is! TextSpan) return span.runtimeType.toString();
  final style = span.style;

  return {
    if (span.text != null) 'text': span.text,
    if (style?.color != null)
      'color': style!.color!.toARGB32().toRadixString(16),
    if (style?.fontWeight != null) 'weight': style!.fontWeight!.value,
    if (style?.fontStyle != null) 'style': style!.fontStyle!.name,
    if (span.children != null)
      'children': span.children!.map(_spanToJson).toList(),
  };
}

Map<String, Object?> _render() => {
  for (final MapEntry(key: language, value: source) in _samples.entries)
    for (final MapEntry(key: mode, value: background) in _backgrounds.entries)
      '$language/$mode': SyntaxHighlight.render(
        source,
        language,
        backgroundColor: background,
      ).map(_spanToJson).toList(),
};

void main() {
  testWidgets('highlighted output matches the recorded spans', (tester) async {
    await SyntaxHighlight.initialize();

    final rendered = _render();
    final file = File(_fixturePath);
    // Synchronous I/O: real async file work never completes in the test zone.
    if (_update) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(rendered)}\n',
      );
    }

    final recorded = jsonDecode(file.readAsStringSync());
    expect(jsonDecode(jsonEncode(rendered)), recorded);
  });
}
