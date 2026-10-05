// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SyncOperationItem _$SyncOperationItemFromJson(Map<String, dynamic> json) {
  return _SyncOperationItem.fromJson(json);
}

/// @nodoc
mixin _$SyncOperationItem {
  @JsonKey(name: 'client_op_id')
  String get clientOpId => throw _privateConstructorUsedError;
  @JsonKey(name: 'device_id')
  String get deviceId => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_seq')
  int get clientSeq => throw _privateConstructorUsedError;
  @JsonKey(name: 'op_type')
  String get opType => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_ts')
  String get clientTs => throw _privateConstructorUsedError;

  /// Serializes this SyncOperationItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SyncOperationItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncOperationItemCopyWith<SyncOperationItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncOperationItemCopyWith<$Res> {
  factory $SyncOperationItemCopyWith(
    SyncOperationItem value,
    $Res Function(SyncOperationItem) then,
  ) = _$SyncOperationItemCopyWithImpl<$Res, SyncOperationItem>;
  @useResult
  $Res call({
    @JsonKey(name: 'client_op_id') String clientOpId,
    @JsonKey(name: 'device_id') String deviceId,
    @JsonKey(name: 'client_seq') int clientSeq,
    @JsonKey(name: 'op_type') String opType,
    Map<String, dynamic> payload,
    @JsonKey(name: 'client_ts') String clientTs,
  });
}

/// @nodoc
class _$SyncOperationItemCopyWithImpl<$Res, $Val extends SyncOperationItem>
    implements $SyncOperationItemCopyWith<$Res> {
  _$SyncOperationItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncOperationItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientOpId = null,
    Object? deviceId = null,
    Object? clientSeq = null,
    Object? opType = null,
    Object? payload = null,
    Object? clientTs = null,
  }) {
    return _then(
      _value.copyWith(
            clientOpId: null == clientOpId
                ? _value.clientOpId
                : clientOpId // ignore: cast_nullable_to_non_nullable
                      as String,
            deviceId: null == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String,
            clientSeq: null == clientSeq
                ? _value.clientSeq
                : clientSeq // ignore: cast_nullable_to_non_nullable
                      as int,
            opType: null == opType
                ? _value.opType
                : opType // ignore: cast_nullable_to_non_nullable
                      as String,
            payload: null == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            clientTs: null == clientTs
                ? _value.clientTs
                : clientTs // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SyncOperationItemImplCopyWith<$Res>
    implements $SyncOperationItemCopyWith<$Res> {
  factory _$$SyncOperationItemImplCopyWith(
    _$SyncOperationItemImpl value,
    $Res Function(_$SyncOperationItemImpl) then,
  ) = __$$SyncOperationItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'client_op_id') String clientOpId,
    @JsonKey(name: 'device_id') String deviceId,
    @JsonKey(name: 'client_seq') int clientSeq,
    @JsonKey(name: 'op_type') String opType,
    Map<String, dynamic> payload,
    @JsonKey(name: 'client_ts') String clientTs,
  });
}

/// @nodoc
class __$$SyncOperationItemImplCopyWithImpl<$Res>
    extends _$SyncOperationItemCopyWithImpl<$Res, _$SyncOperationItemImpl>
    implements _$$SyncOperationItemImplCopyWith<$Res> {
  __$$SyncOperationItemImplCopyWithImpl(
    _$SyncOperationItemImpl _value,
    $Res Function(_$SyncOperationItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncOperationItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientOpId = null,
    Object? deviceId = null,
    Object? clientSeq = null,
    Object? opType = null,
    Object? payload = null,
    Object? clientTs = null,
  }) {
    return _then(
      _$SyncOperationItemImpl(
        clientOpId: null == clientOpId
            ? _value.clientOpId
            : clientOpId // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        clientSeq: null == clientSeq
            ? _value.clientSeq
            : clientSeq // ignore: cast_nullable_to_non_nullable
                  as int,
        opType: null == opType
            ? _value.opType
            : opType // ignore: cast_nullable_to_non_nullable
                  as String,
        payload: null == payload
            ? _value._payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        clientTs: null == clientTs
            ? _value.clientTs
            : clientTs // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncOperationItemImpl implements _SyncOperationItem {
  const _$SyncOperationItemImpl({
    @JsonKey(name: 'client_op_id') required this.clientOpId,
    @JsonKey(name: 'device_id') required this.deviceId,
    @JsonKey(name: 'client_seq') required this.clientSeq,
    @JsonKey(name: 'op_type') required this.opType,
    required final Map<String, dynamic> payload,
    @JsonKey(name: 'client_ts') required this.clientTs,
  }) : _payload = payload;

  factory _$SyncOperationItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncOperationItemImplFromJson(json);

  @override
  @JsonKey(name: 'client_op_id')
  final String clientOpId;
  @override
  @JsonKey(name: 'device_id')
  final String deviceId;
  @override
  @JsonKey(name: 'client_seq')
  final int clientSeq;
  @override
  @JsonKey(name: 'op_type')
  final String opType;
  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  @JsonKey(name: 'client_ts')
  final String clientTs;

  @override
  String toString() {
    return 'SyncOperationItem(clientOpId: $clientOpId, deviceId: $deviceId, clientSeq: $clientSeq, opType: $opType, payload: $payload, clientTs: $clientTs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncOperationItemImpl &&
            (identical(other.clientOpId, clientOpId) ||
                other.clientOpId == clientOpId) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.clientSeq, clientSeq) ||
                other.clientSeq == clientSeq) &&
            (identical(other.opType, opType) || other.opType == opType) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.clientTs, clientTs) ||
                other.clientTs == clientTs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    clientOpId,
    deviceId,
    clientSeq,
    opType,
    const DeepCollectionEquality().hash(_payload),
    clientTs,
  );

  /// Create a copy of SyncOperationItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncOperationItemImplCopyWith<_$SyncOperationItemImpl> get copyWith =>
      __$$SyncOperationItemImplCopyWithImpl<_$SyncOperationItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncOperationItemImplToJson(this);
  }
}

