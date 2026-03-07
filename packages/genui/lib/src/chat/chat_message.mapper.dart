// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'chat_message.dart';

class UserActionPayloadMapper extends ClassMapperBase<UserActionPayload> {
  UserActionPayloadMapper._();

  static UserActionPayloadMapper? _instance;
  static UserActionPayloadMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = UserActionPayloadMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'UserActionPayload';

  static String _$actionName(UserActionPayload v) => v.actionName;
  static const Field<UserActionPayload, String> _f$actionName = Field(
    'actionName',
    _$actionName,
  );
  static Map<String, dynamic> _$context(UserActionPayload v) => v.context;
  static const Field<UserActionPayload, Map<String, dynamic>> _f$context =
      Field('context', _$context);

  @override
  final MappableFields<UserActionPayload> fields = const {
    #actionName: _f$actionName,
    #context: _f$context,
  };

  static UserActionPayload _instantiate(DecodingData data) {
    return UserActionPayload(
      actionName: data.dec(_f$actionName),
      context: data.dec(_f$context),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static UserActionPayload fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<UserActionPayload>(map);
  }

  static UserActionPayload fromJson(String json) {
    return ensureInitialized().decodeJson<UserActionPayload>(json);
  }
}

mixin UserActionPayloadMappable {
  String toJson() {
    return UserActionPayloadMapper.ensureInitialized()
        .encodeJson<UserActionPayload>(this as UserActionPayload);
  }

  Map<String, dynamic> toMap() {
    return UserActionPayloadMapper.ensureInitialized()
        .encodeMap<UserActionPayload>(this as UserActionPayload);
  }

  UserActionPayloadCopyWith<
    UserActionPayload,
    UserActionPayload,
    UserActionPayload
  >
  get copyWith =>
      _UserActionPayloadCopyWithImpl<UserActionPayload, UserActionPayload>(
        this as UserActionPayload,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return UserActionPayloadMapper.ensureInitialized().stringifyValue(
      this as UserActionPayload,
    );
  }

  @override
  bool operator ==(Object other) {
    return UserActionPayloadMapper.ensureInitialized().equalsValue(
      this as UserActionPayload,
      other,
    );
  }

  @override
  int get hashCode {
    return UserActionPayloadMapper.ensureInitialized().hashValue(
      this as UserActionPayload,
    );
  }
}

extension UserActionPayloadValueCopy<$R, $Out>
    on ObjectCopyWith<$R, UserActionPayload, $Out> {
  UserActionPayloadCopyWith<$R, UserActionPayload, $Out>
  get $asUserActionPayload => $base.as(
    (v, t, t2) => _UserActionPayloadCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class UserActionPayloadCopyWith<
  $R,
  $In extends UserActionPayload,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>
  get context;
  $R call({String? actionName, Map<String, dynamic>? context});
  UserActionPayloadCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _UserActionPayloadCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, UserActionPayload, $Out>
    implements UserActionPayloadCopyWith<$R, UserActionPayload, $Out> {
  _UserActionPayloadCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<UserActionPayload> $mapper =
      UserActionPayloadMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>
  get context => MapCopyWith(
    $value.context,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(context: v),
  );
  @override
  $R call({String? actionName, Map<String, dynamic>? context}) => $apply(
    FieldCopyWithData({
      if (actionName != null) #actionName: actionName,
      if (context != null) #context: context,
    }),
  );
  @override
  UserActionPayload $make(CopyWithData data) => UserActionPayload(
    actionName: data.get(#actionName, or: $value.actionName),
    context: data.get(#context, or: $value.context),
  );

  @override
  UserActionPayloadCopyWith<$R2, UserActionPayload, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _UserActionPayloadCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

