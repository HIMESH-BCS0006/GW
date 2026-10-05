// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  id: json['id'] as String,
  username: json['username'] as String,
  role: $enumDecode(_$RoleEnumMap, json['role']),
  depotIds:
      (json['depot_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  outletId: json['outlet_id'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  displayName: json['display_name'] as String,
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'role': _$RoleEnumMap[instance.role]!,
      'depot_ids': instance.depotIds,
      'outlet_id': instance.outletId,
      'vehicle_id': instance.vehicleId,
      'display_name': instance.displayName,
    };

const _$RoleEnumMap = {
  Role.dispatcher: 'dispatcher',
  Role.loader: 'loader',
  Role.driver: 'driver',
  Role.storeManager: 'store_manager',
};
