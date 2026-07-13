// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'markdown_codeblock.dart';

// **************************************************************************
// SpecGenerator
// **************************************************************************

mixin _$MarkdownCodeblockSpec
    implements Spec<MarkdownCodeblockSpec>, Diagnosticable {
  TextStyle? get textStyle;
  StyleSpec<BoxSpec>? get container;
  WrapAlignment? get alignment;

  @override
  Type get type => MarkdownCodeblockSpec;

  @override
  MarkdownCodeblockSpec copyWith({
    TextStyle? textStyle,
    StyleSpec<BoxSpec>? container,
    WrapAlignment? alignment,
  }) {
    return MarkdownCodeblockSpec(
      textStyle: textStyle ?? this.textStyle,
      container: container ?? this.container,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  MarkdownCodeblockSpec lerp(MarkdownCodeblockSpec? other, double t) {
    return MarkdownCodeblockSpec(
      textStyle: MixOps.lerp(textStyle, other?.textStyle, t),
      container: container?.lerp(other?.container, t),
      alignment: MixOps.lerpSnap(alignment, other?.alignment, t),
    );
  }

  @override
  List<Object?> get props => [textStyle, container, alignment];

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MarkdownCodeblockSpec &&
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
      ..add(DiagnosticsProperty('container', container))
      ..add(DiagnosticsProperty('alignment', alignment));
  }
}

@Deprecated(
  'Rename to `_\$MarkdownCodeblockSpec` and migrate the class declaration to `class MarkdownCodeblockSpec with _\$MarkdownCodeblockSpec`. The `_\$MarkdownCodeblockSpecMethods` alias will be removed in mix_generator 3.0.',
)
typedef _$MarkdownCodeblockSpecMethods = _$MarkdownCodeblockSpec; // ignore: unused_element

// **************************************************************************
// SpecStylerGenerator
// **************************************************************************

class MarkdownCodeblockStyler
    extends MixStyler<MarkdownCodeblockStyler, MarkdownCodeblockSpec> {
  final Prop<TextStyle>? $textStyle;
  final Prop<StyleSpec<BoxSpec>>? $container;
  final Prop<WrapAlignment>? $alignment;

  const MarkdownCodeblockStyler.create({
    Prop<TextStyle>? textStyle,
    Prop<StyleSpec<BoxSpec>>? container,
    Prop<WrapAlignment>? alignment,
    super.variants,
    super.modifier,
    super.animation,
  }) : $textStyle = textStyle,
       $container = container,
       $alignment = alignment;

  MarkdownCodeblockStyler({
    TextStyleMix? textStyle,
    BoxStyler? container,
    WrapAlignment? alignment,
    AnimationConfig? animation,
    WidgetModifierConfig? modifier,
    List<VariantStyle<MarkdownCodeblockSpec>>? variants,
  }) : this.create(
         textStyle: Prop.maybeMix(textStyle),
         container: Prop.maybeMix(container),
         alignment: Prop.maybe(alignment),
         variants: variants,
         modifier: modifier,
         animation: animation,
       );

  factory MarkdownCodeblockStyler.textStyle(TextStyleMix value) =>
      MarkdownCodeblockStyler().textStyle(value);
  factory MarkdownCodeblockStyler.container(BoxStyler value) =>
      MarkdownCodeblockStyler().container(value);
  factory MarkdownCodeblockStyler.alignment(WrapAlignment value) =>
      MarkdownCodeblockStyler().alignment(value);

  /// Sets the textStyle.
  MarkdownCodeblockStyler textStyle(TextStyleMix value) {
    return merge(MarkdownCodeblockStyler(textStyle: value));
  }

  /// Sets the container.
  MarkdownCodeblockStyler container(BoxStyler value) {
    return merge(MarkdownCodeblockStyler(container: value));
  }

  /// Sets the alignment.
  MarkdownCodeblockStyler alignment(WrapAlignment value) {
    return merge(MarkdownCodeblockStyler(alignment: value));
  }

  /// Sets the animation configuration.
  @override
  MarkdownCodeblockStyler animate(AnimationConfig value) {
    return merge(MarkdownCodeblockStyler(animation: value));
  }

  /// Sets the style variants.
  @override
  MarkdownCodeblockStyler variants(
    List<VariantStyle<MarkdownCodeblockSpec>> value,
  ) {
    return merge(MarkdownCodeblockStyler(variants: value));
  }

  /// Wraps with a widget modifier.
  @override
  MarkdownCodeblockStyler wrap(WidgetModifierConfig value) {
    return merge(MarkdownCodeblockStyler(modifier: value));
  }

  /// Sets the widget modifier.
  MarkdownCodeblockStyler modifier(WidgetModifierConfig value) {
    return merge(MarkdownCodeblockStyler(modifier: value));
  }

  /// Merges with another [MarkdownCodeblockStyler].
  @override
  MarkdownCodeblockStyler merge(MarkdownCodeblockStyler? other) {
    return MarkdownCodeblockStyler.create(
      textStyle: MixOps.merge($textStyle, other?.$textStyle),
      container: MixOps.merge($container, other?.$container),
      alignment: MixOps.merge($alignment, other?.$alignment),
      variants: MixOps.mergeVariants($variants, other?.$variants),
      modifier: MixOps.mergeModifier($modifier, other?.$modifier),
      animation: MixOps.mergeAnimation($animation, other?.$animation),
    );
  }

  /// Resolves to [StyleSpec<MarkdownCodeblockSpec>] using [context].
  @override
  StyleSpec<MarkdownCodeblockSpec> resolve(BuildContext context) {
    final spec = MarkdownCodeblockSpec(
      textStyle: MixOps.resolve(context, $textStyle),
      container: MixOps.resolve(context, $container),
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
      ..add(DiagnosticsProperty('container', $container))
      ..add(DiagnosticsProperty('alignment', $alignment));
  }

  @override
  List<Object?> get props => [
    $textStyle,
    $container,
    $alignment,
    $animation,
    $modifier,
    $variants,
  ];
}
