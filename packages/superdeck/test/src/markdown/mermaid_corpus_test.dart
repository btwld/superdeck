@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mermaid_core/mermaid_core.dart';
import 'package:superdeck/src/markdown/mermaid/mermaid_source_check.dart';

/// Every Mermaid diagram SuperDeck publishes, rendered for real.
///
/// The corpus is read from the files that make the promise — the guide a
/// reader follows and the demo deck they can run — so a diagram cannot be
/// documented without being renderable, and the renderer cannot be changed
/// without noticing which documented diagram it broke.
void main() {
  final sources = <String, String>{
    for (final path in const [
      '../../docs/guides/mermaid-diagrams.mdx',
      '../../demo/slides.md',
      '../../.agents/skills/superdeck-presentations/references/'
          'runtime-customization.md',
    ])
      ...(_fencesIn(File(path))),
  };

  test('the corpus is the documented one', () {
    // Guards against a silent emptying of the corpus if a path moves.
    expect(sources, hasLength(greaterThanOrEqualTo(12)));
  });

  group('every documented diagram renders', () {
    for (final entry in sources.entries) {
      test(entry.key, () {
        expect(
          () => checkMermaidSource(entry.value),
          returnsNormally,
          reason: entry.value,
        );

        final scene = Mermaid(
          measurer: const ApproximateTextMeasurer(),
        ).render(entry.value);

        expect(scene.nodes, isNotEmpty, reason: entry.value);
        expect(scene.size.width, greaterThan(0));
        expect(scene.size.height, greaterThan(0));
      });
    }
  });
}

/// Extracts ```` ```mermaid ```` fences, keyed by file and first line.
Map<String, String> _fencesIn(File file) {
  if (!file.existsSync()) {
    fail('Mermaid corpus file is missing: ${file.path}');
  }
  final pattern = RegExp(r'```mermaid\n(.*?)```', dotAll: true);
  final name = file.uri.pathSegments.last;
  final found = <String, String>{};
  var index = 0;
  for (final match in pattern.allMatches(file.readAsStringSync())) {
    final source = match.group(1)!;
    final first = source.trim().split('\n').first.trim();
    found['$name #${++index} ($first)'] = source;
  }

  return found;
}
