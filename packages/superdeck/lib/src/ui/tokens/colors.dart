import 'dart:ui';

import 'package:remix/remix.dart';

enum SDColors {
  bgLowest('bgLowest'),
  bgLow('bgLow'),
  bg('bg'),
  bgHigh('bgHigh'),
  bgHighest('bgHighest');

  final String name;
  const SDColors(this.name);

  ColorToken get token => ColorToken(name);

  static Map<ColorToken, Color> get colorMap => {
    SDColors.bgLowest.token: Color(0xFF090909),
    SDColors.bgLow.token: Color(0xFF171717),
    SDColors.bg.token: Color(0xFF333333),
    SDColors.bgHigh.token: Color(0xFF5C5C5C),
    SDColors.bgHighest.token: Color(0xFF7B7B7B),
  };
}
