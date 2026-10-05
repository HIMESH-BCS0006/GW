// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SyncOperationItemImpl _$$SyncOperationItemImplFromJson(
  Map<String, dynamic> json,
) => _$SyncOperationItemImpl(
  clientOpId: json['client_op_id'] as String,
  deviceId: json['device_id'] as String,
  clientSeq: (json['client_seq'] as num).toInt(),
  opType: json['op_type'] as String,
  payload: json['payload'] as Map<String, dynamic>,
  clientTs: json['client_ts'] as String,
);

Map<String, dynamic> _$$SyncOperationItemImplToJson(
  _$SyncOperationItemImpl instance,
) => <String, dynamic>{
  'client_op_id': instance.clientOpId,
  'device_id': instance.deviceId,
  'client_seq': instance.clientSeq,
  'op_type': instance.opType,
  'payload': instance.payload,
  'client_ts': instance.clientTs,
};

_$SyncBatchRequestImpl _$$SyncBatchRequestImplFromJson(
  Map<String, dynamic> json,
) => _$SyncBatchRequestImpl(
  operations: (json['operations'] as List<dynamic>)
      .map((e) => SyncOperationItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$SyncBatchRequestImplToJson(
  _$SyncBatchRequestImpl instance,
) => <String, dynamic>{'operations': instance.operations};

_$SyncOperationResultItemImpl _$$SyncOperationResultItemImplFromJson(
  Map<String, dynamic> json,
) => _$SyncOperationResultItemImpl(
  clientOpId: json['client_op_id'] as String,
  result: $enumDecode(_$SyncOpResultEnumMap, json['result']),
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$$SyncOperationResultItemImplToJson(
  _$SyncOperationResultItemImpl instance,
) => <String, dynamic>{
  'client_op_id': instance.clientOpId,
  'result': _$SyncOpResultEnumMap[instance.result]!,
  'reason': instance.reason,
};

const _$SyncOpResultEnumMap = {
  SyncOpResult.applied: 'applied',
  SyncOpResult.replayed: 'replayed',
  SyncOpResult.appliedWithConflict: 'applied_with_conflict',
  SyncOpResult.rejected: 'rejected',
};

_$SyncBatchResponseImpl _$$SyncBatchResponseImplFromJson(
  Map<String, dynamic> json,
) => _$SyncBatchResponseImpl(
  results: (json['results'] as List<dynamic>)
      .map((e) => SyncOperationResultItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$SyncBatchResponseImplToJson(
  _$SyncBatchResponseImpl instance,
) => <String, dynamic>{'results': instance.results};
