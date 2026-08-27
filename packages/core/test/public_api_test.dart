import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('superdeck_core public api', () {
    test('exports the supported runtime surface', () {
      final workspace = DeckWorkspace(projectDir: '/tmp/test-deck');
      final slide = Slide(key: 'intro');
      final padding = BlockInsets.all(8);

      expect(workspace.deckJson.path, contains('superdeck.json'));
      expect(DeckPlugin, isNotNull);
      expect(slidesContractSchema, isNotNull);
      expect(SectionBlockSchema.wireSchema, isNotNull);
      expect(SlideSchema.wireSchema, isNotNull);
      expect(Slide.fromJson(slide.toJson()), slide);
      expect(parseSlidesContract([slide.toJson()]), hasLength(1));
      expect(padding.left, 8);
    });
  });
}
