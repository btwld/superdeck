import 'package:ack/ack.dart';

extension StringX on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  String snakeCase() {
    return replaceAll(RegExp(r'\s+'), '_')
        .replaceAllMapped(
            RegExp(
                r'[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+'),
            (match) => "${match.group(0)!.toLowerCase()}_")
        .replaceAll(RegExp(r'(_)\1+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

extension ListX<T> on List<T> {
  T? get tryFirst => isNotEmpty ? first : null;
  T? get tryLast => isNotEmpty ? last : null;
  T? tryElementAt(int index) {
    if (index < 0 || index >= length) {
      return null;
    }

    return elementAt(index);
  }
}

StringSchema ackEnum(List<Enum> values) {
  return Ack.enumString(values.map((e) => e.name.snakeCase()).toList());
}
