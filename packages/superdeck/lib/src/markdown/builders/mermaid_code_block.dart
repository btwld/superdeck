import 'package:flutter/material.dart';
import 'package:flutter_mermaid/flutter_mermaid.dart';

import '../../ui/widgets/error_widgets.dart';

final class MermaidCodeBlock extends StatelessWidget {
  final String code;

  const MermaidCodeBlock({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).brightness == Brightness.dark
        ? MermaidStyle.dark()
        : const MermaidStyle();
    final style = baseStyle.copyWith(
      backgroundColor: 0x00000000,
      defaultEdgeStyle: baseStyle.defaultEdgeStyle.copyWith(
        labelColor: baseStyle.defaultNodeStyle.textColor,
      ),
    );

    return MermaidDiagram(
      code: code.trim(),
      style: style,
      errorBuilder: (_, error) =>
          ErrorWidgets.detailed('Unable to render Mermaid diagram', error),
    );
  }
}
