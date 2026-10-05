// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreateLoadCheckRequestImpl _$$CreateLoadCheckRequestImplFromJson(
  Map<String, dynamic> json,
) => _$CreateLoadCheckRequestImpl(
  orderId: json['order_id'] as String,
  planVersion: (json['plan_version'] as num).toInt(),
  expectedQty: (json['expected_qty'] as num).toInt(),
  loadedQty: (json['loaded_qty'] as num).toInt(),
  issue: $enumDecode(_$LoadCheckIssueEnumMap, json['issue']),
  note: json['note'] as String?,
  clientOpId: json['client_op_id'] as String?,
);

Map<String, dynamic> _$$CreateLoadCheckRequestImplToJson(
  _$CreateLoadCheckRequestImpl instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'plan_version': instance.planVersion,
  'expected_qty': instance.expectedQty,
  'loaded_qty': instance.loadedQty,
  'issue': _$LoadCheckIssueEnumMap[instance.issue]!,
  'note': instance.note,
  'client_op_id': instance.clientOpId,
};

const _$LoadCheckIssueEnumMap = {
  LoadCheckIssue.missing: 'missing',
  LoadCheckIssue.damaged: 'damaged',
};

_$ConfirmLoadRequestImpl _$$ConfirmLoadRequestImplFromJson(
  Map<String, dynamic> json,
) => _$ConfirmLoadRequestImpl(
  planVersion: (json['plan_version'] as num).toInt(),
);

Map<String, dynamic> _$$ConfirmLoadRequestImplToJson(
  _$ConfirmLoadRequestImpl instance,
) => <String, dynamic>{'plan_version': instance.planVersion};

_$StartTripRequestImpl _$$StartTripRequestImplFromJson(
  Map<String, dynamic> json,
) => _$StartTripRequestImpl(
  planVersion: (json['plan_version'] as num).toInt(),
  clientOpId: json['client_op_id'] as String?,
);

Map<String, dynamic> _$$StartTripRequestImplToJson(
  _$StartTripRequestImpl instance,
) => <String, dynamic>{
  'plan_version': instance.planVersion,
  'client_op_id': instance.clientOpId,
};

_$RecordStopOutcomeRequestImpl _$$RecordStopOutcomeRequestImplFromJson(
  Map<String, dynamic> json,
) => _$RecordStopOutcomeRequestImpl(
  outcome: $enumDecode(_$StopOutcomeEnumMap, json['outcome']),
  quantityDelivered: (json['quantity_delivered'] as num?)?.toInt(),
  receivedBy: json['received_by'] as String?,
  outcomeNote: json['outcome_note'] as String?,
  completedAt: json['completed_at'] as String,
  clientOpId: json['client_op_id'] as String?,
);

Map<String, dynamic> _$$RecordStopOutcomeRequestImplToJson(
  _$RecordStopOutcomeRequestImpl instance,
) => <String, dynamic>{
  'outcome': _$StopOutcomeEnumMap[instance.outcome]!,
  'quantity_delivered': instance.quantityDelivered,
  'received_by': instance.receivedBy,
  'outcome_note': instance.outcomeNote,
  'completed_at': instance.completedAt,
  'client_op_id': instance.clientOpId,
};

const _$StopOutcomeEnumMap = {
  StopOutcome.delivered: 'delivered',
  StopOutcome.partial: 'partial',
  StopOutcome.refused: 'refused',
  StopOutcome.closed: 'closed',
};

_$RecordStopExceptionRequestImpl _$$RecordStopExceptionRequestImplFromJson(
  Map<String, dynamic> json,
) => _$RecordStopExceptionRequestImpl(
  type: $enumDecode(_$ExceptionTypeEnumMap, json['type']),
  note: json['note'] as String?,
  clientOpId: json['client_op_id'] as String?,
  clientSeq: (json['client_seq'] as num?)?.toInt(),
  clientTs: json['client_ts'] as String?,
  planVersion: (json['plan_version'] as num?)?.toInt(),
);

Map<String, dynamic> _$$RecordStopExceptionRequestImplToJson(
  _$RecordStopExceptionRequestImpl instance,
) => <String, dynamic>{
  'type': _$ExceptionTypeEnumMap[instance.type]!,
  'note': instance.note,
  'client_op_id': instance.clientOpId,
  'client_seq': instance.clientSeq,
  'client_ts': instance.clientTs,
  'plan_version': instance.planVersion,
};

const _$ExceptionTypeEnumMap = {
  ExceptionType.dockBlocked: 'dock_blocked',
  ExceptionType.outletClosed: 'outlet_closed',
  ExceptionType.vehicleIssue: 'vehicle_issue',
  ExceptionType.accessProblem: 'access_problem',
  ExceptionType.other: 'other',
};
