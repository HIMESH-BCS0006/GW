// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Trip _$TripFromJson(Map<String, dynamic> json) {
  return _Trip.fromJson(json);
}

/// @nodoc
mixin _$Trip {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'plan_run_id')
  String get planRunId => throw _privateConstructorUsedError;
  @JsonKey(name: 'vehicle_id')
  String get vehicleId => throw _privateConstructorUsedError;
  @JsonKey(name: 'depot_id')
  String get depotId => throw _privateConstructorUsedError;
  @JsonKey(name: 'delivery_date')
  String get deliveryDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'trip_no')
  int get tripNo => throw _privateConstructorUsedError;
  Brand get brand => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  TripStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'plan_version')
  int get planVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'depart_time')
  String? get departTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'est_minutes')
  int get estMinutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'est_km')
  double get estKm => throw _privateConstructorUsedError;
  @JsonKey(name: 'est_fuel_l')
  double get estFuelL => throw _privateConstructorUsedError;
  @JsonKey(name: 'confirmed_by')
  String? get confirmedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'confirmed_at')
  String? get confirmedAt => throw _privateConstructorUsedError;

  /// Serializes this Trip to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Trip
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TripCopyWith<Trip> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripCopyWith<$Res> {
  factory $TripCopyWith(Trip value, $Res Function(Trip) then) =
      _$TripCopyWithImpl<$Res, Trip>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'plan_run_id') String planRunId,
    @JsonKey(name: 'vehicle_id') String vehicleId,
    @JsonKey(name: 'depot_id') String depotId,
    @JsonKey(name: 'delivery_date') String deliveryDate,
    @JsonKey(name: 'trip_no') int tripNo,
    Brand brand,
    String district,
    TripStatus status,
    @JsonKey(name: 'plan_version') int planVersion,
    @JsonKey(name: 'depart_time') String? departTime,
    @JsonKey(name: 'est_minutes') int estMinutes,
    @JsonKey(name: 'est_km') double estKm,
    @JsonKey(name: 'est_fuel_l') double estFuelL,
    @JsonKey(name: 'confirmed_by') String? confirmedBy,
    @JsonKey(name: 'confirmed_at') String? confirmedAt,
  });
}

/// @nodoc
class _$TripCopyWithImpl<$Res, $Val extends Trip>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Trip
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planRunId = null,
    Object? vehicleId = null,
    Object? depotId = null,
    Object? deliveryDate = null,
    Object? tripNo = null,
    Object? brand = null,
    Object? district = null,
    Object? status = null,
    Object? planVersion = null,
    Object? departTime = freezed,
    Object? estMinutes = null,
    Object? estKm = null,
    Object? estFuelL = null,
    Object? confirmedBy = freezed,
    Object? confirmedAt = freezed,
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
            vehicleId: null == vehicleId
                ? _value.vehicleId
                : vehicleId // ignore: cast_nullable_to_non_nullable
                      as String,
            depotId: null == depotId
                ? _value.depotId
                : depotId // ignore: cast_nullable_to_non_nullable
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
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TripStatus,
            planVersion: null == planVersion
                ? _value.planVersion
                : planVersion // ignore: cast_nullable_to_non_nullable
                      as int,
            departTime: freezed == departTime
                ? _value.departTime
                : departTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            estMinutes: null == estMinutes
                ? _value.estMinutes
                : estMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            estKm: null == estKm
                ? _value.estKm
                : estKm // ignore: cast_nullable_to_non_nullable
                      as double,
            estFuelL: null == estFuelL
                ? _value.estFuelL
                : estFuelL // ignore: cast_nullable_to_non_nullable
                      as double,
            confirmedBy: freezed == confirmedBy
                ? _value.confirmedBy
                : confirmedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            confirmedAt: freezed == confirmedAt
                ? _value.confirmedAt
                : confirmedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TripImplCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$$TripImplCopyWith(
    _$TripImpl value,
    $Res Function(_$TripImpl) then,
  ) = __$$TripImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'plan_run_id') String planRunId,
    @JsonKey(name: 'vehicle_id') String vehicleId,
    @JsonKey(name: 'depot_id') String depotId,
    @JsonKey(name: 'delivery_date') String deliveryDate,
    @JsonKey(name: 'trip_no') int tripNo,
    Brand brand,
    String district,
    TripStatus status,
    @JsonKey(name: 'plan_version') int planVersion,
    @JsonKey(name: 'depart_time') String? departTime,
    @JsonKey(name: 'est_minutes') int estMinutes,
    @JsonKey(name: 'est_km') double estKm,
    @JsonKey(name: 'est_fuel_l') double estFuelL,
    @JsonKey(name: 'confirmed_by') String? confirmedBy,
    @JsonKey(name: 'confirmed_at') String? confirmedAt,
  });
}

