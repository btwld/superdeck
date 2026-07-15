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
    this.progress = const GenerationProgress(.idle),
    this.errorMessage,
    this.noticeMessage,
    this.slideCount,
    this.failedSlideCount = 0,
    this.artworkCount = 0,
    this.failedArtworkCount = 0,
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
  final int artworkCount;
  final int failedArtworkCount;
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
    final highlightedMessage = kind == .failed ? errorMessage : noticeMessage;
    final highlightedColor = kind == .failed
        ? $danger.resolve(context)
        : $warning.resolve(context);
    final (:icon, :title, :description) = switch (kind) {
      .running => (
        icon: LucideIcons.sparkles,
        title: progress.phase == .generatingOutline
            ? 'Creating your outline'
            : 'Building your presentation',
        description: progress.phase == .generatingOutline
            ? 'Shaping a clear story before you review and approve it.'
            : 'Composing the approved story and checking each slide.',
      ),
      .completed => (
        icon: LucideIcons.circleCheck,
        title: failedSlideCount > 0
            ? 'Your presentation is almost ready'
            : 'Your presentation is ready',
        description: failedSlideCount > 0
            ? 'Keep the finished slides and retry only the ones that need attention.'
            : failedArtworkCount > 0
            ? 'The deck is ready, with a text-first fallback where artwork was unavailable.'
            : 'Open the deck now, or return to the outline for changes.',
      ),
      .failed => (
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
      label: kind == .running ? progress.label : title,
      child: Container(
        key: ValueKey(kind),
        padding: const .all(28),
        decoration: BoxDecoration(
          color: $surfaceSecondary.resolve(context),
          border: .all(color: $border.resolve(context)),
          borderRadius: .circular(20),
        ),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 24,
          children: [
            Row(
              crossAxisAlignment: .start,
              spacing: 16,
              children: [
                _StatusIcon(icon: icon, running: kind == .running),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 6,
                    children: [SdHeadline(title), SdBody(description)],
                  ),
                ),
              ],
            ),
            if (kind == .running) ...[
              ClipRRect(
                borderRadius: .circular(999),
                child: LinearProgressIndicator(
                  value: _progressValue(progress),
                  backgroundColor: $border.resolve(context),
                  color: $accent.resolve(context),
                  minHeight: 5,
                  semanticsLabel: progress.label,
                ),
              ),
              _GenerationStages(progress: progress),
              Row(
                mainAxisAlignment: .spaceBetween,
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
            if (kind == .completed && slideCount != null && elapsed != null)
              SdTitle(
                '$slideCount ${slideCount == 1 ? 'slide' : 'slides'} • '
                '${artworkCount > 0 ? '$artworkCount '
                          '${artworkCount == 1 ? 'artwork' : 'artworks'} • ' : ''}'
                '${elapsed!.inSeconds}s',
              ),
            if (highlightedMessage != null)
              Container(
                padding: const .all(14),
                decoration: BoxDecoration(
                  color: highlightedColor.withValues(alpha: 0.08),
                  borderRadius: .circular(12),
                ),
                width: .infinity,
                child: SdCaption(
                  highlightedMessage,
                  style: TextStyler().color(highlightedColor),
                ),
              ),
            if (kind == .failed)
              Wrap(
                alignment: .end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  TextButton(onPressed: onBack, child: Text(backLabel)),
                  SdButton(
                    label: 'Retry',
                    onPressed: onRetry,
                    icon: LucideIcons.refreshCw,
                  ),
                ],
              ),
            if (kind == .completed)
              Wrap(
                alignment: .end,
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
                    onPressed: onPresent,
                    icon: LucideIcons.play,
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
    .idle => 0.05,
    .generatingOutline => 0.15,
    .generatingImages => _imageProgress(progress),
    .composingSlides => _compositionProgress(progress),
    .finalizing => 0.94,
    .generatingThumbnails => 0.98,
  };
}

double _imageProgress(GenerationProgress progress) {
  final completed = progress.completedItems;
  final total = progress.totalItems;
  if (completed == null || total == null || total < 1) return 0.22;

  return (0.2 + 0.14 * (completed / total)).clamp(0.2, 0.34);
}

double _compositionProgress(GenerationProgress progress) {
  final slideIndex = progress.slideIndex;
  final slideCount = progress.slideCount;
  if (slideIndex != null && slideCount != null && slideCount > 0) {
    return (0.35 + 0.55 * (slideIndex / slideCount)).clamp(0.35, 0.9);
  }

  final sectionIndex = progress.sectionIndex;
  final sectionCount = progress.sectionCount;
  if (sectionIndex != null && sectionCount != null && sectionCount > 0) {
    return (0.35 + 0.55 * (sectionIndex / sectionCount)).clamp(0.35, 0.9);
  }

  return 0.38;
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.icon, required this.running});

  final IconData icon;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: $accentSoft.resolve(context),
        borderRadius: .circular(14),
      ),
      width: 48,
      height: 48,
      child: running
          ? const SdSpinner(size: .size3)
          : Icon(icon, size: 23, color: $accent.resolve(context)),
    );
  }
}

class _GenerationStages extends StatelessWidget {
  const _GenerationStages({required this.progress});

  final GenerationProgress progress;

  int get _activeIndex => switch (progress.phase) {
    .generatingOutline || .idle => 0,
    .generatingImages => 1,
    .composingSlides => 2,
    .finalizing || .generatingThumbnails => 3,
  };

  @override
  Widget build(BuildContext context) {
    const stages = [
      'Shape the story',
      'Create the artwork',
      'Compose the slides',
      'Polish the deck',
    ];
    final activeIndex = _activeIndex;

    return Column(
      crossAxisAlignment: .start,
      spacing: 12,
      children: [
        SdTitle(progress.label, style: TextStyler().fontWeight(.w600)),
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
          style: TextStyler().color(color).fontWeight(active ? .w600 : .w400),
        ),
      ],
    );
  }
}
