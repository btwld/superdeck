import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import 'markdown_alert_spec.dart';
import 'markdown_blockquote_spec.dart';
import 'markdown_checkbox_spec.dart';
import 'markdown_codeblock_spec.dart';
import 'markdown_list_spec.dart';
import 'markdown_table_spec.dart';
import 'slide_spec.dart';
import 'markdown_alert_style.dart';
import 'markdown_blockquote_style.dart';
import 'markdown_checkbox_style.dart';
import 'markdown_codeblock_style.dart';
import 'markdown_list_style.dart';
import 'markdown_table_style.dart';

/// Root style class for configuring [SlideSpec] properties.
///
/// This is the main style that controls all markdown element styling
/// including headings, text, alerts, lists, tables, code blocks, and more.
final class SlideStyle extends Style<SlideSpec>
    with
        Diagnosticable,
        WidgetModifierStyleMixin<SlideStyle, SlideSpec>,
        VariantStyleMixin<SlideStyle, SlideSpec>,
        AnimationStyleMixin<SlideStyle, SlideSpec> {
  // Heading Props
  final Prop<StyleSpec<TextSpec>>? $h1;
  final Prop<StyleSpec<TextSpec>>? $h2;
  final Prop<StyleSpec<TextSpec>>? $h3;
  final Prop<StyleSpec<TextSpec>>? $h4;
  final Prop<StyleSpec<TextSpec>>? $h5;
  final Prop<StyleSpec<TextSpec>>? $h6;
  final Prop<StyleSpec<TextSpec>>? $p;

  // Inline text style Props
  final Prop<TextStyle>? $a;
  final Prop<TextStyle>? $em;
  final Prop<TextStyle>? $strong;
  final Prop<TextStyle>? $del;
  final Prop<TextStyle>? $img;
  final Prop<TextStyle>? $link;

  // Scale factor
  final Prop<TextScaler>? $textScaleFactor;

  // Complex markdown element Props
  final Prop<StyleSpec<MarkdownAlertSpec>>? $alert;
  final Prop<BoxDecoration>? $horizontalRuleDecoration;
  final Prop<StyleSpec<MarkdownBlockquoteSpec>>? $blockquote;
  final Prop<StyleSpec<MarkdownListSpec>>? $list;
  final Prop<StyleSpec<MarkdownTableSpec>>? $table;
  final Prop<StyleSpec<MarkdownCodeblockSpec>>? $code;
  final Prop<StyleSpec<MarkdownCheckboxSpec>>? $checkbox;

  // Layout Props
  final Prop<StyleSpec<BoxSpec>>? $blockContainer;
  final Prop<StyleSpec<ImageSpec>>? $image;

  const SlideStyle.create({
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
       $image = image;

  SlideStyle({
    TextStyler? h1,
    TextStyler? h2,
    TextStyler? h3,
    TextStyler? h4,
    TextStyler? h5,
    TextStyler? h6,
    TextStyler? p,
    TextStyle? a,
    TextStyle? em,
    TextStyle? strong,
    TextStyle? del,
    TextStyle? img,
    TextStyle? link,
    TextScaler? textScaleFactor,
    MarkdownAlertStyle? alert,
    BoxDecoration? horizontalRuleDecoration,
    MarkdownBlockquoteStyle? blockquote,
    MarkdownListStyle? list,
    MarkdownTableStyle? table,
    MarkdownCodeblockStyle? code,
    MarkdownCheckboxStyle? checkbox,
    BoxStyler? blockContainer,
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
         a: Prop.maybe(a),
         em: Prop.maybe(em),
         strong: Prop.maybe(strong),
         del: Prop.maybe(del),
         img: Prop.maybe(img),
         link: Prop.maybe(link),
         textScaleFactor: Prop.maybe(textScaleFactor),
         alert: Prop.maybeMix(alert),
         horizontalRuleDecoration: Prop.maybe(horizontalRuleDecoration),
         blockquote: Prop.maybeMix(blockquote),
         list: Prop.maybeMix(list),
         table: Prop.maybeMix(table),
         code: Prop.maybeMix(code),
         checkbox: Prop.maybeMix(checkbox),
         blockContainer: Prop.maybeMix(blockContainer),
         image: Prop.maybeMix(image),
         animation: animation,
         variants: variants,
         modifier: modifier,
       );

  @override
  SlideStyle variants(List<VariantStyle<SlideSpec>> value) {
    return merge(SlideStyle(variants: value));
  }

  @override
  SlideStyle animate(AnimationConfig value) {
    return merge(SlideStyle(animation: value));
  }

  @override
  SlideStyle wrap(WidgetModifierConfig value) {
    return merge(SlideStyle(modifier: value));
  }

  @override
  StyleSpec<SlideSpec> resolve(BuildContext context) {
    return StyleSpec(
      spec: SlideSpec(
        h1: MixOps.resolve(context, $h1),
        h2: MixOps.resolve(context, $h2),
        h3: MixOps.resolve(context, $h3),
        h4: MixOps.resolve(context, $h4),
        h5: MixOps.resolve(context, $h5),
        h6: MixOps.resolve(context, $h6),
        p: MixOps.resolve(context, $p),
        a: MixOps.resolve(context, $a),
        em: MixOps.resolve(context, $em),
        strong: MixOps.resolve(context, $strong),
        del: MixOps.resolve(context, $del),
        img: MixOps.resolve(context, $img),
        link: MixOps.resolve(context, $link),
        textScaleFactor: MixOps.resolve(context, $textScaleFactor),
        alert: MixOps.resolve(context, $alert),
        horizontalRuleDecoration: MixOps.resolve(
          context,
          $horizontalRuleDecoration,
        ),
        blockquote: MixOps.resolve(context, $blockquote),
        list: MixOps.resolve(context, $list),
        table: MixOps.resolve(context, $table),
        code: MixOps.resolve(context, $code),
        checkbox: MixOps.resolve(context, $checkbox),
        blockContainer: MixOps.resolve(context, $blockContainer),
        image: MixOps.resolve(context, $image),
      ),
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  SlideStyle merge(SlideStyle? other) {
    if (other == null) return this;

    return SlideStyle.create(
      h1: MixOps.merge($h1, other.$h1),
      h2: MixOps.merge($h2, other.$h2),
      h3: MixOps.merge($h3, other.$h3),
      h4: MixOps.merge($h4, other.$h4),
      h5: MixOps.merge($h5, other.$h5),
      h6: MixOps.merge($h6, other.$h6),
      p: MixOps.merge($p, other.$p),
      a: MixOps.merge($a, other.$a),
      em: MixOps.merge($em, other.$em),
      strong: MixOps.merge($strong, other.$strong),
      del: MixOps.merge($del, other.$del),
      img: MixOps.merge($img, other.$img),
      link: MixOps.merge($link, other.$link),
      textScaleFactor: MixOps.merge($textScaleFactor, other.$textScaleFactor),
      alert: MixOps.merge($alert, other.$alert),
      horizontalRuleDecoration: MixOps.merge(
        $horizontalRuleDecoration,
        other.$horizontalRuleDecoration,
      ),
      blockquote: MixOps.merge($blockquote, other.$blockquote),
      list: MixOps.merge($list, other.$list),
      table: MixOps.merge($table, other.$table),
      code: MixOps.merge($code, other.$code),
      checkbox: MixOps.merge($checkbox, other.$checkbox),
      blockContainer: MixOps.merge($blockContainer, other.$blockContainer),
      image: MixOps.merge($image, other.$image),
      animation: MixOps.mergeAnimation($animation, other.$animation),
      variants: MixOps.mergeVariants($variants, other.$variants),
      modifier: MixOps.mergeModifier($modifier, other.$modifier),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('h1', $h1))
      ..add(DiagnosticsProperty('h2', $h2))
      ..add(DiagnosticsProperty('h3', $h3))
      ..add(DiagnosticsProperty('h4', $h4))
      ..add(DiagnosticsProperty('h5', $h5))
      ..add(DiagnosticsProperty('h6', $h6))
      ..add(DiagnosticsProperty('p', $p))
      ..add(DiagnosticsProperty('a', $a))
      ..add(DiagnosticsProperty('em', $em))
      ..add(DiagnosticsProperty('strong', $strong))
      ..add(DiagnosticsProperty('del', $del))
      ..add(DiagnosticsProperty('img', $img))
      ..add(DiagnosticsProperty('link', $link))
      ..add(DiagnosticsProperty('textScaleFactor', $textScaleFactor))
      ..add(DiagnosticsProperty('alert', $alert))
      ..add(
        DiagnosticsProperty(
          'horizontalRuleDecoration',
          $horizontalRuleDecoration,
        ),
      )
      ..add(DiagnosticsProperty('blockquote', $blockquote))
      ..add(DiagnosticsProperty('list', $list))
      ..add(DiagnosticsProperty('table', $table))
      ..add(DiagnosticsProperty('code', $code))
      ..add(DiagnosticsProperty('checkbox', $checkbox))
      ..add(DiagnosticsProperty('blockContainer', $blockContainer))
      ..add(DiagnosticsProperty('image', $image));
  }

  @override
  List<Object?> get props => [
    $h1,
    $h2,
    $h3,
    $h4,
    $h5,
    $h6,
    $p,
    $a,
    $em,
    $strong,
    $del,
    $img,
    $link,
    $textScaleFactor,
    $alert,
    $horizontalRuleDecoration,
    $blockquote,
    $list,
    $table,
    $code,
    $checkbox,
    $blockContainer,
    $image,
    $animation,
    $variants,
    $modifier,
  ];
}
