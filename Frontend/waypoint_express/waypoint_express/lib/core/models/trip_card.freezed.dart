// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TripCard _$TripCardFromJson(Map<String, dynamic> json) {
  return _TripCard.fromJson(json);
}

/// @nodoc
mixin _$TripCard {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'plan_run_id')
  String get planRunId => throw _privateConstructorUsedError;
  @JsonKey(name: 'delivery_date')
  String get deliveryDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'trip_no')
  int get tripNo => throw _privateConstructorUsedError;
  Brand get brand => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  @JsonKey(name: 'depot_id')
  String get depotId => throw _privateConstructorUsedError;
  @JsonKey(name: 'vehicle_id')
  String get vehicleId => throw _privateConstructorUsedError;
  @JsonKey(name: 'vehicle_type')
  VehicleType get vehicleType => throw _privateConstructorUsedError;
  @JsonKey(name: 'vehicle_temp')
  TemperatureRequirement get vehicleTemp => throw _privateConstructorUsedError;
  @JsonKey(name: 'stop_count')
  int get stopCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'depart_time')
  String? get departTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'plan_version')
  int get planVersion => throw _privateConstructorUsedError;
  TripStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'weight_used_kg')
  double get weightUsedKg => throw _privateConstructorUsedError;
  @JsonKey(name: 'weight_cap_kg')
  double get weightCapKg => throw _privateConstructorUsedError;
  @JsonKey(name: 'volume_used_m3')
  double get volumeUsedM3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'volume_cap_m3')
  double get volumeCapM3 => throw _privateConstructorUsedError;

  /// Serializes this TripCard to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TripCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TripCardCopyWith<TripCard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripCardCopyWith<$Res> {
  factory $TripCardCopyWith(TripCard value, $Res Function(TripCard) then) =
      _$TripCardCopyWithImpl<$Res, TripCard>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'plan_run_id') String planRunId,
    @JsonKey(name: 'delivery_date') String deliveryDate,
    @JsonKey(name: 'trip_no') int tripNo,
    Brand brand,
    String district,
    @JsonKey(name: 'depot_id') String depotId,
    @JsonKey(name: 'vehicle_id') String vehicleId,
    @JsonKey(name: 'vehicle_type') VehicleType vehicleType,
    @JsonKey(name: 'vehicle_temp') TemperatureRequirement vehicleTemp,
    @JsonKey(name: 'stop_count') int stopCount,
    @JsonKey(name: 'depart_time') String? departTime,
    @JsonKey(name: 'plan_version') int planVersion,
    TripStatus status,
    @JsonKey(name: 'weight_used_kg') double weightUsedKg,
    @JsonKey(name: 'weight_cap_kg') double weightCapKg,
    @JsonKey(name: 'volume_used_m3') double volumeUsedM3,
    @JsonKey(name: 'volume_cap_m3') double volumeCapM3,
  });
}

