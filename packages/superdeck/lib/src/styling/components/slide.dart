import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

import 'block_styler.dart';
import 'markdown_alert.dart';
import 'markdown_blockquote.dart';
import 'markdown_checkbox.dart';
import 'markdown_codeblock.dart';
import 'markdown_list.dart';
import 'markdown_table.dart';

part 'slide.g.dart';

/// Root specification for slide styling containing all markdown element styles.
///
/// This is the main spec that aggregates all markdown styling including headings,
/// text, alerts, lists, tables, code blocks, and more.
///
/// **Active styling path:** block builders read `h1`–`h6`, `p`, and list text
/// for base typography; inline markdown (`strong`, `em`, `del`, `a`/`link`,
/// inline `code` via [code].textStyle) and [textScaleFactor] are applied when
/// rendering paragraphs, headings, and list items. Prefer configuring these
/// through [SlideStyler] / Mix [TextStyler].
@MixableSpec()
@immutable
final class SlideSpec with _$SlideSpec {
  @override
  final StyleSpec<TextSpec>? h1;
  @override
  final StyleSpec<TextSpec>? h2;
  @override
  final StyleSpec<TextSpec>? h3;
  @override
  final StyleSpec<TextSpec>? h4;
  @override
  final StyleSpec<TextSpec>? h5;
  @override
  final StyleSpec<TextSpec>? h6;
  @override
  final StyleSpec<TextSpec>? p;

  /// Anchor style; [link] takes precedence when both are set.
  @override
  final TextStyle? a;
  @override
  final TextStyle? em;
  @override
  final TextStyle? strong;
  @override
  final TextStyle? del;
  @override
  final TextStyle? img;

  /// Preferred link style (used for `a` tags; overrides [a] when set).
  @override
  final TextStyle? link;

  /// Scales markdown text in block builders when set.
  @override
  final TextScaler? textScaleFactor;

  /// Vertical gap between top-level markdown elements.
  ///
  /// An unset value resolves to zero so spacing is owned by SuperDeck styles,
  /// not by flutter_markdown_plus package defaults.
  @override
  final double? blockSpacing;

  @override
  final StyleSpec<MarkdownAlertSpec> alert;
  @override
  final BoxDecoration? horizontalRuleDecoration;
  @override
  final StyleSpec<MarkdownBlockquoteSpec>? blockquote;
  @override
  final StyleSpec<MarkdownListSpec>? list;
  @override
  final StyleSpec<MarkdownTableSpec>? table;
  @override
  final StyleSpec<MarkdownCodeblockSpec>? code;
  @override
  final StyleSpec<MarkdownCheckboxSpec>? checkbox;

  @MixableField(setterType: BlockStyler)
  @override
  final StyleSpec<BoxSpec> blockContainer;
  @override
  final StyleSpec<BoxSpec> slideContainer;
  @override
  final StyleSpec<ImageSpec> image;

  /// Static helper for context access
  static SlideSpec of(BuildContext context) {
    final styleSpec = StyleSpecProvider.of<SlideSpec>(context);
    return styleSpec!.spec;
  }

  const SlideSpec({
    this.h1,
    this.h2,
    this.h3,
    this.h4,
    this.h5,
    this.h6,
    this.p,
    this.a,
    this.em,
    this.strong,
    this.del,
    this.img,
    this.link,
    this.textScaleFactor,
    this.blockSpacing,
    StyleSpec<MarkdownAlertSpec>? alert,
    this.horizontalRuleDecoration,
    this.blockquote,
    this.list,
    this.table,
    this.code,
    this.checkbox,
    StyleSpec<BoxSpec>? blockContainer,
    StyleSpec<BoxSpec>? slideContainer,
    StyleSpec<ImageSpec>? image,
  }) : alert = alert ?? const StyleSpec(spec: MarkdownAlertSpec()),
       blockContainer = blockContainer ?? const StyleSpec(spec: BoxSpec()),
       slideContainer = slideContainer ?? const StyleSpec(spec: BoxSpec()),
       image = image ?? const StyleSpec(spec: ImageSpec());

  /// Converts this SlideSpec to a MarkdownStyleSheet for flutter_markdown.
  ///
  /// Block tags (`p`, `h1`–`h6`, `li`) are rendered by custom builders that
  /// read inline styles from this [SlideSpec] directly. [toStyle] still maps
  /// strong/em/del/link/code/textScaler for any non-builder path.
  MarkdownStyleSheet toStyle() {
    return MarkdownStyleSheet(
      h1: h1?.spec.style,
      h2: h2?.spec.style,
      h3: h3?.spec.style,
      h4: h4?.spec.style,
      h5: h5?.spec.style,
      h6: h6?.spec.style,
      p: p?.spec.style,
      a: link ?? a,
      em: em,
      strong: strong,
      del: del,
      code: code?.spec.textStyle,
      codeblockDecoration: const BoxDecoration(color: Color(0x00000000)),
      textScaler: textScaleFactor,
      blockSpacing: blockSpacing ?? 0,
      listBullet: list?.spec.bullet?.spec.style,
      orderedListAlign: list?.spec.orderedAlignment ?? WrapAlignment.start,
      unorderedListAlign: list?.spec.unorderedAlignment ?? WrapAlignment.start,
      blockquote: blockquote?.spec.textStyle,
      blockquotePadding: blockquote?.spec.padding,
      blockquoteDecoration: blockquote?.spec.decoration,
      blockquoteAlign: blockquote?.spec.alignment ?? WrapAlignment.start,
      horizontalRuleDecoration: horizontalRuleDecoration,
      tableHead: table?.spec.headStyle,
      tableBody: table?.spec.bodyStyle,
      tableHeadAlign: table?.spec.headAlignment,
      tablePadding: table?.spec.padding,
      tableBorder: table?.spec.border,
      tableColumnWidth: table?.spec.columnWidth,
      tableCellsPadding: table?.spec.cellPadding,
      tableCellsDecoration: table?.spec.cellDecoration,
      tableVerticalAlignment:
          table?.spec.verticalAlignment ?? TableCellVerticalAlignment.middle,
      checkbox: checkbox?.spec.textStyle,
    );
  }
}
