import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remix/remix.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../stores/ai_store.dart';
import 'core/ai/services/generation_progress.dart';
import 'core/ui/ui.dart';
import 'presentation/view/loading.dart';

/// Full-screen progress display for AI generation.
///
/// Shown as a pushed route while [AiStore] is generating. Automatically pops
/// when generation finishes (success or error) so the editor is visible again.
class AiProgressScreen extends StatefulWidget {
  const AiProgressScreen({super.key});

  @override
  State<AiProgressScreen> createState() => _AiProgressScreenState();
}

class _AiProgressScreenState extends State<AiProgressScreen> {
  EffectCleanup? _cleanup;

  @override
  void initState() {
    super.initState();
    // Pop when generation is no longer in progress.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<AiStore>();
      _cleanup = effect(() {
        final generating = store.isGenerating.value;
        if (!generating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).maybePop();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _cleanup?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<AiStore>();

    return Scaffold(
      backgroundColor: FortalTokens.gray1.resolve(context),
      body: Watch((context) {
        final error = store.error.value;
        if (error != null) {
          return _buildError(context, error);
        }
        final phase = store.phase.value;
        final imageProgress = store.imageProgress.value;
        return _buildLoading(context, phase, imageProgress);
      }),
    );
  }

  Widget _buildLoading(
    BuildContext context,
    GenerationPhase phase,
    ImageGenerationProgress? imageProgress,
  ) {
    final label = imageProgress != null &&
            phase == GenerationPhase.generatingImages
        ? '${phase.label} (${imageProgress.completed}/${imageProgress.total})'
        : phase.label;

    final sentence = TextStyler()
        .style(FortalTokens.text2.mix())
        .color(FortalTokens.gray9())
        .wrap(
          WidgetModifierConfig.box(
            BoxStyler()
                .padding(.horizontal(12).vertical(6))
                .borderRadius(.circular(6))
                .color(FortalTokens.gray3()),
          ),
        );

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: IsometricLoading(color: FortalTokens.gray8.resolve(context)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: sentence(label),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: FortalTokens.gray8.resolve(context),
            ),
            SdHeadline('Generation Failed'),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: FortalTokens.gray9.resolve(context)),
            ),
            SdButton(
              label: 'Close',
              icon: Icons.close,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