/// @nodoc
class _$TripCardCopyWithImpl<$Res, $Val extends TripCard>
    implements $TripCardCopyWith<$Res> {
  _$TripCardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TripCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planRunId = null,
    Object? deliveryDate = null,
    Object? tripNo = null,
    Object? brand = null,
    Object? district = null,
    Object? depotId = null,
    Object? vehicleId = null,
    Object? vehicleType = null,
    Object? vehicleTemp = null,
    Object? stopCount = null,
    Object? departTime = freezed,
    Object? planVersion = null,
    Object? status = null,
    Object? weightUsedKg = null,
    Object? weightCapKg = null,
    Object? volumeUsedM3 = null,
    Object? volumeCapM3 = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            planRunId: null == planRunId
                ? _value.planRunId
                : planRunId // ignore: cast_nullable_to_non_nullable
                      as String,
            deliveryDate: null == deliveryDate
                ? _value.deliveryDate
                : deliveryDate // ignore: cast_nullable_to_non_nullable
                      as String,
            tripNo: null == tripNo
                ? _value.tripNo
                : tripNo // ignore: cast_nullable_to_non_nullable
                      as int,
            brand: null == brand
                ? _value.brand
                : brand // ignore: cast_nullable_to_non_nullable
                      as Brand,
            district: null == district
                ? _value.district
                : district // ignore: cast_nullable_to_non_nullable
                      as String,
            depotId: null == depotId
                ? _value.depotId
                : depotId // ignore: cast_nullable_to_non_nullable
                      as String,
            vehicleId: null == vehicleId
                ? _value.vehicleId
                : vehicleId // ignore: cast_nullable_to_non_nullable
                      as String,
            vehicleType: null == vehicleType
                ? _value.vehicleType
                : vehicleType // ignore: cast_nullable_to_non_nullable
                      as VehicleType,
            vehicleTemp: null == vehicleTemp
                ? _value.vehicleTemp
                : vehicleTemp // ignore: cast_nullable_to_non_nullable
                      as TemperatureRequirement,
            stopCount: null == stopCount
                ? _value.stopCount
                : stopCount // ignore: cast_nullable_to_non_nullable
                      as int,
            departTime: freezed == departTime
                ? _value.departTime
                : departTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            planVersion: null == planVersion
                ? _value.planVersion
                : planVersion // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TripStatus,
            weightUsedKg: null == weightUsedKg
                ? _value.weightUsedKg
                : weightUsedKg // ignore: cast_nullable_to_non_nullable
                      as double,
            weightCapKg: null == weightCapKg
                ? _value.weightCapKg
                : weightCapKg // ignore: cast_nullable_to_non_nullable
                      as double,
            volumeUsedM3: null == volumeUsedM3
                ? _value.volumeUsedM3
                : volumeUsedM3 // ignore: cast_nullable_to_non_nullable
                      as double,
            volumeCapM3: null == volumeCapM3
                ? _value.volumeCapM3
                : volumeCapM3 // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TripCardImplCopyWith<$Res>
    implements $TripCardCopyWith<$Res> {
  factory _$$TripCardImplCopyWith(
    _$TripCardImpl value,
    $Res Function(_$TripCardImpl) then,
  ) = __$$TripCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'plan_run_id') String planRunId,
    @JsonKey(name: 'delivery_date') String deliveryDate,
    @JsonKey(name: 'trip_no') int tripNo,
    Brand brand,
    String district,
    @JsonKey(name: 'depot_id') String depotId,
    @JsonKey(name: 'vehicle_id') String vehicleId,
    @JsonKey(name: 'vehicle_type') VehicleType vehicleType,
    @JsonKey(name: 'vehicle_temp') TemperatureRequirement vehicleTemp,
    @JsonKey(name: 'stop_count') int stopCount,
    @JsonKey(name: 'depart_time') String? departTime,
    @JsonKey(name: 'plan_version') int planVersion,
    TripStatus status,
    @JsonKey(name: 'weight_used_kg') double weightUsedKg,
    @JsonKey(name: 'weight_cap_kg') double weightCapKg,
    @JsonKey(name: 'volume_used_m3') double volumeUsedM3,
    @JsonKey(name: 'volume_cap_m3') double volumeCapM3,
  });
}

