import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import '../../domain/stores/presentation_store.dart';
import '../widgets/presentation_controls.dart';
import '../widgets/slide_menu.dart';

/// Full-screen present mode.
///
/// Renders the active slide scaled to fit the viewport and drives navigation
/// from the [PresentationStore]. Slides are read straight off
/// `DeckController.slides` (a signal) via [Watch]; the current index and menu
/// state come from the store via Provider.
///
/// Input: arrow/space/page keys and on-slide taps advance; `Esc` closes the menu
/// or exits back to the editor; `m` toggles the thumbnail menu; `Home`/`End`
/// jump to the first/last slide.
class PresentationPage extends StatefulWidget {
  const PresentationPage({super.key});

  @override
  State<PresentationPage> createState() => _PresentationPageState();
}

class _PresentationPageState extends State<PresentationPage> {
  final FocusNode _focusNode = FocusNode();

  /// Whether the thumbnail menu overlay is open. Ephemeral UI chrome — nothing
  /// outside this screen reads it — so it lives here rather than in the store.
  bool _isMenuOpen = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _exit() {
    if (context.canPop()) context.pop();
  }

  void _toggleMenu() => setState(() => _isMenuOpen = !_isMenuOpen);

  void _closeMenu() {
    if (!_isMenuOpen) return;
    setState(() => _isMenuOpen = false);
  }

  /// A tap on the slide advances; if the menu is open it closes first.
  void _onSlideTap(PresentationStore store) {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      store.next();
    }
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeckController>();

    return Scaffold(
      backgroundColor: $background.resolve(context),
      body: _PresentationKeyboard(
        focusNode: _focusNode,
        isMenuOpen: _isMenuOpen,
        onToggleMenu: _toggleMenu,
        onCloseMenu: _closeMenu,
        onExit: _exit,
        child: Watch((context) {
          final slides = controller.slides.value;
          final store = context.watch<PresentationStore>();

          if (slides.isEmpty) {
            return _EmptyState(onExit: _exit);
          }

          final index = store.currentIndex.clamp(0, slides.length - 1);

          return Stack(
            children: [
              // Full-screen slide. Tapping advances (or closes the menu).
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _onSlideTap(store),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: FittedBox(
                      fit: .contain,
                      child: SlideRenderView(slides[index]),
                    ),
                  ),
                ),
              ),

              _SlidingThumbnailMenu(
                isOpen: _isMenuOpen,
                slides: slides,
                activeIndex: index,
                onSelect: (i) {
                  store.goToSlide(i);
                  _closeMenu();
                  _focusNode.requestFocus();
                },
              ),

              _CloseButton(onPressed: _exit),

              // Bottom-centered navigation controls.
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24, right: 24),
                  child: PresentationControls(
                    currentIndex: index,
                    slideCount: slides.length,
                    onFirst: () => store.goToSlide(0),
                    onPrevious: store.previous,
                    onNext: store.next,
                    onToggleMenu: _toggleMenu,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Wraps [child] in a [Focus] that drives present-mode navigation from the
/// keyboard. Slide navigation is read from the [PresentationStore] in context;
/// the menu is screen-owned, so its state and toggles are passed in.
///
/// Keys: →/↓/PageDown/Space/Enter advance · ←/↑/PageUp go back · Home/End jump
/// to the first/last slide · `m` calls [onToggleMenu] · `Esc` calls
/// [onCloseMenu] when [isMenuOpen], otherwise [onExit] to leave present mode.
/// The [focusNode] is owned by the page so it can re-grab focus after pointer
/// interactions.
class _PresentationKeyboard extends StatelessWidget {
  const _PresentationKeyboard({
    required this.focusNode,
    required this.isMenuOpen,
    required this.onToggleMenu,
    required this.onCloseMenu,
    required this.onExit,
    required this.child,
  });

  final FocusNode focusNode;
  final bool isMenuOpen;
  final VoidCallback onToggleMenu;
  final VoidCallback onCloseMenu;
  final VoidCallback onExit;
  final Widget child;

  KeyEventResult _onKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final store = context.read<PresentationStore>();
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter) {
      store.next();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.pageUp) {
      store.previous();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.home) {
      store.goToSlide(0);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.end) {
      store.goToSlide(store.slideCount - 1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyM) {
      onToggleMenu();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      if (isMenuOpen) {
        onCloseMenu();
      } else {
        onExit();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (node, event) => _onKey(context, event),
      child: child,
    );
  }
}

/// The thumbnail menu docked to the left edge, sliding in when [isOpen].
///
/// Returns an [AnimatedPositioned], so it must be placed directly in the
/// present-mode [Stack].
class _SlidingThumbnailMenu extends StatelessWidget {
  const _SlidingThumbnailMenu({
    required this.isOpen,
    required this.slides,
    required this.activeIndex,
    required this.onSelect,
  });

  static const _width = 260.0;
  static const _duration = Duration(milliseconds: 200);

  final bool isOpen;
  final List<SlideConfiguration> slides;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: _duration,
      curve: Curves.easeInOut,
      top: 16,
      bottom: 16,
      left: isOpen ? 16 : -_width,
      width: _width,
      child: SlideMenu(
        slides: slides,
        activeIndex: activeIndex,
        onSelect: onSelect,
      ),
    );
  }
}

/// Shown when the deck has no slides to present.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExit});

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: StyledText(
            'No slides to present',
            style: TextStyler().style(.color($muted())),
          ),
        ),
        _CloseButton(onPressed: onExit),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: HeroIconButton(
        variant: .ghost,
        size: .sm,
        icon: CupertinoIcons.xmark,
        onPressed: onPressed,
      ),
    );
  }
}
