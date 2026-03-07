import 'package:superdeck_core/src/deck_workspace.dart';
import 'package:test/test.dart';

void main() {
  group('DeckWorkspace', () {
    group('constructor', () {
      test('creates with all null values', () {
        final config = DeckWorkspace();

        expect(config.projectDir, isNull);
        expect(config.slidesPath, isNull);
        expect(config.outputDir, isNull);
        expect(config.assetsPath, isNull);
      });

      test('creates with all parameters', () {
        final config = DeckWorkspace(
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
        final config = DeckWorkspace();

        expect(config.slidesFile.path, contains('slides.md'));
        expect(config.pubspecFile.path, contains('pubspec.yaml'));
      });

      test('uses projectDir as baseDir when provided', () {
        final config = DeckWorkspace(projectDir: '/my/project');

        expect(config.slidesFile.path, contains('/my/project'));
        expect(config.pubspecFile.path, contains('/my/project'));
      });

      group('superdeckDir', () {
        test('uses default .superdeck when outputDir is null', () {
          final config = DeckWorkspace();

          expect(config.superdeckDir.path, contains('.superdeck'));
        });

        test('uses custom outputDir when provided', () {
          final config = DeckWorkspace(outputDir: 'custom-output');

          expect(config.superdeckDir.path, contains('custom-output'));
        });

        test('combines projectDir and outputDir', () {
          final config = DeckWorkspace(
            projectDir: '/base',
            outputDir: 'out',
          );

          expect(config.superdeckDir.path, contains('/base'));
          expect(config.superdeckDir.path, contains('out'));
        });
      });

      group('deckJson', () {
        test('is inside superdeckDir', () {
          final config = DeckWorkspace();

          expect(config.deckJson.path, contains(config.superdeckDir.path));
          expect(config.deckJson.path, endsWith('superdeck.v2.json'));
        });
      });

      group('deckFullJson', () {
        test('is inside superdeckDir', () {
          final config = DeckWorkspace();

          expect(config.deckFullJson.path, contains(config.superdeckDir.path));
          expect(config.deckFullJson.path, endsWith('superdeck_full.v2.json'));
        });
      });

      group('assetsDir', () {
        test('uses default assets when assetsPath is null', () {
          final config = DeckWorkspace();

          expect(config.assetsDir.path, contains('assets'));
        });

        test('uses custom assetsPath when provided', () {
          final config = DeckWorkspace(assetsPath: 'custom-assets');

          expect(config.assetsDir.path, contains('custom-assets'));
        });

        test('is inside superdeckDir', () {
          final config = DeckWorkspace();

          expect(config.assetsDir.path, contains(config.superdeckDir.path));
        });
      });

      group('assetsRefJson', () {
        test('is inside superdeckDir', () {
          final config = DeckWorkspace();

          expect(config.assetsRefJson.path, contains(config.superdeckDir.path));
          expect(
            config.assetsRefJson.path,
            endsWith('generated_assets.v2.json'),
          );
        });
      });

      group('buildStatusJson', () {
        test('is inside superdeckDir', () {
          final config = DeckWorkspace();

          expect(
            config.buildStatusJson.path,
            contains(config.superdeckDir.path),
          );
          expect(config.buildStatusJson.path, endsWith('build_status.v2.json'));
        });
      });

      group('slidesFile', () {
        test('uses default slides.md when slidesPath is null', () {
          final config = DeckWorkspace();

          expect(config.slidesFile.path, endsWith('slides.md'));
        });

        test('uses custom slidesPath when provided', () {
          final config = DeckWorkspace(slidesPath: 'custom.md');

          expect(config.slidesFile.path, endsWith('custom.md'));
        });

        test('combines projectDir and slidesPath', () {
          final config = DeckWorkspace(
            projectDir: '/project',
            slidesPath: 'deck.md',
          );

          expect(config.slidesFile.path, contains('/project'));
          expect(config.slidesFile.path, endsWith('deck.md'));
        });
      });

      group('pubspecFile', () {
        test('is always pubspec.yaml in baseDir', () {
          final config = DeckWorkspace(projectDir: '/my/app');

          expect(config.pubspecFile.path, contains('/my/app'));
          expect(config.pubspecFile.path, endsWith('pubspec.yaml'));
        });
      });
    });

    group('copyWith', () {
      test('copies with new projectDir', () {
        final original = DeckWorkspace(projectDir: '/old');
        final copy = original.copyWith(projectDir: '/new');

        expect(copy.projectDir, '/new');
      });

      test('copies with new slidesPath', () {
        final original = DeckWorkspace(slidesPath: 'old.md');
        final copy = original.copyWith(slidesPath: 'new.md');

        expect(copy.slidesPath, 'new.md');
      });

      test('copies with new outputDir', () {
        final original = DeckWorkspace(outputDir: 'old-out');
        final copy = original.copyWith(outputDir: 'new-out');

        expect(copy.outputDir, 'new-out');
      });

      test('copies with new assetsPath', () {
        final original = DeckWorkspace(assetsPath: 'old-assets');
        final copy = original.copyWith(assetsPath: 'new-assets');

        expect(copy.assetsPath, 'new-assets');
      });

      test('preserves values when not specified', () {
        final original = DeckWorkspace(
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
        final config = DeckWorkspace();
        final map = config.toMap();

        expect(map, isEmpty);
      });

      test('serializes only non-null values', () {
        final config = DeckWorkspace(projectDir: '/project');
        final map = config.toMap();

        expect(map['projectDir'], '/project');
        expect(map.containsKey('slidesPath'), isFalse);
        expect(map.containsKey('outputDir'), isFalse);
        expect(map.containsKey('assetsPath'), isFalse);
      });

      test('serializes all values when present', () {
        final config = DeckWorkspace(
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
        final config = DeckWorkspace.fromMap({});

        expect(config.projectDir, isNull);
        expect(config.slidesPath, isNull);
        expect(config.outputDir, isNull);
        expect(config.assetsPath, isNull);
      });

      test('deserializes partial map', () {
        final config = DeckWorkspace.fromMap({
          'projectDir': '/project',
          'slidesPath': 'deck.md',
        });

        expect(config.projectDir, '/project');
        expect(config.slidesPath, 'deck.md');
        expect(config.outputDir, isNull);
        expect(config.assetsPath, isNull);
      });

      test('deserializes full map', () {
        final config = DeckWorkspace.fromMap({
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
        final original = DeckWorkspace(
          projectDir: '/roundtrip',
          slidesPath: 'rt.md',
          outputDir: 'rt-out',
          assetsPath: 'rt-assets',
        );

        final restored = DeckWorkspace.fromMap(original.toMap());

        expect(restored, original);
      });

      test('handles partial config round-trip', () {
        final original = DeckWorkspace(
          projectDir: '/partial',
          outputDir: 'out',
        );

        final restored = DeckWorkspace.fromMap(original.toMap());

        expect(restored.projectDir, '/partial');
        expect(restored.outputDir, 'out');
        expect(restored.slidesPath, isNull);
        expect(restored.assetsPath, isNull);
      });
    });

    group('parse', () {
      test('parses empty map', () {
        final config = DeckWorkspace.parse({});

        expect(config.projectDir, isNull);
      });

      test('parses valid map', () {
        final config = DeckWorkspace.parse({
          'projectDir': '/parsed',
          'slidesPath': 'parsed.md',
        });

        expect(config.projectDir, '/parsed');
        expect(config.slidesPath, 'parsed.md');
      });
    });

    group('schema', () {
      test('validates empty map', () {
        final result = DeckWorkspace.schema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('validates all string fields', () {
        final result = DeckWorkspace.schema.safeParse({
          'projectDir': '/project',
          'slidesPath': 'slides.md',
          'outputDir': 'output',
          'assetsPath': 'assets',
        });
        expect(result.isOk, isTrue);
      });

      test('validates partial map', () {
        final result = DeckWorkspace.schema.safeParse({
          'projectDir': '/only-project',
        });
        expect(result.isOk, isTrue);
      });

      test('fails when optional fields are explicitly null', () {
        for (final field in [
          'projectDir',
          'slidesPath',
          'outputDir',
          'assetsPath',
        ]) {
          final result = DeckWorkspace.schema.safeParse({field: null});
          expect(result.isOk, isFalse);
        }
      });
    });

    group('defaultFile', () {
      test('returns file named superdeck.yaml', () {
        final file = DeckWorkspace.defaultFile;

        expect(file.path, 'superdeck.yaml');
      });
    });

    group('path traversal validation', () {
      test('rejects outputDir with forward slash traversal', () {
        expect(
          () => DeckWorkspace(outputDir: '../escape').superdeckDir,
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('path traversal'),
            ),
          ),
        );
      });

      test('rejects outputDir with backslash traversal', () {
        expect(
          () => DeckWorkspace(outputDir: r'..\escape').superdeckDir,
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('path traversal'),
            ),
          ),
        );
      });

      test('rejects assetsPath with traversal', () {
        expect(
          () => DeckWorkspace(assetsPath: '../../secrets').assetsDir,
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('path traversal'),
            ),
          ),
        );
      });

      test('rejects slidesPath with traversal', () {
        expect(
          () => DeckWorkspace(slidesPath: '../../../etc/passwd').slidesFile,
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('path traversal'),
            ),
          ),
        );
      });

      test('rejects absolute path for outputDir', () {
        expect(
          () => DeckWorkspace(outputDir: '/absolute/path').superdeckDir,
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('relative path'),
            ),
          ),
        );
      });

      test('allows filenames containing double dots', () {
        // Filenames like '..config.png' or 'foo..bar' should be allowed
        // because '..' is not a path segment
        final config = DeckWorkspace(assetsPath: '..hidden');
        expect(config.assetsDir.path, contains('..hidden'));
      });

      test('allows filenames with double dots in middle', () {
        final config = DeckWorkspace(slidesPath: 'my..slides.md');
        expect(config.slidesFile.path, contains('my..slides.md'));
      });

      test('allows nested paths without traversal', () {
        final config = DeckWorkspace(outputDir: 'build/output/slides');
        expect(config.superdeckDir.path, contains('build'));
        expect(config.superdeckDir.path, contains('output'));
        expect(config.superdeckDir.path, contains('slides'));
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        final config1 = DeckWorkspace(projectDir: '/same');
        final config2 = DeckWorkspace(projectDir: '/same');

        expect(config1, config2);
        expect(config1.hashCode, config2.hashCode);
      });

      test('different projectDir makes configs unequal', () {
        final config1 = DeckWorkspace(projectDir: '/a');
        final config2 = DeckWorkspace(projectDir: '/b');

        expect(config1, isNot(config2));
      });

      test('different slidesPath makes configs unequal', () {
        final config1 = DeckWorkspace(slidesPath: 'a.md');
        final config2 = DeckWorkspace(slidesPath: 'b.md');

        expect(config1, isNot(config2));
      });

      test('different outputDir makes configs unequal', () {
        final config1 = DeckWorkspace(outputDir: 'a');
        final config2 = DeckWorkspace(outputDir: 'b');

        expect(config1, isNot(config2));
      });

      test('different assetsPath makes configs unequal', () {
        final config1 = DeckWorkspace(assetsPath: 'a');
        final config2 = DeckWorkspace(assetsPath: 'b');

        expect(config1, isNot(config2));
      });

      test('null vs non-null makes configs unequal', () {
        final config1 = DeckWorkspace();
        final config2 = DeckWorkspace(projectDir: '/project');

        expect(config1, isNot(config2));
      });
    });
  });
}
