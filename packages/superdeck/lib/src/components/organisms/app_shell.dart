import 'package:flutter/material.dart';
import 'package:superdeck/src/components/atoms/slide_thumbnail.dart';
import 'package:superdeck/src/components/molecules/scaled_app.dart';
import 'package:superdeck/src/components/organisms/comments_panel.dart';
import 'package:superdeck/src/components/organisms/thumbnail_panel.dart';
import 'package:superdeck/src/modules/common/helpers/constants.dart';
import 'package:superdeck/src/modules/common/helpers/utils.dart';
import 'package:superdeck/src/modules/slide_capture/thumbnail_controller.dart';

import '../../modules/deck/deck_controller.dart';
import '../../modules/navigation/navigation_controller.dart';
import '../molecules/bottom_bar.dart';
import 'keyboard_shortcuts.dart';

/// High-level app shell that toggles between
/// small layout (bottom panel) or regular layout (side panel).
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationController.of(context);

    return KeyboardShortcuts(
      child: SplitView(
        isOpen: navigation.isMenuOpen,
        isSmallLayout: context.isSmall,
        child: child,
      ),
    );
  }
}

/// A widget that can lay out the "panel" (thumbnails and possibly notes)
/// either at the bottom (vertical layout) or on the side (horizontal layout).
class SplitView extends StatefulWidget {
  const SplitView({
    super.key,
    required this.isOpen,
    required this.child,
    this.isSmallLayout = false,
  });

  final Widget child;
  final bool isOpen;
  final bool isSmallLayout;

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 200);
  late final AnimationController _animationController;
  late final Animation<double> _curvedAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
      value: widget.isOpen ? 1.0 : 0.0,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deckController = DeckController.of(context);
      ThumbnailController.of(context).generateThumbnails(
        deckController.slides,
        context,
      );
    });
  }

  @override
  void didUpdateWidget(covariant SplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Build the panel content (thumbnails + optional comments).
  Widget _buildPanel(BuildContext context) {
    final navigation = NavigationController.of(context);
    final deckController = DeckController.of(context);

    final currentSlide = navigation.currentSlide;
    final isNotesOpen = navigation.isNotesOpen;

    /// Common content for thumbnails
    final thumbnailPanel = ThumbnailPanel(
      scrollDirection: widget.isSmallLayout ? Axis.horizontal : Axis.vertical,
      onItemTap: navigation.goToSlide,
      activeIndex: currentSlide.slideIndex,
      itemBuilder: (index, selected) {
        return SlideThumbnail(
          selected: selected,
          slide: deckController.slides[index],
        );
      },
      itemCount: deckController.slides.length,
    );

    /// Comments panel (shown only if notes are open)
    final commentsPanel = isNotesOpen
        ? CommentsPanel(comments: currentSlide.comments)
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
          Expanded(
            flex: 3,
            child: thumbnailPanel,
          ),
          if (isNotesOpen)
            Expanded(
              flex: 1,
              child: commentsPanel,
            ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationController.of(context);
    final isMenuOpen = navigation.isMenuOpen;

    // For small layout, the panel is typically at the bottom (vertical),
    // so we place it in a Column below the main content.
    // For regular layout, place it on the left in a Row.
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 9, 9, 9),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: !isMenuOpen
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: navigation.openMenu,
            )
          : null,

      // Only show bottom bar on small layout (uncomment if needed):
      bottomNavigationBar: SizeTransition(
        axis: Axis.vertical,
        sizeFactor: _curvedAnimation,
        child: const DeckBottomBar(),
      ),

      // Body changes layout based on [isSmallLayout].
      body: widget.isSmallLayout
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
    );
  }
}
