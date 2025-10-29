import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/rendering/slides/slide_view.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/src/styling/styles.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/deck/widget_definition.dart';
import 'package:superdeck_core/superdeck_core.dart';

extension WidgetTesterX on WidgetTester {
  Future<void> pumpWithScaffold(Widget widget) async {
    await pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  }

  Future<void> pumpSlide(
    SlideConfiguration slide, {
    bool isSnapshot = false,
    SlideStyle? style,
    Map<String, WidgetDefinition> widgets = const {},
    List<GeneratedAsset> assets = const [],
  }) async {
    return pumpWithScaffold(
      InheritedData(data: slide, child: SlideView(slide)),
    );
  }
}
