import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:remix/remix.dart';
import '../../../presentation/view/loading.dart';
import '../../../core/ui/ui.dart';

/// Typing indicator - shows only when AI is thinking.
class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key, required this.isThinking});

  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    if (!isThinking) return const SizedBox.shrink();

    return RowBox(
      style: FlexBoxStyler().spacing(8).padding(.bottom(12)),
      children: [
        SizedBox(
          width: 25,
          height: 25,
          child: IsometricLoading(color: $muted.resolve(context)),
        ),
        StyledText(
          'Thinking...',
          style: TextStyler()
              .color($muted.resolve(context))
              .style($labelSmall.mix()),
        ),
      ],
    );
  }
}

/// Shared surfaces panel used by AI conversation screens.
class AiSurfacesPanel extends StatelessWidget {
  const AiSurfacesPanel({
    super.key,
    required this.controller,
    required this.surfaceIds,
    required this.isThinking,
    this.errorMessage,
    this.inputWidget,
  });

  final SurfaceController? controller;
  final List<String> surfaceIds;
  final bool isThinking;
  final String? errorMessage;

  /// Optional input displayed below the active Wizard surface.
  final Widget? inputWidget;

  @override
  Widget build(BuildContext context) {
    final ids = surfaceIds;
    final thinking = isThinking;

    final flex = FlexBoxStyler()
        .spacing(16)
        .column()
        .mainAxisSize(MainAxisSize.min)
        .marginAll(24);

    Widget? surfacesWidget;
    if (controller case final resolvedController?) {
      if (ids.isNotEmpty) {
        surfacesWidget = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: SdTokens.motionMedium,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: AnimatedOpacity(
                opacity: thinking ? 0.5 : 1.0,
                duration: SdTokens.motionFast,
                child: flex(
                  key: ValueKey(ids.last),
                  children: ids.map((surfaceId) {
                    return IgnorePointer(
                      key: ValueKey('ignore_$surfaceId'),
                      ignoring: thinking,
                      child: Surface(
                        key: ValueKey('surface_$surfaceId'),
                        surfaceContext: resolvedController.contextFor(
                          surfaceId,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      }
    }

    final errorWidget = errorMessage == null
        ? null
        : Padding(
            padding: const EdgeInsets.all(24),
            child: SdCallout(
              text: errorMessage,
              icon: LucideIcons.triangleAlert,
            ),
          );

    if (inputWidget == null) {
      return surfacesWidget ?? errorWidget ?? const SizedBox.shrink();
    }

    return SizedBox(
      width: .infinity,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [?surfacesWidget, ?errorWidget],
                ),
              ),
            ),
          ),
          TypingBubble(isThinking: thinking),
          inputWidget!,
        ],
      ),
    );
  }
}
