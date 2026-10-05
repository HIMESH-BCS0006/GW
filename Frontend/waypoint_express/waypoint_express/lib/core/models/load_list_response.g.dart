// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LoadListResponseImpl _$$LoadListResponseImplFromJson(
  Map<String, dynamic> json,
) => _$LoadListResponseImpl(
  planVersion: (json['plan_version'] as num).toInt(),
  trip: TripCard.fromJson(json['trip'] as Map<String, dynamic>),
  deliverySequence: (json['delivery_sequence'] as List<dynamic>)
      .map((e) => StopDetail.fromJson(e as Map<String, dynamic>))
      .toList(),
  reverseLoadOrder: (json['reverse_load_order'] as List<dynamic>)
      .map((e) => StopDetail.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$LoadListResponseImplToJson(
  _$LoadListResponseImpl instance,
) => <String, dynamic>{
  'plan_version': instance.planVersion,
  'trip': instance.trip,
  'delivery_sequence': instance.deliverySequence,
  'reverse_load_order': instance.reverseLoadOrder,
};
