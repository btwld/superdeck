import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_loader.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledDeckLoader', () {
    test('missing bundled asset emits DeckErrorEvent', () async {
      final configuration = DeckConfiguration();
      final loader = BundledDeckLoader(configuration: configuration);

      final events = await loader.load().toList();

      expect(events, hasLength(2));
      expect(events[0], isA<DeckLoadingEvent>());
      expect(events[1], isA<DeckErrorEvent>());
      final errorEvent = events[1] as DeckErrorEvent;
      expect(errorEvent.message, contains('Superdeck reference error'));
    });
  });
}
