import 'package:flutter/material.dart';
import '../../../core/ui/ui.dart';

/// Initial state displayed before conversation starts.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.input});

  final Widget input;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SdHeadline('What is the presentation about?'),
              const SizedBox(height: 20),
              input,
            ],
          ),
        ),
      ),
    );
  }
}
