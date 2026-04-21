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
      });

      test('normalizes explicit null values to defaults', () {
        final config = DeckWorkspace(
          projectDir: null,
          slidesPath: null,
          outputDir: null,
        );

        expect(config.projectDir, '.');
        expect(config.slidesPath, 'slides.md');
        expect(config.outputDir, '.superdeck');
      });

      test('creates with all parameters', () {
        final config = DeckWorkspace(
          projectDir: '/project',
          slidesPath: 'presentation.md',
          outputDir: 'build',
        );

        expect(config.projectDir, '/project');
        expect(config.slidesPath, 'presentation.md');
        expect(config.outputDir, 'build');
      });

      test('accepts normal relative paths', () {
        expect(
          () => DeckWorkspace(slidesPath: 'slides.md', outputDir: '.superdeck'),
          returnsNormally,
        );
      });

      test('accepts nested relative paths', () {
        expect(
          () => DeckWorkspace(
            slidesPath: 'content/slides.md',
            outputDir: 'build/output',
          ),
          returnsNormally,
        );
      });

      group('rejects unsafe paths', () {
        for (final field in ['slidesPath', 'outputDir']) {
          test('$field rejects ".." traversal', () {
            expect(
              () => DeckWorkspace(
                slidesPath: field == 'slidesPath' ? '../etc/passwd' : null,
                outputDir: field == 'outputDir' ? '../etc/passwd' : null,
              ),
              throwsA(isA<ArgumentError>()),
            );
          });

          test('$field rejects absolute paths', () {
            expect(
              () => DeckWorkspace(
                slidesPath: field == 'slidesPath' ? '/tmp/evil' : null,
                outputDir: field == 'outputDir' ? '/tmp/evil' : null,
              ),
              throwsA(isA<ArgumentError>()),
            );
          });

          test('$field rejects nested ".." traversal', () {
            expect(
              () => DeckWorkspace(
                slidesPath: field == 'slidesPath' ? 'sub/../../outside' : null,
                outputDir: field == 'outputDir' ? 'sub/../../outside' : null,
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
  });
}