/// @nodoc
class __$$TripImplCopyWithImpl<$Res>
    extends _$TripCopyWithImpl<$Res, _$TripImpl>
    implements _$$TripImplCopyWith<$Res> {
  __$$TripImplCopyWithImpl(_$TripImpl _value, $Res Function(_$TripImpl) _then)
    : super(_value, _then);

  /// Create a copy of Trip
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planRunId = null,
    Object? vehicleId = null,
    Object? depotId = null,
    Object? deliveryDate = null,
    Object? tripNo = null,
    Object? brand = null,
    Object? district = null,
    Object? status = null,
    Object? planVersion = null,
    Object? departTime = freezed,
    Object? estMinutes = null,
    Object? estKm = null,
    Object? estFuelL = null,
    Object? confirmedBy = freezed,
    Object? confirmedAt = freezed,
  }) {
    return _then(
      _$TripImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        planRunId: null == planRunId
            ? _value.planRunId
            : planRunId // ignore: cast_nullable_to_non_nullable
                  as String,
        vehicleId: null == vehicleId
            ? _value.vehicleId
            : vehicleId // ignore: cast_nullable_to_non_nullable
                  as String,
        depotId: null == depotId
            ? _value.depotId
            : depotId // ignore: cast_nullable_to_non_nullable
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
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TripStatus,
        planVersion: null == planVersion
            ? _value.planVersion
            : planVersion // ignore: cast_nullable_to_non_nullable
                  as int,
        departTime: freezed == departTime
            ? _value.departTime
            : departTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        estMinutes: null == estMinutes
            ? _value.estMinutes
            : estMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        estKm: null == estKm
            ? _value.estKm
            : estKm // ignore: cast_nullable_to_non_nullable
                  as double,
        estFuelL: null == estFuelL
            ? _value.estFuelL
            : estFuelL // ignore: cast_nullable_to_non_nullable
                  as double,
        confirmedBy: freezed == confirmedBy
            ? _value.confirmedBy
            : confirmedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        confirmedAt: freezed == confirmedAt
            ? _value.confirmedAt
            : confirmedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TripImpl implements _Trip {
  const _$TripImpl({
    required this.id,
    @JsonKey(name: 'plan_run_id') required this.planRunId,
    @JsonKey(name: 'vehicle_id') required this.vehicleId,
    @JsonKey(name: 'depot_id') required this.depotId,
    @JsonKey(name: 'delivery_date') required this.deliveryDate,
    @JsonKey(name: 'trip_no') required this.tripNo,
    required this.brand,
    required this.district,
    required this.status,
    @JsonKey(name: 'plan_version') required this.planVersion,
    @JsonKey(name: 'depart_time') this.departTime,
    @JsonKey(name: 'est_minutes') required this.estMinutes,
    @JsonKey(name: 'est_km') required this.estKm,
    @JsonKey(name: 'est_fuel_l') required this.estFuelL,
    @JsonKey(name: 'confirmed_by') this.confirmedBy,
    @JsonKey(name: 'confirmed_at') this.confirmedAt,
  });

  factory _$TripImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'plan_run_id')
  final String planRunId;
  @override
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @override
  @JsonKey(name: 'depot_id')
  final String depotId;
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
  final TripStatus status;
  @override
  @JsonKey(name: 'plan_version')
  final int planVersion;
  @override
  @JsonKey(name: 'depart_time')
  final String? departTime;
  @override
  @JsonKey(name: 'est_minutes')
  final int estMinutes;
  @override
  @JsonKey(name: 'est_km')
  final double estKm;
  @override
  @JsonKey(name: 'est_fuel_l')
  final double estFuelL;
  @override
  @JsonKey(name: 'confirmed_by')
  final String? confirmedBy;
  @override
  @JsonKey(name: 'confirmed_at')
  final String? confirmedAt;

  @override
  String toString() {
    return 'Trip(id: $id, planRunId: $planRunId, vehicleId: $vehicleId, depotId: $depotId, deliveryDate: $deliveryDate, tripNo: $tripNo, brand: $brand, district: $district, status: $status, planVersion: $planVersion, departTime: $departTime, estMinutes: $estMinutes, estKm: $estKm, estFuelL: $estFuelL, confirmedBy: $confirmedBy, confirmedAt: $confirmedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planRunId, planRunId) ||
                other.planRunId == planRunId) &&
            (identical(other.vehicleId, vehicleId) ||
                other.vehicleId == vehicleId) &&
            (identical(other.depotId, depotId) || other.depotId == depotId) &&
            (identical(other.deliveryDate, deliveryDate) ||
                other.deliveryDate == deliveryDate) &&
            (identical(other.tripNo, tripNo) || other.tripNo == tripNo) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.planVersion, planVersion) ||
                other.planVersion == planVersion) &&
            (identical(other.departTime, departTime) ||
                other.departTime == departTime) &&
            (identical(other.estMinutes, estMinutes) ||
                other.estMinutes == estMinutes) &&
            (identical(other.estKm, estKm) || other.estKm == estKm) &&
            (identical(other.estFuelL, estFuelL) ||
                other.estFuelL == estFuelL) &&
            (identical(other.confirmedBy, confirmedBy) ||
                other.confirmedBy == confirmedBy) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    planRunId,
    vehicleId,
    depotId,
    deliveryDate,
    tripNo,
    brand,
    district,
    status,
    planVersion,
    departTime,
    estMinutes,
    estKm,
    estFuelL,
    confirmedBy,
    confirmedAt,
  );

  /// Create a copy of Trip
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TripImplCopyWith<_$TripImpl> get copyWith =>
      __$$TripImplCopyWithImpl<_$TripImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripImplToJson(this);
  }
}

