import 'package:superdeck_builder/src/parsers/block_parser.dart';
import 'package:superdeck_builder/src/parsers/directive_names.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('reservedDirectiveNames', () {
    test('column is rejected as a bare authoring tag', () {
      expect(
        () => const BlockParser().parse('@$deprecatedColumnDirective'),
        throwsA(
          isA<DeckFormatException>().having(
            (error) => error.message,
            'message',
            contains('Unsupported @$deprecatedColumnDirective directive'),
          ),
        ),
      );
    });

    test('structural tags stay structural, not widgets', () {
      final section = const BlockParser().parse('@section').single;
      final block = const BlockParser().parse('@block').single;
      final widget = const BlockParser()
          .parse('@widget { name: chart }')
          .single;

      expect(section.type, SectionBlock.key);
      expect(section.data['type'], SectionBlock.key);
      expect(block.data['type'], ContentBlock.key);
      expect(widget.data['type'], WidgetBlock.key);
      expect(widget.data['name'], 'chart');
    });

    test('unreserved tags become widget shorthand', () {
      final parsed = const BlockParser().parse('@image').single;
      expect(parsed.data['type'], WidgetBlock.key);
      expect(parsed.data['name'], 'image');
      expect(reservedDirectiveNames.contains('image'), isFalse);
    });
  });
}
