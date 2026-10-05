// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_requests.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CreateLoadCheckRequest _$CreateLoadCheckRequestFromJson(
  Map<String, dynamic> json,
) {
  return _CreateLoadCheckRequest.fromJson(json);
}

/// @nodoc
mixin _$CreateLoadCheckRequest {
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'plan_version')
  int get planVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_qty')
  int get expectedQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'loaded_qty')
  int get loadedQty => throw _privateConstructorUsedError;
  LoadCheckIssue get issue => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_op_id')
  String? get clientOpId => throw _privateConstructorUsedError;

  /// Serializes this CreateLoadCheckRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateLoadCheckRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateLoadCheckRequestCopyWith<CreateLoadCheckRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateLoadCheckRequestCopyWith<$Res> {
  factory $CreateLoadCheckRequestCopyWith(
    CreateLoadCheckRequest value,
    $Res Function(CreateLoadCheckRequest) then,
  ) = _$CreateLoadCheckRequestCopyWithImpl<$Res, CreateLoadCheckRequest>;
  @useResult
  $Res call({
    @JsonKey(name: 'order_id') String orderId,
    @JsonKey(name: 'plan_version') int planVersion,
    @JsonKey(name: 'expected_qty') int expectedQty,
    @JsonKey(name: 'loaded_qty') int loadedQty,
    LoadCheckIssue issue,
    String? note,
    @JsonKey(name: 'client_op_id') String? clientOpId,
  });
}

/// @nodoc
class _$CreateLoadCheckRequestCopyWithImpl<
  $Res,
  $Val extends CreateLoadCheckRequest
>
    implements $CreateLoadCheckRequestCopyWith<$Res> {
  _$CreateLoadCheckRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateLoadCheckRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? planVersion = null,
    Object? expectedQty = null,
    Object? loadedQty = null,
    Object? issue = null,
    Object? note = freezed,
    Object? clientOpId = freezed,
  }) {
    return _then(
      _value.copyWith(
            orderId: null == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                      as String,
            planVersion: null == planVersion
                ? _value.planVersion
                : planVersion // ignore: cast_nullable_to_non_nullable
                      as int,
            expectedQty: null == expectedQty
                ? _value.expectedQty
                : expectedQty // ignore: cast_nullable_to_non_nullable
                      as int,
            loadedQty: null == loadedQty
                ? _value.loadedQty
                : loadedQty // ignore: cast_nullable_to_non_nullable
                      as int,
            issue: null == issue
                ? _value.issue
                : issue // ignore: cast_nullable_to_non_nullable
                      as LoadCheckIssue,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            clientOpId: freezed == clientOpId
                ? _value.clientOpId
                : clientOpId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateLoadCheckRequestImplCopyWith<$Res>
    implements $CreateLoadCheckRequestCopyWith<$Res> {
  factory _$$CreateLoadCheckRequestImplCopyWith(
    _$CreateLoadCheckRequestImpl value,
    $Res Function(_$CreateLoadCheckRequestImpl) then,
  ) = __$$CreateLoadCheckRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'order_id') String orderId,
    @JsonKey(name: 'plan_version') int planVersion,
    @JsonKey(name: 'expected_qty') int expectedQty,
    @JsonKey(name: 'loaded_qty') int loadedQty,
    LoadCheckIssue issue,
    String? note,
    @JsonKey(name: 'client_op_id') String? clientOpId,
  });
}

