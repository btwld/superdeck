import 'package:flutter/widgets.dart';

import '../ui/widgets/provider.dart';
import 'superdeck_handle.dart';

abstract final class SuperDeck {
  static SuperDeckHandle of(BuildContext context) {
    return InheritedData.of<SuperDeckHandle>(context);
  }
}
