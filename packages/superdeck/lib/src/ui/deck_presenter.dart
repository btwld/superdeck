import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../deck/deck_controller.dart';
import '../deck/slide_page_content.dart';
import '../plugins/deck_action.dart';
import 'app_shell.dart';
import 'app_theme.dart';
import 'tokens/colors.dart';
import 'widgets/provider.dart';

/// Embeds SuperDeck's presentation shell around an existing [controller].
///
/// [SuperDeckApp] is the standalone entry point: it owns a [MaterialApp], builds
/// its own [DeckController] from a loader, and hosts the deck at the app root.
/// Use [DeckPresenter] instead when a host app already owns the controller and
/// wants the same shell inside its own widget tree (e.g. a pushed route),
/// sharing that controller's slides, navigation, menu, and thumbnails.
///
/// Renders the identical [AppShell] — side/bottom thumbnail panel, action bar,
/// menu, and scaled slide — that [SuperDeckApp] shows, wrapped in the same dark
/// theme and color tokens. The current slide is read straight off
/// [DeckController.presentation], so navigation stays in sync with the host.
class DeckPresenter extends StatelessWidget {
  const DeckPresenter({
    super.key,
    required this.controller,
    this.actions = const [],
  });

  final DeckController controller;

  /// Runtime actions contributed to the shell's bottom action bar.
  final List<DeckAction> actions;

  @override
  Widget build(BuildContext context) {
    return InheritedData<DeckController>(
      data: controller,
      child: Theme(
        data: theme,
        child: MixScope(
          colors: SDColors.colorMap,
          child: AppShell(
            actions: actions,
            // The shell's navigation writes through DeckController.presentation,
            // so render the current slide reactively and cross-fade between
            // indices to match SuperDeckApp's route transition. (A nested Router
            // would fight the host app's own router for platform route info.)
            child: SignalBuilder(
              builder: (context) {
                final index = controller.presentation.currentIndex.value;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeInOut,
                  child: KeyedSubtree(
                    key: ValueKey<int>(index),
                    child: SlidePageContent(index: index),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
