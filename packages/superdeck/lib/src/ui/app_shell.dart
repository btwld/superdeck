import 'package:flutter/material.dart'
    show Icons, Colors, Scaffold, FloatingActionButtonLocation;
import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../deck/deck_controller.dart';
import '../deck/navigation_input_listener.dart';
import '../deck/slide_configuration.dart';
import '../plugins/deck_action.dart';
import '../rendering/slides/scaled_app.dart';
import '../rendering/slides/slide_thumbnail.dart';
import '../utils/constants.dart';
import 'deck_shell_modal.dart';
import 'extensions.dart';
import 'panels/bottom_bar.dart';
import 'panels/comments_panel.dart';
import 'panels/thumbnail_panel.dart';
import 'widgets/icon_button.dart';
import 'widgets/loading_indicator.dart';

/// High-level app shell that toggles between
/// small layout (bottom panel) or regular layout (side panel).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, this.actions = const []});

  final Widget child;
  final List<DeckAction> actions;

  @override
  Widget build(BuildContext context) {
    return DeckShellModalHost(
      child: NavigationInputListener(
        child: SplitView(
          isSmallLayout: context.isSmall,
          actions: actions,
          child: child,
        ),
      ),
    );
  }
}

/// A widget that can lay out the "panel" (thumbnails and possibly notes)
/// either at the bottom (vertical layout) or on the side (horizontal layout).
class SplitView extends StatefulWidget {
  const SplitView({
    super.key,
    required this.child,
    this.actions = const [],
    this.isSmallLayout = false,
  });

