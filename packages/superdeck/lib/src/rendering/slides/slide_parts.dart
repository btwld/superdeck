import 'package:flutter/widgets.dart';
import 'background.dart';

class SlideParts {
  const SlideParts({
    this.header,
    this.footer,
    this.background = const BackgroundPart(),
  });

  final PreferredSizeWidget? header;
  final PreferredSizeWidget? footer;
  final Widget background;
}