/// @nodoc
class __$$TripCardImplCopyWithImpl<$Res>
    extends _$TripCardCopyWithImpl<$Res, _$TripCardImpl>
    implements _$$TripCardImplCopyWith<$Res> {
  __$$TripCardImplCopyWithImpl(
    _$TripCardImpl _value,
    $Res Function(_$TripCardImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TripCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planRunId = null,
    Object? deliveryDate = null,
    Object? tripNo = null,
    Object? brand = null,
    Object? district = null,
    Object? depotId = null,
    Object? vehicleId = null,
    Object? vehicleType = null,
    Object? vehicleTemp = null,
    Object? stopCount = null,
    Object? departTime = freezed,
    Object? planVersion = null,
    Object? status = null,
    Object? weightUsedKg = null,
    Object? weightCapKg = null,
    Object? volumeUsedM3 = null,
    Object? volumeCapM3 = null,
  }) {
    return _then(
      _$TripCardImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        planRunId: null == planRunId
            ? _value.planRunId
            : planRunId // ignore: cast_nullable_to_non_nullable
                  as String,
        deliveryDate: null == deliveryDate
            ? _value.deliveryDate
            : deliveryDate // ignore: cast_nullable_to_non_nullable
                  as String,
        tripNo: null == tripNo
            ? _value.tripNo
            : tripNo // ignore: cast_nullable_to_non_nullable
                  as int,
        brand: null == brand
            ? _value.brand
            : brand // ignore: cast_nullable_to_non_nullable
                  as Brand,
        district: null == district
            ? _value.district
            : district // ignore: cast_nullable_to_non_nullable
                  as String,
        depotId: null == depotId
            ? _value.depotId
            : depotId // ignore: cast_nullable_to_non_nullable
                  as String,
        vehicleId: null == vehicleId
            ? _value.vehicleId
            : vehicleId // ignore: cast_nullable_to_non_nullable
                  as String,
        vehicleType: null == vehicleType
            ? _value.vehicleType
            : vehicleType // ignore: cast_nullable_to_non_nullable
                  as VehicleType,
        vehicleTemp: null == vehicleTemp
            ? _value.vehicleTemp
            : vehicleTemp // ignore: cast_nullable_to_non_nullable
                  as TemperatureRequirement,
        stopCount: null == stopCount
            ? _value.stopCount
            : stopCount // ignore: cast_nullable_to_non_nullable
                  as int,
        departTime: freezed == departTime
            ? _value.departTime
            : departTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        planVersion: null == planVersion
            ? _value.planVersion
            : planVersion // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TripStatus,
        weightUsedKg: null == weightUsedKg
            ? _value.weightUsedKg
            : weightUsedKg // ignore: cast_nullable_to_non_nullable
                  as double,
        weightCapKg: null == weightCapKg
            ? _value.weightCapKg
            : weightCapKg // ignore: cast_nullable_to_non_nullable
                  as double,
        volumeUsedM3: null == volumeUsedM3
            ? _value.volumeUsedM3
            : volumeUsedM3 // ignore: cast_nullable_to_non_nullable
                  as double,
        volumeCapM3: null == volumeCapM3
            ? _value.volumeCapM3
            : volumeCapM3 // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TripCardImpl implements _TripCard {
  const _$TripCardImpl({
    required this.id,
    @JsonKey(name: 'plan_run_id') required this.planRunId,
    @JsonKey(name: 'delivery_date') required this.deliveryDate,
    @JsonKey(name: 'trip_no') required this.tripNo,
    required this.brand,
    required this.district,
    @JsonKey(name: 'depot_id') required this.depotId,
    @JsonKey(name: 'vehicle_id') required this.vehicleId,
    @JsonKey(name: 'vehicle_type') required this.vehicleType,
    @JsonKey(name: 'vehicle_temp') required this.vehicleTemp,
    @JsonKey(name: 'stop_count') required this.stopCount,
    @JsonKey(name: 'depart_time') this.departTime,
    @JsonKey(name: 'plan_version') required this.planVersion,
    required this.status,
    @JsonKey(name: 'weight_used_kg') required this.weightUsedKg,
    @JsonKey(name: 'weight_cap_kg') required this.weightCapKg,
    @JsonKey(name: 'volume_used_m3') required this.volumeUsedM3,
    @JsonKey(name: 'volume_cap_m3') required this.volumeCapM3,
  });

  factory _$TripCardImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripCardImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'plan_run_id')
  final String planRunId;
  @override
  @JsonKey(name: 'delivery_date')
  final String deliveryDate;
  @override
  @JsonKey(name: 'trip_no')
  final int tripNo;
  @override
  final Brand brand;
  @override
  final String district;
  @override
  @JsonKey(name: 'depot_id')
  final String depotId;
  @override
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @override
  @JsonKey(name: 'vehicle_type')
  final VehicleType vehicleType;
  @override
  @JsonKey(name: 'vehicle_temp')
  final TemperatureRequirement vehicleTemp;
  @override
  @JsonKey(name: 'stop_count')
  final int stopCount;
  @override
  @JsonKey(name: 'depart_time')
  final String? departTime;
  @override
  @JsonKey(name: 'plan_version')
  final int planVersion;
  @override
  final TripStatus status;
  @override
  @JsonKey(name: 'weight_used_kg')
  final double weightUsedKg;
  @override
  @JsonKey(name: 'weight_cap_kg')
  final double weightCapKg;
  @override
  @JsonKey(name: 'volume_used_m3')
  final double volumeUsedM3;
  @override
  @JsonKey(name: 'volume_cap_m3')
  final double volumeCapM3;

  @override
  String toString() {
    return 'TripCard(id: $id, planRunId: $planRunId, deliveryDate: $deliveryDate, tripNo: $tripNo, brand: $brand, district: $district, depotId: $depotId, vehicleId: $vehicleId, vehicleType: $vehicleType, vehicleTemp: $vehicleTemp, stopCount: $stopCount, departTime: $departTime, planVersion: $planVersion, status: $status, weightUsedKg: $weightUsedKg, weightCapKg: $weightCapKg, volumeUsedM3: $volumeUsedM3, volumeCapM3: $volumeCapM3)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripCardImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planRunId, planRunId) ||
                other.planRunId == planRunId) &&
            (identical(other.deliveryDate, deliveryDate) ||
                other.deliveryDate == deliveryDate) &&
            (identical(other.tripNo, tripNo) || other.tripNo == tripNo) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.depotId, depotId) || other.depotId == depotId) &&
            (identical(other.vehicleId, vehicleId) ||
                other.vehicleId == vehicleId) &&
            (identical(other.vehicleType, vehicleType) ||
                other.vehicleType == vehicleType) &&
            (identical(other.vehicleTemp, vehicleTemp) ||
                other.vehicleTemp == vehicleTemp) &&
            (identical(other.stopCount, stopCount) ||
                other.stopCount == stopCount) &&
            (identical(other.departTime, departTime) ||
                other.departTime == departTime) &&
            (identical(other.planVersion, planVersion) ||
                other.planVersion == planVersion) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.weightUsedKg, weightUsedKg) ||
                other.weightUsedKg == weightUsedKg) &&
            (identical(other.weightCapKg, weightCapKg) ||
                other.weightCapKg == weightCapKg) &&
            (identical(other.volumeUsedM3, volumeUsedM3) ||
                other.volumeUsedM3 == volumeUsedM3) &&
            (identical(other.volumeCapM3, volumeCapM3) ||
                other.volumeCapM3 == volumeCapM3));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    planRunId,
    deliveryDate,
    tripNo,
    brand,
    district,
    depotId,
    vehicleId,
    vehicleType,
    vehicleTemp,
    stopCount,
    departTime,
    planVersion,
    status,
    weightUsedKg,
    weightCapKg,
    volumeUsedM3,
    volumeCapM3,
  );

  /// Create a copy of TripCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TripCardImplCopyWith<_$TripCardImpl> get copyWith =>
      __$$TripCardImplCopyWithImpl<_$TripCardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripCardImplToJson(this);
  }
}

