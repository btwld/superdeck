import 'package:flutter/widgets.dart';

class InheritedData<T> extends InheritedWidget {
  const InheritedData({super.key, required super.child, required this.data});

  final T data;

  @override
  bool updateShouldNotify(covariant InheritedData<T> oldWidget) {
    return oldWidget.data != data;
  }

  static T? maybeOf<T>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<InheritedData<T>>();
    return provider?.data;
  }

  static T of<T>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<InheritedData<T>>();
    if (provider == null) {
      throw FlutterError('Provider of type $T not found in the widget tree');
    }
    return provider.data;
  }
}
