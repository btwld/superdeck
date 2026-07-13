// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'markdown_alert_type.dart';

// **************************************************************************
// SpecGenerator
// **************************************************************************

mixin _$MarkdownAlertTypeSpec
    implements Spec<MarkdownAlertTypeSpec>, Diagnosticable {
  StyleSpec<TextSpec> get heading;
  StyleSpec<TextSpec> get description;
  StyleSpec<IconSpec> get icon;
  StyleSpec<BoxSpec> get container;
  StyleSpec<FlexBoxSpec> get containerFlex;
  StyleSpec<FlexBoxSpec> get headingFlex;

  @override
  Type get type => MarkdownAlertTypeSpec;

  @override
  MarkdownAlertTypeSpec copyWith({
    StyleSpec<TextSpec>? heading,
    StyleSpec<TextSpec>? description,
    StyleSpec<IconSpec>? icon,
    StyleSpec<BoxSpec>? container,
    StyleSpec<FlexBoxSpec>? containerFlex,
    StyleSpec<FlexBoxSpec>? headingFlex,
  }) {
    return MarkdownAlertTypeSpec(
      heading: heading ?? this.heading,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      container: container ?? this.container,
      containerFlex: containerFlex ?? this.containerFlex,
      headingFlex: headingFlex ?? this.headingFlex,
    );
  }

  @override
  MarkdownAlertTypeSpec lerp(MarkdownAlertTypeSpec? other, double t) {
    return MarkdownAlertTypeSpec(
      heading: heading.lerp(other?.heading, t),
      description: description.lerp(other?.description, t),
      icon: icon.lerp(other?.icon, t),
      container: container.lerp(other?.container, t),
      containerFlex: containerFlex.lerp(other?.containerFlex, t),
      headingFlex: headingFlex.lerp(other?.headingFlex, t),
    );
  }

  @override
  List<Object?> get props => [
    heading,
    description,
    icon,
    container,
    containerFlex,
    headingFlex,
  ];

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MarkdownAlertTypeSpec &&
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
      ..add(DiagnosticsProperty('heading', heading))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('icon', icon))
      ..add(DiagnosticsProperty('container', container))
      ..add(DiagnosticsProperty('containerFlex', containerFlex))
      ..add(DiagnosticsProperty('headingFlex', headingFlex));
  }
}

@Deprecated(
  'Rename to `_\$MarkdownAlertTypeSpec` and migrate the class declaration to `class MarkdownAlertTypeSpec with _\$MarkdownAlertTypeSpec`. The `_\$MarkdownAlertTypeSpecMethods` alias will be removed in mix_generator 3.0.',
)
typedef _$MarkdownAlertTypeSpecMethods = _$MarkdownAlertTypeSpec; // ignore: unused_element

// **************************************************************************
// SpecStylerGenerator
// **************************************************************************

