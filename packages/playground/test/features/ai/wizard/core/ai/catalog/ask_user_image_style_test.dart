import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:playground/core/domain/design/presentation_image_style_catalog.dart';
import 'package:playground/features/ai/wizard/chat/chat_conversation_profile.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_image_style.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_question_cards.dart';
import 'package:playground/features/ai/wizard/core/ai/schemas/wizard_context_keys.dart';

void main() {
  final imageStyles = PresentationImageStyleCatalog.withDefaults();

  test('the Wizard catalog registers one app-owned image-style surface', () {
    final profile = chatConversationProfile(imageStyleCatalog: imageStyles);

    expect(
      profile.catalog.items.map((item) => item.name),
      contains('AskUserImageStyle'),
    );
    expect(profile.imageStyleCatalog, same(imageStyles));
  });

  test('selection context records the exact catalog ID and version', () {
    final context = buildImageStyleSelectionContext(
      imageStyles.current('minimalist')!,
    );

    expect(context[WizardContextKeys.imageStyleId], 'minimalist');
    expect(context[WizardContextKeys.imageStyleVersion], 1);
    expect(context[WizardContextKeys.title], 'Minimalist');
  });

  testWidgets('a failed preview remains selectable and retryable', (
    tester,
  ) async {
    var selected = false;
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HeroTheme(
          data: HeroThemeData.light(),
          child: Scaffold(
            body: ImageStyleOptionCard(
              style: imageStyles.current('minimalist')!,
              hasFailed: true,
              selected: false,
              onTap: () => selected = true,
              onRetry: () => retried = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.imageOff), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.text(imageStyles.current('minimalist')!.description),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);

    await tester.tap(find.text('Minimalist'));
    expect(selected, isTrue);
  });
}
