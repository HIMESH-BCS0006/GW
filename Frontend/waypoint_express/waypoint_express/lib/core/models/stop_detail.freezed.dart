// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stop_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StopDetail _$StopDetailFromJson(Map<String, dynamic> json) {
  return _StopDetail.fromJson(json);
}

/// @nodoc
mixin _$StopDetail {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'trip_id')
  String get tripId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;
  int get seq => throw _privateConstructorUsedError;
  @JsonKey(name: 'outlet_id')
  String get outletId => throw _privateConstructorUsedError;
  @JsonKey(name: 'outlet_name')
  String get outletName => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  @JsonKey(name: 'dock_type')
  DockType get dockType => throw _privateConstructorUsedError;
  @JsonKey(name: 'parking_constraint')
  ParkingConstraint get parkingConstraint => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_units')
  int get orderUnits => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_weight_kg')
  double get orderWeightKg => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_volume_m3')
  double get orderVolumeM3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'window_open_time')
  String get windowOpenTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'window_close_time')
  String get windowCloseTime => throw _privateConstructorUsedError;
  String? get eta => throw _privateConstructorUsedError;
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

  /// Serializes this StopDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StopDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StopDetailCopyWith<StopDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StopDetailCopyWith<$Res> {
  factory $StopDetailCopyWith(
    StopDetail value,
    $Res Function(StopDetail) then,
  ) = _$StopDetailCopyWithImpl<$Res, StopDetail>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'trip_id') String tripId,
    @JsonKey(name: 'order_id') String orderId,
    int seq,
    @JsonKey(name: 'outlet_id') String outletId,
    @JsonKey(name: 'outlet_name') String outletName,
    String district,
    @JsonKey(name: 'dock_type') DockType dockType,
    @JsonKey(name: 'parking_constraint') ParkingConstraint parkingConstraint,
    @JsonKey(name: 'order_units') int orderUnits,
    @JsonKey(name: 'order_weight_kg') double orderWeightKg,
    @JsonKey(name: 'order_volume_m3') double orderVolumeM3,
    @JsonKey(name: 'window_open_time') String windowOpenTime,
    @JsonKey(name: 'window_close_time') String windowCloseTime,
    String? eta,
    @JsonKey(name: 'service_min') int serviceMin,
    StopStatus status,
    @JsonKey(name: 'receipt_status') ReceiptStatus receiptStatus,
    @JsonKey(name: 'arrived_at') String? arrivedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    StopOutcome? outcome,
    @JsonKey(name: 'quantity_delivered') int? quantityDelivered,
    @JsonKey(name: 'received_by') String? receivedBy,
    @JsonKey(name: 'outcome_note') String? outcomeNote,
  });
}

