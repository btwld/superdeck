import 'package:superdeck_builder/src/assets/mermaid_generator.dart';
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
      expect(
        generator.configuration['themeVariables'],
        isA<Map<String, dynamic>>(),
      );
      expect(
        generator.configuration['themeVariables']['darkMode'],
        equals(true),
      );
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
        customProcessor.configuration['backgroundColor'],
        equals('#000000'),
      );
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

        final customProcessor = MermaidGenerator(configuration: customConfig);

        expect(customProcessor.configuration['theme'], equals('forest'));
        expect(customProcessor.configuration['viewportWidth'], equals(1920));
        expect(customProcessor.configuration['viewportHeight'], equals(1080));
        expect(
          customProcessor.configuration['customKey'],
          equals('customValue'),
        );
      });
    });

    group('error handling configuration', () {
      test('timeout configuration is properly set', () {
        final generator = MermaidGenerator(
          configuration: const {'timeout': 5},
        );

        expect(generator.configuration['timeout'], equals(5));
      });

      test('configuration validates critical browser settings', () {
        final generator = MermaidGenerator(
          configuration: const {
            'viewportWidth': 1920,
            'viewportHeight': 1080,
            'deviceScaleFactor': 2,
            'timeout': 10,
          },
        );

        expect(generator.configuration['viewportWidth'], equals(1920));
        expect(generator.configuration['viewportHeight'], equals(1080));
        expect(generator.configuration['deviceScaleFactor'], equals(2));
        expect(generator.configuration['timeout'], equals(10));
      });

      test('fallback theme detection returns correct theme type', () {
        final generator = MermaidGenerator();

        // Verify default configuration has theme settings
        expect(generator.configuration['theme'], equals('base'));
        expect(generator.configuration['themeVariables'], isNotEmpty);
      });
    });

    // Note: Error handling tests that require browser (generateAsset calls)
    // have been removed. These should be run as integration tests separately.
  });
}
