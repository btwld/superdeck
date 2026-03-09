import 'package:flutter/widgets.dart';

import '../ui/widgets/provider.dart';
import 'deck_controller.dart';

abstract final class SuperDeck {
  /// Returns the [DeckController] exposed by [SuperDeckApp].
  static DeckController of(BuildContext context) {
    return InheritedData.of<DeckController>(context);
  }
}
