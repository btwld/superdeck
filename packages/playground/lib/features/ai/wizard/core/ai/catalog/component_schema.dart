import 'package:json_schema_builder/json_schema_builder.dart';

Schema componentSchema(Schema schema) {
  final schemaMap = Map<String, Object?>.from(schema.value);
  final properties = Map<String, Object?>.from(
    (schemaMap['properties'] as Map?) ?? {},
  );
  final required = [
    for (final value in (schemaMap['required'] as List?) ?? const <Object?>[])
      value.toString(),
  ];

  properties['id'] = {'type': 'string', 'description': 'Unique component id.'};
  if (!required.contains('id')) {
    required.insert(0, 'id');
  }

  return ObjectSchema.fromMap({
    ...schemaMap,
    'properties': properties,
    'required': required,
  });
}