class MarkdownAlertTypeStyler
    extends MixStyler<MarkdownAlertTypeStyler, MarkdownAlertTypeSpec> {
  final Prop<StyleSpec<TextSpec>>? $heading;
  final Prop<StyleSpec<TextSpec>>? $description;
  final Prop<StyleSpec<IconSpec>>? $icon;
  final Prop<StyleSpec<BoxSpec>>? $container;
  final Prop<StyleSpec<FlexBoxSpec>>? $containerFlex;
  final Prop<StyleSpec<FlexBoxSpec>>? $headingFlex;

  const MarkdownAlertTypeStyler.create({
    Prop<StyleSpec<TextSpec>>? heading,
    Prop<StyleSpec<TextSpec>>? description,
    Prop<StyleSpec<IconSpec>>? icon,
    Prop<StyleSpec<BoxSpec>>? container,
    Prop<StyleSpec<FlexBoxSpec>>? containerFlex,
    Prop<StyleSpec<FlexBoxSpec>>? headingFlex,
    super.variants,
    super.modifier,
    super.animation,
  }) : $heading = heading,
       $description = description,
       $icon = icon,
       $container = container,
       $containerFlex = containerFlex,
       $headingFlex = headingFlex;

  MarkdownAlertTypeStyler({
    TextStyler? heading,
    TextStyler? description,
    IconStyler? icon,
    BoxStyler? container,
    FlexBoxStyler? containerFlex,
    FlexBoxStyler? headingFlex,
    AnimationConfig? animation,
    WidgetModifierConfig? modifier,
    List<VariantStyle<MarkdownAlertTypeSpec>>? variants,
  }) : this.create(
         heading: Prop.maybeMix(heading),
         description: Prop.maybeMix(description),
         icon: Prop.maybeMix(icon),
         container: Prop.maybeMix(container),
         containerFlex: Prop.maybeMix(containerFlex),
         headingFlex: Prop.maybeMix(headingFlex),
         variants: variants,
         modifier: modifier,
         animation: animation,
       );

  factory MarkdownAlertTypeStyler.heading(TextStyler value) =>
      MarkdownAlertTypeStyler().heading(value);
  factory MarkdownAlertTypeStyler.description(TextStyler value) =>
      MarkdownAlertTypeStyler().description(value);
  factory MarkdownAlertTypeStyler.icon(IconStyler value) =>
      MarkdownAlertTypeStyler().icon(value);
  factory MarkdownAlertTypeStyler.container(BoxStyler value) =>
      MarkdownAlertTypeStyler().container(value);
  factory MarkdownAlertTypeStyler.containerFlex(FlexBoxStyler value) =>
      MarkdownAlertTypeStyler().containerFlex(value);
  factory MarkdownAlertTypeStyler.headingFlex(FlexBoxStyler value) =>
      MarkdownAlertTypeStyler().headingFlex(value);

  /// Sets the heading.
  MarkdownAlertTypeStyler heading(TextStyler value) {
    return merge(MarkdownAlertTypeStyler(heading: value));
  }

  /// Sets the description.
  MarkdownAlertTypeStyler description(TextStyler value) {
    return merge(MarkdownAlertTypeStyler(description: value));
  }

  /// Sets the icon.
  MarkdownAlertTypeStyler icon(IconStyler value) {
    return merge(MarkdownAlertTypeStyler(icon: value));
  }

  /// Sets the container.
  MarkdownAlertTypeStyler container(BoxStyler value) {
    return merge(MarkdownAlertTypeStyler(container: value));
  }

  /// Sets the containerFlex.
  MarkdownAlertTypeStyler containerFlex(FlexBoxStyler value) {
    return merge(MarkdownAlertTypeStyler(containerFlex: value));
  }

  /// Sets the headingFlex.
  MarkdownAlertTypeStyler headingFlex(FlexBoxStyler value) {
    return merge(MarkdownAlertTypeStyler(headingFlex: value));
  }

  /// Sets the animation configuration.
  @override
  MarkdownAlertTypeStyler animate(AnimationConfig value) {
    return merge(MarkdownAlertTypeStyler(animation: value));
  }

  /// Sets the style variants.
  @override
  MarkdownAlertTypeStyler variants(
    List<VariantStyle<MarkdownAlertTypeSpec>> value,
  ) {
    return merge(MarkdownAlertTypeStyler(variants: value));
  }

  /// Wraps with a widget modifier.
  @override
  MarkdownAlertTypeStyler wrap(WidgetModifierConfig value) {
    return merge(MarkdownAlertTypeStyler(modifier: value));
  }

  /// Sets the widget modifier.
  MarkdownAlertTypeStyler modifier(WidgetModifierConfig value) {
    return merge(MarkdownAlertTypeStyler(modifier: value));
  }

  /// Merges with another [MarkdownAlertTypeStyler].
  @override
  MarkdownAlertTypeStyler merge(MarkdownAlertTypeStyler? other) {
    return MarkdownAlertTypeStyler.create(
      heading: MixOps.merge($heading, other?.$heading),
      description: MixOps.merge($description, other?.$description),
      icon: MixOps.merge($icon, other?.$icon),
      container: MixOps.merge($container, other?.$container),
      containerFlex: MixOps.merge($containerFlex, other?.$containerFlex),
      headingFlex: MixOps.merge($headingFlex, other?.$headingFlex),
      variants: MixOps.mergeVariants($variants, other?.$variants),
      modifier: MixOps.mergeModifier($modifier, other?.$modifier),
      animation: MixOps.mergeAnimation($animation, other?.$animation),
    );
  }

  /// Resolves to [StyleSpec<MarkdownAlertTypeSpec>] using [context].
  @override
  StyleSpec<MarkdownAlertTypeSpec> resolve(BuildContext context) {
    final spec = MarkdownAlertTypeSpec(
      heading: MixOps.resolve(context, $heading),
      description: MixOps.resolve(context, $description),
      icon: MixOps.resolve(context, $icon),
      container: MixOps.resolve(context, $container),
      containerFlex: MixOps.resolve(context, $containerFlex),
      headingFlex: MixOps.resolve(context, $headingFlex),
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
      ..add(DiagnosticsProperty('heading', $heading))
      ..add(DiagnosticsProperty('description', $description))
      ..add(DiagnosticsProperty('icon', $icon))
      ..add(DiagnosticsProperty('container', $container))
      ..add(DiagnosticsProperty('containerFlex', $containerFlex))
      ..add(DiagnosticsProperty('headingFlex', $headingFlex));
  }

  @override
  List<Object?> get props => [
    $heading,
    $description,
    $icon,
    $container,
    $containerFlex,
    $headingFlex,
    $animation,
    $modifier,
    $variants,
  ];
}
