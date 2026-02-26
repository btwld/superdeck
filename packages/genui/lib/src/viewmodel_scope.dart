import 'package:flutter/widgets.dart';

abstract interface class Disposable {
  void dispose();
}

/// A generic InheritedWidget for providing ViewModels to the widget tree.
///
/// Usage:
/// ```dart
/// ViewModelScope<MyViewModel>(
///   create: () => MyViewModel(),
///   child: MyWidget(),
/// )
/// ```
class ViewModelScope<T> extends StatefulWidget {
  final T Function() create;
  final Widget child;

  const ViewModelScope({super.key, required this.create, required this.child});

  /// Retrieves the ViewModel of type [T] from the nearest ancestor.
  static T of<T>(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<_ViewModelInherited<T>>();
    final widget = element?.widget as _ViewModelInherited<T>?;
    if (widget == null) {
      throw FlutterError('No ViewModelScope<$T> found in context');
    }
    return widget.viewModel;
  }

  @override
  State<ViewModelScope<T>> createState() => _ViewModelScopeState<T>();
}

class _ViewModelScopeState<T> extends State<ViewModelScope<T>> {
  late final T _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.create();
  }

  @override
  void dispose() {
    if (_viewModel is Disposable) {
      (_viewModel as Disposable).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ViewModelInherited<T>(viewModel: _viewModel, child: widget.child);
  }
}

class _ViewModelInherited<T> extends InheritedWidget {
  final T viewModel;

  const _ViewModelInherited({required this.viewModel, required super.child});

  @override
  bool updateShouldNotify(_ViewModelInherited<T> oldWidget) => false;
}

/// Extension to mirror Provider's context.read API.
extension ViewModelScopeExtension on BuildContext {
  /// Retrieves the ViewModel of type [T] without listening to changes.
  T read<T>() => ViewModelScope.of<T>(this);
}