  final Widget child;
  final List<DeckAction> actions;
  final bool isSmallLayout;

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 200);
  late final AnimationController _animationController;
  late final Animation<double> _curvedAnimation;
  bool _isInitialized = false;
  EffectCleanup? _menuEffectCleanup;
  EffectCleanup? _thumbnailWarmupEffectCleanup;
  bool _thumbnailWarmupFrameQueued = false;
  String? _lastThumbnailWarmupSignature;
  String? _pendingThumbnailWarmupSignature;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
      value: 0.0, // Will be set in didChangeDependencies
    );
    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only run initialization once
    if (!_isInitialized) {
      _isInitialized = true;

      final deckController = DeckController.of(context);

      // Set initial animation value based on menu state
      final initialMenuState = deckController.presentation.isMenuOpen.value;

      if (initialMenuState) {
        _animationController.value = 1.0;
      }

      // Use effect to listen to menu state changes
      _menuEffectCleanup = effect(() {
        if (!mounted) return;

        final isMenuOpen = deckController.presentation.isMenuOpen.value;

        if (isMenuOpen && _animationController.value != 1.0) {
          _animationController.forward();
        } else if (!isMenuOpen && _animationController.value != 0.0) {
          _animationController.reverse();
        }
      });

      _thumbnailWarmupEffectCleanup = effect(() {
        if (!mounted) return;

        final signature = _thumbnailWarmupSignature(
          deckController.slides.value,
        );
        if (signature == null) {
          _lastThumbnailWarmupSignature = null;
          _pendingThumbnailWarmupSignature = null;
          return;
        }
        if (signature == _lastThumbnailWarmupSignature) {
          return;
        }

        _pendingThumbnailWarmupSignature = signature;
        _scheduleThumbnailWarmup(deckController);
      });
    }
  }

  @override
  void dispose() {
    // Cleanup effect
    _menuEffectCleanup?.call();
    _thumbnailWarmupEffectCleanup?.call();
    _thumbnailWarmupFrameQueued = false;
    _pendingThumbnailWarmupSignature = null;
    _animationController.dispose();
    super.dispose();
  }

  void _scheduleThumbnailWarmup(DeckController deckController) {
    if (_thumbnailWarmupFrameQueued) return;

    _thumbnailWarmupFrameQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _thumbnailWarmupFrameQueued = false;
      if (!mounted) return;

      final pendingSignature = _pendingThumbnailWarmupSignature;
      if (pendingSignature == null ||
          pendingSignature == _lastThumbnailWarmupSignature) {
        return;
      }

      final currentSlides = deckController.slides.value;
      final currentSignature = _thumbnailWarmupSignature(currentSlides);
      if (currentSignature == null) {
        _lastThumbnailWarmupSignature = null;
        _pendingThumbnailWarmupSignature = null;
        return;
      }

      if (currentSignature != pendingSignature) {
        _pendingThumbnailWarmupSignature = currentSignature;
        _scheduleThumbnailWarmup(deckController);
        return;
      }

      deckController.presentation.generateThumbnails(context, currentSlides);
      _lastThumbnailWarmupSignature = currentSignature;
      if (_pendingThumbnailWarmupSignature == currentSignature) {
        _pendingThumbnailWarmupSignature = null;
      }
    });
  }

  String? _thumbnailWarmupSignature(List<SlideConfiguration> slides) {
    if (slides.isEmpty) return null;
    return slides
        .map((slide) => '${slide.key}:${slide.thumbnailKey}')
        .join('|');
  }

  // Build the panel content (thumbnails + optional comments).
  Widget _buildPanel(BuildContext context) {
    final deck = DeckController.of(context);
    final presentation = deck.presentation;

    return Watch((context) {
      final isNotesOpen = presentation.isNotesOpen.value;
      final slides = deck.slides.value;
      final currentSlide = presentation.currentSlide.value;

      /// Common content for thumbnails
      final thumbnailPanel = ThumbnailPanel(
        scrollDirection: widget.isSmallLayout ? Axis.horizontal : Axis.vertical,
        onItemTap: presentation.goToSlide,
        activeIndex:
            currentSlide?.slideIndex ?? presentation.currentIndex.value,
        itemBuilder: (index, selected) {
          return SlideThumbnail(selected: selected, slide: slides[index]);
        },
        itemCount: slides.length,
      );

      /// Comments panel (shown only if notes are open)
      final commentsPanel = isNotesOpen
          ? CommentsPanel(comments: currentSlide?.comments ?? [])
          : const SizedBox();

      // For small layout, show the panel horizontally (i.e., row) if it's at the BOTTOM,
      // or for a big layout, we might do a column if it's on the SIDE.
      // This is somewhat reversed based on your preference, so adjust as needed.
      if (widget.isSmallLayout) {
        // Panel at bottom => put them side-by-side in a Row
        return Row(
          children: [
            !isNotesOpen
                ? Expanded(child: thumbnailPanel)
                : Expanded(child: commentsPanel),
          ],
        );
      } else {
        // Panel on the side => put them in a Column
        return Column(
          children: [
            Expanded(flex: 3, child: thumbnailPanel),
            if (isNotesOpen) Expanded(flex: 1, child: commentsPanel),
          ],
        );
      }
    });
  }

  Widget? _buildFloatingAction({
    required DeckController deckController,
    required bool isMenuOpen,
  }) {
    if (isMenuOpen) {
      return null;
    }

    return SDIconButton(
      icon: Icons.menu,
      onPressed: () {
        FocusManager.instance.primaryFocus?.unfocus();
        deckController.presentation.openMenu();
      },
      semanticLabel: 'Open menu',
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckController = DeckController.of(context);

    // For small layout, the panel is typically at the bottom (vertical),
    // so we place it in a Column below the main content.
    // For regular layout, place it on the left in a Row.
    return Watch((context) {
      final isMenuOpen = deckController.presentation.isMenuOpen.value;
      final isBuildActive = deckController.session.isBuildActive.value;
      final buildFailure = deckController.session.buildFailure.value;

      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 9, 9, 9),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        floatingActionButton: _buildFloatingAction(
          deckController: deckController,
          isMenuOpen: isMenuOpen,
        ),

        bottomNavigationBar: SizeTransition(
          axis: Axis.vertical,
          sizeFactor: _curvedAnimation,
          child: DeckBottomBar(actions: widget.actions),
        ),

        // Body changes layout based on [isSmallLayout].
        body: Stack(
          children: [
            widget.isSmallLayout
                ? Column(
                    children: [
                      // Main slide content
                      Expanded(
                        child: Center(
                          child: ScaledWidget(
                            targetSize: kResolution,
                            child: widget.child,
                          ),
                        ),
                      ),
                      // Animated bottom panel
                      SizeTransition(
                        axis: Axis.vertical,
                        sizeFactor: _curvedAnimation,
                        child: SizedBox(
                          height: 200,
                          child: _buildPanel(context),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Animated side panel
                      SizeTransition(
                        axis: Axis.horizontal,
                        sizeFactor: _curvedAnimation,
                        child: SizedBox(
                          width: 300,
                          child: _buildPanel(context),
                        ),
                      ),
                      // Main slide content
                      Expanded(
                        child: Center(
                          child: ScaledWidget(
                            targetSize: kResolution,
                            child: widget.child,
                          ),
                        ),
                      ),
                    ],
                  ),
            if (isBuildActive || buildFailure != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: buildFailure == null
                          ? Colors.white24
                          : Colors.redAccent.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  child: isBuildActive
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: IsometricLoading(),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Rebuilding...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Build failed',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              buildFailure!.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
