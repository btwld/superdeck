import 'package:superdeck_core/src/deck/deck_workspace.dart';
import 'package:test/test.dart';

void main() {
  group('DeckWorkspace', () {
    group('constructor', () {
      test('creates with default values', () {
        final config = DeckWorkspace();

        expect(config.projectDir, '.');
        expect(config.slidesPath, 'slides.md');
        expect(config.outputDir, '.superdeck');
        expect(config.assetsPath, 'assets');
      });

      test('normalizes explicit null values to defaults', () {
        final config = DeckWorkspace(
          projectDir: null,
          slidesPath: null,
          outputDir: null,
          assetsPath: null,
        );

        expect(config.projectDir, '.');
        expect(config.slidesPath, 'slides.md');
        expect(config.outputDir, '.superdeck');
        expect(config.assetsPath, 'assets');
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

      test('accepts normal relative paths', () {
        expect(
          () => DeckWorkspace(
            slidesPath: 'slides.md',
            outputDir: '.superdeck',
            assetsPath: 'assets',
          ),
          returnsNormally,
        );
      });

      test('accepts nested relative paths', () {
        expect(
          () => DeckWorkspace(
            slidesPath: 'content/slides.md',
            outputDir: 'build/output',
            assetsPath: 'static/assets',
          ),
          returnsNormally,
        );
      });

      group('rejects unsafe paths', () {
        for (final field in ['slidesPath', 'outputDir', 'assetsPath']) {
          test('$field rejects ".." traversal', () {
            expect(
              () => DeckWorkspace(
                slidesPath: field == 'slidesPath' ? '../etc/passwd' : null,
                outputDir: field == 'outputDir' ? '../etc/passwd' : null,
                assetsPath: field == 'assetsPath' ? '../etc/passwd' : null,
              ),
              throwsA(isA<ArgumentError>()),
            );
          });

          test('$field rejects absolute paths', () {
            expect(
              () => DeckWorkspace(
                slidesPath: field == 'slidesPath' ? '/tmp/evil' : null,
                outputDir: field == 'outputDir' ? '/tmp/evil' : null,
                assetsPath: field == 'assetsPath' ? '/tmp/evil' : null,
              ),
              throwsA(isA<ArgumentError>()),
            );
          });

          test('$field rejects nested ".." traversal', () {
            expect(
              () => DeckWorkspace(
                slidesPath: field == 'slidesPath' ? 'sub/../../outside' : null,
                outputDir: field == 'outputDir' ? 'sub/../../outside' : null,
                assetsPath: field == 'assetsPath' ? 'sub/../../outside' : null,
              ),
              throwsA(isA<ArgumentError>()),
            );
          });
        }
      });

      test('projectDir allows absolute paths', () {
        expect(
          () => DeckWorkspace(projectDir: '/absolute/project'),
          returnsNormally,
        );
      });
    });

    group('computed paths', () {
      test('uses default baseDir when projectDir is not provided', () {
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
        test('uses default .superdeck when outputDir is not provided', () {
          final config = DeckWorkspace();

          expect(config.superdeckDir.path, contains('.superdeck'));
        });

        test('uses custom outputDir when provided', () {
          final config = DeckWorkspace(outputDir: 'custom-output');

          expect(config.superdeckDir.path, contains('custom-output'));
        });

        test('combines projectDir and outputDir', () {
          final config = DeckWorkspace(projectDir: '/base', outputDir: 'out');

          expect(config.superdeckDir.path, contains('/base'));
          expect(config.superdeckDir.path, contains('out'));
        });
      });

      group('deckJson', () {
        test('is inside superdeckDir', () {
          final config = DeckWorkspace();

          expect(config.deckJson.path, contains(config.superdeckDir.path));
          expect(config.deckJson.path, endsWith('superdeck.json'));
        });
      });

      group('deckFullJson', () {
        test('is inside superdeckDir', () {
          final config = DeckWorkspace();

          expect(config.deckFullJson.path, contains(config.superdeckDir.path));
          expect(config.deckFullJson.path, endsWith('superdeck_full.json'));
        });
      });

      group('assetsDir', () {
        test('uses default assets when assetsPath is not provided', () {
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
          expect(config.assetsRefJson.path, endsWith('generated_assets.json'));
        });
      });

      group('buildStatusJson', () {
        test('is inside superdeckDir', () {
          final config = DeckWorkspace();

          expect(
            config.buildStatusJson.path,
            contains(config.superdeckDir.path),
          );
          expect(config.buildStatusJson.path, endsWith('build_status.json'));
        });
      });

      group('bundledDeckJsonPath', () {
        test('uses default outputDir path without projectDir prefix', () {
          final config = DeckWorkspace(projectDir: '/abs/project');

          expect(config.bundledDeckJsonPath, '.superdeck/superdeck.json');
        });

        test('uses custom outputDir', () {
          final config = DeckWorkspace(outputDir: 'generated');

          expect(config.bundledDeckJsonPath, 'generated/superdeck.json');
        });
      });

      group('bundledAssetsPath', () {
        test('uses defaults without projectDir prefix', () {
          final config = DeckWorkspace(projectDir: '/abs/project');

          expect(config.bundledAssetsPath, '.superdeck/assets');
        });

        test('uses custom outputDir and assetsPath', () {
          final config = DeckWorkspace(
            outputDir: 'generated',
            assetsPath: 'media',
          );

          expect(config.bundledAssetsPath, 'generated/media');
        });
      });

      group('slidesFile', () {
        test('uses default slides.md when slidesPath is not provided', () {
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
      test('serializes default values', () {
        final config = DeckWorkspace();
        final map = config.toMap();

        expect(map['projectDir'], '.');
        expect(map['slidesPath'], 'slides.md');
        expect(map['outputDir'], '.superdeck');
        expect(map['assetsPath'], 'assets');
      });

      test('serializes updated values alongside defaults', () {
        final config = DeckWorkspace(projectDir: '/project');
        final map = config.toMap();

        expect(map['projectDir'], '/project');
        expect(map['slidesPath'], 'slides.md');
        expect(map['outputDir'], '.superdeck');
        expect(map['assetsPath'], 'assets');
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

        expect(config.projectDir, '.');
        expect(config.slidesPath, 'slides.md');
        expect(config.outputDir, '.superdeck');
        expect(config.assetsPath, 'assets');
      });

      test('deserializes null values using constructor defaults', () {
        final config = DeckWorkspace.fromMap({
          'projectDir': null,
          'slidesPath': null,
          'outputDir': null,
          'assetsPath': null,
        });

        expect(config.projectDir, '.');
        expect(config.slidesPath, 'slides.md');
        expect(config.outputDir, '.superdeck');
        expect(config.assetsPath, 'assets');
      });

      test('deserializes partial map', () {
        final config = DeckWorkspace.fromMap({
          'projectDir': '/project',
          'slidesPath': 'deck.md',
        });

        expect(config.projectDir, '/project');
        expect(config.slidesPath, 'deck.md');
        expect(config.outputDir, '.superdeck');
        expect(config.assetsPath, 'assets');
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
        expect(restored.slidesPath, 'slides.md');
        expect(restored.assetsPath, 'assets');
      });
    });

    group('parse', () {
      test('parses empty map', () {
        final config = DeckWorkspace.parse({});

        expect(config.projectDir, '.');
        expect(config.slidesPath, 'slides.md');
        expect(config.outputDir, '.superdeck');
        expect(config.assetsPath, 'assets');
      });

      test('parses valid map', () {
        final config = DeckWorkspace.parse({
          'projectDir': '/parsed',
          'slidesPath': 'parsed.md',
        });

        expect(config.projectDir, '/parsed');
        expect(config.slidesPath, 'parsed.md');
      });

      test('rejects invalid typed known fields', () {
        for (final field in [
          'projectDir',
          'slidesPath',
          'outputDir',
          'assetsPath',
        ]) {
          expect(
            () => DeckWorkspace.parse({field: 42}),
            throwsA(isA<Exception>()),
          );
        }
      });

      test('ignores unknown keys after validation', () {
        final config = DeckWorkspace.parse({
          'slidesPath': 'parsed.md',
          'extra': {'keep': 'passthrough'},
        });

        expect(config.slidesPath, 'parsed.md');
        expect(config.toMap().containsKey('extra'), isFalse);
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

      test('allows unknown keys while validating known fields', () {
        final result = DeckWorkspace.schema.safeParse({
          'projectDir': '/project',
          'extra': {'nested': true},
        });

        expect(result.isOk, isTrue);
      });

      group('path validation', () {
        for (final field in ['slidesPath', 'outputDir', 'assetsPath']) {
          group(field, () {
            test('accepts simple relative path', () {
              final result = DeckWorkspace.schema.safeParse({
                field: 'my_file.md',
              });
              expect(result.isOk, isTrue);
            });

            test('accepts nested relative path', () {
              final result = DeckWorkspace.schema.safeParse({
                field: 'sub/dir/file.md',
              });
              expect(result.isOk, isTrue);
            });

            test('accepts filename containing ".."', () {
              final result = DeckWorkspace.schema.safeParse({
                field: 'my..file.md',
              });
              expect(result.isOk, isTrue);
            });

            test('accepts dot-prefixed relative path', () {
              final result = DeckWorkspace.schema.safeParse({
                field: '.superdeck',
              });
              expect(result.isOk, isTrue);
            });

            test('rejects absolute path', () {
              final result = DeckWorkspace.schema.safeParse({
                field: '/etc/passwd',
              });
              expect(result.isOk, isFalse);
            });

            test('rejects ".." traversal segment', () {
              final result = DeckWorkspace.schema.safeParse({
                field: '../outside',
              });
              expect(result.isOk, isFalse);
            });

            test('rejects nested ".." traversal segment', () {
              final result = DeckWorkspace.schema.safeParse({
                field: 'sub/../../outside',
              });
              expect(result.isOk, isFalse);
            });

            test('rejects bare ".." path', () {
              final result = DeckWorkspace.schema.safeParse({field: '..'});
              expect(result.isOk, isFalse);
            });
          });
        }

        test('projectDir still allows absolute paths', () {
          final result = DeckWorkspace.schema.safeParse({
            'projectDir': '/absolute/project',
          });
          expect(result.isOk, isTrue);
        });
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

      test('default and custom values make configs unequal', () {
        final config1 = DeckWorkspace();
        final config2 = DeckWorkspace(projectDir: '/project');

        expect(config1, isNot(config2));
      });
    });
  });
}
