part of 'schema.dart';

sealed class ConstraintsValidator<T> {
  const ConstraintsValidator();

  ConstraintsValidationError? validate(T value);
}

extension SchemaExt<S extends Schema<T>, T extends Object> on S {
  S _constraint(ConstraintsValidator<T> validator) {
    return copyWith(
      constraints: [..._constraints, validator],
    ) as S;
  }
}

extension StringSchemaExt<S extends Schema<String>> on S {
  S isEmail() => _constraint(const EmailValidator());

  S isPosixPath() => _constraint(const PosixPathValidator());

  S isHexColor() => _constraint(const HexColorValidator());

  S isEmpty() => _constraint(const IsEmptyValidator());

  S minLength(int min) => _constraint(MinLengthValidator(min));

  S maxLength(int max) => _constraint(MaxLengthValidator(max));

  S oneOf(List<String> values) => _constraint(OneOfValidator(values));

  S notOneOf(List<String> values) => _constraint(NotOneOfValidator(values));

  S isEnum(List<String> values) => _constraint(EnumValidator(values));

  S isUrl() => _constraint(const UrlValidator());

  S isNotEmpty() => _constraint(const NotEmptyValidator());

  S isDateTime() => _constraint(const DateTimeValidator());
}

extension NumberSchemaExt<S extends Schema<num>> on S {
  S minValue(num min) => _constraint(MinValueValidator(min));

  S maxValue(num max) => _constraint(MaxValueValidator(max));

  S range(num min, num max) => _constraint(RangeValidator(min, max));
}

extension ListSchemaExt<S extends Schema<List<T>>, T extends Object> on S {
  S uniqueItems() => _constraint(const UniqueItemsValidator());

  S minItems(int min) => _constraint(MinItemsValidator(min));

  S maxItems(int max) => _constraint(MaxItemsValidator(max));
}

/// Validates that the input string can be parsed into a [DateTime] object.
class DateTimeValidator extends ConstraintsValidator<String> {
  const DateTimeValidator();

  /// Validates the input string and returns null if valid, or an error message if invalid.
  @override
  ConstraintsValidationError? validate(String value) {
    final dateTime = DateTime.tryParse(value);
    if (dateTime != null) {
      return null;
    }
    return ConstraintsValidationError(
      message: 'Invalid date format. Expected a valid date string.',
      context: {'value': value},
    );
  }
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
        message: 'Value is not allowed',
        context: {
          'value': value,
          'disallowedValues': values,
        },
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
        message:
            'String does not match the required $name format. Example: $example',
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

// unique item list validator
class UniqueItemsValidator<T> extends ConstraintsValidator<List<T>> {
  const UniqueItemsValidator();

  @override
  ConstraintsValidationError? validate(List<T> value) {
    final unique = value.toSet();
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
