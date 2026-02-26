import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_ai/core/ai/prompts/font_styles.dart';

void main() {
  group('HeadlineFont', () {
    group('values', () {
      test('has expected number of fonts', () {
        expect(HeadlineFont.values.length, 5);
      });

      test('contains all expected fonts', () {
        expect(
          HeadlineFont.values,
          containsAll([
            HeadlineFont.playfairDisplay,
            HeadlineFont.montserrat,
            HeadlineFont.poppins,
            HeadlineFont.oswald,
            HeadlineFont.lobster,
          ]),
        );
      });
    });

    group('properties', () {
      test('each font has non-empty title', () {
        for (final font in HeadlineFont.values) {
          expect(
            font.title,
            isNotEmpty,
            reason: 'Font ${font.name} has empty title',
          );
        }
      });

      test('each font has non-empty fontFamily', () {
        for (final font in HeadlineFont.values) {
          expect(
            font.fontFamily,
            isNotEmpty,
            reason: 'Font ${font.name} has empty fontFamily',
          );
        }
      });

      test('each font has non-empty description', () {
        for (final font in HeadlineFont.values) {
          expect(
            font.description,
            isNotEmpty,
            reason: 'Font ${font.name} has empty description',
          );
        }
      });

      test('id returns enum name', () {
        expect(HeadlineFont.montserrat.id, 'montserrat');
        expect(HeadlineFont.playfairDisplay.id, 'playfairDisplay');
      });
    });

    group('fromId', () {
      test('returns font for valid ID', () {
        expect(HeadlineFont.fromId('montserrat'), HeadlineFont.montserrat);
        expect(
          HeadlineFont.fromId('playfairDisplay'),
          HeadlineFont.playfairDisplay,
        );
        expect(HeadlineFont.fromId('poppins'), HeadlineFont.poppins);
        expect(HeadlineFont.fromId('oswald'), HeadlineFont.oswald);
        expect(HeadlineFont.fromId('lobster'), HeadlineFont.lobster);
      });

      test('returns null for invalid ID', () {
        expect(HeadlineFont.fromId('nonexistent'), isNull);
        expect(HeadlineFont.fromId(''), isNull);
        expect(HeadlineFont.fromId('MONTSERRAT'), isNull); // Case sensitive
      });

      test('returns correct font for all values', () {
        for (final font in HeadlineFont.values) {
          expect(HeadlineFont.fromId(font.id), font);
        }
      });
    });

    group('ids', () {
      test('has correct count', () {
        final ids = HeadlineFont.values.map((f) => f.name).toList();
        expect(ids.length, HeadlineFont.values.length);
      });

      test('contains all font IDs', () {
        expect(
          HeadlineFont.values.map((f) => f.name).toList(),
          containsAll([
            'playfairDisplay',
            'montserrat',
            'poppins',
            'oswald',
            'lobster',
          ]),
        );
      });

      test('each ID can be resolved', () {
        for (final id in HeadlineFont.values.map((f) => f.name)) {
          expect(
            HeadlineFont.fromId(id),
            isNotNull,
            reason: 'ID $id should resolve',
          );
        }
      });
    });

    group('schemaDescription', () {
      test('includes all font names', () {
        final desc = HeadlineFont.schemaDescription;
        for (final font in HeadlineFont.values) {
          expect(desc, contains(font.name), reason: 'Missing ${font.name}');
        }
      });

      test('includes descriptions', () {
        final desc = HeadlineFont.schemaDescription;
        for (final font in HeadlineFont.values) {
          expect(
            desc,
            contains(font.description),
            reason: 'Missing description for ${font.name}',
          );
        }
      });

      test('starts with expected prefix', () {
        expect(HeadlineFont.schemaDescription, startsWith('Headline font.'));
      });
    });
  });

  group('BodyFont', () {
    group('values', () {
      test('has expected number of fonts', () {
        expect(BodyFont.values.length, 5);
      });

      test('contains all expected fonts', () {
        expect(
          BodyFont.values,
          containsAll([
            BodyFont.inter,
            BodyFont.openSans,
            BodyFont.lato,
            BodyFont.roboto,
            BodyFont.sourceSerif4,
          ]),
        );
      });
    });

    group('properties', () {
      test('each font has non-empty title', () {
        for (final font in BodyFont.values) {
          expect(
            font.title,
            isNotEmpty,
            reason: 'Font ${font.name} has empty title',
          );
        }
      });

      test('each font has non-empty fontFamily', () {
        for (final font in BodyFont.values) {
          expect(
            font.fontFamily,
            isNotEmpty,
            reason: 'Font ${font.name} has empty fontFamily',
          );
        }
      });

      test('each font has non-empty description', () {
        for (final font in BodyFont.values) {
          expect(
            font.description,
            isNotEmpty,
            reason: 'Font ${font.name} has empty description',
          );
        }
      });

      test('id returns enum name', () {
        expect(BodyFont.inter.id, 'inter');
        expect(BodyFont.openSans.id, 'openSans');
      });
    });

    group('fromId', () {
      test('returns font for valid ID', () {
        expect(BodyFont.fromId('inter'), BodyFont.inter);
        expect(BodyFont.fromId('openSans'), BodyFont.openSans);
        expect(BodyFont.fromId('lato'), BodyFont.lato);
        expect(BodyFont.fromId('roboto'), BodyFont.roboto);
        expect(BodyFont.fromId('sourceSerif4'), BodyFont.sourceSerif4);
      });

      test('returns null for invalid ID', () {
        expect(BodyFont.fromId('nonexistent'), isNull);
        expect(BodyFont.fromId(''), isNull);
        expect(BodyFont.fromId('INTER'), isNull); // Case sensitive
      });

      test('returns correct font for all values', () {
        for (final font in BodyFont.values) {
          expect(BodyFont.fromId(font.id), font);
        }
      });
    });

    group('ids', () {
      test('has correct count', () {
        final ids = BodyFont.values.map((f) => f.name).toList();
        expect(ids.length, BodyFont.values.length);
      });

      test('contains all font IDs', () {
        expect(
          BodyFont.values.map((f) => f.name).toList(),
          containsAll(['inter', 'openSans', 'lato', 'roboto', 'sourceSerif4']),
        );
      });

      test('each ID can be resolved', () {
        for (final id in BodyFont.values.map((f) => f.name)) {
          expect(
            BodyFont.fromId(id),
            isNotNull,
            reason: 'ID $id should resolve',
          );
        }
      });
    });

    group('schemaDescription', () {
      test('includes all font names', () {
        final desc = BodyFont.schemaDescription;
        for (final font in BodyFont.values) {
          expect(desc, contains(font.name), reason: 'Missing ${font.name}');
        }
      });

      test('includes descriptions', () {
        final desc = BodyFont.schemaDescription;
        for (final font in BodyFont.values) {
          expect(
            desc,
            contains(font.description),
            reason: 'Missing description for ${font.name}',
          );
        }
      });

      test('starts with expected prefix', () {
        expect(BodyFont.schemaDescription, startsWith('Body font.'));
      });
    });
  });
}
