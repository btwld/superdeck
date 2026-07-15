import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:remix/remix.dart';

import '../../quick_agent/core/engine/services/generation_progress.dart';
import '../core/ui/ui.dart';

enum WizardGenerationStatusKind { running, completed, failed }

/// Focused, full-screen status content for the terminal generation step.
class WizardGenerationStatus extends StatelessWidget {
  const WizardGenerationStatus({
    super.key,
    required this.kind,
    this.progress = const GenerationProgress(GenerationPhase.idle),
    this.errorMessage,
    this.noticeMessage,
    this.onDismiss,
  });

  final WizardGenerationStatusKind kind;
  final GenerationProgress progress;
  final String? errorMessage;
  final String? noticeMessage;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final highlightedMessage = kind == WizardGenerationStatusKind.failed
        ? errorMessage
        : noticeMessage;
    final highlightedColor = kind == WizardGenerationStatusKind.failed
        ? $danger.resolve(context)
        : $warning.resolve(context);
    final (:icon, :title, :description) = switch (kind) {
      WizardGenerationStatusKind.running => (
        icon: LucideIcons.sparkles,
        title: 'Building your presentation',
        description:
            'Shaping the story, composing each slide, and checking the final deck.',
      ),
      WizardGenerationStatusKind.completed => (
        icon: LucideIcons.circleCheck,
        title: 'Your presentation is ready',
        description: 'The generated slides are ready in this session.',
      ),
      WizardGenerationStatusKind.failed => (
        icon: LucideIcons.triangleAlert,
        title: 'We couldn\'t finish the deck',
        description:
            'Your plan is still here, so you can return and try again.',
      ),
    };

    return Semantics(
      liveRegion: true,
      label: kind == WizardGenerationStatusKind.running
          ? progress.label
          : title,
      child: Container(
        key: ValueKey(kind),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: $surfaceSecondary.resolve(context),
          border: Border.all(color: $border.resolve(context)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                _StatusIcon(icon: icon, running: kind == .running),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [SdHeadline(title), SdBody(description)],
                  ),
                ),
              ],
            ),
            if (kind == WizardGenerationStatusKind.running) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  color: $accent.resolve(context),
                  backgroundColor: $border.resolve(context),
                  semanticsLabel: progress.label,
                ),
              ),
              _GenerationStages(progress: progress),
            ],
            if (highlightedMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: highlightedColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SdCaption(
                  highlightedMessage,
                  style: TextStyler().color(highlightedColor),
                ),
              ),
            if (kind != WizardGenerationStatusKind.running)
              Align(
                alignment: Alignment.centerRight,
                child: SdButton(
                  label: 'Back to deck plan',
                  icon: LucideIcons.arrowLeft,
                  onPressed: onDismiss,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.icon, required this.running});

  final IconData icon;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: $accentSoft.resolve(context),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: running
          ? const SdSpinner(size: SdSpinnerSize.size3)
          : Icon(icon, size: 23, color: $accent.resolve(context)),
    );
  }
}

class _GenerationStages extends StatelessWidget {
  const _GenerationStages({required this.progress});

  final GenerationProgress progress;

  int get _activeIndex => switch (progress.phase) {
    GenerationPhase.generatingOutline || GenerationPhase.idle => 0,
    GenerationPhase.composingSlides => 1,
    GenerationPhase.finalizing || GenerationPhase.generatingThumbnails => 2,
  };

  @override
  Widget build(BuildContext context) {
    const stages = ['Shape the story', 'Compose the slides', 'Polish the deck'];
    final activeIndex = _activeIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        SdTitle(
          progress.label,
          style: TextStyler().fontWeight(FontWeight.w600),
        ),
        for (final (index, label) in stages.indexed)
          _GenerationStage(
            label: label,
            completed: index < activeIndex,
            active: index == activeIndex,
          ),
      ],
    );
  }
}

class _GenerationStage extends StatelessWidget {
  const _GenerationStage({
    required this.label,
    required this.completed,
    required this.active,
  });

  final String label;
  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = completed || active
        ? $accent.resolve(context)
        : $muted.resolve(context).withValues(alpha: 0.55);

    return Row(
      spacing: 10,
      children: [
        Icon(
          completed
              ? LucideIcons.circleCheck
              : active
              ? LucideIcons.circleDot
              : LucideIcons.circle,
          size: 17,
          color: color,
        ),
        SdCaption(
          label,
          style: TextStyler()
              .color(color)
              .fontWeight(active ? FontWeight.w600 : FontWeight.w400),
        ),
      ],
    );
  }
}
