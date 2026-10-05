// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_stop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TripStopImpl _$$TripStopImplFromJson(Map<String, dynamic> json) =>
    _$TripStopImpl(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      orderId: json['order_id'] as String,
      seq: (json['seq'] as num).toInt(),
      eta: json['eta'] as String?,
      serviceStartEst: json['service_start_est'] as String?,
      serviceMin: (json['service_min'] as num).toInt(),
      status: $enumDecode(_$StopStatusEnumMap, json['status']),
      receiptStatus: $enumDecode(
        _$ReceiptStatusEnumMap,
        json['receipt_status'],
      ),
      arrivedAt: json['arrived_at'] as String?,
      completedAt: json['completed_at'] as String?,
      outcome: $enumDecodeNullable(_$StopOutcomeEnumMap, json['outcome']),
      quantityDelivered: (json['quantity_delivered'] as num?)?.toInt(),
      receivedBy: json['received_by'] as String?,
      outcomeNote: json['outcome_note'] as String?,
      deviceTs: json['device_ts'] as String?,
    );

Map<String, dynamic> _$$TripStopImplToJson(_$TripStopImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'order_id': instance.orderId,
      'seq': instance.seq,
      'eta': instance.eta,
      'service_start_est': instance.serviceStartEst,
      'service_min': instance.serviceMin,
      'status': _$StopStatusEnumMap[instance.status]!,
      'receipt_status': _$ReceiptStatusEnumMap[instance.receiptStatus]!,
      'arrived_at': instance.arrivedAt,
      'completed_at': instance.completedAt,
      'outcome': _$StopOutcomeEnumMap[instance.outcome],
      'quantity_delivered': instance.quantityDelivered,
      'received_by': instance.receivedBy,
      'outcome_note': instance.outcomeNote,
      'device_ts': instance.deviceTs,
    };

const _$StopStatusEnumMap = {
  StopStatus.pending: 'PENDING',
  StopStatus.arrived: 'ARRIVED',
  StopStatus.delivered: 'DELIVERED',
  StopStatus.partial: 'PARTIAL',
  StopStatus.failed: 'FAILED',
  StopStatus.exception: 'EXCEPTION',
  StopStatus.skipped: 'SKIPPED',
};

const _$ReceiptStatusEnumMap = {
  ReceiptStatus.none: 'NONE',
  ReceiptStatus.awaiting: 'AWAITING',
  ReceiptStatus.confirmed: 'CONFIRMED',
  ReceiptStatus.discrepancy: 'DISCREPANCY',
};

const _$StopOutcomeEnumMap = {
  StopOutcome.delivered: 'delivered',
  StopOutcome.partial: 'partial',
  StopOutcome.refused: 'refused',
  StopOutcome.closed: 'closed',
};
