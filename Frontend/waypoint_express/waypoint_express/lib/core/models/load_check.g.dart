// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load_check.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LoadCheckImpl _$$LoadCheckImplFromJson(Map<String, dynamic> json) =>
    _$LoadCheckImpl(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      orderId: json['order_id'] as String,
      planVersion: (json['plan_version'] as num).toInt(),
      expectedQty: (json['expected_qty'] as num).toInt(),
      loadedQty: (json['loaded_qty'] as num).toInt(),
      issue: $enumDecode(_$LoadCheckIssueEnumMap, json['issue']),
      note: json['note'] as String?,
      status: $enumDecode(_$LoadCheckStatusEnumMap, json['status']),
      resolution: $enumDecodeNullable(
        _$LoadCheckResolutionEnumMap,
        json['resolution'],
      ),
      reportedBy: json['reported_by'] as String,
      resolvedBy: json['resolved_by'] as String?,
    );

Map<String, dynamic> _$$LoadCheckImplToJson(_$LoadCheckImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'order_id': instance.orderId,
      'plan_version': instance.planVersion,
      'expected_qty': instance.expectedQty,
      'loaded_qty': instance.loadedQty,
      'issue': _$LoadCheckIssueEnumMap[instance.issue]!,
      'note': instance.note,
      'status': _$LoadCheckStatusEnumMap[instance.status]!,
      'resolution': _$LoadCheckResolutionEnumMap[instance.resolution],
      'reported_by': instance.reportedBy,
      'resolved_by': instance.resolvedBy,
    };

const _$LoadCheckIssueEnumMap = {
  LoadCheckIssue.missing: 'missing',
  LoadCheckIssue.damaged: 'damaged',
};

const _$LoadCheckStatusEnumMap = {
  LoadCheckStatus.open: 'OPEN',
  LoadCheckStatus.resolved: 'RESOLVED',
};

const _$LoadCheckResolutionEnumMap = {
  LoadCheckResolution.deferOrder: 'defer_order',
  LoadCheckResolution.replanOrder: 'replan_order',
  LoadCheckResolution.proceedPartial: 'proceed_partial',
};
