// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'markdown_table.dart';

// **************************************************************************
// SpecGenerator
// **************************************************************************

mixin _$MarkdownTableSpec implements Spec<MarkdownTableSpec>, Diagnosticable {
  TextStyle? get headStyle;
  TextStyle? get bodyStyle;
  TextAlign? get headAlignment;
  EdgeInsets? get padding;
  TableBorder? get border;
  TableColumnWidth? get columnWidth;
  EdgeInsets? get cellPadding;
  BoxDecoration? get cellDecoration;
  TableCellVerticalAlignment? get verticalAlignment;

  @override
  Type get type => MarkdownTableSpec;

  @override
  MarkdownTableSpec copyWith({
    TextStyle? headStyle,
    TextStyle? bodyStyle,
    TextAlign? headAlignment,
    EdgeInsets? padding,
    TableBorder? border,
    TableColumnWidth? columnWidth,
    EdgeInsets? cellPadding,
    BoxDecoration? cellDecoration,
    TableCellVerticalAlignment? verticalAlignment,
  }) {
    return MarkdownTableSpec(
      headStyle: headStyle ?? this.headStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      headAlignment: headAlignment ?? this.headAlignment,
      padding: padding ?? this.padding,
      border: border ?? this.border,
      columnWidth: columnWidth ?? this.columnWidth,
      cellPadding: cellPadding ?? this.cellPadding,
      cellDecoration: cellDecoration ?? this.cellDecoration,
      verticalAlignment: verticalAlignment ?? this.verticalAlignment,
    );
  }

  @override
  MarkdownTableSpec lerp(MarkdownTableSpec? other, double t) {
    return MarkdownTableSpec(
      headStyle: MixOps.lerp(headStyle, other?.headStyle, t),
      bodyStyle: MixOps.lerp(bodyStyle, other?.bodyStyle, t),
      headAlignment: MixOps.lerpSnap(headAlignment, other?.headAlignment, t),
      padding: MixOps.lerp(padding, other?.padding, t),
      border: MixOps.lerpSnap(border, other?.border, t),
      columnWidth: MixOps.lerpSnap(columnWidth, other?.columnWidth, t),
      cellPadding: MixOps.lerp(cellPadding, other?.cellPadding, t),
      cellDecoration: MixOps.lerp(cellDecoration, other?.cellDecoration, t),
      verticalAlignment: MixOps.lerpSnap(
        verticalAlignment,
        other?.verticalAlignment,
        t,
      ),
    );
  }

  @override
  List<Object?> get props => [
    headStyle,
    bodyStyle,
    headAlignment,
    padding,
    border,
    columnWidth,
    cellPadding,
    cellDecoration,
    verticalAlignment,
  ];

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MarkdownTableSpec &&
            runtimeType == other.runtimeType &&
            propsEquals(props, other.props);
  }

  @override
  int get hashCode => propsHash(runtimeType, props);

  @override
  bool get stringify => true;

  @override
  Map<String, String> getDiff(Equatable other) {
    if (this == other) return const {};

    return propsDiff(props, other.props);
  }

  @override
  String toStringShort() => '$runtimeType';

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      toDiagnosticsNode(
        style: DiagnosticsTreeStyle.singleLine,
      ).toString(minLevel: minLevel);

  @override
  DiagnosticsNode toDiagnosticsNode({
    String? name,
    DiagnosticsTreeStyle? style,
  }) =>
      DiagnosticableNode<Diagnosticable>(name: name, value: this, style: style);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('headStyle', headStyle))
      ..add(DiagnosticsProperty('bodyStyle', bodyStyle))
      ..add(EnumProperty<TextAlign>('headAlignment', headAlignment))
      ..add(DiagnosticsProperty('padding', padding))
      ..add(DiagnosticsProperty('border', border))
      ..add(DiagnosticsProperty('columnWidth', columnWidth))
      ..add(DiagnosticsProperty('cellPadding', cellPadding))
      ..add(DiagnosticsProperty('cellDecoration', cellDecoration))
      ..add(DiagnosticsProperty('verticalAlignment', verticalAlignment));
  }
}

@Deprecated(
  'Rename to `_\$MarkdownTableSpec` and migrate the class declaration to `class MarkdownTableSpec with _\$MarkdownTableSpec`. The `_\$MarkdownTableSpecMethods` alias will be removed in mix_generator 3.0.',
)
typedef _$MarkdownTableSpecMethods = _$MarkdownTableSpec; // ignore: unused_element

// **************************************************************************
// SpecStylerGenerator
// **************************************************************************

