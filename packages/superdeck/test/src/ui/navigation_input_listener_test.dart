import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck/src/deck/navigation_input_listener.dart';
import 'package:superdeck/src/ui/panels/thumbnail_panel.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';

import '../../helpers/mock_deck_loader.dart';

Widget _buildHarness(DeckController controller) {
  return MaterialApp.router(
    routerConfig: controller.router,
    builder: (context, child) {
      return InheritedData(
        data: controller,
        child: NavigationInputListener(
          child: Stack(
            children: [
              Offstage(child: child ?? const SizedBox()),
              Row(
                children: [
                  SizedBox(
                    width: 300,
                    child: ThumbnailPanel(
                      scrollDirection: Axis.vertical,
                      activeIndex: controller.currentIndex.value,
                      itemCount: controller.slides.value.length,
                      onItemTap: controller.goToSlide,
                      itemBuilder: (index, selected) => SizedBox(
                        key: ValueKey<String>('thumb-$index'),
                        width: 120,
                        height: 70,
                        child: ColoredBox(
                          color: selected ? Colors.blue : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationInputListener', () {
    late MockDeckLoader loader;
    late DeckController controller;

    setUp(() async {
      loader = MockDeckLoader();
      controller = DeckController(
        deckLoader: loader,
        options: DeckOptions(),
        transitionDuration: Duration.zero,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    tearDown(() async {
      controller.dispose();
      await loader.dispose();
    });

    testWidgets('menu-open tap does not trigger global slide navigation', (
      tester,
    ) async {
      controller.openMenu();

      await tester.pumpWidget(_buildHarness(controller));
      await tester.pumpAndSettle();

      controller.router.go('/slides/1');
      await tester.pumpAndSettle();
      expect(controller.currentIndex.value, 1);

      await tester.tapAt(const Offset(500, 100));
      await tester.pumpAndSettle();

      expect(controller.currentIndex.value, 1);
    });

    testWidgets('thumbnail tap still navigates while menu is open', (
      tester,
    ) async {
      controller.openMenu();

      await tester.pumpWidget(_buildHarness(controller));
      await tester.pumpAndSettle();

      controller.router.go('/slides/1');
      await tester.pumpAndSettle();
      expect(controller.currentIndex.value, 1);

      await tester.tap(find.byKey(const ValueKey<String>('thumb-2')));
      await tester.pumpAndSettle();

      expect(controller.currentIndex.value, 2);
    });
  });
}
