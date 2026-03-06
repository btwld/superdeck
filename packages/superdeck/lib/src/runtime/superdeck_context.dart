import 'package:flutter/widgets.dart';

import '../ui/widgets/provider.dart';
import 'superdeck_handle.dart';

abstract final class SuperDeck {
  /// Returns the runtime interaction handle exposed by [SuperDeckApp].
  static SuperDeckHandle of(BuildContext context) {
    return InheritedData.of<SuperDeckHandle>(context);
  }
}
