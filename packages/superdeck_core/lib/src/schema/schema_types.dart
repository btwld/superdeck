part of 'schema.dart';

@protected
T? _tryParse<T extends Object>(Object value) {
  if (value is T) return value;
  if (value is! String) return null;
  if (T == bool) return bool.tryParse(value) as T?;
  if (T == int) return int.tryParse(value) as T?;
  if (T == double) return double.tryParse(value) as T?;
  if (T == num) return num.tryParse(value) as T?;
  return null;
}

typedef _DoubleSchema = Schema<double>;
typedef _IntSchema = Schema<int>;
typedef _BooleanSchema = Schema<bool>;
typedef _StringSchema = Schema<String>;

mixin SchemaType<S extends Schema> {
  @protected
  S getSchema();
}

final class Ok<S extends Schema<T>, T extends Object> with SchemaType<S> {
  final S _schema;
  const Ok(this._schema);

  @override
  S nullable() => _schema.copyWith(nullable: true) as S;

  S constraints(List<ConstraintsValidator<T>> constraints) {
    return _schema.copyWith(constraints: constraints) as S;
  }

  S call() => _schema;

  @override
  S getSchema() => _schema;

  void validateOrThrow(Object value) {
    final errors = validate(value);
    if (errors.isNotEmpty) {
      throw SchemaValidationException(errors);
    }
  }

  @override
  List<ValidationError> validate(Object? value) {
    try {
      return _schema.validate(value);
    } catch (e, stackTrace) {
      return [
        ValidationError.unknown(
          message: 'Unknown error: $e',
          context: {
            'error': e,
            'stackTrace': stackTrace,
            'value': value,
            'schema': _schema,
          },
        )
      ];
    }
  }

  @override
  S _getSchema() => _schema;

  static Ok<MapSchema, MapValue> _object(
    Map<String, SchemaType> properties, {
    bool additionalProperties = false,
    List<String> required = const [],
  }) {
    return Ok(
      MapSchema(
        {
          for (final entry in properties.entries)
            entry.key: entry.value.getSchema()
        },
        additionalProperties: additionalProperties,
        required: required,
      ),
    );
  }

  static Ok<DiscriminatedMapSchema, MapValue> _discriminated({
    required String discriminatorKey,
    required Map<String, SchemaType<MapSchema>> schemas,
  }) {
    return Ok(
      DiscriminatedMapSchema(
        discriminatorKey: discriminatorKey,
        schemas: {
          for (final entry in schemas.entries)
            entry.key: entry.value.getSchema()
        },
      ),
    );
  }

  static Ok<ListSchema<T, V>, List<V>>
      _list<T extends Schema<V>, V extends Object>(
    SchemaType<T> itemSchema,
  ) {
    return Ok(ListSchema(itemSchema.getSchema()));
  }

  static Ok<EnumSchema, String> _enum(List<String> values) {
    return Ok(EnumSchema(values));
  }

  static Ok<EnumSchema, String> _enumFromEnum(List<Enum> values) {
    return Ok(EnumSchema(values.map((e) => e.name).toList()));
  }

  static const string = Ok(_StringSchema());
  static const object = _object;
  static const boolean = Ok(_BooleanSchema());
  static const discriminated = _discriminated;

  static const int = Ok(_IntSchema());
  static const double = Ok(_DoubleSchema());
  static const list = _list;
  static final enumValues = _enumFromEnum;
  static final enumString = _enum;
}

final class Schema<T extends Object> with SchemaType<Schema<T>> {
  final bool _nullable;

  @protected
  final List<ConstraintsValidator<T>> _constraints;
  const Schema({
    bool nullable = false,
    List<ConstraintsValidator<T>>? constraints,
  })  : _nullable = nullable,
        _constraints = constraints ?? const [];

  Schema<T> copyWith({
    bool? nullable,
    List<ConstraintsValidator<T>>? constraints,
  }) {
    return Schema<T>(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
    );
  }

  @override
  Schema<T> getSchema() => this;

