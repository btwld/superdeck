import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:signals/signals_flutter.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_genui/src/ai/schemas/deck_schemas.dart';
import 'package:superdeck_genui/src/path_service.dart';
import 'package:superdeck_genui/src/utils/deck_style_service.dart';

void main() {
  late Directory tempDir;
  late String superdeckPath;

  setUp(() async {
    // Create temp directory for tests
    tempDir = await Directory.systemTemp.createTemp('deck_style_test_');
    superdeckPath = p.join(tempDir.path, '.superdeck');

    // Configure PathService to use temp directory
    PathService.instance.setBaseDirForTest(superdeckPath);

    // Create .superdeck directory
    await Directory(superdeckPath).create();

    // Clear any cached state
    DeckStyleService.clearCache();
  });

  tearDown(() async {
    // Reset PathService
    PathService.instance.resetForTest();

    // Clear cache
    DeckStyleService.clearCache();

    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
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
      test('returns null from cache when file does not exist', () async {
        await DeckStyleService.preloadStyle();

        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNull);
      });

      test('returns null from cache when file has no style key', () async {
        final file = File(p.join(superdeckPath, DeckArtifacts.deckJsonFile));
        await file.writeAsString(
          jsonEncode({'slides': [], 'title': 'Test Deck'}),
        );

        await DeckStyleService.preloadStyle();

        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNull);
      });

      test('returns style from cache when present in file', () async {
        final expectedStyle = buildStyle();
        final file = File(p.join(superdeckPath, DeckArtifacts.deckJsonFile));
        await file.writeAsString(
          jsonEncode({'slides': [], 'style': expectedStyle}),
        );

        await DeckStyleService.preloadStyle();

        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNotNull);
        expect(result!.colors.heading, '#FF0000');
      });

      test('does not reload if already preloaded', () async {
        final file = File(p.join(superdeckPath, DeckArtifacts.deckJsonFile));
        await file.writeAsString(
          jsonEncode({'style': buildStyle(heading: '#FF0000')}),
        );

        // First preload
        await DeckStyleService.preloadStyle();
        final result1 = DeckStyleService.readStyleFromCache();

        // Modify file
        await file.writeAsString(
          jsonEncode({'style': buildStyle(heading: '#00FF00')}),
        );

        // Second preload should be no-op (already preloaded)
        await DeckStyleService.preloadStyle();
        final result2 = DeckStyleService.readStyleFromCache();

        // Should return same cached value
        expect(identical(result1, result2), isTrue);
        expect(result2!.colors.heading, '#FF0000');
      });

      test('returns null on JSON parse error', () async {
        final file = File(p.join(superdeckPath, DeckArtifacts.deckJsonFile));
        await file.writeAsString('not valid json {{{');

        await DeckStyleService.preloadStyle();

        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNull);
      });

      test('handles nested style object correctly', () async {
        final complexStyle = buildStyle(
          heading: '#FF5733',
          body: '#33FF57',
          background: '#FFFFFF',
          fonts: {'headline': 'playfairDisplay', 'body': 'openSans'},
        );
        final file = File(p.join(superdeckPath, DeckArtifacts.deckJsonFile));
        await file.writeAsString(
          jsonEncode({'slides': [], 'style': complexStyle}),
        );

        await DeckStyleService.preloadStyle();

        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNotNull);
        expect(result!.colors.heading, '#FF5733');
        expect(result.fonts.headline.name, 'playfairDisplay');
      });
    });

    group('readStyleFromCache', () {
      test('returns null when cache is empty', () {
        final result = DeckStyleService.readStyleFromCache();
        expect(result, isNull);
      });

      test('returns cached style after preload', () async {
        final file = File(p.join(superdeckPath, DeckArtifacts.deckJsonFile));
        await file.writeAsString(
          jsonEncode({'style': buildStyle(heading: '#FF0000')}),
        );

        await DeckStyleService.preloadStyle();

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
        // First set a value
        DeckStyleService.updateCache(
          DeckStyleType.parse(buildStyle(heading: '#000000')),
        );
        expect(DeckStyleService.readStyleFromCache(), isNotNull);

        // Then clear it
        DeckStyleService.updateCache(null);
        expect(DeckStyleService.readStyleFromCache(), isNull);
      });

      test('marks as preloaded so preloadStyle becomes no-op', () async {
        // Update cache directly
        DeckStyleService.updateCache(
          DeckStyleType.parse(buildStyle(heading: '#DIRECT')),
        );

        // Create file with different content
        final file = File(p.join(superdeckPath, DeckArtifacts.deckJsonFile));
        await file.writeAsString(
          jsonEncode({'style': buildStyle(heading: '#FROMFILE')}),
        );

        // preloadStyle should be no-op since cache is already set
        await DeckStyleService.preloadStyle();

        final result = DeckStyleService.readStyleFromCache();
        expect(result!.colors.heading, '#DIRECT');
      });
    });

    group('clearCache', () {
      test('allows fresh preload after clear', () async {
        final file = File(p.join(superdeckPath, DeckArtifacts.deckJsonFile));

        // Write initial style
        await file.writeAsString(
          jsonEncode({'style': buildStyle(heading: '#FF0000')}),
        );

        // First preload
        await DeckStyleService.preloadStyle();
        final result1 = DeckStyleService.readStyleFromCache();
        expect(result1!.colors.heading, '#FF0000');

        // Modify file
        await file.writeAsString(
          jsonEncode({'style': buildStyle(heading: '#00FF00')}),
        );

        // Clear cache
        DeckStyleService.clearCache();

        // Preload again - should read fresh data
        await DeckStyleService.preloadStyle();
        final result2 = DeckStyleService.readStyleFromCache();
        expect(result2!.colors.heading, '#00FF00');
      });

      test('does not throw when called multiple times', () {
        expect(() {
          DeckStyleService.clearCache();
          DeckStyleService.clearCache();
          DeckStyleService.clearCache();
        }, returnsNormally);
      });

      test('does not throw when cache is already empty', () {
        // Cache starts empty
        expect(() => DeckStyleService.clearCache(), returnsNormally);
      });
    });

    group('cache behavior', () {
      test('cache is shared across calls', () async {
        final file = File(p.join(superdeckPath, DeckArtifacts.deckJsonFile));
        await file.writeAsString(
          jsonEncode({'style': buildStyle(heading: '#FF0000')}),
        );

        await DeckStyleService.preloadStyle();

        // Multiple reads should return same cached instance
        final result1 = DeckStyleService.readStyleFromCache();
        final result2 = DeckStyleService.readStyleFromCache();
        final result3 = DeckStyleService.readStyleFromCache();

        expect(identical(result1, result2), isTrue);
        expect(identical(result2, result3), isTrue);
      });
    });
  });
}
