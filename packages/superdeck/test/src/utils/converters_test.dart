import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/utils/converters.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('BlockInsets.toEdgeInsets', () {
    test('maps normalized physical edges', () {
      final insets = BlockInsets(top: 1, right: 2, bottom: 3, left: 4);

      expect(insets.toEdgeInsets, const EdgeInsets.fromLTRB(4, 1, 2, 3));
    });
  });

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

  group('ContentAlignment.toAlignment', () {
    test('null returns Alignment.center', () {
      expect(
        (null as ContentAlignment?)?.toAlignment ?? Alignment.center,
        Alignment.center,
      );
    });

    test('topLeft returns Alignment.topLeft', () {
      expect(ContentAlignment.topLeft.toAlignment, Alignment.topLeft);
    });

    test('topCenter returns Alignment.topCenter', () {
      expect(ContentAlignment.topCenter.toAlignment, Alignment.topCenter);
    });

    test('topRight returns Alignment.topRight', () {
      expect(ContentAlignment.topRight.toAlignment, Alignment.topRight);
    });

    test('centerLeft returns Alignment.centerLeft', () {
      expect(ContentAlignment.centerLeft.toAlignment, Alignment.centerLeft);
    });

    test('center returns Alignment.center', () {
      expect(ContentAlignment.center.toAlignment, Alignment.center);
    });

    test('centerRight returns Alignment.centerRight', () {
      expect(ContentAlignment.centerRight.toAlignment, Alignment.centerRight);
    });

    test('bottomLeft returns Alignment.bottomLeft', () {
      expect(ContentAlignment.bottomLeft.toAlignment, Alignment.bottomLeft);
    });

    test('bottomCenter returns Alignment.bottomCenter', () {
      expect(ContentAlignment.bottomCenter.toAlignment, Alignment.bottomCenter);
    });

    test('bottomRight returns Alignment.bottomRight', () {
      expect(ContentAlignment.bottomRight.toAlignment, Alignment.bottomRight);
    });
  });

  group('ImageFit.toBoxFit', () {
    test('fill returns BoxFit.fill', () {
      expect(ImageFit.fill.toBoxFit, BoxFit.fill);
    });

    test('contain returns BoxFit.contain', () {
      expect(ImageFit.contain.toBoxFit, BoxFit.contain);
    });

    test('cover returns BoxFit.cover', () {
      expect(ImageFit.cover.toBoxFit, BoxFit.cover);
    });

    test('fitWidth returns BoxFit.fitWidth', () {
      expect(ImageFit.fitWidth.toBoxFit, BoxFit.fitWidth);
    });

    test('fitHeight returns BoxFit.fitHeight', () {
      expect(ImageFit.fitHeight.toBoxFit, BoxFit.fitHeight);
    });

    test('none returns BoxFit.none', () {
      expect(ImageFit.none.toBoxFit, BoxFit.none);
    });

    test('scaleDown returns BoxFit.scaleDown', () {
      expect(ImageFit.scaleDown.toBoxFit, BoxFit.scaleDown);
    });
  });

  group('ContentAlignment.toFlexAlignment', () {
    group('Axis.horizontal (Row)', () {
      const axis = Axis.horizontal;

      test('topLeft maps to (start, start)', () {
        final result = ContentAlignment.topLeft.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('topCenter maps to (center, start)', () {
        final result = ContentAlignment.topCenter.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('topRight maps to (end, start)', () {
        final result = ContentAlignment.topRight.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('centerLeft maps to (start, center)', () {
        final result = ContentAlignment.centerLeft.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('center maps to (center, center)', () {
        final result = ContentAlignment.center.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('centerRight maps to (end, center)', () {
        final result = ContentAlignment.centerRight.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('bottomLeft maps to (start, end)', () {
        final result = ContentAlignment.bottomLeft.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.end);
      });

      test('bottomCenter maps to (center, end)', () {
        final result = ContentAlignment.bottomCenter.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.end);
      });

      test('bottomRight maps to (end, end)', () {
        final result = ContentAlignment.bottomRight.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.end);
      });
    });

    group('Axis.vertical (Column)', () {
      const axis = Axis.vertical;

      test('topLeft maps to (start, start)', () {
        final result = ContentAlignment.topLeft.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('topCenter maps to (start, center)', () {
        final result = ContentAlignment.topCenter.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('topRight maps to (start, end)', () {
        final result = ContentAlignment.topRight.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.start);
        expect(result.$2, CrossAxisAlignment.end);
      });

      test('centerLeft maps to (center, start)', () {
        final result = ContentAlignment.centerLeft.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('center maps to (center, center)', () {
        final result = ContentAlignment.center.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('centerRight maps to (center, end)', () {
        final result = ContentAlignment.centerRight.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.center);
        expect(result.$2, CrossAxisAlignment.end);
      });

      test('bottomLeft maps to (end, start)', () {
        final result = ContentAlignment.bottomLeft.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.start);
      });

      test('bottomCenter maps to (end, center)', () {
        final result = ContentAlignment.bottomCenter.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.center);
      });

      test('bottomRight maps to (end, end)', () {
        final result = ContentAlignment.bottomRight.toFlexAlignment(axis);
        expect(result.$1, MainAxisAlignment.end);
        expect(result.$2, CrossAxisAlignment.end);
      });
    });
  });

  group('BoxSpec.calculateBlockOffset', () {
    test('empty spec returns Offset.zero', () {
      final spec = BoxSpec();
      expect(spec.calculateBlockOffset, Offset.zero);
    });

    test('padding only calculates horizontal and vertical', () {
      final spec = BoxSpec(padding: const EdgeInsets.all(10));
      expect(spec.calculateBlockOffset.dx, 20.0);
      expect(spec.calculateBlockOffset.dy, 20.0);
    });

    test('margin only calculates horizontal and vertical', () {
      final spec = BoxSpec(margin: const EdgeInsets.all(5));
      expect(spec.calculateBlockOffset.dx, 10.0);
      expect(spec.calculateBlockOffset.dy, 10.0);
    });

    test('asymmetric padding calculates correctly', () {
      final spec = BoxSpec(
        padding: const EdgeInsets.only(left: 10, right: 20, top: 5, bottom: 15),
      );
      expect(spec.calculateBlockOffset.dx, 30.0);
      expect(spec.calculateBlockOffset.dy, 20.0);
    });

    test('combined padding and margin sums correctly', () {
      final spec = BoxSpec(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(5),
      );
      expect(spec.calculateBlockOffset.dx, 30.0);
      expect(spec.calculateBlockOffset.dy, 30.0);
    });

    test('decoration with border adds border dimensions', () {
      final spec = BoxSpec(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(border: Border.all(width: 2)),
      );
      expect(spec.calculateBlockOffset.dx, 24.0);
      expect(spec.calculateBlockOffset.dy, 24.0);
    });

    test('decoration without border does not add extra offset', () {
      final spec = BoxSpec(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Colors.red),
      );
      expect(spec.calculateBlockOffset.dx, 20.0);
      expect(spec.calculateBlockOffset.dy, 20.0);
    });

    test('symmetric horizontal padding', () {
      final spec = BoxSpec(padding: const EdgeInsets.symmetric(horizontal: 15));
      expect(spec.calculateBlockOffset.dx, 30.0);
      expect(spec.calculateBlockOffset.dy, 0.0);
    });

    test('symmetric vertical margin', () {
      final spec = BoxSpec(margin: const EdgeInsets.symmetric(vertical: 8));
      expect(spec.calculateBlockOffset.dx, 0.0);
      expect(spec.calculateBlockOffset.dy, 16.0);
    });
  });
}
