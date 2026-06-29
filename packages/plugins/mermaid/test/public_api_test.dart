import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_mermaid/superdeck_mermaid.dart';
import 'package:test/test.dart';

void main() {
  group('superdeck_mermaid public api', () {
    test('exports the supported Mermaid surface', () async {
      final plugin = MermaidBuildPlugin(
        configuration: const {'theme': 'forest'},
      );
      addTearDown(plugin.dispose);

      expect(plugin, isA<DeckBuildPlugin>());
      expect(MermaidGenerator, isNotNull);
    });
  });
}