/// @nodoc
class _$StopDetailCopyWithImpl<$Res, $Val extends StopDetail>
    implements $StopDetailCopyWith<$Res> {
  _$StopDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StopDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? orderId = null,
    Object? seq = null,
    Object? outletId = null,
    Object? outletName = null,
    Object? district = null,
    Object? dockType = null,
    Object? parkingConstraint = null,
    Object? orderUnits = null,
    Object? orderWeightKg = null,
    Object? orderVolumeM3 = null,
    Object? windowOpenTime = null,
    Object? windowCloseTime = null,
    Object? eta = freezed,
    Object? serviceMin = null,
    Object? status = null,
    Object? receiptStatus = null,
    Object? arrivedAt = freezed,
    Object? completedAt = freezed,
    Object? outcome = freezed,
    Object? quantityDelivered = freezed,
    Object? receivedBy = freezed,
    Object? outcomeNote = freezed,
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
            outletId: null == outletId
                ? _value.outletId
                : outletId // ignore: cast_nullable_to_non_nullable
                      as String,
            outletName: null == outletName
                ? _value.outletName
                : outletName // ignore: cast_nullable_to_non_nullable
                      as String,
            district: null == district
                ? _value.district
                : district // ignore: cast_nullable_to_non_nullable
                      as String,
            dockType: null == dockType
                ? _value.dockType
                : dockType // ignore: cast_nullable_to_non_nullable
                      as DockType,
            parkingConstraint: null == parkingConstraint
                ? _value.parkingConstraint
                : parkingConstraint // ignore: cast_nullable_to_non_nullable
                      as ParkingConstraint,
            orderUnits: null == orderUnits
                ? _value.orderUnits
                : orderUnits // ignore: cast_nullable_to_non_nullable
                      as int,
            orderWeightKg: null == orderWeightKg
                ? _value.orderWeightKg
                : orderWeightKg // ignore: cast_nullable_to_non_nullable
                      as double,
            orderVolumeM3: null == orderVolumeM3
                ? _value.orderVolumeM3
                : orderVolumeM3 // ignore: cast_nullable_to_non_nullable
                      as double,
            windowOpenTime: null == windowOpenTime
                ? _value.windowOpenTime
                : windowOpenTime // ignore: cast_nullable_to_non_nullable
                      as String,
            windowCloseTime: null == windowCloseTime
                ? _value.windowCloseTime
                : windowCloseTime // ignore: cast_nullable_to_non_nullable
                      as String,
            eta: freezed == eta
                ? _value.eta
                : eta // ignore: cast_nullable_to_non_nullable
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StopDetailImplCopyWith<$Res>
    implements $StopDetailCopyWith<$Res> {
  factory _$$StopDetailImplCopyWith(
    _$StopDetailImpl value,
    $Res Function(_$StopDetailImpl) then,
  ) = __$$StopDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'trip_id') String tripId,
    @JsonKey(name: 'order_id') String orderId,
    int seq,
    @JsonKey(name: 'outlet_id') String outletId,
    @JsonKey(name: 'outlet_name') String outletName,
    String district,
    @JsonKey(name: 'dock_type') DockType dockType,
    @JsonKey(name: 'parking_constraint') ParkingConstraint parkingConstraint,
    @JsonKey(name: 'order_units') int orderUnits,
    @JsonKey(name: 'order_weight_kg') double orderWeightKg,
    @JsonKey(name: 'order_volume_m3') double orderVolumeM3,
    @JsonKey(name: 'window_open_time') String windowOpenTime,
    @JsonKey(name: 'window_close_time') String windowCloseTime,
    String? eta,
    @JsonKey(name: 'service_min') int serviceMin,
    StopStatus status,
    @JsonKey(name: 'receipt_status') ReceiptStatus receiptStatus,
    @JsonKey(name: 'arrived_at') String? arrivedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    StopOutcome? outcome,
    @JsonKey(name: 'quantity_delivered') int? quantityDelivered,
    @JsonKey(name: 'received_by') String? receivedBy,
    @JsonKey(name: 'outcome_note') String? outcomeNote,
  });
}

