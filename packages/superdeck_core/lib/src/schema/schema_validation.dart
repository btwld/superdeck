part of 'schema.dart';

enum ValidationErrorCode {
  discriminatorKeyError('Discriminator key error'),
  unallowedAdditionalProperty('Unallowed additional property'),
  requiredPropMissing('Missing required property'),
  constraints('Validation constraints not met'),
  invalidType('Invalid type'),
  nonNullableValue('Non nullable value is null'),
  unknown('Unknown error'),
  propertyError('Property validation error');

  const ValidationErrorCode(this.message);

  final String message;
}

enum DiscriminatorKeyError {
  missing('Missing discriminator key'),
  noSchema('No schema found for discriminator key'),
  isRequiredInSchema('Discriminator key is required in schema');

  const DiscriminatorKeyError(this.message);

  final String message;
}

class ValidationContext {
  final Map<String, Object?> _context;

  const ValidationContext({required Map<String, Object?> context})
      : _context = context;

  String get message => _context.isEmpty
      ? ''
      : _context.entries.map((e) => '${e.key}: ${e.value}').join('\n');
}

class ValidationError {
  final ValidationErrorCode code;
  final ValidationContext context;

  ValidationError._({
    required Map<String, Object?>? context,
    required this.code,
  }) : context = ValidationContext(context: context ?? {});

  ValidationError.discriminatorKey(
    String discriminatorKey,
    Set<DiscriminatorKeyError> errors,
  )   : code = ValidationErrorCode.discriminatorKeyError,
        context = ValidationContext(
          context: {
            'discriminatorKey': discriminatorKey,
            'errors': errors.map((e) => '${e.message}\n').toList(),
          },
        );

  ValidationError.unallowedAdditionalProperty(String propertyKey)
      : code = ValidationErrorCode.unallowedAdditionalProperty,
        context = ValidationContext(context: {'propertyKey': propertyKey});

  ValidationError.requiredPropertyMissing(String propertyKey)
      : code = ValidationErrorCode.requiredPropMissing,
        context = ValidationContext(context: {'property': propertyKey});

  ValidationError.propertyError(
    String propertyKey,
    List<ValidationError> errors,
  )   : code = ValidationErrorCode.propertyError,
        context = ValidationContext(context: {'property': propertyKey});

  ValidationError.invalidType(
      {required Type invalidType, required Type expectedType})
      : code = ValidationErrorCode.invalidType,
        context = ValidationContext(context: {
          'invalidType': invalidType,
          'expectedType': expectedType
        });

  ValidationError.nonNullableValue()
      : code = ValidationErrorCode.nonNullableValue,
        context = ValidationContext(context: {});

  ValidationError.unknown(
      {required String message, Map<String, Object?>? context})
      : code = ValidationErrorCode.unknown,
        context = ValidationContext(context: context ?? {});

  ValidationError.constraints(List<ConstraintsValidationError> constraintErrors)
      : code = ValidationErrorCode.constraints,
        context = ValidationContext(
          context: {
            'constraints':
                constraintErrors.map((e) => '${e.message}\n\n').toList(),
          },
        );

  @override
  String get message => '${code.message}\n\n${context.message}';
}

final class ConstraintsValidationError {
  final String _message;
  final ValidationContext _context;
  ConstraintsValidationError({
    required String message,
    Map<String, Object?>? context,
  })  : _message = message,
        _context = ValidationContext(context: context ?? {});

  String get message => '$_message\n\n${_context.message}';

  // ValidationContext get context => _context;
}

class SchemaValidationException implements Exception {
  final List<ValidationError> errors;
  final StackTrace? stackTrace;

  const SchemaValidationException(this.errors, {this.stackTrace});

  Map<String, dynamic> toJson() {
    return {
      'errors': errors
          .map((e) => {
                'type': e.code.message,
                'message': e.message,
              })
          .toList(),
    };
  }

  @override
  String toString() {
    return 'SchemaValidationException: $toJson()';
  }
}
