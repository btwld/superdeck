import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_loader.dart';
import 'package:superdeck_core/superdeck_core.dart';

Future<void> _mockAsset(String key, String content) async {
  final bytes = ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        if (message == null) return null;
        final requestedKey = utf8.decode(message.buffer.asUint8List());
        return requestedKey == key ? bytes : null;
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledDeckLoader', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('missing bundled asset emits SlidesErrorEvent', () async {
      final loader = BundledDeckLoader();
      final events = <SlidesEvent>[];
      final subscription = loader.load().listen(events.add);

      addTearDown(() async {
        await subscription.cancel();
        await loader.dispose();
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(events, hasLength(2));
      expect(events[0], isA<SlidesLoadingEvent>());
      expect(events[1], isA<SlidesErrorEvent>());
      final errorEvent = events[1] as SlidesErrorEvent;
      expect(errorEvent.message, contains('Superdeck reference error'));
    });

    test('reload replays bundled load cycle', () async {
      final loader = BundledDeckLoader();
      final events = <SlidesEvent>[];
      final subscription = loader.load().listen(events.add);

      addTearDown(() async {
        await subscription.cancel();
        await loader.dispose();
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await loader.reload();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(events.whereType<SlidesLoadingEvent>(), hasLength(2));
      expect(events.whereType<SlidesErrorEvent>(), hasLength(2));
    });
  });
}
