import 'package:flutter/widgets.dart';

/// InheritedWidget that provides loading state to wizard card components.
///
/// This allows catalog cards to show loading indicators on their Next buttons
/// when the AI is processing a response.
class WizardLoadingState extends InheritedWidget {
  final bool isLoading;

  const WizardLoadingState({
    super.key,
    required this.isLoading,
    required super.child,
  });

  @override
  bool updateShouldNotify(WizardLoadingState oldWidget) {
    return isLoading != oldWidget.isLoading;
  }
}
