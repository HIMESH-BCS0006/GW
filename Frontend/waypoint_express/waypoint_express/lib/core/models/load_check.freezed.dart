// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'load_check.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LoadCheck _$LoadCheckFromJson(Map<String, dynamic> json) {
  return _LoadCheck.fromJson(json);
}

/// @nodoc
mixin _$LoadCheck {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'trip_id')
  String get tripId => throw _privateConstructorUsedError;
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
  LoadCheckStatus get status => throw _privateConstructorUsedError;
  LoadCheckResolution? get resolution => throw _privateConstructorUsedError;
  @JsonKey(name: 'reported_by')
  String get reportedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'resolved_by')
  String? get resolvedBy => throw _privateConstructorUsedError;

  /// Serializes this LoadCheck to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoadCheck
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoadCheckCopyWith<LoadCheck> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoadCheckCopyWith<$Res> {
  factory $LoadCheckCopyWith(LoadCheck value, $Res Function(LoadCheck) then) =
      _$LoadCheckCopyWithImpl<$Res, LoadCheck>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'trip_id') String tripId,
    @JsonKey(name: 'order_id') String orderId,
    @JsonKey(name: 'plan_version') int planVersion,
    @JsonKey(name: 'expected_qty') int expectedQty,
    @JsonKey(name: 'loaded_qty') int loadedQty,
    LoadCheckIssue issue,
    String? note,
    LoadCheckStatus status,
    LoadCheckResolution? resolution,
    @JsonKey(name: 'reported_by') String reportedBy,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
  });
}

/// @nodoc
class _$LoadCheckCopyWithImpl<$Res, $Val extends LoadCheck>
    implements $LoadCheckCopyWith<$Res> {
  _$LoadCheckCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoadCheck
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? orderId = null,
    Object? planVersion = null,
    Object? expectedQty = null,
    Object? loadedQty = null,
    Object? issue = null,
    Object? note = freezed,
    Object? status = null,
    Object? resolution = freezed,
    Object? reportedBy = null,
    Object? resolvedBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            tripId: null == tripId
                ? _value.tripId
                : tripId // ignore: cast_nullable_to_non_nullable
                      as String,
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
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as LoadCheckStatus,
            resolution: freezed == resolution
                ? _value.resolution
                : resolution // ignore: cast_nullable_to_non_nullable
                      as LoadCheckResolution?,
            reportedBy: null == reportedBy
                ? _value.reportedBy
                : reportedBy // ignore: cast_nullable_to_non_nullable
                      as String,
            resolvedBy: freezed == resolvedBy
                ? _value.resolvedBy
                : resolvedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LoadCheckImplCopyWith<$Res>
    implements $LoadCheckCopyWith<$Res> {
  factory _$$LoadCheckImplCopyWith(
    _$LoadCheckImpl value,
    $Res Function(_$LoadCheckImpl) then,
  ) = __$$LoadCheckImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'trip_id') String tripId,
    @JsonKey(name: 'order_id') String orderId,
    @JsonKey(name: 'plan_version') int planVersion,
    @JsonKey(name: 'expected_qty') int expectedQty,
    @JsonKey(name: 'loaded_qty') int loadedQty,
    LoadCheckIssue issue,
    String? note,
    LoadCheckStatus status,
    LoadCheckResolution? resolution,
    @JsonKey(name: 'reported_by') String reportedBy,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
  });
}

