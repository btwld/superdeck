import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';
import '../../../core/ui/ui.dart';
import '../../../presentation/view/loading.dart';

/// Initial state displayed before conversation starts.
///
/// Shows a welcome message with the app logo and example prompts
/// to help users get started with presentation generation.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.onSuggestionTap});

  /// Called when a suggestion chip is tapped, with the suggestion text.
  final ValueChanged<String>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    // Unique: text3 + gray10 (slightly lighter than SdBody)
    final subtitleStyle = TextStyler()
        .style($paragraphMedium.mix())
        .color($muted());

    final suggestionsContainer = FlexBoxStyler()
        .column()
        .crossAxisAlignment(.start)
        .spacing(12);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(80, 80),
              painter: IsometricLogoPainter(
                colors: [
                  $muted.resolve(context),
                  $muted.resolve(context).withValues(alpha: 0.7),
                  $muted.resolve(context).withValues(alpha: 0.4),
                  $muted.resolve(context).withValues(alpha: 0.2),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SdHeadline('Create stunning presentations'),
            const SizedBox(height: 8),
            subtitleStyle(
              'Describe your idea and I\'ll design the slides for you',
            ),
            const SizedBox(height: 40),
            suggestionsContainer(
              children: [
                SdHint('Try asking something like:'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in [
                      'Startup pitch deck',
                      'Sales report Q4',
                      'Team onboarding',
                    ])
                      HeroButton(
                        label: suggestion,
                        variant: .outline,
                        size: .sm,
                        style: .new().variant(
                          HeroButtonVariant.outline,
                          .new().color($background()).foregroundColor($muted()),
                        ),
                        onPressed: () => onSuggestionTap?.call(suggestion),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
