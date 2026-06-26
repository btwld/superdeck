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
    group('style signal initial state', () {
      test('is null when no style has been set', () {
        expect(DeckStyleService.style.value, isNull);
      });
    });

    group('style signal reads', () {
      test('returns null when cache is empty', () {
        expect(DeckStyleService.style.value, isNull);
      });

      test('returns style after setStyle is called', () {
        DeckStyleService.setStyle(
          DeckStyleType.parse(buildStyle(heading: '#FF0000')),
        );

        final result = DeckStyleService.style.value;
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

        final result = DeckStyleService.style.value;
        expect(result, isNotNull);
        expect(result!.colors.heading, '#ABABAB');
        expect(notifications, 1);
      });

      test('setStyleFromJson parses and stores valid style payload', () {
        final parsed = DeckStyleService.setStyleFromJson(buildStyle());

        expect(parsed, isNotNull);
        expect(DeckStyleService.style.value?.name, 'Test Style');
      });

      test('setStyleFromJson returns null for invalid payload', () {
        final parsed = DeckStyleService.setStyleFromJson({'name': 'invalid'});

        expect(parsed, isNull);
        expect(DeckStyleService.style.value, isNull);
      });
    });

    group('setStyle', () {
      test('updates signal with new style', () {
        final style = DeckStyleType.parse(buildStyle(heading: '#123456'));

        DeckStyleService.setStyle(style);

        final result = DeckStyleService.style.value;
        expect(result, isNotNull);
        expect(result!.colors.heading, '#123456');
      });

      test('can set to null', () {
        DeckStyleService.setStyle(
          DeckStyleType.parse(buildStyle(heading: '#000000')),
        );
        expect(DeckStyleService.style.value, isNotNull);

        DeckStyleService.setStyle(null);
        expect(DeckStyleService.style.value, isNull);
      });

      test('setStyle after clearCache leaves signal updated', () {
        DeckStyleService.setStyle(
          DeckStyleType.parse(buildStyle(heading: '#DIRECT')),
        );

        final result = DeckStyleService.style.value;
        expect(result!.colors.heading, '#DIRECT');
      });
    });

    group('clearCache', () {
      test('resets style to null', () {
        DeckStyleService.setStyle(
          DeckStyleType.parse(buildStyle(heading: '#FF0000')),
        );
        expect(DeckStyleService.style.value, isNotNull);

        DeckStyleService.clearCache();

        expect(DeckStyleService.style.value, isNull);
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
      test('signal value is shared across reads', () {
        DeckStyleService.setStyle(
          DeckStyleType.parse(buildStyle(heading: '#FF0000')),
        );

        final result1 = DeckStyleService.style.value;
        final result2 = DeckStyleService.style.value;
        final result3 = DeckStyleService.style.value;

        expect(identical(result1, result2), isTrue);
        expect(identical(result2, result3), isTrue);
      });
    });
  });
}
