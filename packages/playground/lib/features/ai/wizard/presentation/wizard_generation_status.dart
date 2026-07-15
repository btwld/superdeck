import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:remix/remix.dart';

import '../../quick_agent/core/engine/services/generation_progress.dart';
import '../core/ui/ui.dart';

enum WizardGenerationStatusKind { running, completed, failed }

/// Focused, full-screen feedback for generation progress and outcomes.
class WizardGenerationStatus extends StatelessWidget {
  const WizardGenerationStatus({
    super.key,
    required this.kind,
    this.progress = const GenerationProgress(GenerationPhase.idle),
    this.errorMessage,
    this.noticeMessage,
    this.slideCount,
    this.failedSlideCount = 0,
    this.elapsed,
    this.planAvailable = false,
    this.onCancel,
    this.onRetry,
    this.onBack,
    this.backLabel = 'Edit outline',
    this.onPresent,
    this.onRetryFailed,
    this.onEditOutline,
    this.onStartOver,
  });

  final WizardGenerationStatusKind kind;
  final GenerationProgress progress;
  final String? errorMessage;
  final String? noticeMessage;
  final int? slideCount;
  final int failedSlideCount;
  final Duration? elapsed;
  final bool planAvailable;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final String backLabel;
  final VoidCallback? onPresent;
  final VoidCallback? onRetryFailed;
  final VoidCallback? onEditOutline;
  final VoidCallback? onStartOver;

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
        title: progress.phase == GenerationPhase.generatingOutline
            ? 'Creating your outline'
            : 'Building your presentation',
        description: progress.phase == GenerationPhase.generatingOutline
            ? 'Shaping a clear story before you review and approve it.'
            : 'Composing the approved story and checking each slide.',
      ),
      WizardGenerationStatusKind.completed => (
        icon: LucideIcons.circleCheck,
        title: failedSlideCount > 0
            ? 'Your presentation is almost ready'
            : 'Your presentation is ready',
        description: failedSlideCount > 0
            ? 'Keep the finished slides and retry only the ones that need attention.'
            : 'Open the deck now, or return to the outline for changes.',
      ),
      WizardGenerationStatusKind.failed => (
        icon: LucideIcons.triangleAlert,
        title: planAvailable
            ? 'We couldn\'t finish the deck'
            : 'We couldn\'t create the outline',
        description: planAvailable
            ? 'Your plan is still here, so you can return and try again.'
            : 'Your setup is still here, so you can retry or make a new selection.',
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
                  value: _progressValue(progress),
                  minHeight: 5,
                  color: $accent.resolve(context),
                  backgroundColor: $border.resolve(context),
                  semanticsLabel: progress.label,
                ),
              ),
              _GenerationStages(progress: progress),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 16,
                children: [
                  const SdCaption('Usually 20–30 seconds'),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
            ],
            if (kind == WizardGenerationStatusKind.completed &&
                slideCount != null &&
                elapsed != null)
              SdTitle(
                '$slideCount ${slideCount == 1 ? 'slide' : 'slides'} • '
                '${elapsed!.inSeconds}s',
              ),
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
            if (kind == WizardGenerationStatusKind.failed)
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  TextButton(onPressed: onBack, child: Text(backLabel)),
                  SdButton(
                    label: 'Retry',
                    icon: LucideIcons.refreshCw,
                    onPressed: onRetry,
                  ),
                ],
              ),
            if (kind == WizardGenerationStatusKind.completed)
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  TextButton(
                    onPressed: onStartOver,
                    child: const Text('Start over'),
                  ),
                  OutlinedButton(
                    onPressed: onEditOutline,
                    child: const Text('Edit outline'),
                  ),
                  if (failedSlideCount > 0)
                    OutlinedButton.icon(
                      onPressed: onRetryFailed,
                      icon: const Icon(LucideIcons.refreshCw, size: 17),
                      label: Text(
                        'Retry $failedSlideCount '
                        '${failedSlideCount == 1 ? 'slide' : 'slides'}',
                      ),
                    ),
                  SdButton(
                    label: 'Present deck',
                    icon: LucideIcons.play,
                    onPressed: onPresent,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

double _progressValue(GenerationProgress progress) {
  return switch (progress.phase) {
    GenerationPhase.idle => 0.05,
    GenerationPhase.generatingOutline => 0.15,
    GenerationPhase.composingSlides => _compositionProgress(progress),
    GenerationPhase.finalizing => 0.94,
    GenerationPhase.generatingThumbnails => 0.98,
  };
}

double _compositionProgress(GenerationProgress progress) {
  final slideIndex = progress.slideIndex;
  final slideCount = progress.slideCount;
  if (slideIndex != null && slideCount != null && slideCount > 0) {
    return (0.2 + 0.7 * (slideIndex / slideCount)).clamp(0.2, 0.9);
  }

  final sectionIndex = progress.sectionIndex;
  final sectionCount = progress.sectionCount;
  if (sectionIndex != null && sectionCount != null && sectionCount > 0) {
    return (0.2 + 0.7 * (sectionIndex / sectionCount)).clamp(0.2, 0.9);
  }
  return 0.25;
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
