import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/data/mappers/deck_markdown_codec.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/export/domain/deck_export.dart';

const _heroKey = 'wizard-run-slide-01-hero.png';
const _chartKey = 'wizard-run-slide-02-chart.png';

const _markdown =
    '''
---
title: Urban gardens
---

# Urban gardens

![Hero]($_heroKey)

---

@image {
  src: $_chartKey
}
''';

final _heroBytes = [1, 2, 3];
final _chartBytes = [4, 5, 6];

void main() {
  final slides = const DeckMarkdownCodec().decode(_markdown);

  group('DeckExport.fromDeck', () {
    test('writes slides.md with every image under assets/', () {
      final export = DeckExport.fromDeck(
        slides: slides,
        images: [
          GeneratedImageAsset.success(assetKey: _heroKey, bytes: _heroBytes),
          GeneratedImageAsset.success(assetKey: _chartKey, bytes: _chartBytes),
        ],
      );

      final markdown = utf8.decode(export.files['slides.md']!);
      expect(markdown, contains('](assets/$_heroKey)'));
      expect(markdown, contains('src: assets/$_chartKey'));
      expect(markdown, isNot(contains(']($_heroKey)')));
      expect(export.files['assets/$_heroKey'], _heroBytes);
      expect(export.files['assets/$_chartKey'], _chartBytes);
      expect(export.files.keys, hasLength(3));
    });

    test('leaves out images that have no bytes', () {
      final export = DeckExport.fromDeck(
        slides: slides,
        images: [
          GeneratedImageAsset.success(assetKey: _heroKey, bytes: _heroBytes),
          const GeneratedImageAsset.failure(
            assetKey: _chartKey,
            error: 'timeout',
          ),
        ],
      );

      expect(export.files.keys, ['slides.md', 'assets/$_heroKey']);
      final markdown = utf8.decode(export.files['slides.md']!);
      expect(markdown, isNot(contains('assets/$_chartKey')));
    });

    test('names the export after the first slide title', () {
      final export = DeckExport.fromDeck(slides: slides, images: const []);

      expect(export.name, 'Urban gardens');
    });

    test('falls back to a generic name when no title is usable', () {
      final untitled = const DeckMarkdownCodec().decode('# Only a heading\n');
      final slashed = const DeckMarkdownCodec().decode(
        '---\ntitle: "../ops/plan: v2"\n---\n\nBody\n',
      );

      expect(
        DeckExport.fromDeck(slides: untitled, images: const []).name,
        'SuperDeck deck',
      );
      expect(
        DeckExport.fromDeck(slides: slashed, images: const []).name,
        'ops plan v2',
      );
    });
  });

  test('toZip holds exactly the export files', () {
    final export = DeckExport.fromDeck(
      slides: slides,
      images: [
        GeneratedImageAsset.success(assetKey: _heroKey, bytes: _heroBytes),
      ],
    );

    final archive = ZipDecoder().decodeBytes(export.toZip());

    expect(archive.files.map((file) => file.name), [
      'slides.md',
      'assets/$_heroKey',
    ]);
    expect(archive.findFile('assets/$_heroKey')!.content, _heroBytes);
    expect(
      utf8.decode(archive.findFile('slides.md')!.content),
      utf8.decode(export.files['slides.md']!),
    );
  });
}
