import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_loader.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledDeckLoader', () {
    test('missing bundled asset emits DeckErrorEvent', () async {
      final loader = BundledDeckLoader();
      final events = <DeckEvent>[];
      final subscription = loader.load().listen(events.add);

      addTearDown(() async {
        await subscription.cancel();
        await loader.dispose();
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(events, hasLength(2));
      expect(events[0], isA<DeckLoadingEvent>());
      expect(events[1], isA<DeckErrorEvent>());
      final errorEvent = events[1] as DeckErrorEvent;
      expect(errorEvent.message, contains('Superdeck reference error'));
    });

    test('reload replays bundled load cycle', () async {
      final loader = BundledDeckLoader();
      final events = <DeckEvent>[];
      final subscription = loader.load().listen(events.add);

      addTearDown(() async {
        await subscription.cancel();
        await loader.dispose();
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await loader.reload();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(events.whereType<DeckLoadingEvent>(), hasLength(2));
      expect(events.whereType<DeckErrorEvent>(), hasLength(2));
    });
  });
}
