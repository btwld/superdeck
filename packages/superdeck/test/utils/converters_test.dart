import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/utils/converters.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('hexToColor', () {
    group('6-digit hex', () {
      test('parses with # prefix', () {
        final color = hexToColor('#ff0000');
        expect(color, const Color(0xFFFF0000));
      });

      test('parses without # prefix', () {
        final color = hexToColor('00ff00');
        expect(color, const Color(0xFF00FF00));
      });

      test('parses uppercase', () {
        final color = hexToColor('#AABBCC');
        expect(color, const Color(0xFFAABBCC));
      });

      test('parses lowercase', () {
        final color = hexToColor('#aabbcc');
        expect(color, const Color(0xFFAABBCC));
      });

      test('parses mixed case', () {
        final color = hexToColor('#AaBbCc');
        expect(color, const Color(0xFFAABBCC));
      });

      test('parses black', () {
        final color = hexToColor('#000000');
        expect(color, const Color(0xFF000000));
      });

      test('parses white', () {
        final color = hexToColor('#ffffff');
        expect(color, const Color(0xFFFFFFFF));
      });
    });

    group('8-digit hex (with alpha)', () {
      test('parses with # prefix', () {
        final color = hexToColor('#80ff0000');
        expect(color, const Color(0x80FF0000));
      });

      test('parses without # prefix', () {
        final color = hexToColor('80ff0000');
        expect(color, const Color(0x80FF0000));
      });

      test('parses fully transparent', () {
        final color = hexToColor('#00000000');
        expect(color, const Color(0x00000000));
      });

      test('parses fully opaque', () {
        final color = hexToColor('#ffffffff');
        expect(color, const Color(0xFFFFFFFF));
      });

      test('parses 50% alpha', () {
        final color = hexToColor('#7f0000ff');
        expect(color, const Color(0x7F0000FF));
      });
    });
  });

  group('ConverterHelper.toAlignment', () {
    test('null returns Alignment.center', () {
      expect(ConverterHelper.toAlignment(null), Alignment.center);
    });

    test('topLeft returns Alignment.topLeft', () {
      expect(
        ConverterHelper.toAlignment(ContentAlignment.topLeft),
        Alignment.topLeft,
      );
    });

    test('topCenter returns Alignment.topCenter', () {
      expect(
        ConverterHelper.toAlignment(ContentAlignment.topCenter),
        Alignment.topCenter,
      );
    });

    test('topRight returns Alignment.topRight', () {
      expect(
        ConverterHelper.toAlignment(ContentAlignment.topRight),
        Alignment.topRight,
      );
    });

    test('centerLeft returns Alignment.centerLeft', () {
      expect(
        ConverterHelper.toAlignment(ContentAlignment.centerLeft),
        Alignment.centerLeft,
      );
    });

    test('center returns Alignment.center', () {
      expect(
        ConverterHelper.toAlignment(ContentAlignment.center),
        Alignment.center,
      );
    });

    test('centerRight returns Alignment.centerRight', () {
      expect(
        ConverterHelper.toAlignment(ContentAlignment.centerRight),
        Alignment.centerRight,
      );
    });

    test('bottomLeft returns Alignment.bottomLeft', () {
      expect(
        ConverterHelper.toAlignment(ContentAlignment.bottomLeft),
        Alignment.bottomLeft,
      );
    });

    test('bottomCenter returns Alignment.bottomCenter', () {
      expect(
        ConverterHelper.toAlignment(ContentAlignment.bottomCenter),
        Alignment.bottomCenter,
      );
    });

    test('bottomRight returns Alignment.bottomRight', () {
      expect(
        ConverterHelper.toAlignment(ContentAlignment.bottomRight),
        Alignment.bottomRight,
      );
    });
  });

  group('ConverterHelper.toBoxFit', () {
    test('fill returns BoxFit.fill', () {
      expect(ConverterHelper.toBoxFit(ImageFit.fill), BoxFit.fill);
    });

    test('contain returns BoxFit.contain', () {
      expect(ConverterHelper.toBoxFit(ImageFit.contain), BoxFit.contain);
    });

    test('cover returns BoxFit.cover', () {
      expect(ConverterHelper.toBoxFit(ImageFit.cover), BoxFit.cover);
    });

    test('fitWidth returns BoxFit.fitWidth', () {
      expect(ConverterHelper.toBoxFit(ImageFit.fitWidth), BoxFit.fitWidth);
    });

    test('fitHeight returns BoxFit.fitHeight', () {
      expect(ConverterHelper.toBoxFit(ImageFit.fitHeight), BoxFit.fitHeight);
    });

    test('none returns BoxFit.none', () {
      expect(ConverterHelper.toBoxFit(ImageFit.none), BoxFit.none);
    });

    test('scaleDown returns BoxFit.scaleDown', () {
      expect(ConverterHelper.toBoxFit(ImageFit.scaleDown), BoxFit.scaleDown);
    });
  });

  group('ConverterHelper.toFlexAlignment', () {
    group('Axis.horizontal (Row)', () {
      const axis = Axis.horizontal;

      test('topLeft maps to (start, start)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.topLeft,
        );
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('topCenter maps to (center, start)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.topCenter,
        );
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('topRight maps to (end, start)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.topRight,
        );
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('centerLeft maps to (start, center)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.centerLeft,
        );
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('center maps to (center, center)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.center,
        );
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('centerRight maps to (end, center)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.centerRight,
        );
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('bottomLeft maps to (start, end)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.bottomLeft,
        );
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.end);
      });

      test('bottomCenter maps to (center, end)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.bottomCenter,
        );
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.end);
      });

      test('bottomRight maps to (end, end)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.bottomRight,
        );
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.end);
      });
    });

    group('Axis.vertical (Column)', () {
      const axis = Axis.vertical;

      test('topLeft maps to (start, start)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.topLeft,
        );
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('topCenter maps to (start, center)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.topCenter,
        );
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('topRight maps to (start, end)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.topRight,
        );
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.end);
      });

      test('centerLeft maps to (center, start)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.centerLeft,
        );
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('center maps to (center, center)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.center,
        );
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('centerRight maps to (center, end)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.centerRight,
        );
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.end);
      });

      test('bottomLeft maps to (end, start)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.bottomLeft,
        );
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('bottomCenter maps to (end, center)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.bottomCenter,
        );
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('bottomRight maps to (end, end)', () {
        final result = ConverterHelper.toFlexAlignment(
          axis,
          ContentAlignment.bottomRight,
        );
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.end);
      });
    });
  });

  group('ConverterHelper.toRowAlignment', () {
    test('delegates to toFlexAlignment with Axis.horizontal', () {
      for (final alignment in ContentAlignment.values) {
        final rowResult = ConverterHelper.toRowAlignment(alignment);
        final flexResult = ConverterHelper.toFlexAlignment(
          Axis.horizontal,
          alignment,
        );
        expect(rowResult, flexResult);
      }
    });
  });

  group('ConverterHelper.toColumnAlignment', () {
    test('delegates to toFlexAlignment with Axis.vertical', () {
      for (final alignment in ContentAlignment.values) {
        final colResult = ConverterHelper.toColumnAlignment(alignment);
        final flexResult = ConverterHelper.toFlexAlignment(
          Axis.vertical,
          alignment,
        );
        expect(colResult, flexResult);
      }
    });
  });

  group('ConverterHelper.calculateBlockOffset', () {
    test('empty spec returns Offset.zero', () {
      final spec = BoxSpec();
      final offset = ConverterHelper.calculateBlockOffset(spec);
      expect(offset, Offset.zero);
    });

    test('padding only calculates horizontal and vertical', () {
      final spec = BoxSpec(padding: const EdgeInsets.all(10));
      final offset = ConverterHelper.calculateBlockOffset(spec);
      expect(offset.dx, 20.0); // 10 left + 10 right
      expect(offset.dy, 20.0); // 10 top + 10 bottom
    });

    test('margin only calculates horizontal and vertical', () {
      final spec = BoxSpec(margin: const EdgeInsets.all(5));
      final offset = ConverterHelper.calculateBlockOffset(spec);
      expect(offset.dx, 10.0); // 5 left + 5 right
      expect(offset.dy, 10.0); // 5 top + 5 bottom
    });

    test('asymmetric padding calculates correctly', () {
      final spec = BoxSpec(
        padding: const EdgeInsets.only(left: 10, right: 20, top: 5, bottom: 15),
      );
      final offset = ConverterHelper.calculateBlockOffset(spec);
      expect(offset.dx, 30.0); // 10 + 20
      expect(offset.dy, 20.0); // 5 + 15
    });

    test('combined padding and margin sums correctly', () {
      final spec = BoxSpec(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(5),
      );
      final offset = ConverterHelper.calculateBlockOffset(spec);
      expect(offset.dx, 30.0); // (10+10) + (5+5)
      expect(offset.dy, 30.0); // (10+10) + (5+5)
    });

    test('decoration with border adds border dimensions', () {
      final spec = BoxSpec(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(width: 2),
        ),
      );
      final offset = ConverterHelper.calculateBlockOffset(spec);
      expect(offset.dx, 24.0); // 20 padding + 4 border (2 left + 2 right)
      expect(offset.dy, 24.0); // 20 padding + 4 border (2 top + 2 bottom)
    });

    test('decoration without border does not add extra offset', () {
      final spec = BoxSpec(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Colors.red),
      );
      final offset = ConverterHelper.calculateBlockOffset(spec);
      expect(offset.dx, 20.0);
      expect(offset.dy, 20.0);
    });

    test('symmetric horizontal padding', () {
      final spec = BoxSpec(
        padding: const EdgeInsets.symmetric(horizontal: 15),
      );
      final offset = ConverterHelper.calculateBlockOffset(spec);
      expect(offset.dx, 30.0);
      expect(offset.dy, 0.0);
    });

    test('symmetric vertical margin', () {
      final spec = BoxSpec(
        margin: const EdgeInsets.symmetric(vertical: 8),
      );
      final offset = ConverterHelper.calculateBlockOffset(spec);
      expect(offset.dx, 0.0);
      expect(offset.dy, 16.0);
    });
  });
}
