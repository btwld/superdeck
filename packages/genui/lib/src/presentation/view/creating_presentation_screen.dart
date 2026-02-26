import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remix/remix.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';
import '../../debug_logger.dart';
import '../../viewmodel_scope.dart';
import '../../routes.dart';
import '../../ui/ui.dart';
import '../../utils/deck_style_service.dart';
import './loading.dart';
import '../../ai/services/generation_progress.dart';
import '../presentation_viewmodel.dart';
import '../thumbnail_preview_service.dart';

/// Rotating phrases shown while slides are being generated.
const _loadingPhrases = [
  'Building the content...',
  'Designing your slides...',
  'Crafting your presentation...',
  'Bringing your ideas to life...',
  'Generating visuals...',
  'Composing your message...',
  'Arranging elements...',
  'Preparing your deck...',
  'Making it presentable...',
  'Polishing your slides...',
];

/// Loading screen displayed during presentation generation.
///
/// Shows an animated loading indicator with rotating status messages
/// while the AI generates the presentation. After generation succeeds,
/// shows a thumbnail preview grid before navigating to the full viewer.
class CreatingPresentationScreen extends StatefulWidget {
  const CreatingPresentationScreen({super.key});

  @override
  State<CreatingPresentationScreen> createState() =>
      _CreatingPresentationScreenState();
}

