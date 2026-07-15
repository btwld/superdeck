import 'package:flutter/material.dart';
import 'package:remix/remix.dart';

import '../../ui/ui.dart';

/// Shared layout for catalog question widgets with a header, body, and CTA.
class CatalogQuestionStep extends StatelessWidget {
  const CatalogQuestionStep({
    super.key,
    required this.question,
    required this.body,
    required this.onSubmit,
    this.description,
    this.canSubmit = true,
  });

  final String question;
  final String? description;
  final Widget body;
  final VoidCallback? onSubmit;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    final column = FlexBoxStyler()
        .column()
        .crossAxisAlignment(.start)
        .spacing(16);

    return column(
      children: [
        SdSectionHeader(heading: question, subheading: description),
        body,
        CatalogNextButton(onPressed: canSubmit ? onSubmit : null),
      ],
    );
  }
}