abstract class _SyncOperationItem implements SyncOperationItem {
  const factory _SyncOperationItem({
    @JsonKey(name: 'client_op_id') required final String clientOpId,
    @JsonKey(name: 'device_id') required final String deviceId,
    @JsonKey(name: 'client_seq') required final int clientSeq,
    @JsonKey(name: 'op_type') required final String opType,
    required final Map<String, dynamic> payload,
    @JsonKey(name: 'client_ts') required final String clientTs,
  }) = _$SyncOperationItemImpl;

  factory _SyncOperationItem.fromJson(Map<String, dynamic> json) =
      _$SyncOperationItemImpl.fromJson;

  @override
  @JsonKey(name: 'client_op_id')
  String get clientOpId;
  @override
  @JsonKey(name: 'device_id')
  String get deviceId;
  @override
  @JsonKey(name: 'client_seq')
  int get clientSeq;
  @override
  @JsonKey(name: 'op_type')
  String get opType;
  @override
  Map<String, dynamic> get payload;
  @override
  @JsonKey(name: 'client_ts')
  String get clientTs;

  /// Create a copy of SyncOperationItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncOperationItemImplCopyWith<_$SyncOperationItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SyncBatchRequest _$SyncBatchRequestFromJson(Map<String, dynamic> json) {
  return _SyncBatchRequest.fromJson(json);
}

/// @nodoc
mixin _$SyncBatchRequest {
  List<SyncOperationItem> get operations => throw _privateConstructorUsedError;

  /// Serializes this SyncBatchRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SyncBatchRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncBatchRequestCopyWith<SyncBatchRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncBatchRequestCopyWith<$Res> {
  factory $SyncBatchRequestCopyWith(
    SyncBatchRequest value,
    $Res Function(SyncBatchRequest) then,
  ) = _$SyncBatchRequestCopyWithImpl<$Res, SyncBatchRequest>;
  @useResult
  $Res call({List<SyncOperationItem> operations});
}

