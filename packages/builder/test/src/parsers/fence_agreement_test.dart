import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

/// Slide-split and directive tokenization must hide the same `---` / `@`
/// markers inside a fence. These snippets are fed to both shipped APIs.
void main() {
  const cases = <_FenceCase>[
    _FenceCase(
      'backtick fence',
      markdown: '# Slide\n\n```\n---\n@ignored\n```\n\n@visible\n',
      slides: 1,
      tokens: ['visible'],
    ),
    _FenceCase(
      'tilde fence',
      markdown: '# Slide\n\n~~~\n---\n@ignored\n~~~\n\n@visible\n',
      slides: 1,
      tokens: ['visible'],
    ),
    _FenceCase(
      'language + {.hero} fence',
      markdown: '# Slide\n\n```dart {.hero}\n---\n@override\n```\n\n@visible\n',
      slides: 1,
      tokens: ['visible'],
    ),
    _FenceCase(
      'unclosed fence',
      markdown: '# Slide\n\n```\n---\n@ignored\n',
      slides: 1,
      tokens: [],
    ),
    _FenceCase(
      '{.code} closer then separator',
      markdown:
          '### Code\n\n```dart\nvoid main() {}\n```{.code}\n\n---\n\n## Next\n\n@visible\n',
      slides: 2,
      tokens: ['visible'],
    ),
    _FenceCase(
      'separator after a closed fence',
      markdown: '# One\n\n```\ncode\n```\n\n---\n\n# Two\n\n@visible\n',
      slides: 2,
      tokens: ['visible'],
    ),
  ];

  for (final fixture in cases) {
    test('${fixture.name}: split and tokenize agree', () {
      final slides = const MarkdownParser().parse(fixture.markdown);
      final tokens = const TagTokenizer().tokenize(fixture.markdown);

      expect(slides, hasLength(fixture.slides), reason: fixture.name);
      expect(
        tokens.map((token) => token.name),
        fixture.tokens,
        reason: fixture.name,
      );
    });
  }
}

class _FenceCase {
  final String name;
  final String markdown;
  final int slides;
  final List<String> tokens;

  const _FenceCase(
    this.name, {
    required this.markdown,
    required this.slides,
    required this.tokens,
  });
}
