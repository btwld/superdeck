import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/components/atoms/slide_view.dart';
import 'package:superdeck/src/modules/deck/slide_configuration.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../test_helpers.dart';

void main() {
  group('SimpleTemplate', () {
    const slide = Slide(key: 'simple-slide');
    final config = SlideConfiguration(
      slide: slide,
      slideIndex: 0,
      style: Style(),
      thumbnailFile: '',
    );
    testWidgets('builds content', (WidgetTester tester) async {
      await tester.pumpSlide(config);
      final finder = find.byType(SlideView);
      expect(finder, findsOneWidget);
      // Check if template model equals to slide model
      final template = tester.widget<SlideView>(finder);
      expect(template.slide, config);
    });
  });
}
