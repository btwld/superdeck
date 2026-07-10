// The styler below stays hand-written on the legacy @MixableStyler mixin
// path: several fields nest same-package generated stylers
// (MarkdownAlertStyler, MarkdownCodeblockStyler, ...), which @MixableSpec's
// spec_styler_generator can only wire up through @MixableField(setterType:) —
// and annotation type arguments cannot reference same-package generated
// classes (build phases hide them from the resolver, degrading silently to
// value semantics).
// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

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
  @MixableField(setterType: TextStyler)
  final StyleSpec<TextSpec>? h1;
  @override
  @MixableField(setterType: TextStyler)
  final StyleSpec<TextSpec>? h2;
  @override
  @MixableField(setterType: TextStyler)
  final StyleSpec<TextSpec>? h3;
  @override
  @MixableField(setterType: TextStyler)
  final StyleSpec<TextSpec>? h4;
  @override
  @MixableField(setterType: TextStyler)
  final StyleSpec<TextSpec>? h5;
  @override
  @MixableField(setterType: TextStyler)
  final StyleSpec<TextSpec>? h6;
  @override
  @MixableField(setterType: TextStyler)
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

  @override
  @MixableField(setterType: BoxStyler)
  final StyleSpec<BoxSpec> blockContainer;
  @override
  @MixableField(setterType: BoxStyler)
  final StyleSpec<BoxSpec> slideContainer;
  @override
  @MixableField(setterType: ImageStyler)
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
      textScaler: textScaleFactor,
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

