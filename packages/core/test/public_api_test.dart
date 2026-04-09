import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('superdeck_core public api', () {
    test('exports the supported runtime surface', () {
      final workspace = DeckWorkspace(projectDir: '/tmp/test-deck');
      final slide = Slide(key: 'intro');

      expect(workspace.deckJson.path, contains('superdeck.json'));
      expect(slidesContractSchema, isNotNull);
      expect(parseSlidesContract([slide.toMap()]), hasLength(1));
    });
  });
}
