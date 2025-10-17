import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:mix/mix.dart';

import 'markdown_alert_spec.dart';
import 'markdown_blockquote_spec.dart';
import 'markdown_checkbox_spec.dart';
import 'markdown_codeblock_spec.dart';
import 'markdown_list_spec.dart';
import 'markdown_table_spec.dart';

/// Root specification for slide styling containing all markdown element styles.
///
/// This is the main spec that aggregates all markdown styling including headings,
/// text, alerts, lists, tables, code blocks, and more.
final class SlideSpec extends Spec<SlideSpec> with Diagnosticable {
  // Heading styles
  final StyleSpec<TextSpec>? h1;
  final StyleSpec<TextSpec>? h2;
  final StyleSpec<TextSpec>? h3;
  final StyleSpec<TextSpec>? h4;
  final StyleSpec<TextSpec>? h5;
  final StyleSpec<TextSpec>? h6;
  final StyleSpec<TextSpec>? p;

  // Inline text styles
  final TextStyle? a;
  final TextStyle? em;
  final TextStyle? strong;
  final TextStyle? del;
  final TextStyle? img;
  final TextStyle? link;

  // Scale factor
  final TextScaler? textScaleFactor;

  // Complex markdown elements
  final StyleSpec<MarkdownAlertSpec> alert;
  final BoxDecoration? horizontalRuleDecoration;
  final StyleSpec<MarkdownBlockquoteSpec>? blockquote;
  final StyleSpec<MarkdownListSpec>? list;
  final StyleSpec<MarkdownTableSpec>? table;
  final StyleSpec<MarkdownCodeblockSpec>? code;
  final StyleSpec<MarkdownCheckboxSpec>? checkbox;

  // Layout
  final StyleSpec<BoxSpec> blockContainer;
  final StyleSpec<ImageSpec> image;

