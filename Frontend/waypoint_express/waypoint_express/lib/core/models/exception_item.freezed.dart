// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exception_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ExceptionItem _$ExceptionItemFromJson(Map<String, dynamic> json) {
  return _ExceptionItem.fromJson(json);
}

/// @nodoc
mixin _$ExceptionItem {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'trip_id')
  String get tripId => throw _privateConstructorUsedError;
  @JsonKey(name: 'stop_id')
  String get stopId => throw _privateConstructorUsedError;
  ExceptionType get type => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'reported_at')
  String get reportedAt => throw _privateConstructorUsedError;
  ExceptionStatus get status => throw _privateConstructorUsedError;
  ExceptionDecision? get decision => throw _privateConstructorUsedError;
  @JsonKey(name: 'decision_note')
  String? get decisionNote => throw _privateConstructorUsedError;
  @JsonKey(name: 'decided_by')
  String? get decidedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'decided_at')
  String? get decidedAt => throw _privateConstructorUsedError;

  /// Serializes this ExceptionItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExceptionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExceptionItemCopyWith<ExceptionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExceptionItemCopyWith<$Res> {
  factory $ExceptionItemCopyWith(
    ExceptionItem value,
    $Res Function(ExceptionItem) then,
  ) = _$ExceptionItemCopyWithImpl<$Res, ExceptionItem>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'trip_id') String tripId,
    @JsonKey(name: 'stop_id') String stopId,
    ExceptionType type,
    String? note,
    @JsonKey(name: 'reported_at') String reportedAt,
    ExceptionStatus status,
    ExceptionDecision? decision,
    @JsonKey(name: 'decision_note') String? decisionNote,
    @JsonKey(name: 'decided_by') String? decidedBy,
    @JsonKey(name: 'decided_at') String? decidedAt,
  });
}

/// @nodoc
class _$ExceptionItemCopyWithImpl<$Res, $Val extends ExceptionItem>
    implements $ExceptionItemCopyWith<$Res> {
  _$ExceptionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExceptionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? stopId = null,
    Object? type = null,
    Object? note = freezed,
    Object? reportedAt = null,
    Object? status = null,
    Object? decision = freezed,
    Object? decisionNote = freezed,
    Object? decidedBy = freezed,
    Object? decidedAt = freezed,
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
            stopId: null == stopId
                ? _value.stopId
                : stopId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as ExceptionType,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            reportedAt: null == reportedAt
                ? _value.reportedAt
                : reportedAt // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ExceptionStatus,
            decision: freezed == decision
                ? _value.decision
                : decision // ignore: cast_nullable_to_non_nullable
                      as ExceptionDecision?,
            decisionNote: freezed == decisionNote
                ? _value.decisionNote
                : decisionNote // ignore: cast_nullable_to_non_nullable
                      as String?,
            decidedBy: freezed == decidedBy
                ? _value.decidedBy
                : decidedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            decidedAt: freezed == decidedAt
                ? _value.decidedAt
                : decidedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExceptionItemImplCopyWith<$Res>
    implements $ExceptionItemCopyWith<$Res> {
  factory _$$ExceptionItemImplCopyWith(
    _$ExceptionItemImpl value,
    $Res Function(_$ExceptionItemImpl) then,
  ) = __$$ExceptionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'trip_id') String tripId,
    @JsonKey(name: 'stop_id') String stopId,
    ExceptionType type,
    String? note,
    @JsonKey(name: 'reported_at') String reportedAt,
    ExceptionStatus status,
    ExceptionDecision? decision,
    @JsonKey(name: 'decision_note') String? decisionNote,
    @JsonKey(name: 'decided_by') String? decidedBy,
    @JsonKey(name: 'decided_at') String? decidedAt,
  });
}

