import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/features/ai/wizard/chat/chat_conversation_profile.dart';
import 'package:playground/features/ai/wizard/chat/view/widgets/empty_state.dart';
import 'package:playground/features/ai/wizard/core/ai/services/ai_conversation_viewmodel.dart';
import 'package:playground/features/ai/wizard/core/viewmodel_scope.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_view.dart';

/// Smoke test: the wizard mounts and shows its empty state without touching the
/// network. A conversation only starts on the first `sendMessage`, so building
/// the view is offline-safe and needs no Gemini API key.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget host() {
    return MaterialApp(
      home: HeroTheme(
        data: HeroThemeData.light(),
        child: Scaffold(
          body: ViewModelScope<AiConversationViewModel>(
            create: () =>
                AiConversationViewModel(profile: chatConversationProfile()),
            child: const SizedBox(width: 360, height: 720, child: WizardView()),
          ),
        ),
      ),
    );
  }

  testWidgets('wizard mounts and renders its empty state', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.byType(WizardView), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('What is the presentation about?'), findsOneWidget);
    expect(find.text('Describe your presentation topic…'), findsOneWidget);

    // Unmount so the view model disposes its session/signals cleanly.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
