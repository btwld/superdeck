import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/rendering/slides/slide_view.dart';
import 'package:superdeck/src/ui/widgets/cache_image_widget.dart';
import 'package:superdeck/src/ui/widgets/hero_element.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/slide_test_harness.dart';

const _heroText = 'Constraint driven Hero';
const _imageUri = 'https://example.com/hero.png';
const _transitionDuration = Duration(seconds: 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'text Hero interpolates typography between different block frames',
    (tester) async {
      _setSlideViewport(tester);
      final from = _slide(
        key: 'text-hero-from',
        heroContent: '# $_heroText {.shared-text}',
      );
      final to = _slide(
        key: 'text-hero-to',
        heroContent: '### $_heroText {.shared-text}',
        constrainHero: true,
      );

      await _pumpHeroRoutes(tester, from: from, to: to);

      final routeText = _routeTextFinder(_heroText);
      final fromSize = tester.getSize(routeText);
      final fromFontSize = tester.widget<Text>(routeText).style!.fontSize!;

      _navigateToNextSlide(tester);
      await tester.pump();
      await tester.pump(_transitionDuration ~/ 2);

      expect(tester.takeException(), isNull);
      final shuttleText = _shuttleTextFinder(_heroText);
      expect(shuttleText, findsOneWidget);
      final shuttleSize = tester.getSize(shuttleText);
      final shuttleFontSize = tester
          .widget<Text>(shuttleText)
          .textSpan!
          .style!
          .fontSize!;

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final toSize = tester.getSize(routeText);
      final toFontSize = tester.widget<Text>(routeText).style!.fontSize!;
      expect(toSize.width, lessThan(fromSize.width));
      expect(toSize.height, lessThan(fromSize.height));
      expect(shuttleSize.width, inExclusiveRange(toSize.width, fromSize.width));
      expect(
        shuttleSize.height,
        inExclusiveRange(toSize.height, fromSize.height),
      );
      expect(shuttleFontSize, inExclusiveRange(toFontSize, fromFontSize));
    },
  );

  testWidgets('image Hero interpolates its constraint-derived block size', (
    tester,
  ) async {
    _setSlideViewport(tester);
    final from = _slide(
      key: 'image-hero-from',
      heroContent: '![Hero image]($_imageUri){.shared-image}',
    );
    final to = _slide(
      key: 'image-hero-to',
      heroContent: '![Hero image]($_imageUri){.shared-image}',
      constrainHero: true,
    );

    await _pumpHeroRoutes(tester, from: from, to: to);

    final fromData = _imageHeroData(tester).single;

    _navigateToNextSlide(tester);
    await tester.pump();

    final routeData = _imageHeroData(tester, skipOffstage: false);
    final toData = routeData.singleWhere((data) => data.size != fromData.size);
    expect(toData.size.width, lessThan(fromData.size.width));
    expect(toData.size.height, lessThan(fromData.size.height));

    await tester.pump(_transitionDuration ~/ 2);

    expect(tester.takeException(), isNull);
    final targetSizes = tester
        .widgetList<CachedImage>(find.byType(CachedImage))
        .map((image) => image.targetSize)
        .whereType<Size>();
    final shuttleSize = targetSizes.singleWhere(
      (size) =>
          size.width > toData.size.width &&
          size.width < fromData.size.width &&
          size.height > toData.size.height &&
          size.height < fromData.size.height,
    );
    expect(shuttleSize.width.isFinite, isTrue);
    expect(shuttleSize.height.isFinite, isTrue);

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_imageHeroData(tester).single.size, toData.size);
  });
}

Slide _slide({
  required String key,
  required String heroContent,
  bool constrainHero = false,
}) {
  final heroBlock = ContentBlock(heroContent, align: ContentAlignment.center);
  if (!constrainHero) {
    return Slide(
      key: key,
      sections: [
        SectionBlock([heroBlock]),
      ],
    );
  }

  return Slide(
    key: key,
    sections: [
      SectionBlock([heroBlock, ContentBlock('Side')]),
      SectionBlock([ContentBlock('Below')]),
    ],
  );
}

Future<void> _pumpHeroRoutes(
  WidgetTester tester, {
  required Slide from,
  required Slide to,
}) async {
  final fromConfiguration = SlideTestHarness.createConfiguration(from);
  final toConfiguration = SlideTestHarness.createConfiguration(to);

  await tester.pumpWidget(
    MaterialApp(
      home: _SlideRoute(configuration: fromConfiguration),
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        transitionDuration: _transitionDuration,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _SlideRoute(configuration: toConfiguration),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _navigateToNextSlide(WidgetTester tester) {
  tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
}

Finder _routeTextFinder(String text) =>
    find.byWidgetPredicate((widget) => widget is Text && widget.data == text);

Finder _shuttleTextFinder(String text) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.textSpan?.toPlainText() == text,
);

List<ImageElement> _imageHeroData(
  WidgetTester tester, {
  bool skipOffstage = true,
}) {
  return tester
      .widgetList<HeroElement<ImageElement>>(
        find.byWidgetPredicate(
          (widget) => widget is HeroElement<ImageElement>,
          skipOffstage: skipOffstage,
        ),
      )
      .map((element) => element.data)
      .toList();
}

void _setSlideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _SlideRoute extends StatelessWidget {
  const _SlideRoute({required this.configuration});

  final SlideConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InheritedData(data: configuration, child: SlideView(configuration)),
    );
  }
}
