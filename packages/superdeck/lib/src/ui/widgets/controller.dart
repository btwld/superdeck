import 'package:flutter/widgets.dart';

import 'provider.dart';

/// Base class for controllers that extends ChangeNotifier
///
/// Provides a consistent pattern for controller implementation and access.
/// Controllers manage application state and business logic, exposing reactive
/// state through ChangeNotifier.
abstract class Controller extends ChangeNotifier {
  /// Accesses a controller of type [T] from the widget tree
  ///
  /// Throws [FlutterError] if no controller of type [T] is found.
  static T ofType<T extends Controller>(BuildContext context) {
    return InheritedNotifierData.of<T>(context);
  }
}

/// Provider widget for controllers with manual rebuild control
///
/// Unlike InheritedNotifierData, this provider does NOT automatically rebuild
/// dependents when the controller notifies. Instead, consumers must use
/// ListenableBuilder or similar widgets to selectively rebuild.
///
/// This provides fine-grained control over rebuild behavior, useful when a
/// controller manages multiple pieces of state and you want to avoid
/// unnecessary rebuilds.
class ControllerProvider<T extends Controller> extends InheritedWidget {
  final T controller;

  const ControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(ControllerProvider<T> oldWidget) => false;

  static T of<T extends Controller>(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ControllerProvider<T>>();
    if (provider == null) {
      throw FlutterError(
        'ControllerProvider<$T> not found in widget tree.\n'
        'Make sure you have a ControllerProvider<$T> ancestor.',
      );
    }
    return provider.controller;
  }
}

/// Builder widget for controllers with automatic rebuilds
///
/// This widget uses InheritedNotifierData to provide automatic rebuild
/// propagation when the controller notifies. All dependent widgets will
/// rebuild when the controller changes.
///
/// Use this when you want automatic reactivity without manual ListenableBuilder
/// wrappers. For more control over rebuilds, use ControllerProvider instead.
class ControllerBuilder<T extends Controller> extends InheritedNotifier<T> {
  const ControllerBuilder({
    super.key,
    required T controller,
    required super.child,
  }) : super(notifier: controller);

  static T of<T extends Controller>(BuildContext context) {
    final builder =
        context.dependOnInheritedWidgetOfExactType<ControllerBuilder<T>>();
    if (builder == null) {
      throw FlutterError(
        'ControllerBuilder<$T> not found in widget tree.\n'
        'Make sure you have a ControllerBuilder<$T> ancestor.',
      );
    }
    return builder.notifier!;
  }
}
