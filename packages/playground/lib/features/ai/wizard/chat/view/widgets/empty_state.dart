import 'package:flutter/material.dart';

import '../../../core/ui/ui.dart';

/// Initial state displayed before conversation starts.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.input, this.errorMessage});

  final Widget input;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              const SdHeadline('What is the presentation about?'),
              const SizedBox(height: 20),
              if (errorMessage case final message?) ...[
                Container(
                  padding: const .all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: .circular(12),
                  ),
                  width: .infinity,
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              input,
            ],
          ),
        ),
      ),
    );
  }
}
