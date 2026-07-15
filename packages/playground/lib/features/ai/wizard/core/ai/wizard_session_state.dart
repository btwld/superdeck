import 'wizard_context.dart';

enum WizardStep {
  topic,
  audience,
  approach,
  emphasis,
  slideCount,
  theme,
  imageStyle,
  review,
}

/// Canonical, application-owned state for the booth Wizard.
///
/// GenUI chooses how each question is presented, while this state owns the
/// accepted values and the only valid order in which the workflow can advance.
final class WizardSessionState {
  final WizardStep step;

  final WizardContext context;

  final bool imageStyleEnabled;
  const WizardSessionState._({
    required this.step,
    required this.context,
    required this.imageStyleEnabled,
  });

  factory WizardSessionState.initial({bool imageStyleEnabled = true}) {
    return WizardSessionState._(
      step: .topic,
      context: const WizardContext(),
      imageStyleEnabled: imageStyleEnabled,
    );
  }

  WizardSessionState? _advanceSingleChoice(
    Map<String, dynamic> actionContext, {
    required WizardStep nextStep,
    required WizardContext Function(String value) update,
  }) {
    final value = _nonEmptyString(actionContext['selectedOption']);
    if (value == null) return null;

    return _next(step: nextStep, context: update(value));
  }

  WizardSessionState _next({
    required WizardStep step,
    required WizardContext context,
  }) => ._(step: step, context: context, imageStyleEnabled: imageStyleEnabled);

  bool get isReviewReady {
    return step == .review &&
        context.topic != null &&
        context.audience != null &&
        context.approach != null &&
        context.emphasis?.isNotEmpty == true &&
        context.slideCount != null &&
        context.themeId != null &&
        (!imageStyleEnabled ||
            (context.imageStyleId != null &&
                context.imageStyleVersion != null));
  }

  WizardSessionState? startTopic(String rawTopic) {
    if (step != .topic) return null;
    final topic = _nonEmptyString(rawTopic);
    if (topic == null) return null;

    return _next(
      step: .audience,
      context: context.copyWith(topic: topic),
    );
  }

  WizardSessionState? advance(Map<String, dynamic> actionContext) {
    switch (step) {
      case .topic:
      case .review:
        return null;
      case .audience:
        return _advanceSingleChoice(
          actionContext,
          nextStep: .approach,
          update: (value) => context.copyWith(audience: value),
        );
      case .approach:
        return _advanceSingleChoice(
          actionContext,
          nextStep: .emphasis,
          update: (value) => context.copyWith(approach: value),
        );
      case .emphasis:
        final emphasis = _stringList(actionContext['selectedOptions']);
        if (emphasis == null || emphasis.length > 3) return null;

        return _next(
          step: .slideCount,
          context: context.copyWith(emphasis: emphasis),
        );
      case .slideCount:
        final slideCount = _integer(actionContext['value']);
        if (slideCount == null || slideCount < 5 || slideCount > 20) {
          return null;
        }

        return _next(
          step: .theme,
          context: context.copyWith(slideCount: slideCount),
        );
      case .theme:
        final themeId = _nonEmptyString(actionContext['themeId']);
        if (themeId == null) return null;

        return _next(
          step: imageStyleEnabled ? .imageStyle : .review,
          context: context.copyWith(themeId: themeId),
        );
      case .imageStyle:
        final imageStyleId = _nonEmptyString(actionContext['imageStyleId']);
        final imageStyleVersion = _integer(actionContext['imageStyleVersion']);
        if (imageStyleId == null ||
            imageStyleVersion == null ||
            imageStyleVersion < 1) {
          return null;
        }

        return _next(
          step: .review,
          context: context.copyWith(
            imageStyleId: imageStyleId,
            imageStyleVersion: imageStyleVersion,
          ),
        );
    }
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
