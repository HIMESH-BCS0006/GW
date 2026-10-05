// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TripCardImpl _$$TripCardImplFromJson(Map<String, dynamic> json) =>
    _$TripCardImpl(
      id: json['id'] as String,
      planRunId: json['plan_run_id'] as String,
      deliveryDate: json['delivery_date'] as String,
      tripNo: (json['trip_no'] as num).toInt(),
      brand: $enumDecode(_$BrandEnumMap, json['brand']),
      district: json['district'] as String,
      depotId: json['depot_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      vehicleType: $enumDecode(_$VehicleTypeEnumMap, json['vehicle_type']),
      vehicleTemp: $enumDecode(
        _$TemperatureRequirementEnumMap,
        json['vehicle_temp'],
      ),
      stopCount: (json['stop_count'] as num).toInt(),
      departTime: json['depart_time'] as String?,
      planVersion: (json['plan_version'] as num).toInt(),
      status: $enumDecode(_$TripStatusEnumMap, json['status']),
      weightUsedKg: (json['weight_used_kg'] as num).toDouble(),
      weightCapKg: (json['weight_cap_kg'] as num).toDouble(),
      volumeUsedM3: (json['volume_used_m3'] as num).toDouble(),
      volumeCapM3: (json['volume_cap_m3'] as num).toDouble(),
    );

Map<String, dynamic> _$$TripCardImplToJson(_$TripCardImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan_run_id': instance.planRunId,
      'delivery_date': instance.deliveryDate,
      'trip_no': instance.tripNo,
      'brand': _$BrandEnumMap[instance.brand]!,
      'district': instance.district,
      'depot_id': instance.depotId,
      'vehicle_id': instance.vehicleId,
      'vehicle_type': _$VehicleTypeEnumMap[instance.vehicleType]!,
      'vehicle_temp': _$TemperatureRequirementEnumMap[instance.vehicleTemp]!,
      'stop_count': instance.stopCount,
      'depart_time': instance.departTime,
      'plan_version': instance.planVersion,
      'status': _$TripStatusEnumMap[instance.status]!,
      'weight_used_kg': instance.weightUsedKg,
      'weight_cap_kg': instance.weightCapKg,
      'volume_used_m3': instance.volumeUsedM3,
      'volume_cap_m3': instance.volumeCapM3,
    };

const _$BrandEnumMap = {
  Brand.fresh: 'Fresh',
  Brand.style: 'Style',
  Brand.tech: 'Tech',
};

const _$VehicleTypeEnumMap = {
  VehicleType.truck: 'truck',
  VehicleType.van: 'van',
};

const _$TemperatureRequirementEnumMap = {
  TemperatureRequirement.chilled: 'chilled',
  TemperatureRequirement.ambient: 'ambient',
  TemperatureRequirement.reefer: 'reefer',
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
