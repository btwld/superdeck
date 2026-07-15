import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/wizard/chat/chat_conversation_profile.dart';
import 'package:playground/features/ai/wizard/core/ai/services/ai_conversation_viewmodel.dart';
import 'package:playground/features/ai/wizard/core/ai/services/genui_conversation_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mergeFinalOutputSegments', () {
    test('restores a stripped word boundary between decoded segments', () {
      expect(
        mergeFinalOutputSegments('Now, how', 'should we approach the pitch?'),
        'Now, how should we approach the pitch?',
      );
    });

    test('does not add a space before punctuation', () {
      expect(mergeFinalOutputSegments('Great choice', '!'), 'Great choice!');
    });

    test('preserves whitespace already supplied by the adapter', () {
      expect(mergeFinalOutputSegments('Great', ' choice'), 'Great choice');
    });
  });

  group('missing Wizard surfaces', () {
    test('requests recovery when the first response has no surface', () {
      expect(
        decideMissingSurfaceAction(
          hasError: false,
          hasController: true,
          requestProducedSurface: false,
          recoveryAttempts: 0,
        ),
        MissingSurfaceAction.recover,
      );
    });

    test('requests recovery when a later response has no new surface', () {
      expect(
        decideMissingSurfaceAction(
          hasError: false,
          hasController: true,
          requestProducedSurface: false,
          recoveryAttempts: 0,
        ),
        MissingSurfaceAction.recover,
      );
    });

    test('shows an error after one surface recovery attempt', () {
      expect(
        decideMissingSurfaceAction(
          hasError: false,
          hasController: true,
          requestProducedSurface: false,
          recoveryAttempts: 1,
        ),
        MissingSurfaceAction.showError,
      );
    });
  });

  test('Wizard system prompt permits its single-surface replacement flow', () {
    final session = GenUiConversationSession(
      profile: chatConversationProfile(),
      handlers: ConversationSessionHandlers(
        onRequestStarted: () {},
        onRequestFinished: () {},
        onUiSubmit: (_) {},
        onSurfaceUpdate: (_) {},
        onTextResponse: (_) {},
        onError: (_, _) {},
      ),
    );
    addTearDown(session.dispose);

    final prompt = session.buildSystemPromptForTesting(
      'Replace the `wizard` surface by deleting it, then creating it again.',
    );

    expect(prompt, contains('deleteSurface'));
    expect(prompt, contains('To update an existing UI'));
    expect(
      prompt,
      isNot(
        contains('DO NOT update or modify surfaces created in previous turns'),
      ),
    );
  });

  test('Wizard instructions update one persistent surface', () async {
    final prompt = await rootBundle.loadString(
      'assets/ai_prompts/wizard_system.prompt',
    );

    expect(prompt, contains('updateComponents'));
    expect(prompt, isNot(contains('deleteSurface')));
    expect(prompt, isNot(contains('beginRendering')));
  });
}
