// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'markdown_checkbox.dart';

// **************************************************************************
// SpecGenerator
// **************************************************************************

mixin _$MarkdownCheckboxSpec
    implements Spec<MarkdownCheckboxSpec>, Diagnosticable {
  TextStyle? get textStyle;
  StyleSpec<IconSpec>? get icon;

  @override
  Type get type => MarkdownCheckboxSpec;

  @override
  MarkdownCheckboxSpec copyWith({
    TextStyle? textStyle,
    StyleSpec<IconSpec>? icon,
  }) {
    return MarkdownCheckboxSpec(
      textStyle: textStyle ?? this.textStyle,
      icon: icon ?? this.icon,
    );
  }

  @override
  MarkdownCheckboxSpec lerp(MarkdownCheckboxSpec? other, double t) {
    return MarkdownCheckboxSpec(
      textStyle: MixOps.lerp(textStyle, other?.textStyle, t),
      icon: icon?.lerp(other?.icon, t),
    );
  }

  @override
  List<Object?> get props => [textStyle, icon];

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MarkdownCheckboxSpec &&
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
      ..add(DiagnosticsProperty('icon', icon));
  }
}

@Deprecated(
  'Rename to `_\$MarkdownCheckboxSpec` and migrate the class declaration to `class MarkdownCheckboxSpec with _\$MarkdownCheckboxSpec`. The `_\$MarkdownCheckboxSpecMethods` alias will be removed in mix_generator 3.0.',
)
typedef _$MarkdownCheckboxSpecMethods = _$MarkdownCheckboxSpec; // ignore: unused_element

// **************************************************************************
// SpecStylerGenerator
// **************************************************************************

class MarkdownCheckboxStyler
    extends MixStyler<MarkdownCheckboxStyler, MarkdownCheckboxSpec> {
  final Prop<TextStyle>? $textStyle;
  final Prop<StyleSpec<IconSpec>>? $icon;

  const MarkdownCheckboxStyler.create({
    Prop<TextStyle>? textStyle,
    Prop<StyleSpec<IconSpec>>? icon,
    super.variants,
    super.modifier,
    super.animation,
  }) : $textStyle = textStyle,
       $icon = icon;

  MarkdownCheckboxStyler({
    TextStyleMix? textStyle,
    IconStyler? icon,
    AnimationConfig? animation,
    WidgetModifierConfig? modifier,
    List<VariantStyle<MarkdownCheckboxSpec>>? variants,
  }) : this.create(
         textStyle: Prop.maybeMix(textStyle),
         icon: Prop.maybeMix(icon),
         variants: variants,
         modifier: modifier,
         animation: animation,
       );

  factory MarkdownCheckboxStyler.textStyle(TextStyleMix value) =>
      MarkdownCheckboxStyler().textStyle(value);
  factory MarkdownCheckboxStyler.icon(IconStyler value) =>
      MarkdownCheckboxStyler().icon(value);

  /// Sets the textStyle.
  MarkdownCheckboxStyler textStyle(TextStyleMix value) {
    return merge(MarkdownCheckboxStyler(textStyle: value));
  }

  /// Sets the icon.
  MarkdownCheckboxStyler icon(IconStyler value) {
    return merge(MarkdownCheckboxStyler(icon: value));
  }

  /// Sets the animation configuration.
  @override
  MarkdownCheckboxStyler animate(AnimationConfig value) {
    return merge(MarkdownCheckboxStyler(animation: value));
  }

  /// Sets the style variants.
  @override
  MarkdownCheckboxStyler variants(
    List<VariantStyle<MarkdownCheckboxSpec>> value,
  ) {
    return merge(MarkdownCheckboxStyler(variants: value));
  }

  /// Wraps with a widget modifier.
  @override
  MarkdownCheckboxStyler wrap(WidgetModifierConfig value) {
    return merge(MarkdownCheckboxStyler(modifier: value));
  }

  /// Sets the widget modifier.
  MarkdownCheckboxStyler modifier(WidgetModifierConfig value) {
    return merge(MarkdownCheckboxStyler(modifier: value));
  }

  /// Merges with another [MarkdownCheckboxStyler].
  @override
  MarkdownCheckboxStyler merge(MarkdownCheckboxStyler? other) {
    return MarkdownCheckboxStyler.create(
      textStyle: MixOps.merge($textStyle, other?.$textStyle),
      icon: MixOps.merge($icon, other?.$icon),
      variants: MixOps.mergeVariants($variants, other?.$variants),
      modifier: MixOps.mergeModifier($modifier, other?.$modifier),
      animation: MixOps.mergeAnimation($animation, other?.$animation),
    );
  }

  /// Resolves to [StyleSpec<MarkdownCheckboxSpec>] using [context].
  @override
  StyleSpec<MarkdownCheckboxSpec> resolve(BuildContext context) {
    final spec = MarkdownCheckboxSpec(
      textStyle: MixOps.resolve(context, $textStyle),
      icon: MixOps.resolve(context, $icon),
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
      ..add(DiagnosticsProperty('icon', $icon));
  }

  @override
  List<Object?> get props => [
    $textStyle,
    $icon,
    $animation,
    $modifier,
    $variants,
  ];
}
