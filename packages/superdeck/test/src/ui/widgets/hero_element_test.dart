import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/ui/widgets/hero_element.dart';
import 'package:superdeck/src/ui/widgets/text_hero_flight.dart';

/// Regression coverage for the "text size pops at the start/end of a hero
/// transition" bug.
///
/// A flight shuttle must resolve its own text style because it is built inside
/// the Navigator's Overlay, outside the route's Material.
void main() {
  // A heading-like style (mirrors default_style.dart): sets the obvious
  // properties but leaves letterSpacing / leadingDistribution unset so they
  // are inherited from the ambient DefaultTextStyle.
  const headingStyle = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  const text = 'Heading Sample';
  const routeKey = ValueKey('route-text');
  Widget heroWidget() => buildElementHero<String>(
    tag: 'h',
    // Mirrors StyledText -> Text(text, style: spec.style).
    child: const Text(text, style: headingStyle, key: routeKey),
    flightShuttleBuilder: buildTextHeroFlight,
  );

  testWidgets(
    'flight shuttle text renders at the same size as the route text',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: heroWidget())),
          routes: {'/next': (_) => Scaffold(body: Center(child: heroWidget()))},
        ),
      );

      final routePara = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(routeKey),
          matching: find.byType(RichText),
        ),
      );
      final routeWidth = routePara.getMaxIntrinsicWidth(double.infinity);
      final routeHeight = routePara.getMinIntrinsicHeight(double.infinity);

      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
      await tester.pump(); // build the flight
      await tester.pump(const Duration(milliseconds: 1)); // first flight frame

      final shuttlePara = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byType(FittedBox),
              matching: find.byType(RichText),
            )
            .first,
      );
      final shuttleWidth = shuttlePara.getMaxIntrinsicWidth(double.infinity);
      final shuttleHeight = shuttlePara.getMinIntrinsicHeight(double.infinity);

      expect(
        shuttleWidth,
        routeWidth,
        reason: 'shuttle text width must match the route text (no handoff pop)',
      );
      expect(
        shuttleHeight,
        routeHeight,
        reason: 'shuttle text height must match the route text',
      );
    },
  );
}
