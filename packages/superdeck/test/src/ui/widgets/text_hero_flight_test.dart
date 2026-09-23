import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/ui/widgets/text_hero_flight.dart';

const _duration = Duration(seconds: 1);
const _fromStyle = TextStyle(
  fontSize: 96,
  fontWeight: FontWeight.bold,
  height: 1.1,
  color: Colors.white,
);
const _toStyle = TextStyle(
  fontSize: 36,
  fontWeight: FontWeight.w400,
  height: 1.2,
  color: Color(0xFFFF4D4D),
);

void main() {
  for (final copy in [
    'Hello World',
    'Hello\nWorld',
    'A heading wraps',
    'مرحبا بالعالم',
    'Hi scaled',
    'Bold and italic',
  ]) {
    testWidgets('fixed text layout remains visible: $copy', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fromKey = GlobalKey();
      final toKey = GlobalKey();
      final flightKey = GlobalKey();
      final controller = AnimationController(
        vsync: tester,
        duration: _duration,
      );
      addTearDown(controller.dispose);
      Widget endpoints() => Row(
        children: [
          SizedBox(key: fromKey, width: 380, child: _text(copy, _fromStyle)),
          SizedBox(
            key: toKey,
            width: 280,
            child: _text(copy.replaceAll('World', 'Friend'), _toStyle),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: endpoints())));
      final from = _paragraph(tester, fromKey);
      final to = _paragraph(tester, toKey);
      final fromText = from.text;
      final toText = to.text;
      final fromSize = from.size;
      final toSize = to.size;
      final referenceLines = [
        _boxes(from).map((b) => b.top).toSet().length,
        _boxes(to).map((b) => b.top).toSet().length,
      ];
      final flight = buildTextHeroFlight(
        tester.element(find.byKey(fromKey)),
        controller,
        HeroFlightDirection.push,
        tester.element(find.byKey(fromKey)),
        tester.element(find.byKey(toKey)),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) => SizedBox.fromSize(
                  key: flightKey,
                  size: Size.lerp(fromSize, toSize, controller.value),
                  child: flight,
                ),
              ),
            ),
          ),
        ),
      );
      for (var frame = 0; frame < 10; frame++) {
        controller.value = frame / 9;
        await tester.pump();
        final paragraphs = tester
            .renderObjectList<RenderParagraph>(
              find.descendant(
                of: find.byKey(flightKey),
                matching: find.byType(RichText),
              ),
            )
            .toList();
        final rect = tester.getRect(find.byKey(flightKey));
        if (frame == 0 || frame == 9) {
          final destination = frame == 9;
          expect(paragraphs.single.text, destination ? toText : fromText);
          expect(paragraphs.single.size, destination ? toSize : fromSize);
          expect(rect.size, destination ? toSize : fromSize);
        }
        for (var i = 0; i < paragraphs.length; i++) {
          final p = paragraphs[i];
          final reference = p.size == fromSize ? 0 : 1;
          expect(
            _boxes(p).map((b) => b.top).toSet().length,
            referenceLines[reference],
          );
          for (final box in _boxes(p)) {
            final global = MatrixUtils.transformRect(
              p.getTransformTo(null),
              box.toRect(),
            );
            expect(
              rect.inflate(0.01).contains(global.topLeft),
              isTrue,
              reason: 'frame $frame: $global outside $rect',
            );
            expect(
              rect.inflate(0.01).contains(global.bottomRight),
              isTrue,
              reason: 'frame $frame: $global outside $rect',
            );
          }
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets(
    'unchanged single-line text scales fixed glyphs without a midpoint handoff',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fromKey = GlobalKey();
      final toKey = GlobalKey();
      final controller = AnimationController(vsync: tester);
      addTearDown(controller.dispose);
      const copy = 'A small idea';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  key: fromKey,
                  width: 400,
                  child: const Text(
                    copy,
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  key: toKey,
                  width: 720,
                  child: const Text(
                    copy,
                    style: TextStyle(
                      fontSize: 48,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final flightKey = GlobalKey();
      final fromSize = _paragraph(tester, fromKey).size;
      final toSize = _paragraph(tester, toKey).size;
      final flight = buildTextHeroFlight(
        fromKey.currentContext!,
        controller,
        HeroFlightDirection.push,
        fromKey.currentContext!,
        toKey.currentContext!,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: RepaintBoundary(
              key: flightKey,
              child: Center(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) => SizedBox.fromSize(
                    size: Size.lerp(fromSize, toSize, controller.value),
                    child: flight,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Rect? previousGlyph;
      List<InlineSpan>? previousSpans;
      for (var frame = 0; frame <= 100; frame++) {
        controller.value = frame / 100;
        await tester.pump();
        final finder = find.descendant(
          of: find.byType(FittedBox),
          matching: find.byType(RichText),
        );
        expect(finder, findsNWidgets(2));
        final paragraphs = tester
            .renderObjectList<RenderParagraph>(finder)
            .toList();
        final spans = paragraphs.map((p) => p.text).toList();
        expect(spans.map((s) => s.style!.fontSize), [24, 48]);
        if (previousSpans != null) {
          for (var i = 0; i < spans.length; i++) {
            expect(
              identical(spans[i], previousSpans[i]),
              isTrue,
              reason: 'Do not reshape/rasterize a new font size each frame',
            );
          }
        }
        previousSpans = spans;
        final rects = paragraphs.map((paragraph) {
          expect(paragraph.text.toPlainText(), copy);
          final glyph = paragraph
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: 1),
              )
              .single;
          return MatrixUtils.transformRect(
            paragraph.getTransformTo(null),
            glyph.toRect(),
          );
        }).toList();
        // Both paint layers occupy the same glyph geometry, including when
        // their line-height and font-size differ. No midpoint size handoff.
        expect(rects[0].left, closeTo(rects[1].left, 0.01));
        expect(rects[0].top, closeTo(rects[1].top, 0.01));
        expect(rects[0].height, closeTo(rects[1].height, 0.01));
        final rect = rects.first;
        if (previousGlyph != null) {
          expect(
            rect.top,
            lessThanOrEqualTo(previousGlyph.top + 0.001),
            reason: 'No baseline jitter against the direction of motion',
          );
          expect(
            (rect.height - previousGlyph.height).abs(),
            lessThan(0.8),
            reason: 'frame $frame',
          );
          expect(
            (rect.top - previousGlyph.top).abs(),
            lessThan(0.8),
            reason: 'frame $frame',
          );
        }
        if (frame == 50) {
          await tester.runAsync(() async {
            final boundary =
                flightKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            try {
              final bytes = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              var brightest = 0;
              for (var i = 0; i < bytes.lengthInBytes; i += 4) {
                final red = bytes.getUint8(i);
                if (red > brightest) brightest = red;
              }
              expect(
                brightest,
                255,
                reason: 'No grey dip while blending white text',
              );
            } finally {
              image.dispose();
            }
          });
        }
        previousGlyph = rect;
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('identical endpoints use one opaque layout', (tester) async {
    final fromKey = GlobalKey();
    final toKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                key: fromKey,
                width: 300,
                child: const Text('Same text', style: _toStyle),
              ),
              SizedBox(
                key: toKey,
                width: 300,
                child: const Text('Same text', style: _toStyle),
              ),
            ],
          ),
        ),
      ),
    );
    final flight = buildTextHeroFlight(
      tester.element(find.byKey(fromKey)),
      const AlwaysStoppedAnimation(0.5),
      HeroFlightDirection.push,
      tester.element(find.byKey(fromKey)),
      tester.element(find.byKey(toKey)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizedBox(width: 300, height: 100, child: flight)),
      ),
    );
    expect(find.byType(RichText), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(find.byType(ExcludeSemantics), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('push, pop and interruption keep complete endpoint text', (
    tester,
  ) async {
    Widget endpoint(bool destination) => Scaffold(
      body: Center(
        child: Hero(
          tag: 'heading',
          flightShuttleBuilder: buildTextHeroFlight,
          child: Text(
            destination ? 'Hello Friend' : 'Hello World',
            style: destination ? _toStyle : _fromStyle,
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: endpoint(false),
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          transitionDuration: _duration,
          reverseTransitionDuration: _duration,
          pageBuilder: (_, animation, secondary) => endpoint(true),
        ),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/next');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Hello World'), findsOneWidget);
    navigator.pushNamed('/next');
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('Hello World'), findsOneWidget);
    expect(find.byType(FittedBox), findsNothing);
  });
}

RenderParagraph _paragraph(WidgetTester tester, Key key) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
    );

List<TextBox> _boxes(RenderParagraph p) {
  final boxes = <TextBox>[];
  var offset = 0;
  for (final grapheme in p.text.toPlainText().characters) {
    final end = offset + grapheme.length;
    // Selection boxes include trailing spaces beyond a wrapped line's width;
    // those spaces have no painted glyph and are not clipping failures.
    if (grapheme.trim().isNotEmpty) {
      boxes.addAll(
        p.getBoxesForSelection(
          TextSelection(baseOffset: offset, extentOffset: end),
        ),
      );
    }
    offset = end;
  }
  return boxes;
}

Widget _text(String copy, TextStyle style) {
  final direction = copy == 'مرحبا بالعالم'
      ? TextDirection.rtl
      : TextDirection.ltr;
  final scaler = TextScaler.linear(copy == 'Hi scaled' ? 1.5 : 1);
  if (copy == 'Bold and italic') {
    return Text.rich(
      TextSpan(
        style: style,
        children: const [
          TextSpan(
            text: 'Bold',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' and '),
          TextSpan(
            text: 'italic',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
      textDirection: direction,
      textScaler: scaler,
    );
  }
  return Text(copy, style: style, textDirection: direction, textScaler: scaler);
}
