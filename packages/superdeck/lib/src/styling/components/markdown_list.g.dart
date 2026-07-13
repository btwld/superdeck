// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'markdown_list.dart';

// **************************************************************************
// SpecGenerator
// **************************************************************************

mixin _$MarkdownListSpec implements Spec<MarkdownListSpec>, Diagnosticable {
  StyleSpec<TextSpec>? get bullet;
  StyleSpec<TextSpec>? get text;
  WrapAlignment? get orderedAlignment;
  WrapAlignment? get unorderedAlignment;

  @override
  Type get type => MarkdownListSpec;

  @override
  MarkdownListSpec copyWith({
    StyleSpec<TextSpec>? bullet,
    StyleSpec<TextSpec>? text,
    WrapAlignment? orderedAlignment,
    WrapAlignment? unorderedAlignment,
  }) {
    return MarkdownListSpec(
      bullet: bullet ?? this.bullet,
      text: text ?? this.text,
      orderedAlignment: orderedAlignment ?? this.orderedAlignment,
      unorderedAlignment: unorderedAlignment ?? this.unorderedAlignment,
    );
  }

  @override
  MarkdownListSpec lerp(MarkdownListSpec? other, double t) {
    return MarkdownListSpec(
      bullet: bullet?.lerp(other?.bullet, t),
      text: text?.lerp(other?.text, t),
      orderedAlignment: MixOps.lerpSnap(
        orderedAlignment,
        other?.orderedAlignment,
        t,
      ),
      unorderedAlignment: MixOps.lerpSnap(
        unorderedAlignment,
        other?.unorderedAlignment,
        t,
      ),
    );
  }

  @override
  List<Object?> get props => [
    bullet,
    text,
    orderedAlignment,
    unorderedAlignment,
  ];

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MarkdownListSpec &&
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
      ..add(DiagnosticsProperty('bullet', bullet))
      ..add(DiagnosticsProperty('text', text))
      ..add(DiagnosticsProperty('orderedAlignment', orderedAlignment))
      ..add(DiagnosticsProperty('unorderedAlignment', unorderedAlignment));
  }
}

@Deprecated(
  'Rename to `_\$MarkdownListSpec` and migrate the class declaration to `class MarkdownListSpec with _\$MarkdownListSpec`. The `_\$MarkdownListSpecMethods` alias will be removed in mix_generator 3.0.',
)
typedef _$MarkdownListSpecMethods = _$MarkdownListSpec; // ignore: unused_element

// **************************************************************************
// SpecStylerGenerator
// **************************************************************************

class MarkdownListStyler
    extends MixStyler<MarkdownListStyler, MarkdownListSpec> {
  final Prop<StyleSpec<TextSpec>>? $bullet;
  final Prop<StyleSpec<TextSpec>>? $text;
  final Prop<WrapAlignment>? $orderedAlignment;
  final Prop<WrapAlignment>? $unorderedAlignment;

  const MarkdownListStyler.create({
    Prop<StyleSpec<TextSpec>>? bullet,
    Prop<StyleSpec<TextSpec>>? text,
    Prop<WrapAlignment>? orderedAlignment,
    Prop<WrapAlignment>? unorderedAlignment,
    super.variants,
    super.modifier,
    super.animation,
  }) : $bullet = bullet,
       $text = text,
       $orderedAlignment = orderedAlignment,
       $unorderedAlignment = unorderedAlignment;

  MarkdownListStyler({
    TextStyler? bullet,
    TextStyler? text,
    WrapAlignment? orderedAlignment,
    WrapAlignment? unorderedAlignment,
    AnimationConfig? animation,
    WidgetModifierConfig? modifier,
    List<VariantStyle<MarkdownListSpec>>? variants,
  }) : this.create(
         bullet: Prop.maybeMix(bullet),
         text: Prop.maybeMix(text),
         orderedAlignment: Prop.maybe(orderedAlignment),
         unorderedAlignment: Prop.maybe(unorderedAlignment),
         variants: variants,
         modifier: modifier,
         animation: animation,
       );

  factory MarkdownListStyler.bullet(TextStyler value) =>
      MarkdownListStyler().bullet(value);
  factory MarkdownListStyler.text(TextStyler value) =>
      MarkdownListStyler().text(value);
  factory MarkdownListStyler.orderedAlignment(WrapAlignment value) =>
      MarkdownListStyler().orderedAlignment(value);
  factory MarkdownListStyler.unorderedAlignment(WrapAlignment value) =>
      MarkdownListStyler().unorderedAlignment(value);

  /// Sets the bullet.
  MarkdownListStyler bullet(TextStyler value) {
    return merge(MarkdownListStyler(bullet: value));
  }

  /// Sets the text.
  MarkdownListStyler text(TextStyler value) {
    return merge(MarkdownListStyler(text: value));
  }

  /// Sets the orderedAlignment.
  MarkdownListStyler orderedAlignment(WrapAlignment value) {
    return merge(MarkdownListStyler(orderedAlignment: value));
  }

  /// Sets the unorderedAlignment.
  MarkdownListStyler unorderedAlignment(WrapAlignment value) {
    return merge(MarkdownListStyler(unorderedAlignment: value));
  }

  /// Sets the animation configuration.
  @override
  MarkdownListStyler animate(AnimationConfig value) {
    return merge(MarkdownListStyler(animation: value));
  }

  /// Sets the style variants.
  @override
  MarkdownListStyler variants(List<VariantStyle<MarkdownListSpec>> value) {
    return merge(MarkdownListStyler(variants: value));
  }

  /// Wraps with a widget modifier.
  @override
  MarkdownListStyler wrap(WidgetModifierConfig value) {
    return merge(MarkdownListStyler(modifier: value));
  }

  /// Sets the widget modifier.
  MarkdownListStyler modifier(WidgetModifierConfig value) {
    return merge(MarkdownListStyler(modifier: value));
  }

  /// Merges with another [MarkdownListStyler].
  @override
  MarkdownListStyler merge(MarkdownListStyler? other) {
    return MarkdownListStyler.create(
      bullet: MixOps.merge($bullet, other?.$bullet),
      text: MixOps.merge($text, other?.$text),
      orderedAlignment: MixOps.merge(
        $orderedAlignment,
        other?.$orderedAlignment,
      ),
      unorderedAlignment: MixOps.merge(
        $unorderedAlignment,
        other?.$unorderedAlignment,
      ),
      variants: MixOps.mergeVariants($variants, other?.$variants),
      modifier: MixOps.mergeModifier($modifier, other?.$modifier),
      animation: MixOps.mergeAnimation($animation, other?.$animation),
    );
  }

  /// Resolves to [StyleSpec<MarkdownListSpec>] using [context].
  @override
  StyleSpec<MarkdownListSpec> resolve(BuildContext context) {
    final spec = MarkdownListSpec(
      bullet: MixOps.resolve(context, $bullet),
      text: MixOps.resolve(context, $text),
      orderedAlignment: MixOps.resolve(context, $orderedAlignment),
      unorderedAlignment: MixOps.resolve(context, $unorderedAlignment),
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
      ..add(DiagnosticsProperty('bullet', $bullet))
      ..add(DiagnosticsProperty('text', $text))
      ..add(DiagnosticsProperty('orderedAlignment', $orderedAlignment))
      ..add(DiagnosticsProperty('unorderedAlignment', $unorderedAlignment));
  }

  @override
  List<Object?> get props => [
    $bullet,
    $text,
    $orderedAlignment,
    $unorderedAlignment,
    $animation,
    $modifier,
    $variants,
  ];
}
