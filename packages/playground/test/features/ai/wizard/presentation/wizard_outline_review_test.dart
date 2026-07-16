import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_outline_review.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('reviews and edits the typed outline before approval', (
    tester,
  ) async {
    var approved = 0;
    ({int index, String title, String assertion})? edit;

    await tester.pumpWidget(
      MaterialApp(
        home: HeroTheme(
          data: HeroThemeData.light(),
          child: Scaffold(
            body: SizedBox(
              width: 900,
              height: 720,
              child: WizardOutlineReview(
                plan: _plan(),
                onSlideChanged: (index, title, assertion) {
                  edit = (index: index, title: title, assertion: assertion);
                  return true;
                },
                onBack: () {},
                onRegenerate: () {},
                onApprove: () => approved++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Review the story'), findsOneWidget);
    expect(
      find.text('Small interventions build city-scale resilience.'),
      findsOneWidget,
    );
    expect(find.text('Opening'), findsOneWidget);
    expect(find.text('Slide 1'), findsOneWidget);
    expect(find.text('opening'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Edit slide 1'), findsOneWidget);

    await tester.tap(find.text('Edit slide 1'));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('outline-title-opening')),
      'A greener city starts here',
    );
    await tester.enterText(
      find.byKey(const ValueKey('outline-assertion-opening')),
      'Small gardens create city-scale resilience.',
    );
    await tester.pump();

    expect(edit?.index, 0);
    expect(edit?.title, 'A greener city starts here');
    expect(edit?.assertion, 'Small gardens create city-scale resilience.');

    await tester.tap(find.text('Approve & build'));
    expect(approved, 1);
  });

  testWidgets('outline actions stay available while the outline scrolls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HeroTheme(
          data: HeroThemeData.light(),
          child: Scaffold(
            body: SizedBox(
              width: 900,
              height: 360,
              child: WizardOutlineReview(
                plan: _planWithSlides(12),
                onSlideChanged: (_, _, _) => true,
                onBack: () {},
                onRegenerate: () {},
                onApprove: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Approve & build').hitTestable(), findsOneWidget);
    expect(find.text('Regenerate outline').hitTestable(), findsOneWidget);
    expect(find.text('Slide 12').hitTestable(), findsNothing);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pump();

    expect(find.text('Approve & build').hitTestable(), findsOneWidget);
  });

  testWidgets('blocks approval while a visible outline edit is invalid', (
    tester,
  ) async {
    var approved = 0;
    var plan = _plan();
    var planRevision = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: HeroTheme(
          data: HeroThemeData.light(),
          child: Scaffold(
            body: SizedBox(
              width: 900,
              height: 720,
              child: StatefulBuilder(
                builder: (context, setState) {
                  updateHost = setState;
                  return WizardOutlineReview(
                    plan: plan,
                    planRevision: planRevision,
                    onSlideChanged: (_, _, _) => true,
                    onBack: () {},
                    onRegenerate: () {},
                    onApprove: () => approved++,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit slide 1'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('outline-title-opening')),
      '',
    );
    await tester.pump();

    expect(
      find.text('Add both a slide title and core message.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Approve & build'));
    expect(approved, 0);

    updateHost(() {
      plan = _plan();
      planRevision++;
    });
    await tester.pump();

    expect(find.text('Add both a slide title and core message.'), findsNothing);
    expect(find.text('Urban gardens matter'), findsOneWidget);
    expect(find.byKey(const ValueKey('outline-title-opening')), findsNothing);
    await tester.tap(find.text('Approve & build'));
    expect(approved, 1);
  });
}

DeckPlanType _plan() => DeckPlanType.parse({
  'topic': 'Urban gardens',
  'story': 'Small interventions build city-scale resilience.',
  'theme': {'id': 'technical-paper', 'version': 1, 'density': 'balanced'},
  'sections': [
    {
      'key': 'opening-section',
      'title': 'Opening',
      'purpose': 'Frame the opportunity.',
      'transition': 'Move into the evidence.',
      'slideKeys': ['opening'],
    },
  ],
  'slides': [
    {
      'key': 'opening',
      'title': 'Urban gardens matter',
      'purpose': 'Introduce the opportunity.',
      'sectionKey': 'opening-section',
      'assertion': 'Urban gardens strengthen neighborhood resilience.',
      'contentUnits': ['One concrete supporting point'],
      'narrativeRole': 'opening',
      'contentBrief': 'Frame the opportunity clearly.',
      'continuity': 'Open the story and lead into evidence.',
      'composition': 'content',
      'treatment': 'content',
      'density': 'balanced',
      'elements': <Object?>[],
    },
  ],
});

DeckPlanType _planWithSlides(int count) {
  final data = Map<String, Object?>.from(_plan());
  final section = Map<String, Object?>.from(
    (data['sections']! as List<Object?>).single! as Map<String, Object?>,
  );
  final source = Map<String, Object?>.from(
    (data['slides']! as List<Object?>).single! as Map<String, Object?>,
  );
  final slides = [
    for (var index = 0; index < count; index++)
      {...source, 'key': 'slide-$index', 'title': 'Slide title ${index + 1}'},
  ];
  section['slideKeys'] = slides.map((slide) => slide['key']).toList();
  data['sections'] = [section];
  data['slides'] = slides;

  return DeckPlanType.parse(data);
}
