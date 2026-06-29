import 'dart:convert';

import 'package:superdeck_mermaid/superdeck_mermaid.dart';
import 'package:test/test.dart';

void main() {
  group('MermaidGenerator', () {
    late MermaidGenerator generator;

    setUp(() {
      generator = MermaidGenerator();
    });

    test('has default configuration', () {
      expect(generator.configuration, isA<Map<String, dynamic>>());
      expect(generator.configuration['theme'], equals('default'));
      expect(
        generator.configuration['themeVariables'],
        isA<Map<String, dynamic>>(),
      );
      final themeVariables = generator.configuration['themeVariables'] as Map?;
      expect(themeVariables?['darkMode'], isTrue);
      expect(themeVariables?['background'], 'transparent');
      expect(generator.configuration['themeCSS'], isA<String>());
      expect(
        generator.configuration['themeCSS'],
        contains('background: transparent'),
      );
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

    group('render configuration', () {
      test('timeout configuration is properly set', () {
        final generator = MermaidGenerator(configuration: const {'timeout': 5});

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

        expect(generator.configuration['theme'], equals('default'));
        expect(generator.configuration['themeVariables'], isNotEmpty);
      });

      test('partial configuration retains transparent default settings', () {
        final generator = MermaidGenerator(
          configuration: const {
            'themeVariables': {'primaryColor': '#ff00ff'},
          },
        );

        final themeVariables = Map<String, Object?>.from(
          generator.configuration['themeVariables']! as Map,
        );

        expect(generator.configuration['theme'], equals('default'));
        expect(generator.configuration['themeCSS'], contains('font-family'));
        expect(themeVariables['primaryColor'], equals('#ff00ff'));
        expect(themeVariables['darkMode'], equals(true));
        expect(themeVariables['background'], equals('transparent'));
      });

      test('default configuration does not override stroke styling', () {
        final themeVariables = Map<String, Object?>.from(
          generator.configuration['themeVariables']! as Map,
        );
        final themeCSS = generator.configuration['themeCSS'] as String;

        expect(themeCSS, isNot(contains('stroke-width')));
        expect(themeCSS, isNot(contains('stroke:')));
        expect(themeVariables, isNot(containsPair('lineColor', anything)));
        expect(
          themeVariables,
          isNot(containsPair('primaryBorderColor', anything)),
        );
        expect(
          themeVariables,
          isNot(containsPair('defaultLinkColor', anything)),
        );
      });

      test('HTML payload encodes theme strings as JS-safe literals', () async {
        const theme = 'ba"se';
        const look = 'classic\'; window.__broken = true; \'';
        const securityLevel = 'strict"\nwindow.__broken = true;';
        final generator = MermaidGenerator(
          configuration: const {
            'theme': theme,
            'look': look,
            'securityLevel': securityLevel,
          },
        );

        final html = await generator.buildHtmlContentForTesting(
          'graph TD; A-->B',
        );

        expect(html, contains('const theme          = ${jsonEncode(theme)};'));
        expect(html, contains('const look           = ${jsonEncode(look)};'));
        expect(
          html,
          contains('const securityLevel  = ${jsonEncode(securityLevel)};'),
        );
      });

      test(
        'HTML payload uses UTF-8 decoder helper instead of raw atob for text inputs',
        () async {
          final html = await generator.buildHtmlContentForTesting(
            'graph TD; A-->B',
          );

          expect(html, contains('TextDecoder'));
          expect(html, isNot(matches(RegExp(r'const graph\s*=\s*atob\('))));
          expect(html, isNot(matches(RegExp(r'const themeCSS\s*=\s*atob\('))));
          expect(html, isNot(matches(RegExp(r'const extraCSS\s*=\s*atob\('))));
        },
      );

      test(
        'HTML payload embeds vendored Mermaid without external URLs',
        () async {
          final html = await generator.buildHtmlContentForTesting(
            'graph TD; A-->B',
          );

          expect(html, contains('SuperDeck vendored Mermaid library v11.4.1'));
          expect(html, isNot(contains('cdn.jsdelivr.net')));
          expect(html, isNot(contains('type="module"')));
          expect(html, isNot(contains('http://')));
          expect(html, isNot(contains('https://')));
        },
      );
    });

    // Note: Actual render() tests require a headless browser and are run as
    // integration tests separately.

    group('lifecycle management', () {
      test('dispose can be called multiple times safely', () async {
        final generator = MermaidGenerator();

        await expectLater(generator.dispose(), completes);
        await expectLater(generator.dispose(), completes);
      });

      test('render throws after dispose', () async {
        final generator = MermaidGenerator();
        await generator.dispose();

        await expectLater(
          () => generator.render('graph TD; A-->B'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('disposed'),
            ),
          ),
        );
      });
    });
  });
}
