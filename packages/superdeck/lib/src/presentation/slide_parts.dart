import 'package:flutter/widgets.dart';

import '../rendering/slides/background.dart';
import '../rendering/slides/footer.dart';
import '../rendering/slides/header.dart';

class SlideParts {
  const SlideParts({
    this.header = const HeaderPart(),
    this.footer = const FooterPart(),
    this.background = const BackgroundPart(),
  });

  final PreferredSizeWidget header;
  final PreferredSizeWidget footer;
  final Widget background;
}
