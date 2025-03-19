import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../styles/style_spec.dart';

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

  @override
  md.Node parse(md.BlockParser parser) {
    // Parse the alert type from the first line.
    final type =
        pattern.firstMatch(parser.current.content)!.group(1)!.toLowerCase();
    parser.advance();
    final childLines = parseChildLines(parser);

    // Combine the content into a single block
    final content = childLines.map((line) => line.content).join('\n');

    final alertElement = md.Element.text('alert', content)
      ..attributes['type'] = type;

    return md.Element(
      'p',
      [alertElement],
    );
  }
}

class AlertElementBuilder extends MarkdownElementBuilder {
  final MarkdownAlertSpec? spec;
  AlertElementBuilder(this.spec);
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final spec = this.spec ?? const MarkdownAlertSpec();
    var alertType = AlertType.note;

    if (element.attributes['type'] != null) {
      alertType = AlertType.fromString(element.attributes['type'] as String);
    }

    final specType = switch (alertType) {
      AlertType.note => spec.note,
      AlertType.tip => spec.tip,
      AlertType.important => spec.important,
      AlertType.warning => spec.warning,
      AlertType.caution => spec.caution,
    };

    final iconType = switch (alertType) {
      AlertType.note => Icons.info_outline,
      AlertType.tip => Icons.lightbulb_outline,
      AlertType.important => Icons.label_important_outline,
      AlertType.warning => Icons.warning_amber_outlined,
      AlertType.caution => Icons.dangerous_outlined,
    };

    return specType.container(
      child: specType.containerFlex(
        direction: Axis.vertical,
        children: [
          specType.headingFlex(
            direction: Axis.horizontal,
            children: [
              specType.icon(iconType),
              specType.heading(alertType.name),
            ],
          ),
          specType.description(element.textContent.trim()),
        ],
      ),
    );
  }
}
