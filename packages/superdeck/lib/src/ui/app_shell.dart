import 'package:flutter/material.dart'
    show Icons, Colors, Scaffold, FloatingActionButtonLocation;
import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/src/rendering/slides/slide_thumbnail.dart';
import 'package:superdeck/src/rendering/slides/scaled_app.dart';
import 'package:superdeck/src/ui/panels/comments_panel.dart';
import 'package:superdeck/src/ui/panels/thumbnail_panel.dart';
import 'package:superdeck/src/ui/widgets/icon_button.dart';
import 'package:superdeck/src/ui/widgets/loading_indicator.dart';
import 'package:superdeck/src/utils/constants.dart';
import 'package:superdeck/src/ui/extensions.dart';

import '../deck/deck_controller.dart';
import '../deck/navigation_manager.dart';
import 'panels/bottom_bar.dart';

/// High-level app shell that toggles between
/// small layout (bottom panel) or regular layout (side panel).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NavigationManager(
      child: SplitView(isSmallLayout: context.isSmall, child: child),
    );
  }
}

/// A widget that can lay out the "panel" (thumbnails and possibly notes)
/// either at the bottom (vertical layout) or on the side (horizontal layout).
class SplitView extends StatefulWidget {
  const SplitView({super.key, required this.child, this.isSmallLayout = false});

  final Widget child;
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
      final initialMenuState = deckController.isMenuOpen.value;

      if (initialMenuState) {
        _animationController.value = 1.0;
      }

      // Use effect to listen to menu state changes
      _menuEffectCleanup = effect(() {
        if (!mounted) return;

        final isMenuOpen = deckController.isMenuOpen.value;

        if (isMenuOpen && _animationController.value != 1.0) {
          _animationController.forward();
        } else if (!isMenuOpen && _animationController.value != 0.0) {
          _animationController.reverse();
        }
      });

      // Generate thumbnails on first build only
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          deckController.generateThumbnails(context);
        }
      });
    }
  }

  @override
  void dispose() {
    // Cleanup effect
    _menuEffectCleanup?.call();
    _animationController.dispose();
    super.dispose();
  }

  // Build the panel content (thumbnails + optional comments).
  Widget _buildPanel(BuildContext context) {
    final deck = DeckController.of(context);

    return Watch((context) {
      final currentIndex = deck.currentIndex.value;
      final isNotesOpen = deck.isNotesOpen.value;
      final slides = deck.slides.value;

      // Get current slide from index
      final currentSlide = (currentIndex >= 0 && currentIndex < slides.length)
          ? slides[currentIndex]
          : null;

      /// Common content for thumbnails
      final thumbnailPanel = ThumbnailPanel(
        scrollDirection: widget.isSmallLayout
            ? Axis.horizontal
            : Axis.vertical,
        onItemTap: deck.goToSlide,
        activeIndex: currentSlide?.slideIndex ?? 0,
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

  @override
  Widget build(BuildContext context) {
    final deckController = DeckController.of(context);

    // For small layout, the panel is typically at the bottom (vertical),
    // so we place it in a Column below the main content.
    // For regular layout, place it on the left in a Row.
    return Watch((context) {
      final isMenuOpen = deckController.isMenuOpen.value;
      final isRebuilding = deckController.isRebuilding.value;

      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 9, 9, 9),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniEndFloat,
        floatingActionButton: !isMenuOpen
            ? SDIconButton(
                icon: Icons.menu,
                onPressed: deckController.openMenu,
              )
            : null,

        // Only show bottom bar on small layout (uncomment if needed):
        bottomNavigationBar: SizeTransition(
          axis: Axis.vertical,
          sizeFactor: _curvedAnimation,
          child: const DeckBottomBar(),
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
            // Loading indicator when rebuilding
            if (isRebuilding)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: const Row(
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
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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
