import 'package:flutter/material.dart';
import 'package:superdeck/src/components/parts/background.dart';
import 'package:superdeck/src/components/parts/footer.dart';
import 'package:superdeck/src/components/parts/header.dart';

class SlideParts {
  const SlideParts({
    this.header,
    this.footer,
    this.background,
  });

  final PreferredSizeWidget? header;
  final PreferredSizeWidget? footer;
  final Widget? background;

  static const defaultParts = SlideParts(
    header: HeaderPart(),
    footer: FooterPart(),
    background: BackgroundPart(),
  );
}
