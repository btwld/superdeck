import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';

import '../../quick_agent/core/engine/services/generation_progress.dart';
import 'view/loading.dart';

/// Focused progress surface for the deck generation pipeline.
///
/// The command owns the phase state; this widget only translates that state
/// into a live status and a compact outline → slides → finalize stepper.
class GenerationProgressView extends StatelessWidget {
  const GenerationProgressView({required this.phase, super.key});

  final GenerationPhase phase;

  static const _steps = <({GenerationPhase phase, String label})>[
    (phase: GenerationPhase.generatingOutline, label: 'Plan the outline'),
    (phase: GenerationPhase.generatingFinalDeck, label: 'Write the slides'),
    (phase: GenerationPhase.finalizing, label: 'Finalize the deck'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentStep = _stepIndex(phase);
    final foreground = $foreground.resolve(context);
    final muted = $muted.resolve(context);
    final accent = $accent.resolve(context);

    return Semantics(
      liveRegion: true,
      label: 'Generating presentation. ${_phaseLabel(phase)}',
      child: Material(
        key: const ValueKey('generation-progress-view'),
        color: $surfaceSecondary.resolve(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            border: Border.all(color: $border.resolve(context)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(child: IsometricLoading(color: accent)),
              const SizedBox(height: 20),
              Text(
                'Generating your presentation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _phaseLabel(phase),
                  key: ValueKey(phase),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ),
              const SizedBox(height: 24),
              for (final (index, step) in _steps.indexed) ...[
                _GenerationStep(
                  label: step.label,
                  state: index < currentStep
                      ? _GenerationStepState.complete
                      : index == currentStep
                      ? _GenerationStepState.active
                      : _GenerationStepState.pending,
                ),
                if (index != _steps.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static int _stepIndex(GenerationPhase phase) => switch (phase) {
    GenerationPhase.idle || GenerationPhase.generatingOutline => 0,
    GenerationPhase.generatingFinalDeck => 1,
    GenerationPhase.finalizing => 2,
    GenerationPhase.generatingThumbnails => _steps.length,
  };

  static String _phaseLabel(GenerationPhase phase) => switch (phase) {
    GenerationPhase.idle => 'Preparing generation…',
    _ => phase.label,
  };
}

enum _GenerationStepState { complete, active, pending }

class _GenerationStep extends StatelessWidget {
  const _GenerationStep({required this.label, required this.state});

  final String label;
  final _GenerationStepState state;

  @override
  Widget build(BuildContext context) {
    final active = state != _GenerationStepState.pending;
    final color = active
        ? $accent.resolve(context)
        : $muted.resolve(context).withValues(alpha: 0.55);
    final icon = switch (state) {
      _GenerationStepState.complete => Icons.check_circle,
      _GenerationStepState.active => Icons.radio_button_checked,
      _GenerationStepState.pending => Icons.circle_outlined,
    };

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: state == _GenerationStepState.active
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