  T? tryParse(Object value) => _tryParse<T>(value);

  Schema<T> withValidator(ConstraintsValidator<T> validator) {
    return copyWith(constraints: [
      ..._constraints,
      validator,
    ]);
  }

  @protected
  List<ValidationError> validateParsed(T value) {
    final constraintsErrors = <ConstraintsValidationError>[];

    for (final constraint in _constraints) {
      final error = constraint.validate(value);
      if (error != null) {
        constraintsErrors.add(error);
      }
    }

    return constraintsErrors.isEmpty
        ? []
        : [ValidationError.constraints(constraintsErrors)];
  }

  List<ValidationError> validate(Object? value) {
    if (value == null) {
      return _nullable ? [] : [ValidationError.nonNullableValue()];
    }

    final typedValue = tryParse(value);
    if (typedValue == null) {
      return [
        ValidationError.invalidType(
          invalidType: value.runtimeType,
          expectedType: T,
        )
      ];
    }

    return validateParsed(typedValue);
  }
}

final class DiscriminatedMapSchema extends Schema<MapValue> {
  final String _discriminatorKey;
  final Map<String, MapSchema> _schemas;

  const DiscriminatedMapSchema({
    super.nullable,
    required String discriminatorKey,
    required Map<String, MapSchema> schemas,
    super.constraints,
  })  : _discriminatorKey = discriminatorKey,
        _schemas = schemas;

  @override
  DiscriminatedMapSchema copyWith({
    List<ConstraintsValidator<MapValue>>? constraints,
    String? discriminatorKey,
    Map<String, MapSchema>? schemas,
    bool? nullable,
  }) {
    return DiscriminatedMapSchema(
      discriminatorKey: discriminatorKey ?? _discriminatorKey,
      schemas: schemas ?? _schemas,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
    );
  }

  @override
  MapValue? tryParse(Object value) {
    return value is MapValue ? value : null;
  }

  MapSchema? _getDiscriminatedKeyValue(MapValue value) {
    final discriminatorValue = value[_discriminatorKey];
    return discriminatorValue != null ? _schemas[discriminatorValue] : null;
  }

  @override
  List<ValidationError> validateParsed(MapValue value) {
    final discriminatedSchema = _getDiscriminatedKeyValue(value);
    if (discriminatedSchema == null) {
      return [
        ValidationError.discriminatorKey(
          _discriminatorKey,
          {DiscriminatorKeyError.noSchema},
        ),
      ];
    } else {
      final errors = <DiscriminatorKeyError>{};
      if (!discriminatedSchema.required.contains(_discriminatorKey)) {
        errors.add(DiscriminatorKeyError.isRequiredInSchema);
      }
      if (discriminatedSchema._properties.containsKey(_discriminatorKey)) {
        errors.add(DiscriminatorKeyError.missing);
      }
      if (errors.isNotEmpty) {
        return [
          ValidationError.discriminatorKey(
            _discriminatorKey,
            errors,
          ),
        ];
      }
      return discriminatedSchema.validate(value);
    }
  }
}

typedef MapValue = Map<String, Object?>;

final class EnumSchema extends Schema<String> {
  EnumSchema(List<String> values, {super.nullable})
      : super(constraints: [EnumValidator(values)]);
}

final class MapSchema extends Schema<MapValue> {
  final Map<String, Schema> _properties;
  final bool additionalProperties;
  final List<String> required;

  const MapSchema(
    this._properties, {
    this.additionalProperties = false,
    super.constraints = const [],
    this.required = const [],
    super.nullable,
  });

  @override
  MapSchema copyWith({
    bool? additionalProperties,
    List<String>? required,
    Map<String, Schema>? properties,
    List<ConstraintsValidator<MapValue>>? constraints,
    bool? nullable,
  }) {
    return MapSchema(
      properties ?? _properties,
      additionalProperties: additionalProperties ?? this.additionalProperties,
      required: required ?? this.required,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
    );
  }

