import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

part 'style_spec.g.dart';

const _mdCode = MixableFieldProperty(type: 'MarkdownCodeblockSpecAttribute');
const _mdList = MixableFieldProperty(type: 'MarkdownListSpecAttribute');
const _mdTable = MixableFieldProperty(type: 'MarkdownTableSpecAttribute');
const _mdCheckbox = MixableFieldProperty(type: 'MarkdownCheckboxSpecAttribute');

const _mdBlockQuote =
    MixableFieldProperty(type: 'MarkdownBlockquoteSpecAttribute');
const _mdAlert = MixableFieldProperty(type: 'MarkdownAlertSpecAttribute');

const _mdAlertItem =
    MixableFieldProperty(type: 'MarkdownAlertTypeSpecAttribute');

@MixableSpec()
final class MarkdownTextSpec extends Spec<MarkdownTextSpec>
    with _$MarkdownTextSpec {
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final WrapAlignment? alignment;

  const MarkdownTextSpec({
    this.textStyle,
    this.padding,
    this.alignment,
  });
}

@MixableSpec()
final class MarkdownListSpec extends Spec<MarkdownListSpec>
    with _$MarkdownListSpec {
  final TextSpec? bullet;
  final TextSpec? text;

  final WrapAlignment? orderedAlignment;
  final WrapAlignment? unorderedAlignment;

  const MarkdownListSpec({
    this.bullet,
    this.text,
    this.orderedAlignment,
    this.unorderedAlignment,
  });
}

@MixableSpec()
final class MarkdownAlertSpec extends Spec<MarkdownAlertSpec>
    with _$MarkdownAlertSpec {
  @MixableField(dto: _mdAlertItem)
  final MarkdownAlertTypeSpec note;

  @MixableField(dto: _mdAlertItem)
  final MarkdownAlertTypeSpec tip;

  @MixableField(dto: _mdAlertItem)
  final MarkdownAlertTypeSpec important;

  @MixableField(dto: _mdAlertItem)
  final MarkdownAlertTypeSpec warning;

  @MixableField(dto: _mdAlertItem)
  final MarkdownAlertTypeSpec caution;

  const MarkdownAlertSpec({
    MarkdownAlertTypeSpec? note,
    MarkdownAlertTypeSpec? tip,
    MarkdownAlertTypeSpec? important,
    MarkdownAlertTypeSpec? warning,
    MarkdownAlertTypeSpec? caution,
  })  : note = note ?? const MarkdownAlertTypeSpec(),
        tip = tip ?? const MarkdownAlertTypeSpec(),
        important = important ?? const MarkdownAlertTypeSpec(),
        warning = warning ?? const MarkdownAlertTypeSpec(),
        caution = caution ?? const MarkdownAlertTypeSpec();
}

@MixableSpec()
final class MarkdownAlertTypeSpec extends Spec<MarkdownAlertTypeSpec>
    with _$MarkdownAlertTypeSpec {
  final TextSpec heading;
  final TextSpec description;
  final IconSpec icon;
  final BoxSpec container;
  final FlexSpec containerFlex;
  final FlexSpec headingFlex;

  const MarkdownAlertTypeSpec({
    TextSpec? heading,
    TextSpec? description,
    IconSpec? icon,
    BoxSpec? container,
    FlexSpec? headingFlex,
    FlexSpec? containerFlex,
  })  : heading = heading ?? const TextSpec(),
        description = description ?? const TextSpec(),
        icon = icon ?? const IconSpec(),
        containerFlex = containerFlex ?? const FlexSpec(),
        headingFlex = headingFlex ?? const FlexSpec(),
        container = container ?? const BoxSpec();
}

extension MarkdownAlertSpecUtilityX<T extends Attribute>
    on MarkdownAlertSpecUtility<T> {
  MarkdownAlertTypeSpecUtility<T> get all => MarkdownAlertTypeSpecUtility(
        (value) => only(
          note: value,
          tip: value,
          important: value,
          warning: value,
          caution: value,
        ),
      );
}
//TODO Mix example

extension MarkdownAlertTypeSpecUtilityX<T extends Attribute>
    on MarkdownAlertTypeSpecUtility<T> {
  ColorUtility<T> get color => ColorUtility<T>((value) {
        return heading.style
            .only(color: value)
            .merge(container.border.left.only(color: value))
            .merge(icon.only(color: value)) as T;
      });
}

