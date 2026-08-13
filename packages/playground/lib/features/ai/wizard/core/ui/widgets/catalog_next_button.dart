import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ui.dart';

class CatalogNextButton extends StatelessWidget {
  const CatalogNextButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SdButton(
          label: 'Continue',
          onPressed: onPressed,
          icon: LucideIcons.arrowRight,
          semanticLabel: 'Next step',
        ),
      ),
    );
  }
}
