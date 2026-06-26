import 'package:flutter_test/flutter_test.dart';
import 'package:signals/signals_flutter.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/utils/deck_style_service.dart';

void main() {
  setUp(() {
    DeckStyleService.clearCache();
  });

  tearDown(() {
    DeckStyleService.clearCache();
  });

  Map<String, Object?> buildStyle({
    String name = 'Test Style',
    String heading = '#FF0000',
    String body = '#00FF00',
    String background = '#FFFFFF',
    Map<String, Object?> fonts = const {
      'headline': 'montserrat',
      'body': 'openSans',
    },
  }) {
    return {
      'name': name,
      'colors': {'background': background, 'heading': heading, 'body': body},
      'fonts': fonts,
    };
  }

  group('DeckStyleService', () {
    group('preloadStyle', () {
      test('returns null from cache when no style has been set', () async {
        // preloadStyle is a no-op in the in-memory implementation
        await DeckStyleService.preloadStyle();

        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNull);
      });
    });

    group('readStyleFromCache', () {
      test('returns null when cache is empty', () {
        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNull);
      });

      test('returns style after setStyle is called', () {
        DeckStyleService.setStyle(
          DeckStyleType.parse(buildStyle(heading: '#FF0000')),
        );

        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNotNull);
        expect(result!.colors.heading, '#FF0000');
      });
    });

    group('reactive style API', () {
      test('setStyle updates cache and notifies signal subscribers', () {
        var notifications = -1;
        final dispose = effect(() {
          DeckStyleService.style.value;
          notifications++;
        });

        DeckStyleService.setStyle(
          DeckStyleType.parse(buildStyle(heading: '#ABABAB')),
        );

        dispose();

        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNotNull);
        expect(result!.colors.heading, '#ABABAB');
        expect(notifications, 1);
      });

      test('setStyleFromJson parses and stores valid style payload', () {
        final parsed = DeckStyleService.setStyleFromJson(buildStyle());

        expect(parsed, isNotNull);
        expect(DeckStyleService.readStyleFromCache()?.name, 'Test Style');
      });

      test('setStyleFromJson returns null for invalid payload', () {
        final parsed = DeckStyleService.setStyleFromJson({'name': 'invalid'});

        expect(parsed, isNull);
        expect(DeckStyleService.readStyleFromCache(), isNull);
      });
    });

    group('updateCache', () {
      test('updates cache with new style', () {
        final style = DeckStyleType.parse(buildStyle(heading: '#123456'));

        DeckStyleService.updateCache(style);

        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNotNull);
        expect(result!.colors.heading, '#123456');
      });

      test('can update cache to null', () {
        DeckStyleService.updateCache(
          DeckStyleType.parse(buildStyle(heading: '#000000')),
        );
        expect(DeckStyleService.readStyleFromCache(), isNotNull);

        DeckStyleService.updateCache(null);
        expect(DeckStyleService.readStyleFromCache(), isNull);
      });

      test('preloadStyle is a no-op after updateCache', () async {
        DeckStyleService.updateCache(
          DeckStyleType.parse(buildStyle(heading: '#DIRECT')),
        );

        // preloadStyle is always a no-op in the in-memory implementation
        await DeckStyleService.preloadStyle();

        final result = DeckStyleService.readStyleFromCache();
        expect(result!.colors.heading, '#DIRECT');
      });
    });

    group('clearCache', () {
      test('resets style to null', () {
        DeckStyleService.setStyle(
          DeckStyleType.parse(buildStyle(heading: '#FF0000')),
        );
        expect(DeckStyleService.readStyleFromCache(), isNotNull);

        DeckStyleService.clearCache();

        expect(DeckStyleService.readStyleFromCache(), isNull);
      });

      test('does not throw when called multiple times', () {
        expect(() {
          DeckStyleService.clearCache();
          DeckStyleService.clearCache();
          DeckStyleService.clearCache();
        }, returnsNormally);
      });

      test('does not throw when cache is already empty', () {
        expect(() => DeckStyleService.clearCache(), returnsNormally);
      });
    });

    group('cache behavior', () {
      test('cache is shared across calls', () {
        DeckStyleService.setStyle(
          DeckStyleType.parse(buildStyle(heading: '#FF0000')),
        );

        final result1 = DeckStyleService.readStyleFromCache();
        final result2 = DeckStyleService.readStyleFromCache();
        final result3 = DeckStyleService.readStyleFromCache();

        expect(identical(result1, result2), isTrue);
        expect(identical(result2, result3), isTrue);
      });
    });
  });
}
