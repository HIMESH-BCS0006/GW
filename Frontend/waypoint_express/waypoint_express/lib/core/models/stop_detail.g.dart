// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StopDetailImpl _$$StopDetailImplFromJson(Map<String, dynamic> json) =>
    _$StopDetailImpl(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      orderId: json['order_id'] as String,
      seq: (json['seq'] as num).toInt(),
      outletId: json['outlet_id'] as String,
      outletName: json['outlet_name'] as String,
      district: json['district'] as String,
      dockType: $enumDecode(_$DockTypeEnumMap, json['dock_type']),
      parkingConstraint: $enumDecode(
        _$ParkingConstraintEnumMap,
        json['parking_constraint'],
      ),
      orderUnits: (json['order_units'] as num).toInt(),
      orderWeightKg: (json['order_weight_kg'] as num).toDouble(),
      orderVolumeM3: (json['order_volume_m3'] as num).toDouble(),
      windowOpenTime: json['window_open_time'] as String,
      windowCloseTime: json['window_close_time'] as String,
      eta: json['eta'] as String?,
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
    );

Map<String, dynamic> _$$StopDetailImplToJson(
  _$StopDetailImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'trip_id': instance.tripId,
  'order_id': instance.orderId,
  'seq': instance.seq,
  'outlet_id': instance.outletId,
  'outlet_name': instance.outletName,
  'district': instance.district,
  'dock_type': _$DockTypeEnumMap[instance.dockType]!,
  'parking_constraint': _$ParkingConstraintEnumMap[instance.parkingConstraint]!,
  'order_units': instance.orderUnits,
  'order_weight_kg': instance.orderWeightKg,
  'order_volume_m3': instance.orderVolumeM3,
  'window_open_time': instance.windowOpenTime,
  'window_close_time': instance.windowCloseTime,
  'eta': instance.eta,
  'service_min': instance.serviceMin,
  'status': _$StopStatusEnumMap[instance.status]!,
  'receipt_status': _$ReceiptStatusEnumMap[instance.receiptStatus]!,
  'arrived_at': instance.arrivedAt,
  'completed_at': instance.completedAt,
  'outcome': _$StopOutcomeEnumMap[instance.outcome],
  'quantity_delivered': instance.quantityDelivered,
  'received_by': instance.receivedBy,
  'outcome_note': instance.outcomeNote,
};

const _$DockTypeEnumMap = {
  DockType.rearDock: 'rear_dock',
  DockType.street: 'street',
  DockType.mallBay: 'mall_bay',
};

const _$ParkingConstraintEnumMap = {
  ParkingConstraint.normal: 'normal',
  ParkingConstraint.vanOnly: 'van_only',
  ParkingConstraint.mallDock: 'mall_dock',
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
