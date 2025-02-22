part of 'schema.dart';

sealed class ConstraintsValidator<T> {
  const ConstraintsValidator();

  ConstraintsValidationError? validate(T value);
}

class EnumValidator extends ConstraintsValidator<String> {
  final List<String> enumValues;
  const EnumValidator(this.enumValues);

  @override
  ConstraintsValidationError? validate(String value) {
    if (enumValues.contains(value)) {
      return null;
    }
    return ConstraintsValidationError(
      message: 'Value is not a valid enum value',
      context: {'value': value, 'possibleValues': enumValues},
    );
  }
}

class EmailValidator extends RegexValidator {
  const EmailValidator()
      : super(
          name: 'email',
          pattern: r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$',
          example: 'example@domain.com',
        );
}

class UrlValidator extends RegexValidator {
  const UrlValidator()
      : super(
          name: 'url',
          pattern:
              r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
          example: 'https://example.com',
        );
}

class PosixPathValidator extends RegexValidator {
  const PosixPathValidator()
      : super(
          name: 'posix path',
          example: '/path/to/file',
          pattern: r'^(/[^/ ]*)+/?$',
        );
}

class HexColorValidator extends RegexValidator {
  const HexColorValidator()
      : super(
          name: 'hex color',
          example: '#ff0000',
          pattern: r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$',
        );
}

class OneOfValidator extends ConstraintsValidator<String> {
  final List<String> values;
  const OneOfValidator(this.values);

  @override
  ConstraintsValidationError? validate(String value) {
    if (values.contains(value)) {
      return null;
    }
    return ConstraintsValidationError(
      message: 'Value is not one of the allowed values',
    );
  }
}

class NotOneOfValidator extends ConstraintsValidator<String> {
  final List<String> values;
  const NotOneOfValidator(this.values);

  @override
  ConstraintsValidationError? validate(String value) {
    if (values.contains(value)) {
      return ConstraintsValidationError(
        message: 'Value is one of the allowed values',
      );
    }
    return null;
  }
}

class NotEmptyValidator extends ConstraintsValidator<String> {
  const NotEmptyValidator();

  @override
  ConstraintsValidationError? validate(String value) {
    return value.isEmpty
        ? ConstraintsValidationError(
            message: 'String is empty',
          )
        : null;
  }
}

class RegexValidator extends ConstraintsValidator<String> {
  final String name;
  final String pattern;
  final String example;
  const RegexValidator({
    required this.name,
    required this.pattern,
    required this.example,
  });

  @override
  ConstraintsValidationError? validate(String value) {
    if (!RegExp(pattern).hasMatch(value)) {
      return ConstraintsValidationError(
        message: 'String does is not $name. Example: $example',
      );
    }

    return null;
  }
}

class IsEmptyValidator extends ConstraintsValidator<String> {
  const IsEmptyValidator();

  @override
  ConstraintsValidationError? validate(String value) {
    return value.isEmpty
        ? null
        : ConstraintsValidationError(
            message: 'String is not empty',
          );
  }
}

class MinLengthValidator extends ConstraintsValidator<String> {
  final int min;
  const MinLengthValidator(this.min);

  @override
  ConstraintsValidationError? validate(String value) {
    return value.length >= min
        ? null
        : ConstraintsValidationError(
            message:
                'String length is less than the minimum required length: $min',
          );
  }
}

class MaxLengthValidator extends ConstraintsValidator<String> {
  final int max;
  const MaxLengthValidator(this.max);

  @override
  ConstraintsValidationError? validate(String value) {
    return value.length <= max
        ? null
        : ConstraintsValidationError(
            message:
                'String length is greater than the maximum required length: $max',
          );
  }
}

class MinValueValidator extends ConstraintsValidator<num> {
  final num min;
  const MinValueValidator(this.min);

  @override
  ConstraintsValidationError? validate(num value) {
    return value >= min
        ? null
        : ConstraintsValidationError(
            message: 'Value is less than the minimum required value: $min',
          );
  }
}

class MaxValueValidator extends ConstraintsValidator<num> {
  final num max;
  const MaxValueValidator(this.max);

  @override
  ConstraintsValidationError? validate(num value) {
    return value <= max
        ? null
        : ConstraintsValidationError(
            message: 'Value is greater than the maximum required value: $max',
          );
  }
}

class RangeValidator extends ConstraintsValidator<num> {
  final num min;
  final num max;
  const RangeValidator(this.min, this.max);

  @override
  ConstraintsValidationError? validate(num value) {
    return value >= min && value <= max
        ? null
        : ConstraintsValidationError(
            message: 'Value is not within the required range: $min - $max',
          );
  }
}

class RequiredValidator<T> extends ConstraintsValidator<T> {
  const RequiredValidator();

  @override
  ConstraintsValidationError? validate(T value) {
    return value != null
        ? null
        : ConstraintsValidationError(
            message: 'is required',
          );
  }
}

// unique item list validator
class UniqueItemsValidator<T> extends ConstraintsValidator<List<T>> {
  const UniqueItemsValidator();

  @override
  ConstraintsValidationError? validate(List<T> value) {
    final unique = value.toSet().toList();
    return unique.length == value.length
        ? null
        : ConstraintsValidationError(
            message: 'List items are not unique',
          );
  }
}

// min length of list validator
class MinItemsValidator<T> extends ConstraintsValidator<List<T>> {
  final int min;
  const MinItemsValidator(this.min);

  @override
  ConstraintsValidationError? validate(List<T> value) {
    return value.length >= min
        ? null
        : ConstraintsValidationError(
            message:
                'List length is less than the minimum required length: $min',
          );
  }
}

// max length of list validator
class MaxItemsValidator<T> extends ConstraintsValidator<List<T>> {
  final int max;
  const MaxItemsValidator(this.max);

  @override
  ConstraintsValidationError? validate(List<T> value) {
    return value.length <= max
        ? null
        : ConstraintsValidationError(
            message:
                'List length is greater than the maximum required length: $max',
          );
  }
}
