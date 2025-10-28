import 'package:flutter/widgets.dart';
import 'background.dart';
import 'footer.dart';
import 'header.dart';

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
