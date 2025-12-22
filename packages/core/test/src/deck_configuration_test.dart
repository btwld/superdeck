import 'package:superdeck_core/src/deck_configuration.dart';
import 'package:test/test.dart';

void main() {
  group('DeckConfiguration', () {
    group('constructor', () {
      test('creates with all null values', () {
        final config = DeckConfiguration();

        expect(config.projectDir, isNull);
        expect(config.slidesPath, isNull);
        expect(config.outputDir, isNull);
        expect(config.assetsPath, isNull);
      });

      test('creates with all parameters', () {
        final config = DeckConfiguration(
          projectDir: '/project',
          slidesPath: 'presentation.md',
          outputDir: 'build',
          assetsPath: 'images',
        );

        expect(config.projectDir, '/project');
        expect(config.slidesPath, 'presentation.md');
        expect(config.outputDir, 'build');
        expect(config.assetsPath, 'images');
      });
    });

    group('computed paths', () {
      test('uses default baseDir when projectDir is null', () {
        final config = DeckConfiguration();

        expect(config.slidesFile.path, contains('slides.md'));
        expect(config.pubspecFile.path, contains('pubspec.yaml'));
      });

      test('uses projectDir as baseDir when provided', () {
        final config = DeckConfiguration(projectDir: '/my/project');

        expect(config.slidesFile.path, contains('/my/project'));
        expect(config.pubspecFile.path, contains('/my/project'));
      });

      group('superdeckDir', () {
        test('uses default .superdeck when outputDir is null', () {
          final config = DeckConfiguration();

          expect(config.superdeckDir.path, contains('.superdeck'));
        });

        test('uses custom outputDir when provided', () {
          final config = DeckConfiguration(outputDir: 'custom-output');

          expect(config.superdeckDir.path, contains('custom-output'));
        });

        test('combines projectDir and outputDir', () {
          final config = DeckConfiguration(
            projectDir: '/base',
            outputDir: 'out',
          );

          expect(config.superdeckDir.path, contains('/base'));
          expect(config.superdeckDir.path, contains('out'));
        });
      });

      group('deckJson', () {
        test('is inside superdeckDir', () {
          final config = DeckConfiguration();

          expect(
            config.deckJson.path,
            contains(config.superdeckDir.path),
          );
          expect(config.deckJson.path, endsWith('superdeck.json'));
        });
      });

      group('deckFullJson', () {
        test('is inside superdeckDir', () {
          final config = DeckConfiguration();

          expect(
            config.deckFullJson.path,
            contains(config.superdeckDir.path),
          );
          expect(config.deckFullJson.path, endsWith('superdeck_full.json'));
        });
      });

      group('assetsDir', () {
        test('uses default assets when assetsPath is null', () {
          final config = DeckConfiguration();

          expect(config.assetsDir.path, contains('assets'));
        });

        test('uses custom assetsPath when provided', () {
          final config = DeckConfiguration(assetsPath: 'custom-assets');

          expect(config.assetsDir.path, contains('custom-assets'));
        });

        test('is inside superdeckDir', () {
          final config = DeckConfiguration();

          expect(
            config.assetsDir.path,
            contains(config.superdeckDir.path),
          );
        });
      });

      group('assetsRefJson', () {
        test('is inside superdeckDir', () {
          final config = DeckConfiguration();

          expect(
            config.assetsRefJson.path,
            contains(config.superdeckDir.path),
          );
          expect(
            config.assetsRefJson.path,
            endsWith('generated_assets.json'),
          );
        });
      });

      group('buildStatusJson', () {
        test('is inside superdeckDir', () {
          final config = DeckConfiguration();

          expect(
            config.buildStatusJson.path,
            contains(config.superdeckDir.path),
          );
          expect(config.buildStatusJson.path, endsWith('build_status.json'));
        });
      });

      group('slidesFile', () {
        test('uses default slides.md when slidesPath is null', () {
          final config = DeckConfiguration();

          expect(config.slidesFile.path, endsWith('slides.md'));
        });

        test('uses custom slidesPath when provided', () {
          final config = DeckConfiguration(slidesPath: 'custom.md');

          expect(config.slidesFile.path, endsWith('custom.md'));
        });

        test('combines projectDir and slidesPath', () {
          final config = DeckConfiguration(
            projectDir: '/project',
            slidesPath: 'deck.md',
          );

          expect(config.slidesFile.path, contains('/project'));
          expect(config.slidesFile.path, endsWith('deck.md'));
        });
      });

      group('pubspecFile', () {
        test('is always pubspec.yaml in baseDir', () {
          final config = DeckConfiguration(projectDir: '/my/app');

          expect(config.pubspecFile.path, contains('/my/app'));
          expect(config.pubspecFile.path, endsWith('pubspec.yaml'));
        });
      });
    });

    group('copyWith', () {
      test('copies with new projectDir', () {
        final original = DeckConfiguration(projectDir: '/old');
        final copy = original.copyWith(projectDir: '/new');

        expect(copy.projectDir, '/new');
      });

      test('copies with new slidesPath', () {
        final original = DeckConfiguration(slidesPath: 'old.md');
        final copy = original.copyWith(slidesPath: 'new.md');

        expect(copy.slidesPath, 'new.md');
      });

      test('copies with new outputDir', () {
        final original = DeckConfiguration(outputDir: 'old-out');
        final copy = original.copyWith(outputDir: 'new-out');

        expect(copy.outputDir, 'new-out');
      });

      test('copies with new assetsPath', () {
        final original = DeckConfiguration(assetsPath: 'old-assets');
        final copy = original.copyWith(assetsPath: 'new-assets');

        expect(copy.assetsPath, 'new-assets');
      });

      test('preserves values when not specified', () {
        final original = DeckConfiguration(
          projectDir: '/project',
          slidesPath: 'slides.md',
          outputDir: 'output',
          assetsPath: 'assets',
        );
        final copy = original.copyWith();

        expect(copy.projectDir, original.projectDir);
        expect(copy.slidesPath, original.slidesPath);
        expect(copy.outputDir, original.outputDir);
        expect(copy.assetsPath, original.assetsPath);
      });
    });

    group('toMap', () {
      test('serializes empty config', () {
        final config = DeckConfiguration();
        final map = config.toMap();

        expect(map, isEmpty);
      });

      test('serializes only non-null values', () {
        final config = DeckConfiguration(projectDir: '/project');
        final map = config.toMap();

        expect(map['projectDir'], '/project');
        expect(map.containsKey('slidesPath'), isFalse);
        expect(map.containsKey('outputDir'), isFalse);
        expect(map.containsKey('assetsPath'), isFalse);
      });

      test('serializes all values when present', () {
        final config = DeckConfiguration(
          projectDir: '/project',
          slidesPath: 'slides.md',
          outputDir: 'output',
          assetsPath: 'assets',
        );
        final map = config.toMap();

        expect(map['projectDir'], '/project');
        expect(map['slidesPath'], 'slides.md');
        expect(map['outputDir'], 'output');
        expect(map['assetsPath'], 'assets');
      });
    });

    group('fromMap', () {
      test('deserializes empty map', () {
        final config = DeckConfiguration.fromMap({});

        expect(config.projectDir, isNull);
        expect(config.slidesPath, isNull);
        expect(config.outputDir, isNull);
        expect(config.assetsPath, isNull);
      });

      test('deserializes partial map', () {
        final config = DeckConfiguration.fromMap({
          'projectDir': '/project',
          'slidesPath': 'deck.md',
        });

        expect(config.projectDir, '/project');
        expect(config.slidesPath, 'deck.md');
        expect(config.outputDir, isNull);
        expect(config.assetsPath, isNull);
      });

      test('deserializes full map', () {
        final config = DeckConfiguration.fromMap({
          'projectDir': '/project',
          'slidesPath': 'slides.md',
          'outputDir': 'output',
          'assetsPath': 'assets',
        });

        expect(config.projectDir, '/project');
        expect(config.slidesPath, 'slides.md');
        expect(config.outputDir, 'output');
        expect(config.assetsPath, 'assets');
      });
    });

    group('round-trip serialization', () {
      test('preserves data through toMap/fromMap', () {
        final original = DeckConfiguration(
          projectDir: '/roundtrip',
          slidesPath: 'rt.md',
          outputDir: 'rt-out',
          assetsPath: 'rt-assets',
        );

        final restored = DeckConfiguration.fromMap(original.toMap());

        expect(restored, original);
      });

      test('handles partial config round-trip', () {
        final original = DeckConfiguration(
          projectDir: '/partial',
          outputDir: 'out',
        );

        final restored = DeckConfiguration.fromMap(original.toMap());

        expect(restored.projectDir, '/partial');
        expect(restored.outputDir, 'out');
        expect(restored.slidesPath, isNull);
        expect(restored.assetsPath, isNull);
      });
    });

    group('parse', () {
      test('parses empty map', () {
        final config = DeckConfiguration.parse({});

        expect(config.projectDir, isNull);
      });

      test('parses valid map', () {
        final config = DeckConfiguration.parse({
          'projectDir': '/parsed',
          'slidesPath': 'parsed.md',
        });

        expect(config.projectDir, '/parsed');
        expect(config.slidesPath, 'parsed.md');
      });
    });

    group('schema', () {
      test('validates empty map', () {
        final result = DeckConfiguration.schema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('validates all string fields', () {
        final result = DeckConfiguration.schema.safeParse({
          'projectDir': '/project',
          'slidesPath': 'slides.md',
          'outputDir': 'output',
          'assetsPath': 'assets',
        });
        expect(result.isOk, isTrue);
      });

      test('validates partial map', () {
        final result = DeckConfiguration.schema.safeParse({
          'projectDir': '/only-project',
        });
        expect(result.isOk, isTrue);
      });
    });

    group('defaultFile', () {
      test('returns file named superdeck.yaml', () {
        final file = DeckConfiguration.defaultFile;

        expect(file.path, 'superdeck.yaml');
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        final config1 = DeckConfiguration(projectDir: '/same');
        final config2 = DeckConfiguration(projectDir: '/same');

        expect(config1, config2);
        expect(config1.hashCode, config2.hashCode);
      });

      test('different projectDir makes configs unequal', () {
        final config1 = DeckConfiguration(projectDir: '/a');
        final config2 = DeckConfiguration(projectDir: '/b');

        expect(config1, isNot(config2));
      });

      test('different slidesPath makes configs unequal', () {
        final config1 = DeckConfiguration(slidesPath: 'a.md');
        final config2 = DeckConfiguration(slidesPath: 'b.md');

        expect(config1, isNot(config2));
      });

      test('different outputDir makes configs unequal', () {
        final config1 = DeckConfiguration(outputDir: 'a');
        final config2 = DeckConfiguration(outputDir: 'b');

        expect(config1, isNot(config2));
      });

      test('different assetsPath makes configs unequal', () {
        final config1 = DeckConfiguration(assetsPath: 'a');
        final config2 = DeckConfiguration(assetsPath: 'b');

        expect(config1, isNot(config2));
      });

      test('null vs non-null makes configs unequal', () {
        final config1 = DeckConfiguration();
        final config2 = DeckConfiguration(projectDir: '/project');

        expect(config1, isNot(config2));
      });
    });
  });
}