abstract class _TripCard implements TripCard {
  const factory _TripCard({
    required final String id,
    @JsonKey(name: 'plan_run_id') required final String planRunId,
    @JsonKey(name: 'delivery_date') required final String deliveryDate,
    @JsonKey(name: 'trip_no') required final int tripNo,
    required final Brand brand,
    required final String district,
    @JsonKey(name: 'depot_id') required final String depotId,
    @JsonKey(name: 'vehicle_id') required final String vehicleId,
    @JsonKey(name: 'vehicle_type') required final VehicleType vehicleType,
    @JsonKey(name: 'vehicle_temp')
    required final TemperatureRequirement vehicleTemp,
    @JsonKey(name: 'stop_count') required final int stopCount,
    @JsonKey(name: 'depart_time') final String? departTime,
    @JsonKey(name: 'plan_version') required final int planVersion,
    required final TripStatus status,
    @JsonKey(name: 'weight_used_kg') required final double weightUsedKg,
    @JsonKey(name: 'weight_cap_kg') required final double weightCapKg,
    @JsonKey(name: 'volume_used_m3') required final double volumeUsedM3,
    @JsonKey(name: 'volume_cap_m3') required final double volumeCapM3,
  }) = _$TripCardImpl;

  factory _TripCard.fromJson(Map<String, dynamic> json) =
      _$TripCardImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'plan_run_id')
  String get planRunId;
  @override
  @JsonKey(name: 'delivery_date')
  String get deliveryDate;
  @override
  @JsonKey(name: 'trip_no')
  int get tripNo;
  @override
  Brand get brand;
  @override
  String get district;
  @override
  @JsonKey(name: 'depot_id')
  String get depotId;
  @override
  @JsonKey(name: 'vehicle_id')
  String get vehicleId;
  @override
  @JsonKey(name: 'vehicle_type')
  VehicleType get vehicleType;
  @override
  @JsonKey(name: 'vehicle_temp')
  TemperatureRequirement get vehicleTemp;
  @override
  @JsonKey(name: 'stop_count')
  int get stopCount;
  @override
  @JsonKey(name: 'depart_time')
  String? get departTime;
  @override
  @JsonKey(name: 'plan_version')
  int get planVersion;
  @override
  TripStatus get status;
  @override
  @JsonKey(name: 'weight_used_kg')
  double get weightUsedKg;
  @override
  @JsonKey(name: 'weight_cap_kg')
  double get weightCapKg;
  @override
  @JsonKey(name: 'volume_used_m3')
  double get volumeUsedM3;
  @override
  @JsonKey(name: 'volume_cap_m3')
  double get volumeCapM3;

  /// Create a copy of TripCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TripCardImplCopyWith<_$TripCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
