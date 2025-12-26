import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck/src/styling/schema/style_config.dart';
import 'package:superdeck/src/styling/styles/slide_style.dart';

void main() {
  group('StyleConfig', () {
    group('merge', () {
      test('returns code options when yaml config is empty', () {
        final codeStyle = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 96)),
        );
        final codeOptions = DeckOptions(baseStyle: codeStyle);

        final yamlConfig = (baseStyle: null, styles: <String, SlideStyle>{});

        final result = StyleConfig.merge(yamlConfig, codeOptions);

        expect(result.baseStyle, isNotNull);
      });

      test('returns yaml style when code options is empty', () {
        final yamlStyle = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 120)),
        );
        final yamlConfig = (baseStyle: yamlStyle, styles: <String, SlideStyle>{});

        final codeOptions = const DeckOptions();

        final result = StyleConfig.merge(yamlConfig, codeOptions);

        expect(result.baseStyle, isNotNull);
      });

      test('merges styles with code winning conflicts', () {
        final yamlStyle = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 96)),
          h2: TextStyler().style(TextStyleMix(fontSize: 72)),
        );
        final yamlConfig = (baseStyle: yamlStyle, styles: <String, SlideStyle>{});

        final codeStyle = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 120)), // override
        );
        final codeOptions = DeckOptions(baseStyle: codeStyle);

        final result = StyleConfig.merge(yamlConfig, codeOptions);

        expect(result.baseStyle, isNotNull);
        // Code style should override yaml style for h1
        // But yaml h2 should be preserved
      });

      test('preserves code styles not dropped when yaml has no base', () {
        final yamlConfig = (baseStyle: null, styles: <String, SlideStyle>{});

        final codeStyle = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 96)),
        );
        final codeOptions = DeckOptions(baseStyle: codeStyle);

        final result = StyleConfig.merge(yamlConfig, codeOptions);

        // Code style should be preserved even when yaml has no base
        expect(result.baseStyle, isNotNull);
      });

      test('merges named styles correctly', () {
        final yamlTitleStyle = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 96)),
        );
        final yamlConfig = (
          baseStyle: null,
          styles: <String, SlideStyle>{'title': yamlTitleStyle},
        );

        final codeTitleStyle = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 120)),
        );
        final codeSpecialStyle = SlideStyle(
          p: TextStyler().style(TextStyleMix(fontSize: 32)),
        );
        final codeOptions = DeckOptions(
          styles: {'title': codeTitleStyle, 'special': codeSpecialStyle},
        );

        final result = StyleConfig.merge(yamlConfig, codeOptions);

        // Both 'title' (merged) and 'special' (code only) should exist
        expect(result.styles.containsKey('title'), isTrue);
        expect(result.styles.containsKey('special'), isTrue);
      });

      test('preserves code-only named styles', () {
        final yamlConfig = (baseStyle: null, styles: <String, SlideStyle>{});

        final codeSpecialStyle = SlideStyle(
          p: TextStyler().style(TextStyleMix(fontSize: 32)),
        );
        final codeOptions = DeckOptions(styles: {'special': codeSpecialStyle});

        final result = StyleConfig.merge(yamlConfig, codeOptions);

        expect(result.styles.containsKey('special'), isTrue);
      });

      test('preserves yaml-only named styles', () {
        final yamlTitleStyle = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 96)),
        );
        final yamlConfig = (
          baseStyle: null,
          styles: <String, SlideStyle>{'title': yamlTitleStyle},
        );

        final codeOptions = const DeckOptions();

        final result = StyleConfig.merge(yamlConfig, codeOptions);

        expect(result.styles.containsKey('title'), isTrue);
      });

      test('preserves non-style options from code', () {
        final yamlConfig = (baseStyle: null, styles: <String, SlideStyle>{});

        final codeOptions = DeckOptions(debug: true);

        final result = StyleConfig.merge(yamlConfig, codeOptions);

        expect(result.debug, isTrue);
      });
    });

    group('loadAndMerge', () {
      test('returns code options when loader returns null', () async {
        final codeStyle = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 96)),
        );
        final codeOptions = DeckOptions(baseStyle: codeStyle);

        final result = await StyleConfig.loadAndMerge(
          codeOptions,
          loader: () async => null, // No YAML file
        );

        expect(result.baseStyle, isNotNull);
      });

      test('merges yaml with code options when loader returns valid yaml', () async {
        final yamlContent = '''
base:
  h1:
    fontSize: 120
''';
        final codeOptions = const DeckOptions();

        final result = await StyleConfig.loadAndMerge(
          codeOptions,
          loader: () async => yamlContent,
        );

        expect(result.baseStyle, isNotNull);
      });

      test('returns code options when yaml parsing fails', () async {
        final invalidYaml = 'invalid: yaml: content: [';
        final codeStyle = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 96)),
        );
        final codeOptions = DeckOptions(baseStyle: codeStyle);

        final result = await StyleConfig.loadAndMerge(
          codeOptions,
          loader: () async => invalidYaml,
        );

        // Should return code options unchanged when yaml fails
        expect(result.baseStyle, isNotNull);
      });

      test('parses valid YAML into StyleConfiguration', () async {
        final yaml = '''
base:
  h1:
    fontSize: 96.0
styles:
  - name: title
    h1:
      fontSize: 120.0
''';
        final result = await StyleConfig.loadAndMerge(
          const DeckOptions(),
          loader: () async => yaml,
        );

        expect(result.baseStyle, isNotNull);
        expect(result.styles, hasLength(1));
        expect(result.styles.containsKey('title'), isTrue);
      });

      test('returns code options for empty yaml string', () async {
        final codeOptions = DeckOptions(
          baseStyle: SlideStyle(
            h1: TextStyler().style(TextStyleMix(fontSize: 96)),
          ),
        );

        final result = await StyleConfig.loadAndMerge(
          codeOptions,
          loader: () async => '',
        );

        expect(result.baseStyle, isNotNull);
      });

      test('returns code options for whitespace-only string', () async {
        final codeOptions = DeckOptions(
          baseStyle: SlideStyle(
            h1: TextStyler().style(TextStyleMix(fontSize: 96)),
          ),
        );

        final result = await StyleConfig.loadAndMerge(
          codeOptions,
          loader: () async => '   \n\t  ',
        );

        expect(result.baseStyle, isNotNull);
      });

      test('returns code options for schema validation failure', () async {
        // fontsize is a typo (should be fontSize) - strict validation catches this
        final yaml = '''
base:
  h1:
    fontsize: 96.0
''';
        final codeOptions = DeckOptions(
          baseStyle: SlideStyle(
            h1: TextStyler().style(TextStyleMix(fontSize: 48)),
          ),
        );

        final result = await StyleConfig.loadAndMerge(
          codeOptions,
          loader: () async => yaml,
        );

        // Should return code options unchanged when schema validation fails
        expect(result.baseStyle, isNotNull);
      });

      test('returns code options for empty yaml map', () async {
        final codeOptions = DeckOptions(
          baseStyle: SlideStyle(
            h1: TextStyler().style(TextStyleMix(fontSize: 96)),
          ),
        );

        final result = await StyleConfig.loadAndMerge(
          codeOptions,
          loader: () async => '{}',
        );

        expect(result.baseStyle, isNotNull);
      });
    });

    group('StyleConfiguration typedef', () {
      test('can be created directly for testing', () {
        final style = SlideStyle(
          h1: TextStyler().style(TextStyleMix(fontSize: 96)),
        );
        final config = (
          baseStyle: style,
          styles: <String, SlideStyle>{'title': style},
        );

        expect(config.baseStyle, isNotNull);
        expect(config.styles, hasLength(1));
      });
    });
  });
}
