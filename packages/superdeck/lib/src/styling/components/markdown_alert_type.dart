import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

part 'markdown_alert_type.g.dart';

/// Specification for individual markdown alert type styling.
///
/// Defines the complete styling for a single alert type (note, tip, important, etc.)
/// including heading, description, icon, container, and flex layout properties.
@MixableSpec()
@immutable
final class MarkdownAlertTypeSpec with _$MarkdownAlertTypeSpec {
  @override
  final StyleSpec<TextSpec> heading;

  @override
  final StyleSpec<TextSpec> description;

  @override
  final StyleSpec<IconSpec> icon;

  @override
  final StyleSpec<BoxSpec> container;

  @override
  final StyleSpec<FlexBoxSpec> containerFlex;

  @override
  final StyleSpec<FlexBoxSpec> headingFlex;

  const MarkdownAlertTypeSpec({
    StyleSpec<TextSpec>? heading,
    StyleSpec<TextSpec>? description,
    StyleSpec<IconSpec>? icon,
    StyleSpec<BoxSpec>? container,
    StyleSpec<FlexBoxSpec>? containerFlex,
    StyleSpec<FlexBoxSpec>? headingFlex,
  }) : heading = heading ?? const StyleSpec(spec: TextSpec()),
       description = description ?? const StyleSpec(spec: TextSpec()),
       icon = icon ?? const StyleSpec(spec: IconSpec()),
       container = container ?? const StyleSpec(spec: BoxSpec()),
       containerFlex = containerFlex ?? const StyleSpec(spec: FlexBoxSpec()),
       headingFlex = headingFlex ?? const StyleSpec(spec: FlexBoxSpec());
}

/// Legacy alias for [MarkdownAlertTypeStyler] (the pre-codegen class name).
typedef MarkdownAlertTypeStyle = MarkdownAlertTypeStyler;