class _CreatingPresentationScreenState
    extends State<CreatingPresentationScreen> {
  int _currentPhraseIndex = 0;
  Timer? _timer;

  /// Guards against multiple navigation callbacks being scheduled.
  bool _navigated = false;

  /// The epoch at which thumbnail generation was started, or null if not started.
  /// Compared against viewModel.thumbnailEpoch to detect cancellation.
  int? _thumbnailEpoch;

  @override
  void initState() {
    super.initState();
    _startPhraseTimer();
  }

  void _startPhraseTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentPhraseIndex++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _startThumbnailGeneration(PresentationViewModel viewModel) {
    final epoch = viewModel.thumbnailEpoch;
    if (_thumbnailEpoch == epoch) return;
    _thumbnailEpoch = epoch;

    final style = viewModel.result.value?.style;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final generationContext = context;
      if (!generationContext.mounted) return;
      try {
        // Load the deck that was just written by the generation pipeline
        final configuration = DeckConfiguration();
        final deckService = DeckService(configuration: configuration);
        final deck = await deckService.loadDeck();

        if (!generationContext.mounted || viewModel.thumbnailEpoch != epoch) {
          return;
        }

        final service = ThumbnailPreviewService();
        await service.generatePreviews(
          context: generationContext,
          slides: deck.slides,
          style: style,
          onThumbnailCaptured: (slideIndex, imageBytes) {
            viewModel.addThumbnailPreview(slideIndex, imageBytes, epoch: epoch);
          },
          isCancelled: () =>
              !generationContext.mounted || viewModel.thumbnailEpoch != epoch,
        );
        if (generationContext.mounted && viewModel.thumbnailEpoch == epoch) {
          viewModel.finishThumbnailGeneration(epoch: epoch);
        }
      } catch (e, stack) {
        debugLog.error('THUMBNAIL', e, stack);
        if (generationContext.mounted && viewModel.thumbnailEpoch == epoch) {
          viewModel.finishThumbnailGeneration(epoch: epoch);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PresentationViewModel>();

    return Watch((context) {
      final status = viewModel.status.value;

      switch (status) {
        case GenerationStatus.success:
          // Navigate on next frame to avoid build-during-build
          // Use _navigated guard to prevent multiple callbacks being queued
          if (!_navigated) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final style = viewModel.result.value?.style;
                DeckStyleService.setStyle(style);
                context.go(GenUiRoutes.presentation, extra: {'style': style});
              }
            });
          }
          return _buildLoadingUI(context);

        case GenerationStatus.preview:
          _startThumbnailGeneration(viewModel);
          return _buildPreviewUI(context, viewModel);

        case GenerationStatus.error:
          return _buildErrorUI(
            context,
            error: viewModel.error.value,
            onRetry: () {
              _navigated = false;
              _thumbnailEpoch = null;
              viewModel.retry();
            },
            onCancel: () {
              viewModel.reset();
              context.go(GenUiRoutes.chat);
            },
          );

        case GenerationStatus.generating:
          return _buildLoadingUI(context);

        case GenerationStatus.idle:
          // If idle, redirect to chat - reset is handled before generation starts
          // Use _navigated guard to prevent multiple callbacks being queued
          if (!_navigated) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go(GenUiRoutes.chat);
              }
            });
          }
          return _buildLoadingUI(context);
      }
    });
  }

  Widget _buildPreviewUI(
    BuildContext context,
    PresentationViewModel viewModel,
  ) {
    return Scaffold(
      backgroundColor: FortalTokens.gray1.resolve(context),
      body: Column(
        children: [
          // Header with title and action button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: Watch((context) {
                    final thumbnails = viewModel.thumbnailPreviews.value;
                    final phase = viewModel.phase.value;
                    final isGenerating =
                        phase == GenerationPhase.generatingThumbnails;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SdHeadline('Presentation Preview'),
                        const SizedBox(height: 4),
                        Text(
                          isGenerating
                              ? 'Generating previews (${thumbnails.length})...'
                              : '${thumbnails.length} slides ready',
                          style: TextStyle(
                            color: FortalTokens.gray9.resolve(context),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                Watch((context) {
                  final thumbnails = viewModel.thumbnailPreviews.value;
                  return SdButton(
                    label: 'View Presentation',
                    icon: Icons.slideshow,
                    onPressed: thumbnails.isNotEmpty
                        ? () => viewModel.proceedToPresentation()
                        : null,
                  );
                }),
              ],
            ),
          ),

          // Thumbnail grid
          Expanded(
            child: Watch((context) {
              final thumbnails = viewModel.thumbnailPreviews.value;
              final phase = viewModel.phase.value;
              final isGenerating =
                  phase == GenerationPhase.generatingThumbnails;

              if (thumbnails.isEmpty && isGenerating) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IsometricLoading(
                        color: FortalTokens.gray8.resolve(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Rendering slide previews...',
                        style: TextStyle(
                          color: FortalTokens.gray9.resolve(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  childAspectRatio: 16 / 9,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: thumbnails.length + (isGenerating ? 1 : 0),
                itemBuilder: (context, index) {
                  // Loading placeholder for the next slide being generated
                  if (index >= thumbnails.length) {
                    return Container(
                      decoration: BoxDecoration(
                        color: FortalTokens.gray3.resolve(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: IsometricLoading(
                            color: FortalTokens.gray6.resolve(context),
                          ),
                        ),
                      ),
                    );
                  }

                  final (slideIndex, imageBytes) = thumbnails[index];
                  return _ThumbnailPreviewCard(
                    imageBytes: imageBytes,
                    slideIndex: slideIndex,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingUI(BuildContext context) {
    final viewModel = context.read<PresentationViewModel>();
    final flexBoxStyler = StackBoxStyler().alignment(.center).paddingAll(24);

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

    return Scaffold(
      backgroundColor: FortalTokens.gray1.resolve(context),
      body: flexBoxStyler(
        children: [
          Center(
            child: IsometricLoading(color: FortalTokens.gray8.resolve(context)),
          ),
          Align(
            alignment: .bottomCenter,
            child: Watch((context) {
              // Use progress message from ViewModel, fall back to rotating phrases
              final progressMsg = viewModel.progressMessage.value;
              final displayText = progressMsg.isNotEmpty
                  ? progressMsg
                  : _loadingPhrases[_currentPhraseIndex %
                        _loadingPhrases.length];
              return sentence(displayText);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI(
    BuildContext context, {
    String? error,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    final container = FlexBoxStyler()
        .column()
        .mainAxisAlignment(.center)
        .crossAxisAlignment(.center)
        .spacing(24)
        .paddingAll(48);

    final message = TextStyler()
        .style(FortalTokens.text3.mix())
        .color(FortalTokens.gray11())
        .textAlign(.center);

    final buttonRow = FlexBoxStyler().row().spacing(16);

    return Scaffold(
      backgroundColor: FortalTokens.gray1.resolve(context),
      body: Center(
        child: container(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: FortalTokens.gray8.resolve(context),
            ),
            SdHeadline('Generation Failed'),
            message(error ?? 'An unexpected error occurred'),
            buttonRow(
              children: [
                SdButton(
                  label: 'Go Back',
                  icon: Icons.arrow_back,
                  onPressed: onCancel,
                ),
                SdButton(
                  label: 'Retry',
                  icon: Icons.refresh,
                  onPressed: onRetry,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A card displaying a single slide thumbnail preview.
class _ThumbnailPreviewCard extends StatelessWidget {
  const _ThumbnailPreviewCard({
    required this.imageBytes,
    required this.slideIndex,
  });

  final Uint8List imageBytes;
  final int slideIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FortalTokens.gray4.resolve(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(imageBytes, fit: BoxFit.cover, gaplessPlayback: true),
            // Slide number badge
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${slideIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
