import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/wizard/core/ai/wizard_session_state.dart';

void main() {
  test('starts with a trimmed topic and expects an audience', () {
    final state = WizardSessionState.initial().startTopic(
      '  Urban gardens for resilient cities  ',
    );

    expect(state, isNotNull);
    expect(state!.step, WizardStep.audience);
    expect(state.context.topic, 'Urban gardens for resilient cities');
  });

  test('accepts only the value required by the current step', () {
    final audienceState = WizardSessionState.initial().startTopic('Topic')!;

    expect(audienceState.advance({'value': 12}), isNull);

    final approachState = audienceState.advance({
      'selectedOption': 'City planners',
    });
    expect(approachState, isNotNull);
    expect(approachState!.step, WizardStep.approach);
    expect(approachState.context.audience, 'City planners');
  });

  test('builds canonical context through the complete selection flow', () {
    var state = WizardSessionState.initial().startTopic('Urban gardens')!;
    state = state.advance({'selectedOption': 'City planners'})!;
    state = state.advance({'selectedOption': 'Policy blueprint'})!;
    state = state.advance({
      'selectedOptions': ['Zoning', 'Community funding'],
    })!;
    state = state.advance({'value': 10})!;
    state = state.advance({'themeId': 'civic-blueprint'})!;

    expect(state.step.name, 'imageStyle');
    expect(state.isReviewReady, isFalse);
    state = state.advance({
      'imageStyleId': 'minimalist',
      'imageStyleVersion': 1,
    })!;

    expect(state.step, WizardStep.review);
    expect(state.isReviewReady, isTrue);
    expect(state.context.topic, 'Urban gardens');
    expect(state.context.audience, 'City planners');
    expect(state.context.approach, 'Policy blueprint');
    expect(state.context.emphasis, ['Zoning', 'Community funding']);
    expect(state.context.slideCount, 10);
    expect(state.context.themeId, 'civic-blueprint');
    expect(state.context.toMap()['imageStyleId'], 'minimalist');
    expect(state.context.toMap()['imageStyleVersion'], 1);
    expect(state.advance({'selectedOption': 'Unexpected'}), isNull);
  });

  test('rejects out-of-range slide counts and empty selections', () {
    var state = WizardSessionState.initial().startTopic('Topic')!;

    expect(state.advance({'selectedOption': '   '}), isNull);
    state = state.advance({'selectedOption': 'Audience'})!;
    state = state.advance({'selectedOption': 'Approach'})!;
    state = state.advance({
      'selectedOptions': ['Focus'],
    })!;

    expect(state.step, WizardStep.slideCount);
    expect(state.advance({'value': 4}), isNull);
    expect(state.advance({'value': 21}), isNull);
  });

  test('can roll out without image generation in release builds', () {
    var state = WizardSessionState.initial(
      imageStyleEnabled: false,
    ).startTopic('Urban gardens')!;
    state = state.advance({'selectedOption': 'City planners'})!;
    state = state.advance({'selectedOption': 'Policy blueprint'})!;
    state = state.advance({
      'selectedOptions': ['Zoning'],
    })!;
    state = state.advance({'value': 10})!;
    state = state.advance({'themeId': 'civic-blueprint'})!;

    expect(state.step, WizardStep.review);
    expect(state.isReviewReady, isTrue);
    expect(state.context.imageStyleId, isNull);
  });
}