/// @nodoc
class __$$StopDetailImplCopyWithImpl<$Res>
    extends _$StopDetailCopyWithImpl<$Res, _$StopDetailImpl>
    implements _$$StopDetailImplCopyWith<$Res> {
  __$$StopDetailImplCopyWithImpl(
    _$StopDetailImpl _value,
    $Res Function(_$StopDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StopDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? orderId = null,
    Object? seq = null,
    Object? outletId = null,
    Object? outletName = null,
    Object? district = null,
    Object? dockType = null,
    Object? parkingConstraint = null,
    Object? orderUnits = null,
    Object? orderWeightKg = null,
    Object? orderVolumeM3 = null,
    Object? windowOpenTime = null,
    Object? windowCloseTime = null,
    Object? eta = freezed,
    Object? serviceMin = null,
    Object? status = null,
    Object? receiptStatus = null,
    Object? arrivedAt = freezed,
    Object? completedAt = freezed,
    Object? outcome = freezed,
    Object? quantityDelivered = freezed,
    Object? receivedBy = freezed,
    Object? outcomeNote = freezed,
  }) {
    return _then(
      _$StopDetailImpl(
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
        outletId: null == outletId
            ? _value.outletId
            : outletId // ignore: cast_nullable_to_non_nullable
                  as String,
        outletName: null == outletName
            ? _value.outletName
            : outletName // ignore: cast_nullable_to_non_nullable
                  as String,
        district: null == district
            ? _value.district
            : district // ignore: cast_nullable_to_non_nullable
                  as String,
        dockType: null == dockType
            ? _value.dockType
            : dockType // ignore: cast_nullable_to_non_nullable
                  as DockType,
        parkingConstraint: null == parkingConstraint
            ? _value.parkingConstraint
            : parkingConstraint // ignore: cast_nullable_to_non_nullable
                  as ParkingConstraint,
        orderUnits: null == orderUnits
            ? _value.orderUnits
            : orderUnits // ignore: cast_nullable_to_non_nullable
                  as int,
        orderWeightKg: null == orderWeightKg
            ? _value.orderWeightKg
            : orderWeightKg // ignore: cast_nullable_to_non_nullable
                  as double,
        orderVolumeM3: null == orderVolumeM3
            ? _value.orderVolumeM3
            : orderVolumeM3 // ignore: cast_nullable_to_non_nullable
                  as double,
        windowOpenTime: null == windowOpenTime
            ? _value.windowOpenTime
            : windowOpenTime // ignore: cast_nullable_to_non_nullable
                  as String,
        windowCloseTime: null == windowCloseTime
            ? _value.windowCloseTime
            : windowCloseTime // ignore: cast_nullable_to_non_nullable
                  as String,
        eta: freezed == eta
            ? _value.eta
            : eta // ignore: cast_nullable_to_non_nullable
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StopDetailImpl implements _StopDetail {
  const _$StopDetailImpl({
    required this.id,
    @JsonKey(name: 'trip_id') required this.tripId,
    @JsonKey(name: 'order_id') required this.orderId,
    required this.seq,
    @JsonKey(name: 'outlet_id') required this.outletId,
    @JsonKey(name: 'outlet_name') required this.outletName,
    required this.district,
    @JsonKey(name: 'dock_type') required this.dockType,
    @JsonKey(name: 'parking_constraint') required this.parkingConstraint,
    @JsonKey(name: 'order_units') required this.orderUnits,
    @JsonKey(name: 'order_weight_kg') required this.orderWeightKg,
    @JsonKey(name: 'order_volume_m3') required this.orderVolumeM3,
    @JsonKey(name: 'window_open_time') required this.windowOpenTime,
    @JsonKey(name: 'window_close_time') required this.windowCloseTime,
    this.eta,
    @JsonKey(name: 'service_min') required this.serviceMin,
    required this.status,
    @JsonKey(name: 'receipt_status') required this.receiptStatus,
    @JsonKey(name: 'arrived_at') this.arrivedAt,
    @JsonKey(name: 'completed_at') this.completedAt,
    this.outcome,
    @JsonKey(name: 'quantity_delivered') this.quantityDelivered,
    @JsonKey(name: 'received_by') this.receivedBy,
    @JsonKey(name: 'outcome_note') this.outcomeNote,
  });

  factory _$StopDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$StopDetailImplFromJson(json);

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
  @JsonKey(name: 'outlet_id')
  final String outletId;
  @override
  @JsonKey(name: 'outlet_name')
  final String outletName;
  @override
  final String district;
  @override
  @JsonKey(name: 'dock_type')
  final DockType dockType;
  @override
  @JsonKey(name: 'parking_constraint')
  final ParkingConstraint parkingConstraint;
  @override
  @JsonKey(name: 'order_units')
  final int orderUnits;
  @override
  @JsonKey(name: 'order_weight_kg')
  final double orderWeightKg;
  @override
  @JsonKey(name: 'order_volume_m3')
  final double orderVolumeM3;
  @override
  @JsonKey(name: 'window_open_time')
  final String windowOpenTime;
  @override
  @JsonKey(name: 'window_close_time')
  final String windowCloseTime;
  @override
  final String? eta;
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
  String toString() {
    return 'StopDetail(id: $id, tripId: $tripId, orderId: $orderId, seq: $seq, outletId: $outletId, outletName: $outletName, district: $district, dockType: $dockType, parkingConstraint: $parkingConstraint, orderUnits: $orderUnits, orderWeightKg: $orderWeightKg, orderVolumeM3: $orderVolumeM3, windowOpenTime: $windowOpenTime, windowCloseTime: $windowCloseTime, eta: $eta, serviceMin: $serviceMin, status: $status, receiptStatus: $receiptStatus, arrivedAt: $arrivedAt, completedAt: $completedAt, outcome: $outcome, quantityDelivered: $quantityDelivered, receivedBy: $receivedBy, outcomeNote: $outcomeNote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StopDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.seq, seq) || other.seq == seq) &&
            (identical(other.outletId, outletId) ||
                other.outletId == outletId) &&
            (identical(other.outletName, outletName) ||
                other.outletName == outletName) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.dockType, dockType) ||
                other.dockType == dockType) &&
            (identical(other.parkingConstraint, parkingConstraint) ||
                other.parkingConstraint == parkingConstraint) &&
            (identical(other.orderUnits, orderUnits) ||
                other.orderUnits == orderUnits) &&
            (identical(other.orderWeightKg, orderWeightKg) ||
                other.orderWeightKg == orderWeightKg) &&
            (identical(other.orderVolumeM3, orderVolumeM3) ||
                other.orderVolumeM3 == orderVolumeM3) &&
            (identical(other.windowOpenTime, windowOpenTime) ||
                other.windowOpenTime == windowOpenTime) &&
            (identical(other.windowCloseTime, windowCloseTime) ||
                other.windowCloseTime == windowCloseTime) &&
            (identical(other.eta, eta) || other.eta == eta) &&
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
                other.outcomeNote == outcomeNote));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    tripId,
    orderId,
    seq,
    outletId,
    outletName,
    district,
    dockType,
    parkingConstraint,
    orderUnits,
    orderWeightKg,
    orderVolumeM3,
    windowOpenTime,
    windowCloseTime,
    eta,
    serviceMin,
    status,
    receiptStatus,
    arrivedAt,
    completedAt,
    outcome,
    quantityDelivered,
    receivedBy,
    outcomeNote,
  ]);

  /// Create a copy of StopDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StopDetailImplCopyWith<_$StopDetailImpl> get copyWith =>
      __$$StopDetailImplCopyWithImpl<_$StopDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StopDetailImplToJson(this);
  }
}

