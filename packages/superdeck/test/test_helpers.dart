import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/components/atoms/slide_view.dart';
import 'package:superdeck/src/modules/common/helpers/provider.dart';
import 'package:superdeck/src/modules/common/styles/style.dart';
import 'package:superdeck/src/modules/deck/deck_options.dart';
import 'package:superdeck/src/modules/deck/slide_configuration.dart';
import 'package:superdeck_core/superdeck_core.dart';

extension WidgetTesterX on WidgetTester {
  Future<void> pumpWithScaffold(Widget widget) async {
    await pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  }

  Future<void> pumpSlide(
    SlideConfiguration slide, {
    bool isSnapshot = false,
    DeckStyle? style,
    Map<String, WidgetBlockBuilder> widgets = const {},
    List<GeneratedAsset> assets = const [],
  }) async {
    return pumpWithScaffold(
      InheritedData(
        data: slide,
        child: SlideView(slide),
      ),
    );
  }
}