/// @nodoc
class __$$CreateLoadCheckRequestImplCopyWithImpl<$Res>
    extends
        _$CreateLoadCheckRequestCopyWithImpl<$Res, _$CreateLoadCheckRequestImpl>
    implements _$$CreateLoadCheckRequestImplCopyWith<$Res> {
  __$$CreateLoadCheckRequestImplCopyWithImpl(
    _$CreateLoadCheckRequestImpl _value,
    $Res Function(_$CreateLoadCheckRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateLoadCheckRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? planVersion = null,
    Object? expectedQty = null,
    Object? loadedQty = null,
    Object? issue = null,
    Object? note = freezed,
    Object? clientOpId = freezed,
  }) {
    return _then(
      _$CreateLoadCheckRequestImpl(
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as String,
        planVersion: null == planVersion
            ? _value.planVersion
            : planVersion // ignore: cast_nullable_to_non_nullable
                  as int,
        expectedQty: null == expectedQty
            ? _value.expectedQty
            : expectedQty // ignore: cast_nullable_to_non_nullable
                  as int,
        loadedQty: null == loadedQty
            ? _value.loadedQty
            : loadedQty // ignore: cast_nullable_to_non_nullable
                  as int,
        issue: null == issue
            ? _value.issue
            : issue // ignore: cast_nullable_to_non_nullable
                  as LoadCheckIssue,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        clientOpId: freezed == clientOpId
            ? _value.clientOpId
            : clientOpId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateLoadCheckRequestImpl implements _CreateLoadCheckRequest {
  const _$CreateLoadCheckRequestImpl({
    @JsonKey(name: 'order_id') required this.orderId,
    @JsonKey(name: 'plan_version') required this.planVersion,
    @JsonKey(name: 'expected_qty') required this.expectedQty,
    @JsonKey(name: 'loaded_qty') required this.loadedQty,
    required this.issue,
    this.note,
    @JsonKey(name: 'client_op_id') this.clientOpId,
  });

  factory _$CreateLoadCheckRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateLoadCheckRequestImplFromJson(json);

  @override
  @JsonKey(name: 'order_id')
  final String orderId;
  @override
  @JsonKey(name: 'plan_version')
  final int planVersion;
  @override
  @JsonKey(name: 'expected_qty')
  final int expectedQty;
  @override
  @JsonKey(name: 'loaded_qty')
  final int loadedQty;
  @override
  final LoadCheckIssue issue;
  @override
  final String? note;
  @override
  @JsonKey(name: 'client_op_id')
  final String? clientOpId;

  @override
  String toString() {
    return 'CreateLoadCheckRequest(orderId: $orderId, planVersion: $planVersion, expectedQty: $expectedQty, loadedQty: $loadedQty, issue: $issue, note: $note, clientOpId: $clientOpId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateLoadCheckRequestImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.planVersion, planVersion) ||
                other.planVersion == planVersion) &&
            (identical(other.expectedQty, expectedQty) ||
                other.expectedQty == expectedQty) &&
            (identical(other.loadedQty, loadedQty) ||
                other.loadedQty == loadedQty) &&
            (identical(other.issue, issue) || other.issue == issue) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.clientOpId, clientOpId) ||
                other.clientOpId == clientOpId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    orderId,
    planVersion,
    expectedQty,
    loadedQty,
    issue,
    note,
    clientOpId,
  );

  /// Create a copy of CreateLoadCheckRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateLoadCheckRequestImplCopyWith<_$CreateLoadCheckRequestImpl>
  get copyWith =>
      __$$CreateLoadCheckRequestImplCopyWithImpl<_$CreateLoadCheckRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateLoadCheckRequestImplToJson(this);
  }
}

abstract class _CreateLoadCheckRequest implements CreateLoadCheckRequest {
  const factory _CreateLoadCheckRequest({
    @JsonKey(name: 'order_id') required final String orderId,
    @JsonKey(name: 'plan_version') required final int planVersion,
    @JsonKey(name: 'expected_qty') required final int expectedQty,
    @JsonKey(name: 'loaded_qty') required final int loadedQty,
    required final LoadCheckIssue issue,
    final String? note,
    @JsonKey(name: 'client_op_id') final String? clientOpId,
  }) = _$CreateLoadCheckRequestImpl;

  factory _CreateLoadCheckRequest.fromJson(Map<String, dynamic> json) =
      _$CreateLoadCheckRequestImpl.fromJson;

  @override
  @JsonKey(name: 'order_id')
  String get orderId;
  @override
  @JsonKey(name: 'plan_version')
  int get planVersion;
  @override
  @JsonKey(name: 'expected_qty')
  int get expectedQty;
  @override
  @JsonKey(name: 'loaded_qty')
  int get loadedQty;
  @override
  LoadCheckIssue get issue;
  @override
  String? get note;
  @override
  @JsonKey(name: 'client_op_id')
  String? get clientOpId;

  /// Create a copy of CreateLoadCheckRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateLoadCheckRequestImplCopyWith<_$CreateLoadCheckRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ConfirmLoadRequest _$ConfirmLoadRequestFromJson(Map<String, dynamic> json) {
  return _ConfirmLoadRequest.fromJson(json);
}

/// @nodoc
mixin _$ConfirmLoadRequest {
  @JsonKey(name: 'plan_version')
  int get planVersion => throw _privateConstructorUsedError;

  /// Serializes this ConfirmLoadRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConfirmLoadRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConfirmLoadRequestCopyWith<ConfirmLoadRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConfirmLoadRequestCopyWith<$Res> {
  factory $ConfirmLoadRequestCopyWith(
    ConfirmLoadRequest value,
    $Res Function(ConfirmLoadRequest) then,
  ) = _$ConfirmLoadRequestCopyWithImpl<$Res, ConfirmLoadRequest>;
  @useResult
  $Res call({@JsonKey(name: 'plan_version') int planVersion});
}

/// @nodoc
class _$ConfirmLoadRequestCopyWithImpl<$Res, $Val extends ConfirmLoadRequest>
    implements $ConfirmLoadRequestCopyWith<$Res> {
  _$ConfirmLoadRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConfirmLoadRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? planVersion = null}) {
    return _then(
      _value.copyWith(
            planVersion: null == planVersion
                ? _value.planVersion
                : planVersion // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConfirmLoadRequestImplCopyWith<$Res>
    implements $ConfirmLoadRequestCopyWith<$Res> {
  factory _$$ConfirmLoadRequestImplCopyWith(
    _$ConfirmLoadRequestImpl value,
    $Res Function(_$ConfirmLoadRequestImpl) then,
  ) = __$$ConfirmLoadRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'plan_version') int planVersion});
}