  @override
  MapValue? tryParse(Object value) {
    return value is MapValue ? value : null;
  }

  MapSchema extend(
    Map<String, Schema> properties, {
    bool? additionalProperties,
    List<String>? required,
    List<ConstraintsValidator<MapValue>>? constraints,
  }) {
    // if property SchemaValue is of SchemaMap, we need to merge them
    final mergedProperties = {..._properties};

    for (final entry in properties.entries) {
      final key = entry.key;
      final prop = entry.value;

      final existingProp = mergedProperties[key];

      if (existingProp is MapSchema) {
        mergedProperties[key] = existingProp.extend(
          properties,
          additionalProperties: additionalProperties,
          constraints: constraints,
          required: required,
        );
      } else {
        mergedProperties[key] = prop;
      }
    }

    return copyWith(
      properties: mergedProperties,
      additionalProperties: additionalProperties,
      constraints: constraints,
      required: required,
    );
  }

  @override
  List<ValidationError> validateParsed(MapValue value) {
    final errors = <ValidationError>[];
    final valueKeys = value.keys.toSet();
    final schemaKeys = _properties.keys.toSet();
    final requiredKeys = required.toSet();

    // Check for unallowed additional properties
    if (!additionalProperties) {
      for (final key in valueKeys.difference(schemaKeys)) {
        errors.add(ValidationError.unallowedAdditionalProperty(key));
      }
    }

    // Validate properties
    for (final key in schemaKeys) {
      final schemaProp = _properties[key]!;
      final prop = value[key];
      if (prop == null) {
        if (requiredKeys.contains(key)) {
          errors.add(ValidationError.requiredPropertyMissing(key));
        }
      } else {
        final propErrors = schemaProp.validate(prop);
        errors.add(ValidationError.propertyError(key, propErrors));
      }
    }

    return errors;
  }
}

final class ListSchema<T extends Schema<V>, V extends Object>
    extends Schema<List<V>> {
  final T itemSchema;
  const ListSchema(
    this.itemSchema, {
    super.constraints = const [],
    super.nullable,
  });

  @override
  ListSchema<T, V> copyWith({
    List<ConstraintsValidator<List<V>>>? constraints,
    bool? nullable,
  }) {
    return ListSchema(
      itemSchema,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
    );
  }

  @override
  List<V>? tryParse(Object value) {
    if (value is! List) return null;

    final parsedList = <V>[];
    for (final v in value) {
      final parsed = itemSchema.tryParse(v);
      if (parsed == null) {
        parsedList.clear();
        break;
      }
      parsedList.add(parsed);
    }
    return parsedList;
  }

  @override
  List<ValidationError> validateParsed(List<V> value) {
    final errors = <ValidationError>[];
    for (var i = 0; i < value.length; i++) {
      final propErrors = itemSchema.validate(value[i]);
      errors.add(ValidationError.propertyError(i.toString(), propErrors));
    }
    return errors;
  }
}

extension StringSchemaExt on Schema<String> {
  Schema<String> isPosixPath() => withValidator(const PosixPathValidator());

  Schema<String> isEmail() => withValidator(const EmailValidator());

  Schema<String> isHexColor() => withValidator(const HexColorValidator());

  Schema<String> isEmpty() => withValidator(const IsEmptyValidator());

  Schema<String> minLength(int min) => withValidator(MinLengthValidator(min));

  Schema<String> maxLength(int max) => withValidator(MaxLengthValidator(max));
}

extension OkMapExt on Ok<MapSchema, MapValue> {
  Ok<MapSchema, MapValue> extend(
    Map<String, Schema> properties, {
    bool? additionalProperties,
    List<String>? required,
    List<ConstraintsValidator<MapValue>>? constraints,
  }) {
    return Ok(
      _schema.extend(
        {
          for (final entry in properties.entries)
            entry.key: entry.value.getSchema()
        },
        additionalProperties: additionalProperties,
        required: required,
        constraints: constraints,
      ),
    );
  }
}
