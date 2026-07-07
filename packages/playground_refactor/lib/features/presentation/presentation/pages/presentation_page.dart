import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

/// Full-screen present mode.
///
/// Reuses SuperDeck's own presentation shell ([DeckPresenter]) so present mode
/// matches the standalone SuperDeck app — the same side/bottom thumbnail panel,
/// action bar, menu, and scaled slide — all driven off the shared
/// [DeckController]. Navigation, the menu, and thumbnails are the shell's own.
///
/// The playground pushes this over the editor (unlike standalone SuperDeck,
/// which is the whole app), so a close button is overlaid to return.
/// [initialIndex], from the route, seeds the slide the author was editing.
class PresentationPage extends StatefulWidget {
  const PresentationPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<PresentationPage> createState() => _PresentationPageState();
}

class _PresentationPageState extends State<PresentationPage> {
  @override
  void initState() {
    super.initState();
    // The shell reads the current slide off DeckController.presentation, so seed
    // it once mounted to open on the slide the author was editing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeckController>().presentation.goToSlide(widget.initialIndex);
    });
  }

  void _exit() {
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeckController>();

    return Stack(
      children: [
        Positioned.fill(child: DeckPresenter(controller: controller)),
        Positioned(
          top: 16,
          right: 16,
          child: HeroIconButton(
            variant: .ghost,
            size: .sm,
            icon: CupertinoIcons.xmark,
            onPressed: _exit,
          ),
        ),
      ],
    );
  }
}