class MarkdownTableStyler
    extends MixStyler<MarkdownTableStyler, MarkdownTableSpec> {
  final Prop<TextStyle>? $headStyle;
  final Prop<TextStyle>? $bodyStyle;
  final Prop<TextAlign>? $headAlignment;
  final Prop<EdgeInsets>? $padding;
  final Prop<TableBorder>? $border;
  final Prop<TableColumnWidth>? $columnWidth;
  final Prop<EdgeInsets>? $cellPadding;
  final Prop<BoxDecoration>? $cellDecoration;
  final Prop<TableCellVerticalAlignment>? $verticalAlignment;

  const MarkdownTableStyler.create({
    Prop<TextStyle>? headStyle,
    Prop<TextStyle>? bodyStyle,
    Prop<TextAlign>? headAlignment,
    Prop<EdgeInsets>? padding,
    Prop<TableBorder>? border,
    Prop<TableColumnWidth>? columnWidth,
    Prop<EdgeInsets>? cellPadding,
    Prop<BoxDecoration>? cellDecoration,
    Prop<TableCellVerticalAlignment>? verticalAlignment,
    super.variants,
    super.modifier,
    super.animation,
  }) : $headStyle = headStyle,
       $bodyStyle = bodyStyle,
       $headAlignment = headAlignment,
       $padding = padding,
       $border = border,
       $columnWidth = columnWidth,
       $cellPadding = cellPadding,
       $cellDecoration = cellDecoration,
       $verticalAlignment = verticalAlignment;

  MarkdownTableStyler({
    TextStyleMix? headStyle,
    TextStyleMix? bodyStyle,
    TextAlign? headAlignment,
    EdgeInsets? padding,
    TableBorder? border,
    TableColumnWidth? columnWidth,
    EdgeInsets? cellPadding,
    BoxDecoration? cellDecoration,
    TableCellVerticalAlignment? verticalAlignment,
    AnimationConfig? animation,
    WidgetModifierConfig? modifier,
    List<VariantStyle<MarkdownTableSpec>>? variants,
  }) : this.create(
         headStyle: Prop.maybeMix(headStyle),
         bodyStyle: Prop.maybeMix(bodyStyle),
         headAlignment: Prop.maybe(headAlignment),
         padding: Prop.maybe(padding),
         border: Prop.maybe(border),
         columnWidth: Prop.maybe(columnWidth),
         cellPadding: Prop.maybe(cellPadding),
         cellDecoration: Prop.maybe(cellDecoration),
         verticalAlignment: Prop.maybe(verticalAlignment),
         variants: variants,
         modifier: modifier,
         animation: animation,
       );

  factory MarkdownTableStyler.headStyle(TextStyleMix value) =>
      MarkdownTableStyler().headStyle(value);
  factory MarkdownTableStyler.bodyStyle(TextStyleMix value) =>
      MarkdownTableStyler().bodyStyle(value);
  factory MarkdownTableStyler.headAlignment(TextAlign value) =>
      MarkdownTableStyler().headAlignment(value);
  factory MarkdownTableStyler.padding(EdgeInsets value) =>
      MarkdownTableStyler().padding(value);
  factory MarkdownTableStyler.border(TableBorder value) =>
      MarkdownTableStyler().border(value);
  factory MarkdownTableStyler.columnWidth(TableColumnWidth value) =>
      MarkdownTableStyler().columnWidth(value);
  factory MarkdownTableStyler.cellPadding(EdgeInsets value) =>
      MarkdownTableStyler().cellPadding(value);
  factory MarkdownTableStyler.cellDecoration(BoxDecoration value) =>
      MarkdownTableStyler().cellDecoration(value);
  factory MarkdownTableStyler.verticalAlignment(
    TableCellVerticalAlignment value,
  ) => MarkdownTableStyler().verticalAlignment(value);

  /// Sets the headStyle.
  MarkdownTableStyler headStyle(TextStyleMix value) {
    return merge(MarkdownTableStyler(headStyle: value));
  }

  /// Sets the bodyStyle.
  MarkdownTableStyler bodyStyle(TextStyleMix value) {
    return merge(MarkdownTableStyler(bodyStyle: value));
  }

  /// Sets the headAlignment.
  MarkdownTableStyler headAlignment(TextAlign value) {
    return merge(MarkdownTableStyler(headAlignment: value));
  }

  /// Sets the padding.
  MarkdownTableStyler padding(EdgeInsets value) {
    return merge(MarkdownTableStyler(padding: value));
  }

  /// Sets the border.
  MarkdownTableStyler border(TableBorder value) {
    return merge(MarkdownTableStyler(border: value));
  }

  /// Sets the columnWidth.
  MarkdownTableStyler columnWidth(TableColumnWidth value) {
    return merge(MarkdownTableStyler(columnWidth: value));
  }

  /// Sets the cellPadding.
  MarkdownTableStyler cellPadding(EdgeInsets value) {
    return merge(MarkdownTableStyler(cellPadding: value));
  }

  /// Sets the cellDecoration.
  MarkdownTableStyler cellDecoration(BoxDecoration value) {
    return merge(MarkdownTableStyler(cellDecoration: value));
  }

  /// Sets the verticalAlignment.
  MarkdownTableStyler verticalAlignment(TableCellVerticalAlignment value) {
    return merge(MarkdownTableStyler(verticalAlignment: value));
  }

  /// Sets the animation configuration.
  @override
  MarkdownTableStyler animate(AnimationConfig value) {
    return merge(MarkdownTableStyler(animation: value));
  }

  /// Sets the style variants.
  @override
  MarkdownTableStyler variants(List<VariantStyle<MarkdownTableSpec>> value) {
    return merge(MarkdownTableStyler(variants: value));
  }

  /// Wraps with a widget modifier.
  @override
  MarkdownTableStyler wrap(WidgetModifierConfig value) {
    return merge(MarkdownTableStyler(modifier: value));
  }

  /// Sets the widget modifier.
  MarkdownTableStyler modifier(WidgetModifierConfig value) {
    return merge(MarkdownTableStyler(modifier: value));
  }

  /// Merges with another [MarkdownTableStyler].
  @override
  MarkdownTableStyler merge(MarkdownTableStyler? other) {
    return MarkdownTableStyler.create(
      headStyle: MixOps.merge($headStyle, other?.$headStyle),
      bodyStyle: MixOps.merge($bodyStyle, other?.$bodyStyle),
      headAlignment: MixOps.merge($headAlignment, other?.$headAlignment),
      padding: MixOps.merge($padding, other?.$padding),
      border: MixOps.merge($border, other?.$border),
      columnWidth: MixOps.merge($columnWidth, other?.$columnWidth),
      cellPadding: MixOps.merge($cellPadding, other?.$cellPadding),
      cellDecoration: MixOps.merge($cellDecoration, other?.$cellDecoration),
      verticalAlignment: MixOps.merge(
        $verticalAlignment,
        other?.$verticalAlignment,
      ),
      variants: MixOps.mergeVariants($variants, other?.$variants),
      modifier: MixOps.mergeModifier($modifier, other?.$modifier),
      animation: MixOps.mergeAnimation($animation, other?.$animation),
    );
  }

  /// Resolves to [StyleSpec<MarkdownTableSpec>] using [context].
  @override
  StyleSpec<MarkdownTableSpec> resolve(BuildContext context) {
    final spec = MarkdownTableSpec(
      headStyle: MixOps.resolve(context, $headStyle),
      bodyStyle: MixOps.resolve(context, $bodyStyle),
      headAlignment: MixOps.resolve(context, $headAlignment),
      padding: MixOps.resolve(context, $padding),
      border: MixOps.resolve(context, $border),
      columnWidth: MixOps.resolve(context, $columnWidth),
      cellPadding: MixOps.resolve(context, $cellPadding),
      cellDecoration: MixOps.resolve(context, $cellDecoration),
      verticalAlignment: MixOps.resolve(context, $verticalAlignment),
    );

    return StyleSpec(
      spec: spec,
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('headStyle', $headStyle))
      ..add(DiagnosticsProperty('bodyStyle', $bodyStyle))
      ..add(DiagnosticsProperty('headAlignment', $headAlignment))
      ..add(DiagnosticsProperty('padding', $padding))
      ..add(DiagnosticsProperty('border', $border))
      ..add(DiagnosticsProperty('columnWidth', $columnWidth))
      ..add(DiagnosticsProperty('cellPadding', $cellPadding))
      ..add(DiagnosticsProperty('cellDecoration', $cellDecoration))
      ..add(DiagnosticsProperty('verticalAlignment', $verticalAlignment));
  }

  @override
  List<Object?> get props => [
    $headStyle,
    $bodyStyle,
    $headAlignment,
    $padding,
    $border,
    $columnWidth,
    $cellPadding,
    $cellDecoration,
    $verticalAlignment,
    $animation,
    $modifier,
    $variants,
  ];
}