abstract class _Trip implements Trip {
  const factory _Trip({
    required final String id,
    @JsonKey(name: 'plan_run_id') required final String planRunId,
    @JsonKey(name: 'vehicle_id') required final String vehicleId,
    @JsonKey(name: 'depot_id') required final String depotId,
    @JsonKey(name: 'delivery_date') required final String deliveryDate,
    @JsonKey(name: 'trip_no') required final int tripNo,
    required final Brand brand,
    required final String district,
    required final TripStatus status,
    @JsonKey(name: 'plan_version') required final int planVersion,
    @JsonKey(name: 'depart_time') final String? departTime,
    @JsonKey(name: 'est_minutes') required final int estMinutes,
    @JsonKey(name: 'est_km') required final double estKm,
    @JsonKey(name: 'est_fuel_l') required final double estFuelL,
    @JsonKey(name: 'confirmed_by') final String? confirmedBy,
    @JsonKey(name: 'confirmed_at') final String? confirmedAt,
  }) = _$TripImpl;

  factory _Trip.fromJson(Map<String, dynamic> json) = _$TripImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'plan_run_id')
  String get planRunId;
  @override
  @JsonKey(name: 'vehicle_id')
  String get vehicleId;
  @override
  @JsonKey(name: 'depot_id')
  String get depotId;
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
  TripStatus get status;
  @override
  @JsonKey(name: 'plan_version')
  int get planVersion;
  @override
  @JsonKey(name: 'depart_time')
  String? get departTime;
  @override
  @JsonKey(name: 'est_minutes')
  int get estMinutes;
  @override
  @JsonKey(name: 'est_km')
  double get estKm;
  @override
  @JsonKey(name: 'est_fuel_l')
  double get estFuelL;
  @override
  @JsonKey(name: 'confirmed_by')
  String? get confirmedBy;
  @override
  @JsonKey(name: 'confirmed_at')
  String? get confirmedAt;

  /// Create a copy of Trip
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TripImplCopyWith<_$TripImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