/// @nodoc
class __$$ExceptionItemImplCopyWithImpl<$Res>
    extends _$ExceptionItemCopyWithImpl<$Res, _$ExceptionItemImpl>
    implements _$$ExceptionItemImplCopyWith<$Res> {
  __$$ExceptionItemImplCopyWithImpl(
    _$ExceptionItemImpl _value,
    $Res Function(_$ExceptionItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExceptionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? stopId = null,
    Object? type = null,
    Object? note = freezed,
    Object? reportedAt = null,
    Object? status = null,
    Object? decision = freezed,
    Object? decisionNote = freezed,
    Object? decidedBy = freezed,
    Object? decidedAt = freezed,
  }) {
    return _then(
      _$ExceptionItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        tripId: null == tripId
            ? _value.tripId
            : tripId // ignore: cast_nullable_to_non_nullable
                  as String,
        stopId: null == stopId
            ? _value.stopId
            : stopId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ExceptionType,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        reportedAt: null == reportedAt
            ? _value.reportedAt
            : reportedAt // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ExceptionStatus,
        decision: freezed == decision
            ? _value.decision
            : decision // ignore: cast_nullable_to_non_nullable
                  as ExceptionDecision?,
        decisionNote: freezed == decisionNote
            ? _value.decisionNote
            : decisionNote // ignore: cast_nullable_to_non_nullable
                  as String?,
        decidedBy: freezed == decidedBy
            ? _value.decidedBy
            : decidedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        decidedAt: freezed == decidedAt
            ? _value.decidedAt
            : decidedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ExceptionItemImpl implements _ExceptionItem {
  const _$ExceptionItemImpl({
    required this.id,
    @JsonKey(name: 'trip_id') required this.tripId,
    @JsonKey(name: 'stop_id') required this.stopId,
    required this.type,
    this.note,
    @JsonKey(name: 'reported_at') required this.reportedAt,
    required this.status,
    this.decision,
    @JsonKey(name: 'decision_note') this.decisionNote,
    @JsonKey(name: 'decided_by') this.decidedBy,
    @JsonKey(name: 'decided_at') this.decidedAt,
  });

  factory _$ExceptionItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExceptionItemImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'trip_id')
  final String tripId;
  @override
  @JsonKey(name: 'stop_id')
  final String stopId;
  @override
  final ExceptionType type;
  @override
  final String? note;
  @override
  @JsonKey(name: 'reported_at')
  final String reportedAt;
  @override
  final ExceptionStatus status;
  @override
  final ExceptionDecision? decision;
  @override
  @JsonKey(name: 'decision_note')
  final String? decisionNote;
  @override
  @JsonKey(name: 'decided_by')
  final String? decidedBy;
  @override
  @JsonKey(name: 'decided_at')
  final String? decidedAt;

  @override
  String toString() {
    return 'ExceptionItem(id: $id, tripId: $tripId, stopId: $stopId, type: $type, note: $note, reportedAt: $reportedAt, status: $status, decision: $decision, decisionNote: $decisionNote, decidedBy: $decidedBy, decidedAt: $decidedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExceptionItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.stopId, stopId) || other.stopId == stopId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.reportedAt, reportedAt) ||
                other.reportedAt == reportedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.decision, decision) ||
                other.decision == decision) &&
            (identical(other.decisionNote, decisionNote) ||
                other.decisionNote == decisionNote) &&
            (identical(other.decidedBy, decidedBy) ||
                other.decidedBy == decidedBy) &&
            (identical(other.decidedAt, decidedAt) ||
                other.decidedAt == decidedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tripId,
    stopId,
    type,
    note,
    reportedAt,
    status,
    decision,
    decisionNote,
    decidedBy,
    decidedAt,
  );

  /// Create a copy of ExceptionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExceptionItemImplCopyWith<_$ExceptionItemImpl> get copyWith =>
      __$$ExceptionItemImplCopyWithImpl<_$ExceptionItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExceptionItemImplToJson(this);
  }
}

abstract class _ExceptionItem implements ExceptionItem {
  const factory _ExceptionItem({
    required final String id,
    @JsonKey(name: 'trip_id') required final String tripId,
    @JsonKey(name: 'stop_id') required final String stopId,
    required final ExceptionType type,
    final String? note,
    @JsonKey(name: 'reported_at') required final String reportedAt,
    required final ExceptionStatus status,
    final ExceptionDecision? decision,
    @JsonKey(name: 'decision_note') final String? decisionNote,
    @JsonKey(name: 'decided_by') final String? decidedBy,
    @JsonKey(name: 'decided_at') final String? decidedAt,
  }) = _$ExceptionItemImpl;

  factory _ExceptionItem.fromJson(Map<String, dynamic> json) =
      _$ExceptionItemImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'trip_id')
  String get tripId;
  @override
  @JsonKey(name: 'stop_id')
  String get stopId;
  @override
  ExceptionType get type;
  @override
  String? get note;
  @override
  @JsonKey(name: 'reported_at')
  String get reportedAt;
  @override
  ExceptionStatus get status;
  @override
  ExceptionDecision? get decision;
  @override
  @JsonKey(name: 'decision_note')
  String? get decisionNote;
  @override
  @JsonKey(name: 'decided_by')
  String? get decidedBy;
  @override
  @JsonKey(name: 'decided_at')
  String? get decidedAt;

  /// Create a copy of ExceptionItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExceptionItemImplCopyWith<_$ExceptionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