/// Root style class for configuring [SlideSpec] properties.
///
/// This is the main style that controls all markdown element styling
/// including headings, text, alerts, lists, tables, code blocks, and more.
@MixableStyler()
final class SlideStyler extends MixStyler<SlideStyler, SlideSpec>
    with _$SlideStylerMixin {
  @override
  @MixableField(setterType: TextStyler)
  final Prop<StyleSpec<TextSpec>>? $h1;
  @override
  @MixableField(setterType: TextStyler)
  final Prop<StyleSpec<TextSpec>>? $h2;
  @override
  @MixableField(setterType: TextStyler)
  final Prop<StyleSpec<TextSpec>>? $h3;
  @override
  @MixableField(setterType: TextStyler)
  final Prop<StyleSpec<TextSpec>>? $h4;
  @override
  @MixableField(setterType: TextStyler)
  final Prop<StyleSpec<TextSpec>>? $h5;
  @override
  @MixableField(setterType: TextStyler)
  final Prop<StyleSpec<TextSpec>>? $h6;
  @override
  @MixableField(setterType: TextStyler)
  final Prop<StyleSpec<TextSpec>>? $p;

  @override
  final Prop<TextStyle>? $a;
  @override
  final Prop<TextStyle>? $em;
  @override
  final Prop<TextStyle>? $strong;
  @override
  final Prop<TextStyle>? $del;
  @override
  final Prop<TextStyle>? $img;
  @override
  final Prop<TextStyle>? $link;

  @override
  final Prop<TextScaler>? $textScaleFactor;

  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownAlertSpec>>? $alert;
  @override
  final Prop<BoxDecoration>? $horizontalRuleDecoration;
  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownBlockquoteSpec>>? $blockquote;
  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownListSpec>>? $list;
  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownTableSpec>>? $table;
  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownCodeblockSpec>>? $code;
  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownCheckboxSpec>>? $checkbox;

  @override
  @MixableField(setterType: BoxStyler)
  final Prop<StyleSpec<BoxSpec>>? $blockContainer;
  @override
  @MixableField(setterType: BoxStyler)
  final Prop<StyleSpec<BoxSpec>>? $slideContainer;
  @override
  @MixableField(setterType: ImageStyler)
  final Prop<StyleSpec<ImageSpec>>? $image;

  const SlideStyler.create({
    Prop<StyleSpec<TextSpec>>? h1,
    Prop<StyleSpec<TextSpec>>? h2,
    Prop<StyleSpec<TextSpec>>? h3,
    Prop<StyleSpec<TextSpec>>? h4,
    Prop<StyleSpec<TextSpec>>? h5,
    Prop<StyleSpec<TextSpec>>? h6,
    Prop<StyleSpec<TextSpec>>? p,
    Prop<TextStyle>? a,
    Prop<TextStyle>? em,
    Prop<TextStyle>? strong,
    Prop<TextStyle>? del,
    Prop<TextStyle>? img,
    Prop<TextStyle>? link,
    Prop<TextScaler>? textScaleFactor,
    Prop<StyleSpec<MarkdownAlertSpec>>? alert,
    Prop<BoxDecoration>? horizontalRuleDecoration,
    Prop<StyleSpec<MarkdownBlockquoteSpec>>? blockquote,
    Prop<StyleSpec<MarkdownListSpec>>? list,
    Prop<StyleSpec<MarkdownTableSpec>>? table,
    Prop<StyleSpec<MarkdownCodeblockSpec>>? code,
    Prop<StyleSpec<MarkdownCheckboxSpec>>? checkbox,
    Prop<StyleSpec<BoxSpec>>? blockContainer,
    Prop<StyleSpec<BoxSpec>>? slideContainer,
    Prop<StyleSpec<ImageSpec>>? image,
    required super.variants,
    required super.animation,
    required super.modifier,
  }) : $h1 = h1,
       $h2 = h2,
       $h3 = h3,
       $h4 = h4,
       $h5 = h5,
       $h6 = h6,
       $p = p,
       $a = a,
       $em = em,
       $strong = strong,
       $del = del,
       $img = img,
       $link = link,
       $textScaleFactor = textScaleFactor,
       $alert = alert,
       $horizontalRuleDecoration = horizontalRuleDecoration,
       $blockquote = blockquote,
       $list = list,
       $table = table,
       $code = code,
       $checkbox = checkbox,
       $blockContainer = blockContainer,
       $slideContainer = slideContainer,
       $image = image;

  SlideStyler({
    TextStyler? h1,
    TextStyler? h2,
    TextStyler? h3,
    TextStyler? h4,
    TextStyler? h5,
    TextStyler? h6,
    TextStyler? p,
    TextStyleMix? a,
    TextStyleMix? em,
    TextStyleMix? strong,
    TextStyleMix? del,
    TextStyleMix? img,
    TextStyleMix? link,
    TextScaler? textScaleFactor,
    MarkdownAlertStyler? alert,
    BoxDecoration? horizontalRuleDecoration,
    MarkdownBlockquoteStyler? blockquote,
    MarkdownListStyler? list,
    MarkdownTableStyler? table,
    MarkdownCodeblockStyler? code,
    MarkdownCheckboxStyler? checkbox,
    BoxStyler? blockContainer,
    BoxStyler? slideContainer,
    ImageStyler? image,
    AnimationConfig? animation,
    List<VariantStyle<SlideSpec>>? variants,
    WidgetModifierConfig? modifier,
  }) : this.create(
         h1: Prop.maybeMix(h1),
         h2: Prop.maybeMix(h2),
         h3: Prop.maybeMix(h3),
         h4: Prop.maybeMix(h4),
         h5: Prop.maybeMix(h5),
         h6: Prop.maybeMix(h6),
         p: Prop.maybeMix(p),
         a: Prop.maybeMix(a),
         em: Prop.maybeMix(em),
         strong: Prop.maybeMix(strong),
         del: Prop.maybeMix(del),
         img: Prop.maybeMix(img),
         link: Prop.maybeMix(link),
         textScaleFactor: Prop.maybe(textScaleFactor),
         alert: Prop.maybeMix(alert),
         horizontalRuleDecoration: Prop.maybe(horizontalRuleDecoration),
         blockquote: Prop.maybeMix(blockquote),
         list: Prop.maybeMix(list),
         table: Prop.maybeMix(table),
         code: Prop.maybeMix(code),
         checkbox: Prop.maybeMix(checkbox),
         blockContainer: Prop.maybeMix(blockContainer),
         slideContainer: Prop.maybeMix(slideContainer),
         image: Prop.maybeMix(image),
         animation: animation,
         variants: variants,
         modifier: modifier,
       );

  /// Sets the alert styles.
  SlideStyler alert(MarkdownAlertStyler value) {
    return merge(SlideStyler(alert: value));
  }

  /// Sets the blockquote style.
  SlideStyler blockquote(MarkdownBlockquoteStyler value) {
    return merge(SlideStyler(blockquote: value));
  }

  /// Sets the list style.
  SlideStyler list(MarkdownListStyler value) {
    return merge(SlideStyler(list: value));
  }

  /// Sets the table style.
  SlideStyler table(MarkdownTableStyler value) {
    return merge(SlideStyler(table: value));
  }

  /// Sets the code block style.
  SlideStyler code(MarkdownCodeblockStyler value) {
    return merge(SlideStyler(code: value));
  }

  /// Sets the checkbox style.
  SlideStyler checkbox(MarkdownCheckboxStyler value) {
    return merge(SlideStyler(checkbox: value));
  }
}

/// Legacy alias for [SlideStyler] (the pre-codegen class name).
typedef SlideStyle = SlideStyler;
