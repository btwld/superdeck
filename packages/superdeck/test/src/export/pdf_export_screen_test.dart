import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck/src/deck/navigation_service.dart';
import 'package:superdeck/src/ui/panels/bottom_bar.dart';
import 'package:superdeck/src/ui/tokens/colors.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/test_helpers.dart';

final class _MockDeckLoader extends DeckLoader {
  _MockDeckLoader() : super(workspace: DeckWorkspace());

  final StreamController<SlidesEvent> _events =
      StreamController<SlidesEvent>.broadcast();

  @override
  Stream<SlidesEvent> load() {
    Future.microtask(() {
      _events.add(SlidesLoadingEvent('Loading...'));
      _events.add(SlidesLoadedEvent(createTestSlidesPayload()));
    });
    return _events.stream;
  }

  @override
  Future<void> reload() async {}

  @override
  Future<void> dispose() => _events.close();
}

Widget _buildHarness(DeckController controller) {
  return MaterialApp.router(
    routerConfig: controller.router,
    builder: (context, child) {
      return MixScope(
        colors: SDColors.colorMap,
        child: InheritedData(
          data: controller,
          child: Stack(
            children: [
              Offstage(child: child ?? const SizedBox()),
              const Align(
                alignment: Alignment.bottomCenter,
                child: DeckBottomBar(),
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

  group('PdfExportDialogScreen', () {
    late _MockDeckLoader loader;
    late DeckController controller;

    setUp(() async {
      loader = _MockDeckLoader();
      controller = DeckController(
        deckLoader: loader,
        options: const DeckOptions(),
        navigationService: NavigationService(transitionDuration: Duration.zero),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    tearDown(() async {
      controller.dispose();
      await loader.dispose();
    });

    testWidgets(
      'opens from bottom bar overlay context without throwing a navigator error',
      (tester) async {
        await tester.pumpWidget(_buildHarness(controller));
        await tester.pump();

        await tester.tap(find.bySemanticsLabel('Export PDF'));
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