@MixableSpec()
final class MarkdownTableSpec extends Spec<MarkdownTableSpec>
    with _$MarkdownTableSpec {
  final TextStyle? headStyle;
  final TextStyle? bodyStyle;
  final TextAlign? headAlignment;
  final EdgeInsets? padding;
  final TableBorder? border;
  final TableColumnWidth? columnWidth;
  final EdgeInsets? cellPadding;

  final BoxDecoration? cellDecoration;
  final TableCellVerticalAlignment? verticalAlignment;

  const MarkdownTableSpec({
    this.headStyle,
    this.bodyStyle,
    this.headAlignment,
    this.padding,
    this.border,
    this.columnWidth,
    this.cellPadding,
    this.cellDecoration,
    this.verticalAlignment,
    super.modifiers,
    super.animated,
  });
}

@MixableSpec()
final class MarkdownBlockquoteSpec extends Spec<MarkdownBlockquoteSpec>
    with _$MarkdownBlockquoteSpec {
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;
  final WrapAlignment? alignment;

  const MarkdownBlockquoteSpec({
    this.textStyle,
    this.padding,
    this.decoration,
    this.alignment,
    super.modifiers,
    super.animated,
  });
}

@MixableSpec()
final class MarkdownCodeblockSpec extends Spec<MarkdownCodeblockSpec>
    with _$MarkdownCodeblockSpec {
  final TextStyle? textStyle;
  final BoxSpec? container;

  final WrapAlignment? alignment;

  const MarkdownCodeblockSpec({
    this.textStyle,
    this.container,
    this.alignment,
    super.modifiers,
    super.animated,
  });
}

@MixableSpec()
class MarkdownCheckboxSpec extends Spec<MarkdownCheckboxSpec>
    with _$MarkdownCheckboxSpec {
  final TextStyle? textStyle;
  final IconSpec? icon;

  const MarkdownCheckboxSpec({
    this.textStyle,
    this.icon,
    super.modifiers,
    super.animated,
  });
}

@MixableSpec()
final class SlideSpec extends Spec<SlideSpec> with _$SlideSpec {
  final TextSpec? h1;

  final TextSpec? h2;

  final TextStyle? a;
  final TextStyle? em;
  final TextStyle? strong;
  final TextStyle? del;
  final TextStyle? img;

  final TextScaler? textScaleFactor;

  final TextSpec? h3;

  final TextSpec? h4;

  final TextSpec? h5;

  final TextSpec? h6;

  final TextSpec? p;

  final TextStyle? link;

  @MixableField(dto: _mdAlert)
  final MarkdownAlertSpec alert;

  @MixableField(utilities: [MixableFieldUtility(alias: 'divider')])
  final BoxDecoration? horizontalRuleDecoration;
  @MixableField(dto: _mdBlockQuote)
  final MarkdownBlockquoteSpec? blockquote;

  @MixableField(dto: _mdList)
  final MarkdownListSpec? list;

  @MixableField(dto: _mdTable)
  final MarkdownTableSpec? table;

  @MixableField(dto: _mdCode)
  final MarkdownCodeblockSpec? code;

  final BoxSpec blockContainer;
  final ImageSpec image;

  @MixableField(dto: _mdCheckbox)
  final MarkdownCheckboxSpec? checkbox;

  static const of = _$SlideSpec.of;
  static const from = _$SlideSpec.from;

  const SlideSpec({
    this.h1,
    this.h2,
    this.h3,
    this.h4,
    this.h5,
    this.h6,
    this.p,
    this.link,
    this.blockquote,
    this.list,
    this.table,
    this.checkbox,
    this.code,
    this.a,
    this.em,
    this.strong,
    this.del,
    this.img,
    this.horizontalRuleDecoration,
    this.textScaleFactor,
    BoxSpec? blockContainer,
    ImageSpec? image,
    MarkdownAlertSpec? alert,
    super.modifiers,
    super.animated,
  })  : blockContainer = blockContainer ?? const BoxSpec(),
        image = image ?? const ImageSpec(),
        alert = alert ?? const MarkdownAlertSpec();

  MarkdownStyleSheet toStyle() {
    return MarkdownStyleSheet(
      a: link,
      blockquote: blockquote?.textStyle,
      blockquotePadding: blockquote?.padding,
      horizontalRuleDecoration: horizontalRuleDecoration,
      blockquoteDecoration: blockquote?.decoration,
      blockquoteAlign: blockquote?.alignment ?? WrapAlignment.start,
      orderedListAlign: list?.orderedAlignment ?? WrapAlignment.start,
      unorderedListAlign: list?.unorderedAlignment ?? WrapAlignment.start,
      tableHead: table?.headStyle,
      tableBody: table?.bodyStyle,
      tableHeadAlign: table?.headAlignment,
      tablePadding: table?.padding,
      tableBorder: table?.border,
      tableColumnWidth: table?.columnWidth,
      tableCellsPadding: table?.cellPadding,
      tableCellsDecoration: table?.cellDecoration,
      tableVerticalAlignment:
          table?.verticalAlignment ?? TableCellVerticalAlignment.middle,
      checkbox: checkbox?.textStyle,
    );
  }
}
