import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/modules/common/helpers/extensions.dart';

import 'style_spec.dart';

TextStyle get _baseTextStyle => GoogleFonts.poppins().copyWith(
      fontSize: 24,
      color: Colors.white,
    );

const onGist = Variant('gist');
const onDebug = Variant('debug');
const onImage = Variant('image');

class DeckStyle {
  const DeckStyle();
  SlideSpecUtility<SlideSpecAttribute> get $ => SlideSpecUtility.self;

  Style build() {
    final containers = [
      $.blockContainer.padding.all(40),
      $.section.image(
        $.blockContainer.padding.all(0),
      ),
      $.section.gist(
        $.blockContainer.chain
          ..margin.all(0)
          ..padding.all(0),
      ),
    ];

    final alertStyle = [
      // Heading
      $.alert.all.heading.chain
        ..capitalize()
        ..style.as(_baseTextStyle)
        ..style.bold(),
      // Container
      $.alert.all.container.chain
        ..padding.horizontal(24)
        ..padding.vertical(8)
        ..margin.bottom(12)
        ..color.withOpacity(0.05)
        ..border.left.width(4),
      // Description
      $.alert.all.description.chain
        ..style.as(_baseTextStyle)
        ..textAlign.left()
        ..style.height(1.6),

      // Remaining
      $.alert.all.chain
        ..containerFlex.gap(12)
        ..containerFlex.crossAxisAlignment.start()
        ..headingFlex.gap(8),
      // Types
      $.alert.note.color(Colors.blue),
      $.alert.tip.color(Colors.green),
      $.alert.important.color(Colors.deepPurpleAccent),
      $.alert.warning.color(Colors.amber),
      $.alert.caution.color(Colors.redAccent),
    ];

    final typography = [
      $.headingTextStyle.chain,
      $.baseTextStyle.as(_baseTextStyle),
      $.h1.chain
        ..style.fontSize(96)
        ..style.fontWeight.bold()
        ..style.height(1.1)
        ..wrap.padding.bottom(16),
      $.h2.chain
        ..style.fontSize(72)
        ..style.fontWeight.bold()
        ..style.height(1.2)
        ..wrap.padding.bottom(12),
      $.h3.chain
        ..style.fontSize(48)
        ..style.fontWeight.w600()
        ..style.height(1.3)
        ..wrap.padding.bottom(12),
      $.h4.chain
        ..style.fontSize(36)
        ..style.fontWeight.normal()
        ..style.height(1.3)
        ..wrap.padding.bottom(8),
      $.h5.chain
        ..style.fontSize(24)
        ..style.fontWeight.normal()
        ..style.height(1.4)
        ..wrap.padding.bottom(4),
      $.h6.chain
        ..style.as(_baseTextStyle)
        ..style.height(1.4)
        ..style.fontWeight.normal()
        ..wrap.padding.bottom(3),
      $.p.chain
        ..style.as(_baseTextStyle)
        ..style.height(1.6)
        ..wrap.padding.bottom(12),
    ];

    final codeStyle = $.code.chain
      ..textStyle.as(GoogleFonts.jetBrainsMono())
      ..textStyle.fontSize(18)
      ..container.padding.all(32)
      ..container.color(const Color.fromARGB(255, 0, 0, 0))
      ..container.borderRadius.circular(10);

    final tableStyle = $.table.chain
      ..headStyle.as(_baseTextStyle)
      ..headStyle.fontWeight.bold()
      ..bodyStyle.as(_baseTextStyle)
      ..cellPadding.all(12)
      ..border.all(color: Colors.grey, width: 2)
      ..cellDecoration.color(Colors.grey.useOpacity(0.1));

    final blockquoteStyle = $.blockquote.chain
      ..textStyle.as(_baseTextStyle)
      ..textStyle.fontSize(32)
      ..padding(
        bottom: 12,
        left: 30,
      )
      ..decoration.border.left(
            color: Colors.grey,
            width: 4,
          );

    final listStyle = $.list.chain
      ..bullet.style.as(_baseTextStyle)
      ..text.style.as(_baseTextStyle)
      ..text.style.height(1.6)
      ..text.wrap.padding.bottom(8);

    return Style.create([
      ...containers,
      ...typography,
      codeStyle,
      listStyle,
      ...alertStyle,

      $.link.color(const Color.fromARGB(255, 66, 82, 96)),
      $.list.bullet.style.as(_baseTextStyle),
      $.checkbox.textStyle.as(_baseTextStyle),

      tableStyle,
      blockquoteStyle,
      // divider
      $.divider.border(width: 2, color: Colors.grey),
      // $.image.fit.cover(),
    ]);
  }
}

