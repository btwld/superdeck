import 'package:flutter/material.dart'
    show Icons, Scaffold, FloatingActionButtonLocation;
import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../rendering/slides/scaled_app.dart';
import '../rendering/slides/slide_thumbnail.dart';
import '../runtime/deck_controller.dart';
import '../runtime/navigation/navigation_input_listener.dart';
import '../runtime/superdeck_context.dart';
import '../utils/constants.dart';
import 'extensions.dart';
import 'panels/bottom_bar.dart';
import 'panels/notes_panel.dart';
import 'panels/thumbnail_panel.dart';
import 'widgets/icon_button.dart';

/// High-level app shell that toggles between
/// small layout (bottom panel) or regular layout (side panel).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NavigationInputListener(
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

  EffectCleanup? _menuEffectCleanup;
  DeckController? _observedDeck;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
      value: 0.0,
    );

    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final deck = SuperDeck.of(context);
    if (identical(deck, _observedDeck)) {
      return;
    }

    _observedDeck = deck;
    _menuEffectCleanup?.call();

    _animationController.value = deck.isMenuOpen.value ? 1.0 : 0.0;

    _menuEffectCleanup = effect(() {
      if (!mounted) return;

      final isMenuOpen = deck.isMenuOpen.value;
      final thumbnailAssetKeyHash = deck.thumbnailAssetKeyHash.value;

      if (isMenuOpen && _animationController.value != 1.0) {
        _animationController.forward();
      } else if (!isMenuOpen && _animationController.value != 0.0) {
        _animationController.reverse();
      }

      if (isMenuOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !deck.isMenuOpen.value) {
            return;
          }
          final currentHash = deck.thumbnailAssetKeyHash.value;
          if (currentHash != thumbnailAssetKeyHash) {
            return;
          }
          deck.generateThumbnails(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _menuEffectCleanup?.call();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildPanel(BuildContext context) {
    final deck = SuperDeck.of(context);

    return Watch((context) {
      final currentIndex = deck.currentIndex.value;
      final isNotesOpen = deck.isNotesOpen.value;
      final slides = deck.slides.value;

      final currentSlide = (currentIndex >= 0 && currentIndex < slides.length)
          ? slides[currentIndex]
          : null;

      final thumbnailPanel = ThumbnailPanel(
        scrollDirection: widget.isSmallLayout ? Axis.horizontal : Axis.vertical,
        onItemTap: deck.goToSlide,
        activeIndex: currentSlide?.slideIndex ?? 0,
        itemBuilder: (index, selected) {
          return SlideThumbnail(selected: selected, slide: slides[index]);
        },
        itemCount: slides.length,
      );

      final notesPanel = isNotesOpen
          ? NotesPanel(notes: currentSlide?.notes ?? [])
          : const SizedBox();

      if (widget.isSmallLayout) {
        return isNotesOpen ? notesPanel : thumbnailPanel;
      }

      return Column(
        children: [
          Expanded(flex: 3, child: thumbnailPanel),
          if (isNotesOpen) Expanded(flex: 1, child: notesPanel),
        ],
      );
    });
  }

  Widget? _buildFloatingAction({
    required BuildContext context,
    required DeckController deck,
    required bool isMenuOpen,
  }) {
    if (isMenuOpen) {
      return null;
    }

    final menuButton = SDIconButton(
      icon: Icons.menu,
      onPressed: deck.openMenu,
      semanticLabel: 'Open menu',
    );

    final extensionAction = deck.buildFloatingAction(context);
    if (extensionAction == null) {
      return menuButton;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [extensionAction, const SizedBox(height: 12), menuButton],
    );
  }

  @override
  Widget build(BuildContext context) {
    final deck = SuperDeck.of(context);

    return Watch((context) {
      final isMenuOpen = deck.isMenuOpen.value;

      final mainContent = Expanded(
        child: Center(
          child: ScaledWidget(targetSize: kResolution, child: widget.child),
        ),
      );

      final panel = _buildPanel(context);

      final panelTransition = widget.isSmallLayout
          ? SizeTransition(
              axis: Axis.vertical,
              sizeFactor: _curvedAnimation,
              child: SizedBox(height: 200, child: panel),
            )
          : SizeTransition(
              axis: Axis.horizontal,
              sizeFactor: _curvedAnimation,
              child: SizedBox(width: 300, child: panel),
            );

      final layout = widget.isSmallLayout
          ? Column(children: [mainContent, panelTransition])
          : Row(children: [panelTransition, mainContent]);

      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 9, 9, 9),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        floatingActionButton: _buildFloatingAction(
          context: context,
          deck: deck,
          isMenuOpen: isMenuOpen,
        ),
        bottomNavigationBar: SizeTransition(
          axis: Axis.vertical,
          sizeFactor: _curvedAnimation,
          child: const DeckBottomBar(),
        ),
        body: layout,
      );
    });
  }
}