/// @nodoc
class _$SyncBatchRequestCopyWithImpl<$Res, $Val extends SyncBatchRequest>
    implements $SyncBatchRequestCopyWith<$Res> {
  _$SyncBatchRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncBatchRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? operations = null}) {
    return _then(
      _value.copyWith(
            operations: null == operations
                ? _value.operations
                : operations // ignore: cast_nullable_to_non_nullable
                      as List<SyncOperationItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SyncBatchRequestImplCopyWith<$Res>
    implements $SyncBatchRequestCopyWith<$Res> {
  factory _$$SyncBatchRequestImplCopyWith(
    _$SyncBatchRequestImpl value,
    $Res Function(_$SyncBatchRequestImpl) then,
  ) = __$$SyncBatchRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<SyncOperationItem> operations});
}

/// @nodoc
class __$$SyncBatchRequestImplCopyWithImpl<$Res>
    extends _$SyncBatchRequestCopyWithImpl<$Res, _$SyncBatchRequestImpl>
    implements _$$SyncBatchRequestImplCopyWith<$Res> {
  __$$SyncBatchRequestImplCopyWithImpl(
    _$SyncBatchRequestImpl _value,
    $Res Function(_$SyncBatchRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncBatchRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? operations = null}) {
    return _then(
      _$SyncBatchRequestImpl(
        operations: null == operations
            ? _value._operations
            : operations // ignore: cast_nullable_to_non_nullable
                  as List<SyncOperationItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncBatchRequestImpl implements _SyncBatchRequest {
  const _$SyncBatchRequestImpl({
    required final List<SyncOperationItem> operations,
  }) : _operations = operations;

  factory _$SyncBatchRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncBatchRequestImplFromJson(json);

  final List<SyncOperationItem> _operations;
  @override
  List<SyncOperationItem> get operations {
    if (_operations is EqualUnmodifiableListView) return _operations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_operations);
  }

  @override
  String toString() {
    return 'SyncBatchRequest(operations: $operations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncBatchRequestImpl &&
            const DeepCollectionEquality().equals(
              other._operations,
              _operations,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_operations),
  );

  /// Create a copy of SyncBatchRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncBatchRequestImplCopyWith<_$SyncBatchRequestImpl> get copyWith =>
      __$$SyncBatchRequestImplCopyWithImpl<_$SyncBatchRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncBatchRequestImplToJson(this);
  }
}

abstract class _SyncBatchRequest implements SyncBatchRequest {
  const factory _SyncBatchRequest({
    required final List<SyncOperationItem> operations,
  }) = _$SyncBatchRequestImpl;

  factory _SyncBatchRequest.fromJson(Map<String, dynamic> json) =
      _$SyncBatchRequestImpl.fromJson;

  @override
  List<SyncOperationItem> get operations;

  /// Create a copy of SyncBatchRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncBatchRequestImplCopyWith<_$SyncBatchRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SyncOperationResultItem _$SyncOperationResultItemFromJson(
  Map<String, dynamic> json,
) {
  return _SyncOperationResultItem.fromJson(json);
}

/// @nodoc
mixin _$SyncOperationResultItem {
  @JsonKey(name: 'client_op_id')
  String get clientOpId => throw _privateConstructorUsedError;
  SyncOpResult get result => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;

  /// Serializes this SyncOperationResultItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SyncOperationResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncOperationResultItemCopyWith<SyncOperationResultItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncOperationResultItemCopyWith<$Res> {
  factory $SyncOperationResultItemCopyWith(
    SyncOperationResultItem value,
    $Res Function(SyncOperationResultItem) then,
  ) = _$SyncOperationResultItemCopyWithImpl<$Res, SyncOperationResultItem>;
  @useResult
  $Res call({
    @JsonKey(name: 'client_op_id') String clientOpId,
    SyncOpResult result,
    String? reason,
  });
}

/// @nodoc
class _$SyncOperationResultItemCopyWithImpl<
  $Res,
  $Val extends SyncOperationResultItem
>
    implements $SyncOperationResultItemCopyWith<$Res> {
  _$SyncOperationResultItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncOperationResultItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientOpId = null,
    Object? result = null,
    Object? reason = freezed,
  }) {
    return _then(
      _value.copyWith(
            clientOpId: null == clientOpId
                ? _value.clientOpId
                : clientOpId // ignore: cast_nullable_to_non_nullable
                      as String,
            result: null == result
                ? _value.result
                : result // ignore: cast_nullable_to_non_nullable
                      as SyncOpResult,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SyncOperationResultItemImplCopyWith<$Res>
    implements $SyncOperationResultItemCopyWith<$Res> {
  factory _$$SyncOperationResultItemImplCopyWith(
    _$SyncOperationResultItemImpl value,
    $Res Function(_$SyncOperationResultItemImpl) then,
  ) = __$$SyncOperationResultItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'client_op_id') String clientOpId,
    SyncOpResult result,
    String? reason,
  });
}

/// @nodoc
class __$$SyncOperationResultItemImplCopyWithImpl<$Res>
    extends
        _$SyncOperationResultItemCopyWithImpl<
          $Res,
          _$SyncOperationResultItemImpl
        >
    implements _$$SyncOperationResultItemImplCopyWith<$Res> {
  __$$SyncOperationResultItemImplCopyWithImpl(
    _$SyncOperationResultItemImpl _value,
    $Res Function(_$SyncOperationResultItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncOperationResultItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientOpId = null,
    Object? result = null,
    Object? reason = freezed,
  }) {
    return _then(
      _$SyncOperationResultItemImpl(
        clientOpId: null == clientOpId
            ? _value.clientOpId
            : clientOpId // ignore: cast_nullable_to_non_nullable
                  as String,
        result: null == result
            ? _value.result
            : result // ignore: cast_nullable_to_non_nullable
                  as SyncOpResult,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncOperationResultItemImpl implements _SyncOperationResultItem {
  const _$SyncOperationResultItemImpl({
    @JsonKey(name: 'client_op_id') required this.clientOpId,
    required this.result,
    this.reason,
  });

  factory _$SyncOperationResultItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncOperationResultItemImplFromJson(json);

  @override
  @JsonKey(name: 'client_op_id')
  final String clientOpId;
  @override
  final SyncOpResult result;
  @override
  final String? reason;

  @override
  String toString() {
    return 'SyncOperationResultItem(clientOpId: $clientOpId, result: $result, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncOperationResultItemImpl &&
            (identical(other.clientOpId, clientOpId) ||
                other.clientOpId == clientOpId) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, clientOpId, result, reason);

  /// Create a copy of SyncOperationResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncOperationResultItemImplCopyWith<_$SyncOperationResultItemImpl>
  get copyWith =>
      __$$SyncOperationResultItemImplCopyWithImpl<
        _$SyncOperationResultItemImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncOperationResultItemImplToJson(this);
  }
}

abstract class _SyncOperationResultItem implements SyncOperationResultItem {
  const factory _SyncOperationResultItem({
    @JsonKey(name: 'client_op_id') required final String clientOpId,
    required final SyncOpResult result,
    final String? reason,
  }) = _$SyncOperationResultItemImpl;

  factory _SyncOperationResultItem.fromJson(Map<String, dynamic> json) =
      _$SyncOperationResultItemImpl.fromJson;

  @override
  @JsonKey(name: 'client_op_id')
  String get clientOpId;
  @override
  SyncOpResult get result;
  @override
  String? get reason;

  /// Create a copy of SyncOperationResultItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncOperationResultItemImplCopyWith<_$SyncOperationResultItemImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SyncBatchResponse _$SyncBatchResponseFromJson(Map<String, dynamic> json) {
  return _SyncBatchResponse.fromJson(json);
}

/// @nodoc
mixin _$SyncBatchResponse {
  List<SyncOperationResultItem> get results =>
      throw _privateConstructorUsedError;

  /// Serializes this SyncBatchResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SyncBatchResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncBatchResponseCopyWith<SyncBatchResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncBatchResponseCopyWith<$Res> {
  factory $SyncBatchResponseCopyWith(
    SyncBatchResponse value,
    $Res Function(SyncBatchResponse) then,
  ) = _$SyncBatchResponseCopyWithImpl<$Res, SyncBatchResponse>;
  @useResult
  $Res call({List<SyncOperationResultItem> results});
}

/// @nodoc
class _$SyncBatchResponseCopyWithImpl<$Res, $Val extends SyncBatchResponse>
    implements $SyncBatchResponseCopyWith<$Res> {
  _$SyncBatchResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncBatchResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? results = null}) {
    return _then(
      _value.copyWith(
            results: null == results
                ? _value.results
                : results // ignore: cast_nullable_to_non_nullable
                      as List<SyncOperationResultItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SyncBatchResponseImplCopyWith<$Res>
    implements $SyncBatchResponseCopyWith<$Res> {
  factory _$$SyncBatchResponseImplCopyWith(
    _$SyncBatchResponseImpl value,
    $Res Function(_$SyncBatchResponseImpl) then,
  ) = __$$SyncBatchResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<SyncOperationResultItem> results});
}

/// @nodoc
class __$$SyncBatchResponseImplCopyWithImpl<$Res>
    extends _$SyncBatchResponseCopyWithImpl<$Res, _$SyncBatchResponseImpl>
    implements _$$SyncBatchResponseImplCopyWith<$Res> {
  __$$SyncBatchResponseImplCopyWithImpl(
    _$SyncBatchResponseImpl _value,
    $Res Function(_$SyncBatchResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncBatchResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? results = null}) {
    return _then(
      _$SyncBatchResponseImpl(
        results: null == results
            ? _value._results
            : results // ignore: cast_nullable_to_non_nullable
                  as List<SyncOperationResultItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncBatchResponseImpl implements _SyncBatchResponse {
  const _$SyncBatchResponseImpl({
    required final List<SyncOperationResultItem> results,
  }) : _results = results;

  factory _$SyncBatchResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncBatchResponseImplFromJson(json);

  final List<SyncOperationResultItem> _results;
  @override
  List<SyncOperationResultItem> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  String toString() {
    return 'SyncBatchResponse(results: $results)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncBatchResponseImpl &&
            const DeepCollectionEquality().equals(other._results, _results));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_results));

  /// Create a copy of SyncBatchResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncBatchResponseImplCopyWith<_$SyncBatchResponseImpl> get copyWith =>
      __$$SyncBatchResponseImplCopyWithImpl<_$SyncBatchResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncBatchResponseImplToJson(this);
  }
}

abstract class _SyncBatchResponse implements SyncBatchResponse {
  const factory _SyncBatchResponse({
    required final List<SyncOperationResultItem> results,
  }) = _$SyncBatchResponseImpl;

  factory _SyncBatchResponse.fromJson(Map<String, dynamic> json) =
      _$SyncBatchResponseImpl.fromJson;

  @override
  List<SyncOperationResultItem> get results;

  /// Create a copy of SyncBatchResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncBatchResponseImplCopyWith<_$SyncBatchResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