/// @nodoc
class __$$ConfirmLoadRequestImplCopyWithImpl<$Res>
    extends _$ConfirmLoadRequestCopyWithImpl<$Res, _$ConfirmLoadRequestImpl>
    implements _$$ConfirmLoadRequestImplCopyWith<$Res> {
  __$$ConfirmLoadRequestImplCopyWithImpl(
    _$ConfirmLoadRequestImpl _value,
    $Res Function(_$ConfirmLoadRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConfirmLoadRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? planVersion = null}) {
    return _then(
      _$ConfirmLoadRequestImpl(
        planVersion: null == planVersion
            ? _value.planVersion
            : planVersion // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConfirmLoadRequestImpl implements _ConfirmLoadRequest {
  const _$ConfirmLoadRequestImpl({
    @JsonKey(name: 'plan_version') required this.planVersion,
  });

  factory _$ConfirmLoadRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConfirmLoadRequestImplFromJson(json);

  @override
  @JsonKey(name: 'plan_version')
  final int planVersion;

  @override
  String toString() {
    return 'ConfirmLoadRequest(planVersion: $planVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConfirmLoadRequestImpl &&
            (identical(other.planVersion, planVersion) ||
                other.planVersion == planVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, planVersion);

  /// Create a copy of ConfirmLoadRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConfirmLoadRequestImplCopyWith<_$ConfirmLoadRequestImpl> get copyWith =>
      __$$ConfirmLoadRequestImplCopyWithImpl<_$ConfirmLoadRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConfirmLoadRequestImplToJson(this);
  }
}

abstract class _ConfirmLoadRequest implements ConfirmLoadRequest {
  const factory _ConfirmLoadRequest({
    @JsonKey(name: 'plan_version') required final int planVersion,
  }) = _$ConfirmLoadRequestImpl;

  factory _ConfirmLoadRequest.fromJson(Map<String, dynamic> json) =
      _$ConfirmLoadRequestImpl.fromJson;

  @override
  @JsonKey(name: 'plan_version')
  int get planVersion;

  /// Create a copy of ConfirmLoadRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConfirmLoadRequestImplCopyWith<_$ConfirmLoadRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StartTripRequest _$StartTripRequestFromJson(Map<String, dynamic> json) {
  return _StartTripRequest.fromJson(json);
}

/// @nodoc
mixin _$StartTripRequest {
  @JsonKey(name: 'plan_version')
  int get planVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_op_id')
  String? get clientOpId => throw _privateConstructorUsedError;

  /// Serializes this StartTripRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StartTripRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StartTripRequestCopyWith<StartTripRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StartTripRequestCopyWith<$Res> {
  factory $StartTripRequestCopyWith(
    StartTripRequest value,
    $Res Function(StartTripRequest) then,
  ) = _$StartTripRequestCopyWithImpl<$Res, StartTripRequest>;
  @useResult
  $Res call({
    @JsonKey(name: 'plan_version') int planVersion,
    @JsonKey(name: 'client_op_id') String? clientOpId,
  });
}

/// @nodoc
class _$StartTripRequestCopyWithImpl<$Res, $Val extends StartTripRequest>
    implements $StartTripRequestCopyWith<$Res> {
  _$StartTripRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StartTripRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? planVersion = null, Object? clientOpId = freezed}) {
    return _then(
      _value.copyWith(
            planVersion: null == planVersion
                ? _value.planVersion
                : planVersion // ignore: cast_nullable_to_non_nullable
                      as int,
            clientOpId: freezed == clientOpId
                ? _value.clientOpId
                : clientOpId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StartTripRequestImplCopyWith<$Res>
    implements $StartTripRequestCopyWith<$Res> {
  factory _$$StartTripRequestImplCopyWith(
    _$StartTripRequestImpl value,
    $Res Function(_$StartTripRequestImpl) then,
  ) = __$$StartTripRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'plan_version') int planVersion,
    @JsonKey(name: 'client_op_id') String? clientOpId,
  });
}

/// @nodoc
class __$$StartTripRequestImplCopyWithImpl<$Res>
    extends _$StartTripRequestCopyWithImpl<$Res, _$StartTripRequestImpl>
    implements _$$StartTripRequestImplCopyWith<$Res> {
  __$$StartTripRequestImplCopyWithImpl(
    _$StartTripRequestImpl _value,
    $Res Function(_$StartTripRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StartTripRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? planVersion = null, Object? clientOpId = freezed}) {
    return _then(
      _$StartTripRequestImpl(
        planVersion: null == planVersion
            ? _value.planVersion
            : planVersion // ignore: cast_nullable_to_non_nullable
                  as int,
        clientOpId: freezed == clientOpId
            ? _value.clientOpId
            : clientOpId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StartTripRequestImpl implements _StartTripRequest {
  const _$StartTripRequestImpl({
    @JsonKey(name: 'plan_version') required this.planVersion,
    @JsonKey(name: 'client_op_id') this.clientOpId,
  });

  factory _$StartTripRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$StartTripRequestImplFromJson(json);

  @override
  @JsonKey(name: 'plan_version')
  final int planVersion;
  @override
  @JsonKey(name: 'client_op_id')
  final String? clientOpId;

  @override
  String toString() {
    return 'StartTripRequest(planVersion: $planVersion, clientOpId: $clientOpId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StartTripRequestImpl &&
            (identical(other.planVersion, planVersion) ||
                other.planVersion == planVersion) &&
            (identical(other.clientOpId, clientOpId) ||
                other.clientOpId == clientOpId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, planVersion, clientOpId);

  /// Create a copy of StartTripRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StartTripRequestImplCopyWith<_$StartTripRequestImpl> get copyWith =>
      __$$StartTripRequestImplCopyWithImpl<_$StartTripRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StartTripRequestImplToJson(this);
  }
}

abstract class _StartTripRequest implements StartTripRequest {
  const factory _StartTripRequest({
    @JsonKey(name: 'plan_version') required final int planVersion,
    @JsonKey(name: 'client_op_id') final String? clientOpId,
  }) = _$StartTripRequestImpl;

  factory _StartTripRequest.fromJson(Map<String, dynamic> json) =
      _$StartTripRequestImpl.fromJson;

  @override
  @JsonKey(name: 'plan_version')
  int get planVersion;
  @override
  @JsonKey(name: 'client_op_id')
  String? get clientOpId;

  /// Create a copy of StartTripRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StartTripRequestImplCopyWith<_$StartTripRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecordStopOutcomeRequest _$RecordStopOutcomeRequestFromJson(
  Map<String, dynamic> json,
) {
  return _RecordStopOutcomeRequest.fromJson(json);
}

/// @nodoc
mixin _$RecordStopOutcomeRequest {
  StopOutcome get outcome => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_delivered')
  int? get quantityDelivered => throw _privateConstructorUsedError;
  @JsonKey(name: 'received_by')
  String? get receivedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'outcome_note')
  String? get outcomeNote => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  String get completedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_op_id')
  String? get clientOpId => throw _privateConstructorUsedError;

  /// Serializes this RecordStopOutcomeRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecordStopOutcomeRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecordStopOutcomeRequestCopyWith<RecordStopOutcomeRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordStopOutcomeRequestCopyWith<$Res> {
  factory $RecordStopOutcomeRequestCopyWith(
    RecordStopOutcomeRequest value,
    $Res Function(RecordStopOutcomeRequest) then,
  ) = _$RecordStopOutcomeRequestCopyWithImpl<$Res, RecordStopOutcomeRequest>;
  @useResult
  $Res call({
    StopOutcome outcome,
    @JsonKey(name: 'quantity_delivered') int? quantityDelivered,
    @JsonKey(name: 'received_by') String? receivedBy,
    @JsonKey(name: 'outcome_note') String? outcomeNote,
    @JsonKey(name: 'completed_at') String completedAt,
    @JsonKey(name: 'client_op_id') String? clientOpId,
  });
}

/// @nodoc
class _$RecordStopOutcomeRequestCopyWithImpl<
  $Res,
  $Val extends RecordStopOutcomeRequest
>
    implements $RecordStopOutcomeRequestCopyWith<$Res> {
  _$RecordStopOutcomeRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecordStopOutcomeRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? outcome = null,
    Object? quantityDelivered = freezed,
    Object? receivedBy = freezed,
    Object? outcomeNote = freezed,
    Object? completedAt = null,
    Object? clientOpId = freezed,
  }) {
    return _then(
      _value.copyWith(
            outcome: null == outcome
                ? _value.outcome
                : outcome // ignore: cast_nullable_to_non_nullable
                      as StopOutcome,
            quantityDelivered: freezed == quantityDelivered
                ? _value.quantityDelivered
                : quantityDelivered // ignore: cast_nullable_to_non_nullable
                      as int?,
            receivedBy: freezed == receivedBy
                ? _value.receivedBy
                : receivedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            outcomeNote: freezed == outcomeNote
                ? _value.outcomeNote
                : outcomeNote // ignore: cast_nullable_to_non_nullable
                      as String?,
            completedAt: null == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as String,
            clientOpId: freezed == clientOpId
                ? _value.clientOpId
                : clientOpId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecordStopOutcomeRequestImplCopyWith<$Res>
    implements $RecordStopOutcomeRequestCopyWith<$Res> {
  factory _$$RecordStopOutcomeRequestImplCopyWith(
    _$RecordStopOutcomeRequestImpl value,
    $Res Function(_$RecordStopOutcomeRequestImpl) then,
  ) = __$$RecordStopOutcomeRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    StopOutcome outcome,
    @JsonKey(name: 'quantity_delivered') int? quantityDelivered,
    @JsonKey(name: 'received_by') String? receivedBy,
    @JsonKey(name: 'outcome_note') String? outcomeNote,
    @JsonKey(name: 'completed_at') String completedAt,
    @JsonKey(name: 'client_op_id') String? clientOpId,
  });
}

/// @nodoc
class __$$RecordStopOutcomeRequestImplCopyWithImpl<$Res>
    extends
        _$RecordStopOutcomeRequestCopyWithImpl<
          $Res,
          _$RecordStopOutcomeRequestImpl
        >
    implements _$$RecordStopOutcomeRequestImplCopyWith<$Res> {
  __$$RecordStopOutcomeRequestImplCopyWithImpl(
    _$RecordStopOutcomeRequestImpl _value,
    $Res Function(_$RecordStopOutcomeRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecordStopOutcomeRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? outcome = null,
    Object? quantityDelivered = freezed,
    Object? receivedBy = freezed,
    Object? outcomeNote = freezed,
    Object? completedAt = null,
    Object? clientOpId = freezed,
  }) {
    return _then(
      _$RecordStopOutcomeRequestImpl(
        outcome: null == outcome
            ? _value.outcome
            : outcome // ignore: cast_nullable_to_non_nullable
                  as StopOutcome,
        quantityDelivered: freezed == quantityDelivered
            ? _value.quantityDelivered
            : quantityDelivered // ignore: cast_nullable_to_non_nullable
                  as int?,
        receivedBy: freezed == receivedBy
            ? _value.receivedBy
            : receivedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        outcomeNote: freezed == outcomeNote
            ? _value.outcomeNote
            : outcomeNote // ignore: cast_nullable_to_non_nullable
                  as String?,
        completedAt: null == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as String,
        clientOpId: freezed == clientOpId
            ? _value.clientOpId
            : clientOpId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecordStopOutcomeRequestImpl implements _RecordStopOutcomeRequest {
  const _$RecordStopOutcomeRequestImpl({
    required this.outcome,
    @JsonKey(name: 'quantity_delivered') this.quantityDelivered,
    @JsonKey(name: 'received_by') this.receivedBy,
    @JsonKey(name: 'outcome_note') this.outcomeNote,
    @JsonKey(name: 'completed_at') required this.completedAt,
    @JsonKey(name: 'client_op_id') this.clientOpId,
  });

  factory _$RecordStopOutcomeRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecordStopOutcomeRequestImplFromJson(json);

  @override
  final StopOutcome outcome;
  @override
  @JsonKey(name: 'quantity_delivered')
  final int? quantityDelivered;
  @override
  @JsonKey(name: 'received_by')
  final String? receivedBy;
  @override
  @JsonKey(name: 'outcome_note')
  final String? outcomeNote;
  @override
  @JsonKey(name: 'completed_at')
  final String completedAt;
  @override
  @JsonKey(name: 'client_op_id')
  final String? clientOpId;

  @override
  String toString() {
    return 'RecordStopOutcomeRequest(outcome: $outcome, quantityDelivered: $quantityDelivered, receivedBy: $receivedBy, outcomeNote: $outcomeNote, completedAt: $completedAt, clientOpId: $clientOpId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordStopOutcomeRequestImpl &&
            (identical(other.outcome, outcome) || other.outcome == outcome) &&
            (identical(other.quantityDelivered, quantityDelivered) ||
                other.quantityDelivered == quantityDelivered) &&
            (identical(other.receivedBy, receivedBy) ||
                other.receivedBy == receivedBy) &&
            (identical(other.outcomeNote, outcomeNote) ||
                other.outcomeNote == outcomeNote) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.clientOpId, clientOpId) ||
                other.clientOpId == clientOpId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    outcome,
    quantityDelivered,
    receivedBy,
    outcomeNote,
    completedAt,
    clientOpId,
  );

  /// Create a copy of RecordStopOutcomeRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordStopOutcomeRequestImplCopyWith<_$RecordStopOutcomeRequestImpl>
  get copyWith =>
      __$$RecordStopOutcomeRequestImplCopyWithImpl<
        _$RecordStopOutcomeRequestImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecordStopOutcomeRequestImplToJson(this);
  }
}

abstract class _RecordStopOutcomeRequest implements RecordStopOutcomeRequest {
  const factory _RecordStopOutcomeRequest({
    required final StopOutcome outcome,
    @JsonKey(name: 'quantity_delivered') final int? quantityDelivered,
    @JsonKey(name: 'received_by') final String? receivedBy,
    @JsonKey(name: 'outcome_note') final String? outcomeNote,
    @JsonKey(name: 'completed_at') required final String completedAt,
    @JsonKey(name: 'client_op_id') final String? clientOpId,
  }) = _$RecordStopOutcomeRequestImpl;

  factory _RecordStopOutcomeRequest.fromJson(Map<String, dynamic> json) =
      _$RecordStopOutcomeRequestImpl.fromJson;

  @override
  StopOutcome get outcome;
  @override
  @JsonKey(name: 'quantity_delivered')
  int? get quantityDelivered;
  @override
  @JsonKey(name: 'received_by')
  String? get receivedBy;
  @override
  @JsonKey(name: 'outcome_note')
  String? get outcomeNote;
  @override
  @JsonKey(name: 'completed_at')
  String get completedAt;
  @override
  @JsonKey(name: 'client_op_id')
  String? get clientOpId;

  /// Create a copy of RecordStopOutcomeRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecordStopOutcomeRequestImplCopyWith<_$RecordStopOutcomeRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}

RecordStopExceptionRequest _$RecordStopExceptionRequestFromJson(
  Map<String, dynamic> json,
) {
  return _RecordStopExceptionRequest.fromJson(json);
}

/// @nodoc
mixin _$RecordStopExceptionRequest {
  ExceptionType get type => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_op_id')
  String? get clientOpId => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_seq')
  int? get clientSeq => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_ts')
  String? get clientTs => throw _privateConstructorUsedError;
  @JsonKey(name: 'plan_version')
  int? get planVersion => throw _privateConstructorUsedError;

  /// Serializes this RecordStopExceptionRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecordStopExceptionRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecordStopExceptionRequestCopyWith<RecordStopExceptionRequest>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordStopExceptionRequestCopyWith<$Res> {
  factory $RecordStopExceptionRequestCopyWith(
    RecordStopExceptionRequest value,
    $Res Function(RecordStopExceptionRequest) then,
  ) =
      _$RecordStopExceptionRequestCopyWithImpl<
        $Res,
        RecordStopExceptionRequest
      >;
  @useResult
  $Res call({
    ExceptionType type,
    String? note,
    @JsonKey(name: 'client_op_id') String? clientOpId,
    @JsonKey(name: 'client_seq') int? clientSeq,
    @JsonKey(name: 'client_ts') String? clientTs,
    @JsonKey(name: 'plan_version') int? planVersion,
  });
}

/// @nodoc
class _$RecordStopExceptionRequestCopyWithImpl<
  $Res,
  $Val extends RecordStopExceptionRequest
>
    implements $RecordStopExceptionRequestCopyWith<$Res> {
  _$RecordStopExceptionRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecordStopExceptionRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? note = freezed,
    Object? clientOpId = freezed,
    Object? clientSeq = freezed,
    Object? clientTs = freezed,
    Object? planVersion = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as ExceptionType,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            clientOpId: freezed == clientOpId
                ? _value.clientOpId
                : clientOpId // ignore: cast_nullable_to_non_nullable
                      as String?,
            clientSeq: freezed == clientSeq
                ? _value.clientSeq
                : clientSeq // ignore: cast_nullable_to_non_nullable
                      as int?,
            clientTs: freezed == clientTs
                ? _value.clientTs
                : clientTs // ignore: cast_nullable_to_non_nullable
                      as String?,
            planVersion: freezed == planVersion
                ? _value.planVersion
                : planVersion // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecordStopExceptionRequestImplCopyWith<$Res>
    implements $RecordStopExceptionRequestCopyWith<$Res> {
  factory _$$RecordStopExceptionRequestImplCopyWith(
    _$RecordStopExceptionRequestImpl value,
    $Res Function(_$RecordStopExceptionRequestImpl) then,
  ) = __$$RecordStopExceptionRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    ExceptionType type,
    String? note,
    @JsonKey(name: 'client_op_id') String? clientOpId,
    @JsonKey(name: 'client_seq') int? clientSeq,
    @JsonKey(name: 'client_ts') String? clientTs,
    @JsonKey(name: 'plan_version') int? planVersion,
  });
}

/// @nodoc
class __$$RecordStopExceptionRequestImplCopyWithImpl<$Res>
    extends
        _$RecordStopExceptionRequestCopyWithImpl<
          $Res,
          _$RecordStopExceptionRequestImpl
        >
    implements _$$RecordStopExceptionRequestImplCopyWith<$Res> {
  __$$RecordStopExceptionRequestImplCopyWithImpl(
    _$RecordStopExceptionRequestImpl _value,
    $Res Function(_$RecordStopExceptionRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecordStopExceptionRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? note = freezed,
    Object? clientOpId = freezed,
    Object? clientSeq = freezed,
    Object? clientTs = freezed,
    Object? planVersion = freezed,
  }) {
    return _then(
      _$RecordStopExceptionRequestImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ExceptionType,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        clientOpId: freezed == clientOpId
            ? _value.clientOpId
            : clientOpId // ignore: cast_nullable_to_non_nullable
                  as String?,
        clientSeq: freezed == clientSeq
            ? _value.clientSeq
            : clientSeq // ignore: cast_nullable_to_non_nullable
                  as int?,
        clientTs: freezed == clientTs
            ? _value.clientTs
            : clientTs // ignore: cast_nullable_to_non_nullable
                  as String?,
        planVersion: freezed == planVersion
            ? _value.planVersion
            : planVersion // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecordStopExceptionRequestImpl implements _RecordStopExceptionRequest {
  const _$RecordStopExceptionRequestImpl({
    required this.type,
    this.note,
    @JsonKey(name: 'client_op_id') this.clientOpId,
    @JsonKey(name: 'client_seq') this.clientSeq,
    @JsonKey(name: 'client_ts') this.clientTs,
    @JsonKey(name: 'plan_version') this.planVersion,
  });

  factory _$RecordStopExceptionRequestImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$RecordStopExceptionRequestImplFromJson(json);

  @override
  final ExceptionType type;
  @override
  final String? note;
  @override
  @JsonKey(name: 'client_op_id')
  final String? clientOpId;
  @override
  @JsonKey(name: 'client_seq')
  final int? clientSeq;
  @override
  @JsonKey(name: 'client_ts')
  final String? clientTs;
  @override
  @JsonKey(name: 'plan_version')
  final int? planVersion;

  @override
  String toString() {
    return 'RecordStopExceptionRequest(type: $type, note: $note, clientOpId: $clientOpId, clientSeq: $clientSeq, clientTs: $clientTs, planVersion: $planVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordStopExceptionRequestImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.clientOpId, clientOpId) ||
                other.clientOpId == clientOpId) &&
            (identical(other.clientSeq, clientSeq) ||
                other.clientSeq == clientSeq) &&
            (identical(other.clientTs, clientTs) ||
                other.clientTs == clientTs) &&
            (identical(other.planVersion, planVersion) ||
                other.planVersion == planVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    note,
    clientOpId,
    clientSeq,
    clientTs,
    planVersion,
  );

  /// Create a copy of RecordStopExceptionRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordStopExceptionRequestImplCopyWith<_$RecordStopExceptionRequestImpl>
  get copyWith =>
      __$$RecordStopExceptionRequestImplCopyWithImpl<
        _$RecordStopExceptionRequestImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecordStopExceptionRequestImplToJson(this);
  }
}

abstract class _RecordStopExceptionRequest
    implements RecordStopExceptionRequest {
  const factory _RecordStopExceptionRequest({
    required final ExceptionType type,
    final String? note,
    @JsonKey(name: 'client_op_id') final String? clientOpId,
    @JsonKey(name: 'client_seq') final int? clientSeq,
    @JsonKey(name: 'client_ts') final String? clientTs,
    @JsonKey(name: 'plan_version') final int? planVersion,
  }) = _$RecordStopExceptionRequestImpl;

  factory _RecordStopExceptionRequest.fromJson(Map<String, dynamic> json) =
      _$RecordStopExceptionRequestImpl.fromJson;

  @override
  ExceptionType get type;
  @override
  String? get note;
  @override
  @JsonKey(name: 'client_op_id')
  String? get clientOpId;
  @override
  @JsonKey(name: 'client_seq')
  int? get clientSeq;
  @override
  @JsonKey(name: 'client_ts')
  String? get clientTs;
  @override
  @JsonKey(name: 'plan_version')
  int? get planVersion;

  /// Create a copy of RecordStopExceptionRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecordStopExceptionRequestImplCopyWith<_$RecordStopExceptionRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}
