// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_stop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TripStop _$TripStopFromJson(Map<String, dynamic> json) {
  return _TripStop.fromJson(json);
}

/// @nodoc
mixin _$TripStop {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'trip_id')
  String get tripId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;
  int get seq => throw _privateConstructorUsedError;
  String? get eta => throw _privateConstructorUsedError;
  @JsonKey(name: 'service_start_est')
  String? get serviceStartEst => throw _privateConstructorUsedError;
  @JsonKey(name: 'service_min')
  int get serviceMin => throw _privateConstructorUsedError;
  StopStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'receipt_status')
  ReceiptStatus get receiptStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'arrived_at')
  String? get arrivedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  String? get completedAt => throw _privateConstructorUsedError;
  StopOutcome? get outcome => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_delivered')
  int? get quantityDelivered => throw _privateConstructorUsedError;
  @JsonKey(name: 'received_by')
  String? get receivedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'outcome_note')
  String? get outcomeNote => throw _privateConstructorUsedError;
  @JsonKey(name: 'device_ts')
  String? get deviceTs => throw _privateConstructorUsedError;

  /// Serializes this TripStop to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TripStop
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TripStopCopyWith<TripStop> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripStopCopyWith<$Res> {
  factory $TripStopCopyWith(TripStop value, $Res Function(TripStop) then) =
      _$TripStopCopyWithImpl<$Res, TripStop>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'trip_id') String tripId,
    @JsonKey(name: 'order_id') String orderId,
    int seq,
    String? eta,
    @JsonKey(name: 'service_start_est') String? serviceStartEst,
    @JsonKey(name: 'service_min') int serviceMin,
    StopStatus status,
    @JsonKey(name: 'receipt_status') ReceiptStatus receiptStatus,
    @JsonKey(name: 'arrived_at') String? arrivedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    StopOutcome? outcome,
    @JsonKey(name: 'quantity_delivered') int? quantityDelivered,
    @JsonKey(name: 'received_by') String? receivedBy,
    @JsonKey(name: 'outcome_note') String? outcomeNote,
    @JsonKey(name: 'device_ts') String? deviceTs,
  });
}

/// @nodoc
class _$TripStopCopyWithImpl<$Res, $Val extends TripStop>
    implements $TripStopCopyWith<$Res> {
  _$TripStopCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TripStop
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? orderId = null,
    Object? seq = null,
    Object? eta = freezed,
    Object? serviceStartEst = freezed,
    Object? serviceMin = null,
    Object? status = null,
    Object? receiptStatus = null,
    Object? arrivedAt = freezed,
    Object? completedAt = freezed,
    Object? outcome = freezed,
    Object? quantityDelivered = freezed,
    Object? receivedBy = freezed,
    Object? outcomeNote = freezed,
    Object? deviceTs = freezed,
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
            seq: null == seq
                ? _value.seq
                : seq // ignore: cast_nullable_to_non_nullable
                      as int,
            eta: freezed == eta
                ? _value.eta
                : eta // ignore: cast_nullable_to_non_nullable
                      as String?,
            serviceStartEst: freezed == serviceStartEst
                ? _value.serviceStartEst
                : serviceStartEst // ignore: cast_nullable_to_non_nullable
                      as String?,
            serviceMin: null == serviceMin
                ? _value.serviceMin
                : serviceMin // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as StopStatus,
            receiptStatus: null == receiptStatus
                ? _value.receiptStatus
                : receiptStatus // ignore: cast_nullable_to_non_nullable
                      as ReceiptStatus,
            arrivedAt: freezed == arrivedAt
                ? _value.arrivedAt
                : arrivedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            outcome: freezed == outcome
                ? _value.outcome
                : outcome // ignore: cast_nullable_to_non_nullable
                      as StopOutcome?,
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
            deviceTs: freezed == deviceTs
                ? _value.deviceTs
                : deviceTs // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TripStopImplCopyWith<$Res>
    implements $TripStopCopyWith<$Res> {
  factory _$$TripStopImplCopyWith(
    _$TripStopImpl value,
    $Res Function(_$TripStopImpl) then,
  ) = __$$TripStopImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'trip_id') String tripId,
    @JsonKey(name: 'order_id') String orderId,
    int seq,
    String? eta,
    @JsonKey(name: 'service_start_est') String? serviceStartEst,
    @JsonKey(name: 'service_min') int serviceMin,
    StopStatus status,
    @JsonKey(name: 'receipt_status') ReceiptStatus receiptStatus,
    @JsonKey(name: 'arrived_at') String? arrivedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    StopOutcome? outcome,
    @JsonKey(name: 'quantity_delivered') int? quantityDelivered,
    @JsonKey(name: 'received_by') String? receivedBy,
    @JsonKey(name: 'outcome_note') String? outcomeNote,
    @JsonKey(name: 'device_ts') String? deviceTs,
  });
}