abstract class _StopDetail implements StopDetail {
  const factory _StopDetail({
    required final String id,
    @JsonKey(name: 'trip_id') required final String tripId,
    @JsonKey(name: 'order_id') required final String orderId,
    required final int seq,
    @JsonKey(name: 'outlet_id') required final String outletId,
    @JsonKey(name: 'outlet_name') required final String outletName,
    required final String district,
    @JsonKey(name: 'dock_type') required final DockType dockType,
    @JsonKey(name: 'parking_constraint')
    required final ParkingConstraint parkingConstraint,
    @JsonKey(name: 'order_units') required final int orderUnits,
    @JsonKey(name: 'order_weight_kg') required final double orderWeightKg,
    @JsonKey(name: 'order_volume_m3') required final double orderVolumeM3,
    @JsonKey(name: 'window_open_time') required final String windowOpenTime,
    @JsonKey(name: 'window_close_time') required final String windowCloseTime,
    final String? eta,
    @JsonKey(name: 'service_min') required final int serviceMin,
    required final StopStatus status,
    @JsonKey(name: 'receipt_status') required final ReceiptStatus receiptStatus,
    @JsonKey(name: 'arrived_at') final String? arrivedAt,
    @JsonKey(name: 'completed_at') final String? completedAt,
    final StopOutcome? outcome,
    @JsonKey(name: 'quantity_delivered') final int? quantityDelivered,
    @JsonKey(name: 'received_by') final String? receivedBy,
    @JsonKey(name: 'outcome_note') final String? outcomeNote,
  }) = _$StopDetailImpl;

  factory _StopDetail.fromJson(Map<String, dynamic> json) =
      _$StopDetailImpl.fromJson;

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
  @JsonKey(name: 'outlet_id')
  String get outletId;
  @override
  @JsonKey(name: 'outlet_name')
  String get outletName;
  @override
  String get district;
  @override
  @JsonKey(name: 'dock_type')
  DockType get dockType;
  @override
  @JsonKey(name: 'parking_constraint')
  ParkingConstraint get parkingConstraint;
  @override
  @JsonKey(name: 'order_units')
  int get orderUnits;
  @override
  @JsonKey(name: 'order_weight_kg')
  double get orderWeightKg;
  @override
  @JsonKey(name: 'order_volume_m3')
  double get orderVolumeM3;
  @override
  @JsonKey(name: 'window_open_time')
  String get windowOpenTime;
  @override
  @JsonKey(name: 'window_close_time')
  String get windowCloseTime;
  @override
  String? get eta;
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

  /// Create a copy of StopDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StopDetailImplCopyWith<_$StopDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
