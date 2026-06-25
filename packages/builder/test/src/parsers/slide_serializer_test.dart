import 'dart:convert';
import 'dart:io';

import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

/// Parses a SuperDeck markdown document into [Slide]s exactly the way the
/// runtime loader (`MemoryDeckLoader`) does.
List<Slide> parseDeck(String markdown) {
  final raw = const MarkdownParser().parse(markdown);
  return [
    for (final slide in raw)
      Slide(
        key: slide.key,
        options: SlideOptions.parse(slide.frontmatter),
        sections: const SectionParser().parse(slide.content),
        comments: const CommentParser().parse(slide.content),
      ),
  ];
}

/// Reduces a [Slide] to a structural fingerprint, ignoring the content-hash
/// [Slide.key] and insignificant whitespace inside content blocks.
Map<String, Object?> canonicalSlide(Slide slide) {
  return {
    'options': slide.options == null
        ? null
        : {
            'title': slide.options!.title,
            'style': slide.options!.style,
            'template': slide.options!.template,
            'args': slide.options!.args,
          },
    'sections': slide.sections.map(canonicalSection).toList(),
    'comments': slide.comments,
  };
}

Map<String, Object?> canonicalSection(SectionBlock section) {
  return {
    'flex': section.flex,
    'align': section.align?.name,
    'blocks': section.blocks.map(canonicalBlock).toList(),
  };
}

Map<String, Object?> canonicalBlock(Block block) {
  return switch (block) {
    ContentBlock() => {
      'type': 'block',
      'flex': block.flex,
      'align': block.align?.name,
      'scrollable': block.scrollable,
      'content': block.content.trim(),
    },
    WidgetBlock() => {
      'type': 'widget',
      'name': block.name,
      'flex': block.flex,
      'align': block.align?.name,
      'scrollable': block.scrollable,
      'args': block.args,
    },
  };
}

List<Map<String, Object?>> canonicalDeck(List<Slide> slides) =>
    slides.map(canonicalSlide).toList();

/// Asserts that serializing [slides] and re-parsing reproduces the same
/// structure.
void expectRoundTrip(List<Slide> slides, {String? reason}) {
  final markdown = const SlideSerializer().serialize(slides);
  final reparsed = parseDeck(markdown);
  expect(
    canonicalDeck(reparsed),
    equals(canonicalDeck(slides)),
    reason:
        '${reason ?? 'round-trip'} mismatch.\n--- serialized ---\n$markdown\n---',
  );
}

void main() {
  group('SlideSerializer round-trips inline fixtures', () {
    test('plain single-block slide', () {
      expectRoundTrip(parseDeck('# Hello\n\nSome body text.'));
    });

    test('multiple plain slides', () {
      expectRoundTrip(
        parseDeck('# Slide One\n\nBody.\n\n---\n\n# Slide Two\n\nMore.'),
      );
    });

    test('frontmatter title/style/template + extra args', () {
      expectRoundTrip(
        parseDeck(
          '---\n'
          'title: Welcome\n'
          'style: hero\n'
          'template: cover\n'
          'background: dark\n'
          '---\n\n'
          '# Welcome',
        ),
      );
    });

    test('multi-section with flex and align', () {
      expectRoundTrip(
        parseDeck(
          '@section {\n  flex: 2\n}\n'
          '@block {\n  align: center\n}\n'
          '# Left\n\n'
          '@section {\n  flex: 3\n  align: bottomRight\n}\n'
          '@block\n'
          'Right content',
        ),
      );
    });

    test('multiple content blocks in one section stay separate', () {
      expectRoundTrip(
        parseDeck(
          '@section\n'
          '@block\n'
          'First block\n'
          '@block {\n  align: topLeft\n}\n'
          'Second block',
        ),
      );
    });

    test('widget block with args (shorthand tag)', () {
      expectRoundTrip(
        parseDeck(
          '@section\n'
          '@image {\n  src: photo.png\n  fit: cover\n  align: center\n}',
        ),
      );
    });

    test('scrollable block', () {
      expectRoundTrip(
        parseDeck('@block {\n  scrollable: true\n}\nLong content here'),
      );
    });

    test('speaker comments are preserved', () {
      expectRoundTrip(
        parseDeck('# Slide\n\nVisible.\n\n<!-- Remember to slow down here -->'),
      );
    });

    test('content lines beginning with @ survive escaping', () {
      expectRoundTrip(
        parseDeck('# Mentions\n\n_@channel please review\n\nNormal line.'),
      );
    });

    test('fenced code containing --- and @ is preserved', () {
      expectRoundTrip(
        parseDeck(
          '# Code\n\n```dart\n@override\nvoid main() {}\n---\nnot a separator\n```',
        ),
      );
    });

    test('serialize then re-serialize is stable (idempotent)', () {
      final slides = parseDeck(
        '@section {\n  flex: 2\n}\n@block {\n  align: center\n}\n# Title',
      );
      final once = const SlideSerializer().serialize(slides);
      final twice = const SlideSerializer().serialize(parseDeck(once));
      expect(twice, equals(once));
    });
  });

  group('SlideSerializer round-trips real decks', () {
    final demoSlides = File('../../demo/slides.md');

    test(
      'demo/slides.md',
      () {
        final slides = parseDeck(demoSlides.readAsStringSync());
        expect(slides, isNotEmpty);
        expectRoundTrip(slides, reason: 'demo/slides.md');
      },
      skip: demoSlides.existsSync() ? false : 'demo/slides.md not found',
    );

    for (final name in ['coffee', 'polar_bear', 'zebra']) {
      final deckFile = File('../playground/assets/ai_examples/${name}_deck.json');
      test(
        'AI example deck: $name',
        () {
          final json =
              jsonDecode(deckFile.readAsStringSync()) as Map<String, Object?>;
          final slides = [
            for (final entry in json['slides'] as List)
              Slide.parse(Map<String, Object?>.from(entry as Map)),
          ];
          expect(slides, isNotEmpty);
          expectRoundTrip(slides, reason: '$name deck');
        },
        skip: deckFile.existsSync() ? false : '${name}_deck.json not found',
      );
    }
  });
}
