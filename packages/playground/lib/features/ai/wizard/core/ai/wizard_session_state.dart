import 'wizard_context.dart';

enum WizardStep {
  topic,
  audience,
  approach,
  emphasis,
  slideCount,
  theme,
  review,
}

/// Canonical, application-owned state for the booth Wizard.
///
/// GenUI chooses how each question is presented, while this state owns the
/// accepted values and the only valid order in which the workflow can advance.
final class WizardSessionState {
  const WizardSessionState._({required this.step, required this.context});

  factory WizardSessionState.initial() {
    return const WizardSessionState._(
      step: WizardStep.topic,
      context: WizardContext(),
    );
  }

  final WizardStep step;
  final WizardContext context;

  bool get isReviewReady {
    return step == WizardStep.review &&
        context.topic != null &&
        context.audience != null &&
        context.approach != null &&
        context.emphasis?.isNotEmpty == true &&
        context.slideCount != null &&
        context.themeId != null;
  }

  WizardSessionState? startTopic(String rawTopic) {
    if (step != WizardStep.topic) return null;
    final topic = _nonEmptyString(rawTopic);
    if (topic == null) return null;

    return WizardSessionState._(
      step: WizardStep.audience,
      context: context.copyWith(topic: topic),
    );
  }

  WizardSessionState? advance(Map<String, dynamic> actionContext) {
    switch (step) {
      case WizardStep.topic:
      case WizardStep.review:
        return null;
      case WizardStep.audience:
        return _advanceSingleChoice(
          actionContext,
          nextStep: WizardStep.approach,
          update: (value) => context.copyWith(audience: value),
        );
      case WizardStep.approach:
        return _advanceSingleChoice(
          actionContext,
          nextStep: WizardStep.emphasis,
          update: (value) => context.copyWith(approach: value),
        );
      case WizardStep.emphasis:
        final emphasis = _stringList(actionContext['selectedOptions']);
        if (emphasis == null || emphasis.length > 3) return null;
        return WizardSessionState._(
          step: WizardStep.slideCount,
          context: context.copyWith(emphasis: emphasis),
        );
      case WizardStep.slideCount:
        final slideCount = _integer(actionContext['value']);
        if (slideCount == null || slideCount < 5 || slideCount > 20) {
          return null;
        }
        return WizardSessionState._(
          step: WizardStep.theme,
          context: context.copyWith(slideCount: slideCount),
        );
      case WizardStep.theme:
        final themeId = _nonEmptyString(actionContext['themeId']);
        if (themeId == null) return null;
        return WizardSessionState._(
          step: WizardStep.review,
          context: context.copyWith(themeId: themeId),
        );
    }
  }

  WizardSessionState? _advanceSingleChoice(
    Map<String, dynamic> actionContext, {
    required WizardStep nextStep,
    required WizardContext Function(String value) update,
  }) {
    final value = _nonEmptyString(actionContext['selectedOption']);
    if (value == null) return null;
    return WizardSessionState._(step: nextStep, context: update(value));
  }
}

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String>? _stringList(Object? value) {
  if (value is! List) return null;
  final items = value.map(_nonEmptyString).whereType<String>().toList();
  if (items.isEmpty || items.length != value.length) return null;
  return List.unmodifiable(items);
}

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  return null;
}
