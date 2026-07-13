// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'markdown_blockquote.dart';

// **************************************************************************
// SpecGenerator
// **************************************************************************

mixin _$MarkdownBlockquoteSpec
    implements Spec<MarkdownBlockquoteSpec>, Diagnosticable {
  TextStyle? get textStyle;
  EdgeInsets? get padding;
  BoxDecoration? get decoration;
  WrapAlignment? get alignment;

  @override
  Type get type => MarkdownBlockquoteSpec;

  @override
  MarkdownBlockquoteSpec copyWith({
    TextStyle? textStyle,
    EdgeInsets? padding,
    BoxDecoration? decoration,
    WrapAlignment? alignment,
  }) {
    return MarkdownBlockquoteSpec(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      decoration: decoration ?? this.decoration,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  MarkdownBlockquoteSpec lerp(MarkdownBlockquoteSpec? other, double t) {
    return MarkdownBlockquoteSpec(
      textStyle: MixOps.lerp(textStyle, other?.textStyle, t),
      padding: MixOps.lerp(padding, other?.padding, t),
      decoration: MixOps.lerp(decoration, other?.decoration, t),
      alignment: MixOps.lerpSnap(alignment, other?.alignment, t),
    );
  }

  @override
  List<Object?> get props => [textStyle, padding, decoration, alignment];

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MarkdownBlockquoteSpec &&
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
      ..add(DiagnosticsProperty('textStyle', textStyle))
      ..add(DiagnosticsProperty('padding', padding))
      ..add(DiagnosticsProperty('decoration', decoration))
      ..add(DiagnosticsProperty('alignment', alignment));
  }
}

@Deprecated(
  'Rename to `_\$MarkdownBlockquoteSpec` and migrate the class declaration to `class MarkdownBlockquoteSpec with _\$MarkdownBlockquoteSpec`. The `_\$MarkdownBlockquoteSpecMethods` alias will be removed in mix_generator 3.0.',
)
typedef _$MarkdownBlockquoteSpecMethods = _$MarkdownBlockquoteSpec; // ignore: unused_element

// **************************************************************************
// SpecStylerGenerator
// **************************************************************************

class MarkdownBlockquoteStyler
    extends MixStyler<MarkdownBlockquoteStyler, MarkdownBlockquoteSpec> {
  final Prop<TextStyle>? $textStyle;
  final Prop<EdgeInsets>? $padding;
  final Prop<BoxDecoration>? $decoration;
  final Prop<WrapAlignment>? $alignment;

  const MarkdownBlockquoteStyler.create({
    Prop<TextStyle>? textStyle,
    Prop<EdgeInsets>? padding,
    Prop<BoxDecoration>? decoration,
    Prop<WrapAlignment>? alignment,
    super.variants,
    super.modifier,
    super.animation,
  }) : $textStyle = textStyle,
       $padding = padding,
       $decoration = decoration,
       $alignment = alignment;

  MarkdownBlockquoteStyler({
    TextStyleMix? textStyle,
    EdgeInsets? padding,
    BoxDecoration? decoration,
    WrapAlignment? alignment,
    AnimationConfig? animation,
    WidgetModifierConfig? modifier,
    List<VariantStyle<MarkdownBlockquoteSpec>>? variants,
  }) : this.create(
         textStyle: Prop.maybeMix(textStyle),
         padding: Prop.maybe(padding),
         decoration: Prop.maybe(decoration),
         alignment: Prop.maybe(alignment),
         variants: variants,
         modifier: modifier,
         animation: animation,
       );

  factory MarkdownBlockquoteStyler.textStyle(TextStyleMix value) =>
      MarkdownBlockquoteStyler().textStyle(value);
  factory MarkdownBlockquoteStyler.padding(EdgeInsets value) =>
      MarkdownBlockquoteStyler().padding(value);
  factory MarkdownBlockquoteStyler.decoration(BoxDecoration value) =>
      MarkdownBlockquoteStyler().decoration(value);
  factory MarkdownBlockquoteStyler.alignment(WrapAlignment value) =>
      MarkdownBlockquoteStyler().alignment(value);

  /// Sets the textStyle.
  MarkdownBlockquoteStyler textStyle(TextStyleMix value) {
    return merge(MarkdownBlockquoteStyler(textStyle: value));
  }

  /// Sets the padding.
  MarkdownBlockquoteStyler padding(EdgeInsets value) {
    return merge(MarkdownBlockquoteStyler(padding: value));
  }

  /// Sets the decoration.
  MarkdownBlockquoteStyler decoration(BoxDecoration value) {
    return merge(MarkdownBlockquoteStyler(decoration: value));
  }

  /// Sets the alignment.
  MarkdownBlockquoteStyler alignment(WrapAlignment value) {
    return merge(MarkdownBlockquoteStyler(alignment: value));
  }

  /// Sets the animation configuration.
  @override
  MarkdownBlockquoteStyler animate(AnimationConfig value) {
    return merge(MarkdownBlockquoteStyler(animation: value));
  }

  /// Sets the style variants.
  @override
  MarkdownBlockquoteStyler variants(
    List<VariantStyle<MarkdownBlockquoteSpec>> value,
  ) {
    return merge(MarkdownBlockquoteStyler(variants: value));
  }

  /// Wraps with a widget modifier.
  @override
  MarkdownBlockquoteStyler wrap(WidgetModifierConfig value) {
    return merge(MarkdownBlockquoteStyler(modifier: value));
  }

  /// Sets the widget modifier.
  MarkdownBlockquoteStyler modifier(WidgetModifierConfig value) {
    return merge(MarkdownBlockquoteStyler(modifier: value));
  }

  /// Merges with another [MarkdownBlockquoteStyler].
  @override
  MarkdownBlockquoteStyler merge(MarkdownBlockquoteStyler? other) {
    return MarkdownBlockquoteStyler.create(
      textStyle: MixOps.merge($textStyle, other?.$textStyle),
      padding: MixOps.merge($padding, other?.$padding),
      decoration: MixOps.merge($decoration, other?.$decoration),
      alignment: MixOps.merge($alignment, other?.$alignment),
      variants: MixOps.mergeVariants($variants, other?.$variants),
      modifier: MixOps.mergeModifier($modifier, other?.$modifier),
      animation: MixOps.mergeAnimation($animation, other?.$animation),
    );
  }

  /// Resolves to [StyleSpec<MarkdownBlockquoteSpec>] using [context].
  @override
  StyleSpec<MarkdownBlockquoteSpec> resolve(BuildContext context) {
    final spec = MarkdownBlockquoteSpec(
      textStyle: MixOps.resolve(context, $textStyle),
      padding: MixOps.resolve(context, $padding),
      decoration: MixOps.resolve(context, $decoration),
      alignment: MixOps.resolve(context, $alignment),
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
      ..add(DiagnosticsProperty('textStyle', $textStyle))
      ..add(DiagnosticsProperty('padding', $padding))
      ..add(DiagnosticsProperty('decoration', $decoration))
      ..add(DiagnosticsProperty('alignment', $alignment));
  }

  @override
  List<Object?> get props => [
    $textStyle,
    $padding,
    $decoration,
    $alignment,
    $animation,
    $modifier,
    $variants,
  ];
}
