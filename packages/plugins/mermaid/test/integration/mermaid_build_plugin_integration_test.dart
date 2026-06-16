import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_mermaid/superdeck_mermaid.dart';
import 'package:test/test.dart';

void main() {
  group('MermaidBuildPlugin browser integration', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'mermaid_build_plugin_integration_',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'renders a real Mermaid PNG through DeckBuilder',
      () async {
        final workspace = DeckWorkspace(projectDir: tempDir.path);
        final store = DeckBuildStore(workspace: workspace);
        final plugin = MermaidBuildPlugin();
        final builder = DeckBuilder(
          workspace: workspace,
          store: store,
          plugins: [plugin],
        );
        addTearDown(builder.dispose);

        await workspace.slidesFile.writeAsString('''
# Architecture

```mermaid
graph TD
  Markdown[slides.md] --> Builder[DeckBuilder]
  Builder --> Image[PNG asset]
  Image --> Runtime[SuperDeck runtime]
```
''');

        final slides = (await builder.build()).toList(growable: false);
        final block =
            slides.single.sections.single.blocks.single as ContentBlock;
        final imagePath = _extractImagePath(block.content);
        final imageFile = File(p.join(tempDir.path, imagePath));
        final pngBytes = await imageFile.readAsBytes();

        expect(block.content, isNot(contains('```mermaid')));
        expect(imagePath, startsWith('.superdeck/mermaid/mermaid_'));
        expect(pngBytes.take(8), _pngSignature);
        expect(pngBytes.length, greaterThan(1000));

        final deckJson =
            jsonDecode(await workspace.deckJson.readAsString())
                as List<dynamic>;
        final savedBlock =
            (((deckJson.single as Map<String, dynamic>)['sections']
                            as List<dynamic>)
                        .single
                    as Map<String, dynamic>)['blocks']
                as List<dynamic>;
        expect(
          (savedBlock.single as Map<String, dynamic>)['content'],
          contains(imagePath),
        );
      },
      skip: Platform.environment['SUPERDECK_RUN_BROWSER_TESTS'] == '1'
          ? false
          : 'Set SUPERDECK_RUN_BROWSER_TESTS=1 to run the browser-backed '
                'Mermaid integration test.',
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

const _pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

String _extractImagePath(String content) {
  final match = RegExp(r'!\[Mermaid diagram\]\(([^)]+)\)').firstMatch(content);
  if (match == null) {
    fail('Expected Mermaid image markdown in transformed content:\n$content');
  }

  return match.group(1)!;
}
