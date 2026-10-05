// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TripImpl _$$TripImplFromJson(Map<String, dynamic> json) => _$TripImpl(
  id: json['id'] as String,
  planRunId: json['plan_run_id'] as String,
  vehicleId: json['vehicle_id'] as String,
  depotId: json['depot_id'] as String,
  deliveryDate: json['delivery_date'] as String,
  tripNo: (json['trip_no'] as num).toInt(),
  brand: $enumDecode(_$BrandEnumMap, json['brand']),
  district: json['district'] as String,
  status: $enumDecode(_$TripStatusEnumMap, json['status']),
  planVersion: (json['plan_version'] as num).toInt(),
  departTime: json['depart_time'] as String?,
  estMinutes: (json['est_minutes'] as num).toInt(),
  estKm: (json['est_km'] as num).toDouble(),
  estFuelL: (json['est_fuel_l'] as num).toDouble(),
  confirmedBy: json['confirmed_by'] as String?,
  confirmedAt: json['confirmed_at'] as String?,
);

Map<String, dynamic> _$$TripImplToJson(_$TripImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan_run_id': instance.planRunId,
      'vehicle_id': instance.vehicleId,
      'depot_id': instance.depotId,
      'delivery_date': instance.deliveryDate,
      'trip_no': instance.tripNo,
      'brand': _$BrandEnumMap[instance.brand]!,
      'district': instance.district,
      'status': _$TripStatusEnumMap[instance.status]!,
      'plan_version': instance.planVersion,
      'depart_time': instance.departTime,
      'est_minutes': instance.estMinutes,
      'est_km': instance.estKm,
      'est_fuel_l': instance.estFuelL,
      'confirmed_by': instance.confirmedBy,
      'confirmed_at': instance.confirmedAt,
    };

const _$BrandEnumMap = {
  Brand.fresh: 'Fresh',
  Brand.style: 'Style',
  Brand.tech: 'Tech',
};

const _$TripStatusEnumMap = {
  TripStatus.draft: 'DRAFT',
  TripStatus.confirmed: 'CONFIRMED',
  TripStatus.loading: 'LOADING',
  TripStatus.loaded: 'LOADED',
  TripStatus.inProgress: 'IN_PROGRESS',
  TripStatus.completed: 'COMPLETED',
  TripStatus.blocked: 'BLOCKED',
  TripStatus.cancelled: 'CANCELLED',
};
