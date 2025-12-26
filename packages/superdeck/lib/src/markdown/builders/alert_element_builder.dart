import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../rendering/blocks/block_provider.dart';
import '../../styling/styling.dart';
import '../markdown_element_builders_registry.dart';
import '../../rendering/blocks/markdown_render_scope.dart';

const _alertHeadingLabels = <AlertType, String>{
  AlertType.note: 'Note',
  AlertType.tip: 'Tip',
  AlertType.important: 'Important',
  AlertType.warning: 'Warning',
  AlertType.caution: 'Caution',
};

enum AlertType {
  note,
  tip,
  important,
  warning,
  caution;

  static AlertType fromString(String type) {
    return AlertType.values.firstWhere(
      (e) => type.toLowerCase() == e.name,
      orElse: () => AlertType.note,
    );
  }
}

class AlertBlockSyntax extends md.AlertBlockSyntax {
  const AlertBlockSyntax();

  static const markdownSourceAttribute = 'markdownSource';

  @override
  md.Node parse(md.BlockParser parser) {
    // Extract type before advancing
    final type = pattern
        .firstMatch(parser.current.content)!
        .group(1)!
        .toLowerCase();
    parser.advance();

    // Use base class to parse child lines (handles all edge cases)
    final childLines = parseChildLines(parser);

    // Simple heuristic for lazy continuation: if last line has content,
    // disable setext headers. This is a simplification of the base class's
    // logic, but sufficient for our needs since we re-parse content in the builder.
    final disableSetext =
        childLines.isNotEmpty && childLines.last.content.trim().isNotEmpty;

    // Parse children
    final children = md.BlockParser(
      childLines,
      parser.document,
    ).parseLines(parentSyntax: this, disabledSetextHeading: disableSetext);

    // Store raw markdown for re-parsing in builder
    final rawMarkdown = childLines.map((line) => line.content).join('\n');

    // Return custom <alert> element (not <div>) with type and raw source
    return md.Element('alert', children)
      ..attributes['type'] = type
      ..attributes[markdownSourceAttribute] = rawMarkdown;
  }
}

class AlertElementBuilder extends MarkdownElementBuilder {
  final StyleSpec<MarkdownAlertSpec> styleSpec;

  AlertElementBuilder([
    this.styleSpec = const StyleSpec(spec: MarkdownAlertSpec()),
  ]);

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    var alertType = AlertType.note;

    if (element.attributes['type'] != null) {
      alertType = AlertType.fromString(element.attributes['type'] as String);
    }

    final iconType = switch (alertType) {
      AlertType.note => Icons.info_outline,
      AlertType.tip => Icons.lightbulb_outline,
      AlertType.important => Icons.label_important_outline,
      AlertType.warning => Icons.warning_amber_outlined,
      AlertType.caution => Icons.dangerous_outlined,
    };

    final blockData = BlockConfiguration.of(context);
    final renderScope = MarkdownRenderScope.maybeOf(context);
    final registry =
        renderScope?.registry ?? SpecMarkdownBuilders(blockData.spec);
    final extensionSet = renderScope?.extensionSet ?? md.ExtensionSet.gitHubWeb;

    final rawMarkdown =
        element.attributes[AlertBlockSyntax.markdownSourceAttribute] ??
        element.textContent.trim();

    return StyleSpecBuilder<MarkdownAlertSpec>(
      styleSpec: styleSpec,
      builder: (context, alertSpec) {
        // Get the specific alert type spec
        final typeStyleSpec = switch (alertType) {
          AlertType.note => alertSpec.note,
          AlertType.tip => alertSpec.tip,
          AlertType.important => alertSpec.important,
          AlertType.warning => alertSpec.warning,
          AlertType.caution => alertSpec.caution,
        };

        // Now unwrap that to get the MarkdownAlertTypeSpec
        return StyleSpecBuilder<MarkdownAlertTypeSpec>(
          styleSpec: typeStyleSpec,
          builder: (context, typeSpec) {
            return Box(
              styleSpec: typeSpec.container,
              child: ColumnBox(
                styleSpec: typeSpec.containerFlex,
                children: [
                  RowBox(
                    styleSpec: typeSpec.headingFlex,
                    children: [
                      StyledIcon(icon: iconType, styleSpec: typeSpec.icon),
                      StyledText(
                        _alertHeadingLabels[alertType] ?? alertType.name,
                        styleSpec: typeSpec.heading,
                      ),
                    ],
                  ),
                  // Render the nested markdown content with its own scope
                  MarkdownRenderScope(
                    registry: registry,
                    styleSheet:
                        renderScope?.styleSheet ?? blockData.spec.toStyle(),
                    extensionSet: extensionSet,
                    child: MarkdownBody(
                      data: rawMarkdown.trimRight(),
                      extensionSet: extensionSet,
                      blockSyntaxes: registry.blockSyntaxes,
                      inlineSyntaxes: registry.inlineSyntaxes,
                      builders: registry.builders,
                      paddingBuilders: registry.paddingBuilders,
                      checkboxBuilder: registry.checkboxBuilder,
                      bulletBuilder: registry.bulletBuilder,
                      styleSheet:
                          renderScope?.styleSheet ?? blockData.spec.toStyle(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