  /// Static helper for context access
  /// TODO: Implement proper Mix 2.0 context resolution
  static SlideSpec of(BuildContext context) {
    // Will be implemented with proper StyleSpec resolution
    return const SlideSpec();
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
    StyleSpec<ImageSpec>? image,
  }) : alert = alert ?? const StyleSpec(spec: MarkdownAlertSpec()),
       blockContainer = blockContainer ?? const StyleSpec(spec: BoxSpec()),
       image = image ?? const StyleSpec(spec: ImageSpec());

  @override
  SlideSpec copyWith({
    StyleSpec<TextSpec>? h1,
    StyleSpec<TextSpec>? h2,
    StyleSpec<TextSpec>? h3,
    StyleSpec<TextSpec>? h4,
    StyleSpec<TextSpec>? h5,
    StyleSpec<TextSpec>? h6,
    StyleSpec<TextSpec>? p,
    TextStyle? a,
    TextStyle? em,
    TextStyle? strong,
    TextStyle? del,
    TextStyle? img,
    TextStyle? link,
    TextScaler? textScaleFactor,
    StyleSpec<MarkdownAlertSpec>? alert,
    BoxDecoration? horizontalRuleDecoration,
    StyleSpec<MarkdownBlockquoteSpec>? blockquote,
    StyleSpec<MarkdownListSpec>? list,
    StyleSpec<MarkdownTableSpec>? table,
    StyleSpec<MarkdownCodeblockSpec>? code,
    StyleSpec<MarkdownCheckboxSpec>? checkbox,
    StyleSpec<BoxSpec>? blockContainer,
    StyleSpec<ImageSpec>? image,
  }) {
    return SlideSpec(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      h5: h5 ?? this.h5,
      h6: h6 ?? this.h6,
      p: p ?? this.p,
      a: a ?? this.a,
      em: em ?? this.em,
      strong: strong ?? this.strong,
      del: del ?? this.del,
      img: img ?? this.img,
      link: link ?? this.link,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      alert: alert ?? this.alert,
      horizontalRuleDecoration:
          horizontalRuleDecoration ?? this.horizontalRuleDecoration,
      blockquote: blockquote ?? this.blockquote,
      list: list ?? this.list,
      table: table ?? this.table,
      code: code ?? this.code,
      checkbox: checkbox ?? this.checkbox,
      blockContainer: blockContainer ?? this.blockContainer,
      image: image ?? this.image,
    );
  }

  @override
  SlideSpec lerp(SlideSpec? other, double t) {
    if (other == null) return this;

    return SlideSpec(
      h1: MixOps.lerp(h1, other.h1, t),
      h2: MixOps.lerp(h2, other.h2, t),
      h3: MixOps.lerp(h3, other.h3, t),
      h4: MixOps.lerp(h4, other.h4, t),
      h5: MixOps.lerp(h5, other.h5, t),
      h6: MixOps.lerp(h6, other.h6, t),
      p: MixOps.lerp(p, other.p, t),
      a: TextStyle.lerp(a, other.a, t),
      em: TextStyle.lerp(em, other.em, t),
      strong: TextStyle.lerp(strong, other.strong, t),
      del: TextStyle.lerp(del, other.del, t),
      img: TextStyle.lerp(img, other.img, t),
      link: TextStyle.lerp(link, other.link, t),
      textScaleFactor: t < 0.5 ? textScaleFactor : other.textScaleFactor,
      alert: MixOps.lerp(alert, other.alert, t)!,
      horizontalRuleDecoration: BoxDecoration.lerp(
        horizontalRuleDecoration,
        other.horizontalRuleDecoration,
        t,
      ),
      blockquote: MixOps.lerp(blockquote, other.blockquote, t),
      list: MixOps.lerp(list, other.list, t),
      table: MixOps.lerp(table, other.table, t),
      code: MixOps.lerp(code, other.code, t),
      checkbox: MixOps.lerp(checkbox, other.checkbox, t),
      blockContainer: MixOps.lerp(blockContainer, other.blockContainer, t)!,
      image: MixOps.lerp(image, other.image, t)!,
    );
  }

  /// Converts this SlideSpec to a MarkdownStyleSheet for flutter_markdown.
  ///
  /// This method maintains compatibility with flutter_markdown by extracting
  /// the relevant properties and converting them to the expected format.
  MarkdownStyleSheet toStyle() {
    return MarkdownStyleSheet(
      // Headings
      h1: h1?.spec.style,
      h2: h2?.spec.style,
      h3: h3?.spec.style,
      h4: h4?.spec.style,
      h5: h5?.spec.style,
      h6: h6?.spec.style,

      // Paragraph
      p: p?.spec.style,

      // Links
      a: link,

      // Lists
      listBullet: list?.spec.bullet?.spec.style,
      orderedListAlign: list?.spec.orderedAlignment ?? WrapAlignment.start,
      unorderedListAlign: list?.spec.unorderedAlignment ?? WrapAlignment.start,

      // Blockquotes
      blockquote: blockquote?.spec.textStyle,
      blockquotePadding: blockquote?.spec.padding,
      blockquoteDecoration: blockquote?.spec.decoration,
      blockquoteAlign: blockquote?.spec.alignment ?? WrapAlignment.start,

      // Horizontal rules
      horizontalRuleDecoration: horizontalRuleDecoration,

      // Tables
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

      // Checkboxes
      checkbox: checkbox?.spec.textStyle,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('h1', h1))
      ..add(DiagnosticsProperty('h2', h2))
      ..add(DiagnosticsProperty('h3', h3))
      ..add(DiagnosticsProperty('h4', h4))
      ..add(DiagnosticsProperty('h5', h5))
      ..add(DiagnosticsProperty('h6', h6))
      ..add(DiagnosticsProperty('p', p))
      ..add(DiagnosticsProperty('a', a))
      ..add(DiagnosticsProperty('link', link))
      ..add(DiagnosticsProperty('alert', alert))
      ..add(DiagnosticsProperty('blockquote', blockquote))
      ..add(DiagnosticsProperty('list', list))
      ..add(DiagnosticsProperty('table', table))
      ..add(DiagnosticsProperty('code', code))
      ..add(DiagnosticsProperty('checkbox', checkbox))
      ..add(DiagnosticsProperty('blockContainer', blockContainer))
      ..add(DiagnosticsProperty('image', image));
  }

  @override
  List<Object?> get props => [
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    p,
    a,
    em,
    strong,
    del,
    img,
    link,
    textScaleFactor,
    alert,
    horizontalRuleDecoration,
    blockquote,
    list,
    table,
    code,
    checkbox,
    blockContainer,
    image,
  ];
}
