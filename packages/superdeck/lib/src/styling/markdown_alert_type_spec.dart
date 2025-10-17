import 'package:flutter/foundation.dart';
import 'package:mix/mix.dart';

/// Specification for individual markdown alert type styling.
///
/// Defines the complete styling for a single alert type (note, tip, important, etc.)
/// including heading, description, icon, container, and flex layout properties.
final class MarkdownAlertTypeSpec extends Spec<MarkdownAlertTypeSpec>
    with Diagnosticable {
  final StyleSpec<TextSpec> heading;
  final StyleSpec<TextSpec> description;
  final StyleSpec<IconSpec> icon;
  final StyleSpec<BoxSpec> container;
  final StyleSpec<FlexBoxSpec> containerFlex;
  final StyleSpec<FlexBoxSpec> headingFlex;

  const MarkdownAlertTypeSpec({
    StyleSpec<TextSpec>? heading,
    StyleSpec<TextSpec>? description,
    StyleSpec<IconSpec>? icon,
    StyleSpec<BoxSpec>? container,
    StyleSpec<FlexBoxSpec>? containerFlex,
    StyleSpec<FlexBoxSpec>? headingFlex,
  })  : heading = heading ?? const StyleSpec(spec: TextSpec()),
        description = description ?? const StyleSpec(spec: TextSpec()),
        icon = icon ?? const StyleSpec(spec: IconSpec()),
        container = container ?? const StyleSpec(spec: BoxSpec()),
        containerFlex = containerFlex ?? const StyleSpec(spec: FlexBoxSpec()),
        headingFlex = headingFlex ?? const StyleSpec(spec: FlexBoxSpec());

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
    if (other == null) return this;

    return MarkdownAlertTypeSpec(
      heading: MixOps.lerp(heading, other.heading, t)!,
      description: MixOps.lerp(description, other.description, t)!,
      icon: MixOps.lerp(icon, other.icon, t)!,
      container: MixOps.lerp(container, other.container, t)!,
      containerFlex: MixOps.lerp(containerFlex, other.containerFlex, t)!,
      headingFlex: MixOps.lerp(headingFlex, other.headingFlex, t)!,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('heading', heading))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('icon', icon))
      ..add(DiagnosticsProperty('container', container))
      ..add(DiagnosticsProperty('containerFlex', containerFlex))
      ..add(DiagnosticsProperty('headingFlex', headingFlex));
  }

  @override
  List<Object?> get props =>
      [heading, description, icon, container, containerFlex, headingFlex];
}
