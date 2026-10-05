// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exception_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExceptionItemImpl _$$ExceptionItemImplFromJson(Map<String, dynamic> json) =>
    _$ExceptionItemImpl(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      stopId: json['stop_id'] as String,
      type: $enumDecode(_$ExceptionTypeEnumMap, json['type']),
      note: json['note'] as String?,
      reportedAt: json['reported_at'] as String,
      status: $enumDecode(_$ExceptionStatusEnumMap, json['status']),
      decision: $enumDecodeNullable(
        _$ExceptionDecisionEnumMap,
        json['decision'],
      ),
      decisionNote: json['decision_note'] as String?,
      decidedBy: json['decided_by'] as String?,
      decidedAt: json['decided_at'] as String?,
    );

Map<String, dynamic> _$$ExceptionItemImplToJson(_$ExceptionItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'stop_id': instance.stopId,
      'type': _$ExceptionTypeEnumMap[instance.type]!,
      'note': instance.note,
      'reported_at': instance.reportedAt,
      'status': _$ExceptionStatusEnumMap[instance.status]!,
      'decision': _$ExceptionDecisionEnumMap[instance.decision],
      'decision_note': instance.decisionNote,
      'decided_by': instance.decidedBy,
      'decided_at': instance.decidedAt,
    };

const _$ExceptionTypeEnumMap = {
  ExceptionType.dockBlocked: 'dock_blocked',
  ExceptionType.outletClosed: 'outlet_closed',
  ExceptionType.vehicleIssue: 'vehicle_issue',
  ExceptionType.accessProblem: 'access_problem',
  ExceptionType.other: 'other',
};

const _$ExceptionStatusEnumMap = {
  ExceptionStatus.open: 'OPEN',
  ExceptionStatus.decided: 'DECIDED',
};

const _$ExceptionDecisionEnumMap = {
  ExceptionDecision.retry: 'retry',
  ExceptionDecision.skip: 'skip',
};