/// @nodoc
class __$$TripStopImplCopyWithImpl<$Res>
    extends _$TripStopCopyWithImpl<$Res, _$TripStopImpl>
    implements _$$TripStopImplCopyWith<$Res> {
  __$$TripStopImplCopyWithImpl(
    _$TripStopImpl _value,
    $Res Function(_$TripStopImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TripStop
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? orderId = null,
    Object? seq = null,
    Object? eta = freezed,
    Object? serviceStartEst = freezed,
    Object? serviceMin = null,
    Object? status = null,
    Object? receiptStatus = null,
    Object? arrivedAt = freezed,
    Object? completedAt = freezed,
    Object? outcome = freezed,
    Object? quantityDelivered = freezed,
    Object? receivedBy = freezed,
    Object? outcomeNote = freezed,
    Object? deviceTs = freezed,
  }) {
    return _then(
      _$TripStopImpl(
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
        seq: null == seq
            ? _value.seq
            : seq // ignore: cast_nullable_to_non_nullable
                  as int,
        eta: freezed == eta
            ? _value.eta
            : eta // ignore: cast_nullable_to_non_nullable
                  as String?,
        serviceStartEst: freezed == serviceStartEst
            ? _value.serviceStartEst
            : serviceStartEst // ignore: cast_nullable_to_non_nullable
                  as String?,
        serviceMin: null == serviceMin
            ? _value.serviceMin
            : serviceMin // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as StopStatus,
        receiptStatus: null == receiptStatus
            ? _value.receiptStatus
            : receiptStatus // ignore: cast_nullable_to_non_nullable
                  as ReceiptStatus,
        arrivedAt: freezed == arrivedAt
            ? _value.arrivedAt
            : arrivedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        outcome: freezed == outcome
            ? _value.outcome
            : outcome // ignore: cast_nullable_to_non_nullable
                  as StopOutcome?,
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
        deviceTs: freezed == deviceTs
            ? _value.deviceTs
            : deviceTs // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TripStopImpl implements _TripStop {
  const _$TripStopImpl({
    required this.id,
    @JsonKey(name: 'trip_id') required this.tripId,
    @JsonKey(name: 'order_id') required this.orderId,
    required this.seq,
    this.eta,
    @JsonKey(name: 'service_start_est') this.serviceStartEst,
    @JsonKey(name: 'service_min') required this.serviceMin,
    required this.status,
    @JsonKey(name: 'receipt_status') required this.receiptStatus,
    @JsonKey(name: 'arrived_at') this.arrivedAt,
    @JsonKey(name: 'completed_at') this.completedAt,
    this.outcome,
    @JsonKey(name: 'quantity_delivered') this.quantityDelivered,
    @JsonKey(name: 'received_by') this.receivedBy,
    @JsonKey(name: 'outcome_note') this.outcomeNote,
    @JsonKey(name: 'device_ts') this.deviceTs,
  });

  factory _$TripStopImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripStopImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'trip_id')
  final String tripId;
  @override
  @JsonKey(name: 'order_id')
  final String orderId;
  @override
  final int seq;
  @override
  final String? eta;
  @override
  @JsonKey(name: 'service_start_est')
  final String? serviceStartEst;
  @override
  @JsonKey(name: 'service_min')
  final int serviceMin;
  @override
  final StopStatus status;
  @override
  @JsonKey(name: 'receipt_status')
  final ReceiptStatus receiptStatus;
  @override
  @JsonKey(name: 'arrived_at')
  final String? arrivedAt;
  @override
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  @override
  final StopOutcome? outcome;
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
  @JsonKey(name: 'device_ts')
  final String? deviceTs;

  @override
  String toString() {
    return 'TripStop(id: $id, tripId: $tripId, orderId: $orderId, seq: $seq, eta: $eta, serviceStartEst: $serviceStartEst, serviceMin: $serviceMin, status: $status, receiptStatus: $receiptStatus, arrivedAt: $arrivedAt, completedAt: $completedAt, outcome: $outcome, quantityDelivered: $quantityDelivered, receivedBy: $receivedBy, outcomeNote: $outcomeNote, deviceTs: $deviceTs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripStopImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.seq, seq) || other.seq == seq) &&
            (identical(other.eta, eta) || other.eta == eta) &&
            (identical(other.serviceStartEst, serviceStartEst) ||
                other.serviceStartEst == serviceStartEst) &&
            (identical(other.serviceMin, serviceMin) ||
                other.serviceMin == serviceMin) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.receiptStatus, receiptStatus) ||
                other.receiptStatus == receiptStatus) &&
            (identical(other.arrivedAt, arrivedAt) ||
                other.arrivedAt == arrivedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.outcome, outcome) || other.outcome == outcome) &&
            (identical(other.quantityDelivered, quantityDelivered) ||
                other.quantityDelivered == quantityDelivered) &&
            (identical(other.receivedBy, receivedBy) ||
                other.receivedBy == receivedBy) &&
            (identical(other.outcomeNote, outcomeNote) ||
                other.outcomeNote == outcomeNote) &&
            (identical(other.deviceTs, deviceTs) ||
                other.deviceTs == deviceTs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tripId,
    orderId,
    seq,
    eta,
    serviceStartEst,
    serviceMin,
    status,
    receiptStatus,
    arrivedAt,
    completedAt,
    outcome,
    quantityDelivered,
    receivedBy,
    outcomeNote,
    deviceTs,
  );

  /// Create a copy of TripStop
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TripStopImplCopyWith<_$TripStopImpl> get copyWith =>
      __$$TripStopImplCopyWithImpl<_$TripStopImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripStopImplToJson(this);
  }
}