/// @nodoc
class __$$LoadCheckImplCopyWithImpl<$Res>
    extends _$LoadCheckCopyWithImpl<$Res, _$LoadCheckImpl>
    implements _$$LoadCheckImplCopyWith<$Res> {
  __$$LoadCheckImplCopyWithImpl(
    _$LoadCheckImpl _value,
    $Res Function(_$LoadCheckImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoadCheck
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? orderId = null,
    Object? planVersion = null,
    Object? expectedQty = null,
    Object? loadedQty = null,
    Object? issue = null,
    Object? note = freezed,
    Object? status = null,
    Object? resolution = freezed,
    Object? reportedBy = null,
    Object? resolvedBy = freezed,
  }) {
    return _then(
      _$LoadCheckImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        tripId: null == tripId
            ? _value.tripId
            : tripId // ignore: cast_nullable_to_non_nullable
                  as String,
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
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as LoadCheckStatus,
        resolution: freezed == resolution
            ? _value.resolution
            : resolution // ignore: cast_nullable_to_non_nullable
                  as LoadCheckResolution?,
        reportedBy: null == reportedBy
            ? _value.reportedBy
            : reportedBy // ignore: cast_nullable_to_non_nullable
                  as String,
        resolvedBy: freezed == resolvedBy
            ? _value.resolvedBy
            : resolvedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LoadCheckImpl implements _LoadCheck {
  const _$LoadCheckImpl({
    required this.id,
    @JsonKey(name: 'trip_id') required this.tripId,
    @JsonKey(name: 'order_id') required this.orderId,
    @JsonKey(name: 'plan_version') required this.planVersion,
    @JsonKey(name: 'expected_qty') required this.expectedQty,
    @JsonKey(name: 'loaded_qty') required this.loadedQty,
    required this.issue,
    this.note,
    required this.status,
    this.resolution,
    @JsonKey(name: 'reported_by') required this.reportedBy,
    @JsonKey(name: 'resolved_by') this.resolvedBy,
  });

  factory _$LoadCheckImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoadCheckImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'trip_id')
  final String tripId;
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
  final LoadCheckStatus status;
  @override
  final LoadCheckResolution? resolution;
  @override
  @JsonKey(name: 'reported_by')
  final String reportedBy;
  @override
  @JsonKey(name: 'resolved_by')
  final String? resolvedBy;

  @override
  String toString() {
    return 'LoadCheck(id: $id, tripId: $tripId, orderId: $orderId, planVersion: $planVersion, expectedQty: $expectedQty, loadedQty: $loadedQty, issue: $issue, note: $note, status: $status, resolution: $resolution, reportedBy: $reportedBy, resolvedBy: $resolvedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadCheckImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.planVersion, planVersion) ||
                other.planVersion == planVersion) &&
            (identical(other.expectedQty, expectedQty) ||
                other.expectedQty == expectedQty) &&
            (identical(other.loadedQty, loadedQty) ||
                other.loadedQty == loadedQty) &&
            (identical(other.issue, issue) || other.issue == issue) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.resolution, resolution) ||
                other.resolution == resolution) &&
            (identical(other.reportedBy, reportedBy) ||
                other.reportedBy == reportedBy) &&
            (identical(other.resolvedBy, resolvedBy) ||
                other.resolvedBy == resolvedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tripId,
    orderId,
    planVersion,
    expectedQty,
    loadedQty,
    issue,
    note,
    status,
    resolution,
    reportedBy,
    resolvedBy,
  );

  /// Create a copy of LoadCheck
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadCheckImplCopyWith<_$LoadCheckImpl> get copyWith =>
      __$$LoadCheckImplCopyWithImpl<_$LoadCheckImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoadCheckImplToJson(this);
  }
}

abstract class _LoadCheck implements LoadCheck {
  const factory _LoadCheck({
    required final String id,
    @JsonKey(name: 'trip_id') required final String tripId,
    @JsonKey(name: 'order_id') required final String orderId,
    @JsonKey(name: 'plan_version') required final int planVersion,
    @JsonKey(name: 'expected_qty') required final int expectedQty,
    @JsonKey(name: 'loaded_qty') required final int loadedQty,
    required final LoadCheckIssue issue,
    final String? note,
    required final LoadCheckStatus status,
    final LoadCheckResolution? resolution,
    @JsonKey(name: 'reported_by') required final String reportedBy,
    @JsonKey(name: 'resolved_by') final String? resolvedBy,
  }) = _$LoadCheckImpl;

  factory _LoadCheck.fromJson(Map<String, dynamic> json) =
      _$LoadCheckImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'trip_id')
  String get tripId;
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
  LoadCheckStatus get status;
  @override
  LoadCheckResolution? get resolution;
  @override
  @JsonKey(name: 'reported_by')
  String get reportedBy;
  @override
  @JsonKey(name: 'resolved_by')
  String? get resolvedBy;

  /// Create a copy of LoadCheck
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadCheckImplCopyWith<_$LoadCheckImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
