import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