abstract class _TripStop implements TripStop {
  const factory _TripStop({
    required final String id,
    @JsonKey(name: 'trip_id') required final String tripId,
    @JsonKey(name: 'order_id') required final String orderId,
    required final int seq,
    final String? eta,
    @JsonKey(name: 'service_start_est') final String? serviceStartEst,
    @JsonKey(name: 'service_min') required final int serviceMin,
    required final StopStatus status,
    @JsonKey(name: 'receipt_status') required final ReceiptStatus receiptStatus,
    @JsonKey(name: 'arrived_at') final String? arrivedAt,
    @JsonKey(name: 'completed_at') final String? completedAt,
    final StopOutcome? outcome,
    @JsonKey(name: 'quantity_delivered') final int? quantityDelivered,
    @JsonKey(name: 'received_by') final String? receivedBy,
    @JsonKey(name: 'outcome_note') final String? outcomeNote,
    @JsonKey(name: 'device_ts') final String? deviceTs,
  }) = _$TripStopImpl;

  factory _TripStop.fromJson(Map<String, dynamic> json) =
      _$TripStopImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'trip_id')
  String get tripId;
  @override
  @JsonKey(name: 'order_id')
  String get orderId;
  @override
  int get seq;
  @override
  String? get eta;
  @override
  @JsonKey(name: 'service_start_est')
  String? get serviceStartEst;
  @override
  @JsonKey(name: 'service_min')
  int get serviceMin;
  @override
  StopStatus get status;
  @override
  @JsonKey(name: 'receipt_status')
  ReceiptStatus get receiptStatus;
  @override
  @JsonKey(name: 'arrived_at')
  String? get arrivedAt;
  @override
  @JsonKey(name: 'completed_at')
  String? get completedAt;
  @override
  StopOutcome? get outcome;
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
  @JsonKey(name: 'device_ts')
  String? get deviceTs;

  /// Create a copy of TripStop
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TripStopImplCopyWith<_$TripStopImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
