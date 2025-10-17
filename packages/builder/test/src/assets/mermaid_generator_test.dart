import 'package:superdeck_builder/src/assets/mermaid_generator.dart';
import 'package:superdeck_builder/src/assets/mermaid_theme.dart';
import 'package:test/test.dart';

void main() {
  group('MermaidGenerator', () {
    late MermaidGenerator generator;

    setUp(() {
      // Create generator for interface testing
      generator = MermaidGenerator();
    });

    test('has correct type', () {
      expect(generator.type, equals('mermaid'));
    });

    test('canProcess returns true for mermaid content', () {
      expect(generator.canProcess('mermaid'), isTrue);
    });

    test('canProcess returns false for other content types', () {
      expect(generator.canProcess('dart'), isFalse);
      expect(generator.canProcess('javascript'), isFalse);
      expect(generator.canProcess('html'), isFalse);
      expect(generator.canProcess('css'), isFalse);
    });

    test('has default configuration', () {
      expect(generator.configuration, isA<Map<String, dynamic>>());
      expect(generator.configuration['theme'], equals('base'));
      expect(generator.configuration['themeVariables'], isA<Map<String, dynamic>>());
      expect(generator.configuration['themeVariables']['darkMode'], equals(true));
      expect(generator.configuration['themeCSS'], isA<String>());
      expect(generator.configuration['look'], equals('classic'));
      expect(generator.configuration['viewportWidth'], equals(1280));
      expect(generator.configuration['viewportHeight'], equals(780));
    });

    test('supports custom configuration', () {
      final customProcessor = MermaidGenerator(
        configuration: const {
          'theme': 'dark',
          'viewportWidth': 800,
          'viewportHeight': 600,
          'backgroundColor': '#000000',
        },
      );

      expect(customProcessor.configuration['theme'], equals('dark'));
      expect(customProcessor.configuration['viewportWidth'], equals(800));
      expect(customProcessor.configuration['viewportHeight'], equals(600));
      expect(
          customProcessor.configuration['backgroundColor'], equals('#000000'));
    });

    test('dispose completes without error', () async {
      await expectLater(generator.dispose(), completes);
    });

    test('implements AssetGenerator interface correctly', () {
      expect(generator.type, isA<String>());
      expect(generator.configuration, isA<Map<String, dynamic>>());
      expect(generator.canProcess('mermaid'), isA<bool>());
    });

    group('content validation', () {
      test('canProcess handles empty string', () {
        expect(generator.canProcess(''), isFalse);
      });

      test('canProcess handles null-like values', () {
        expect(generator.canProcess('null'), isFalse);
        expect(generator.canProcess('undefined'), isFalse);
      });

      test('canProcess is case sensitive', () {
        expect(generator.canProcess('MERMAID'), isFalse);
        expect(generator.canProcess('Mermaid'), isFalse);
        expect(generator.canProcess('mermaid'), isTrue);
      });
    });

    group('configuration validation', () {
      test('default configuration has required keys', () {
        final config = generator.configuration;
        expect(config.containsKey('theme'), isTrue);
        expect(config.containsKey('viewportWidth'), isTrue);
        expect(config.containsKey('viewportHeight'), isTrue);
      });

      test('configuration values have correct types', () {
        final config = generator.configuration;
        expect(config['theme'], isA<String>());
        expect(config['viewportWidth'], isA<int>());
        expect(config['viewportHeight'], isA<int>());
      });

      test('custom configuration overrides defaults', () {
        final customConfig = {
          'theme': 'forest',
          'viewportWidth': 1920,
          'viewportHeight': 1080,
          'customKey': 'customValue',
        };

        final customProcessor = MermaidGenerator(
          configuration: customConfig,
        );

        expect(customProcessor.configuration['theme'], equals('forest'));
        expect(customProcessor.configuration['viewportWidth'], equals(1920));
        expect(customProcessor.configuration['viewportHeight'], equals(1080));
        expect(
            customProcessor.configuration['customKey'], equals('customValue'));
      });
    });

    group('theme integration', () {
      test('accepts MermaidTheme and converts to configuration', () {
        final generator = MermaidGenerator(
          theme: MermaidTheme.dark,
        );

        expect(generator.configuration['theme'], equals('base'));
        expect(generator.configuration['themeVariables'], isA<Map<String, dynamic>>());
        expect(generator.configuration['themeVariables']['darkMode'], equals(true));
        expect(generator.configuration['themeVariables']['primaryColor'], equals('#0ea5e9'));
      });

      test('theme parameter always sets theme to base', () {
        final generator = MermaidGenerator(
          theme: MermaidTheme.light,
        );

        // When using MermaidTheme, 'theme' is always 'base'
        expect(generator.configuration['theme'], equals('base'));
        expect(generator.configuration['themeVariables']['darkMode'], equals(false));
      });

      test('supports custom theme', () {
        final customTheme = MermaidTheme(
          background: '#1a1a2e',
          primary: '#00ff88',
          text: '#ffffff',
          darkMode: true,
        );

        final generator = MermaidGenerator(theme: customTheme);

        final vars = generator.configuration['themeVariables'] as Map<String, dynamic>;
        expect(vars['background'], equals('#1a1a2e'));
        expect(vars['primaryColor'], equals('#00ff88'));
        // textColor is now driven by canvasOnDarkSlide (defaults to false -> dark text)
        expect(vars['textColor'], equals('#1a1a1a'));
        // The theme's text property is used for nodeTextColor (text inside nodes)
        expect(vars['nodeTextColor'], equals('#ffffff'));
        expect(vars['darkMode'], equals(true));
      });

      test('theme includes all derived colors', () {
        final generator = MermaidGenerator(theme: MermaidTheme.dark);
        final vars = generator.configuration['themeVariables'] as Map<String, dynamic>;

        // Check that color derivation happened
        expect(vars['mainBkg'], isNotNull);
        expect(vars['primaryBorderColor'], isNotNull);
        expect(vars['lineColor'], isNotNull);
        expect(vars['nodeBorder'], isNotNull);
        expect(vars['actorBkg'], isNotNull);
      });

      test('configuration can override theme-generated values', () {
        final generator = MermaidGenerator(
          theme: MermaidTheme.dark,
          configuration: const {
            'viewportWidth': 1920,
            'timeout': 20,
          },
        );

        expect(generator.configuration['viewportWidth'], equals(1920));
        expect(generator.configuration['timeout'], equals(20));
        // But theme values are still there
        expect(generator.configuration['themeVariables'], isNotNull);
      });
    });

    group('error handling', () {
      test('throws descriptive error for invalid Mermaid syntax', () async {
        final generator = MermaidGenerator(
          configuration: const {'timeout': 5}, // Shorter timeout for tests
        );

        // Invalid Mermaid syntax - missing closing quote
        const invalidDiagram = '''
flowchart TB
    A[Start] --> B{Is Valid?
    B --> C[End]
''';

        expect(
          () => generator.generateAsset(invalidDiagram, '/tmp/test.png'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Mermaid'),
            ),
          ),
        );

        await generator.dispose();
      });

      test('includes diagram content in error message for debugging', () async {
        final generator = MermaidGenerator(
          configuration: const {'timeout': 5},
        );

        const brokenDiagram = 'invalid mermaid syntax here';

        try {
          await generator.generateAsset(brokenDiagram, '/tmp/test.png');
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e.toString(), contains('Diagram:'));
          expect(e.toString(), contains(brokenDiagram));
        } finally {
          await generator.dispose();
        }
      });
    });
  });
}