class SlideSpecSectionsUtility {
  const SlideSpecSectionsUtility();

  final gist = const Variant('gist');

  final image = const Variant('image');
}

extension SlideSpecUtilityX<T extends Attribute> on SlideSpecUtility<T> {
  Variant get debug => const Variant('debug');
  TextStyleUtility<T> get baseTextStyle {
    return TextStyleUtility(
      (value) => only(
        link: value,
        a: value,
        em: value,
        strong: value,
        p: TextSpecAttribute(style: value),
        h1: TextSpecAttribute(style: value),
        h2: TextSpecAttribute(style: value),
        h3: TextSpecAttribute(style: value),
        h4: TextSpecAttribute(style: value),
        h5: TextSpecAttribute(style: value),
        h6: TextSpecAttribute(style: value),
        list: MarkdownListSpecAttribute(
            bullet: TextSpecAttribute(
          style: value,
        )),
        table: MarkdownTableSpecAttribute(bodyStyle: value, headStyle: value),
        code: MarkdownCodeblockSpecAttribute(textStyle: value),
        blockquote: MarkdownBlockquoteSpecAttribute(textStyle: value),
      ),
    );
  }

  // PaddingModifierSpecUtility<T> get blockSpacing {
  //   return PaddingModifierSpecUtility((value) {
  //     final modifier = WidgetModifiersDataDto([value]);
  //     return only(
  //       h1: TextSpecAttribute(modifiers: modifier),
  //       h2: TextSpecAttribute(modifiers: modifier),
  //       h3: TextSpecAttribute(modifiers: modifier),
  //       h4: TextSpecAttribute(modifiers: modifier),
  //       h5: TextSpecAttribute(modifiers: modifier),
  //       h6: TextSpecAttribute(modifiers: modifier),
  //       p: TextSpecAttribute(modifiers: modifier),
  //       list: MarkdownListSpecAttribute(
  //         bullet: TextSpecAttribute(modifiers: modifier),
  //       ),
  //       blockquote: MarkdownBlockquoteSpecAttribute(
  //         modifiers: modifier,
  //       ),
  //       image: ImageSpecAttribute(modifiers: modifier),
  //       code: MarkdownCodeblockSpecAttribute(
  //         modifiers: modifier,
  //       ),
  //       table: MarkdownTableSpecAttribute(
  //         modifiers: modifier,
  //       ),
  //     );
  //   });
  // }

  SlideSpecSectionsUtility get section => const SlideSpecSectionsUtility();

  TextSpecUtility<T> get headingTextStyle {
    return TextSpecUtility(
      (value) => only(
        h1: value,
        h2: value,
        h3: value,
        h4: value,
        h5: value,
        h6: value,
      ),
    );
  }
}

extension TextDirectiveX<T extends Attribute> on TextDirectiveUtility<T> {
  T sameWidthLines(int lines) => call((String text) {
        final words = text.split(' ');
        final averageLineLength = text.length / lines;

        final formattedLines = <String>[];
        var currentLine = StringBuffer();

        for (var word in words) {
          final newLineLength = currentLine.length + word.length + 1;
          if (newLineLength > averageLineLength && currentLine.isNotEmpty) {
            formattedLines.add(currentLine.toString());
            currentLine.clear();
          }
          currentLine.write(currentLine.isEmpty ? word : ' $word');
        }

        if (currentLine.isNotEmpty) {
          formattedLines.add(currentLine.toString());
        }

        return formattedLines.join('\n');
      });
}
