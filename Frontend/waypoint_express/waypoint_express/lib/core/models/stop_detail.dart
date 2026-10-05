import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'stop_detail.freezed.dart';
part 'stop_detail.g.dart';

@freezed
class StopDetail with _$StopDetail {
  const factory StopDetail({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'order_id') required String orderId,
    required int seq,
    @JsonKey(name: 'outlet_id') required String outletId,
    @JsonKey(name: 'outlet_name') required String outletName,
    required String district,
    @JsonKey(name: 'dock_type') required DockType dockType,
    @JsonKey(name: 'parking_constraint') required ParkingConstraint parkingConstraint,
    @JsonKey(name: 'order_units') required int orderUnits,
    @JsonKey(name: 'order_weight_kg') required double orderWeightKg,
    @JsonKey(name: 'order_volume_m3') required double orderVolumeM3,
    @JsonKey(name: 'window_open_time') required String windowOpenTime,
    @JsonKey(name: 'window_close_time') required String windowCloseTime,
    String? eta,
    @JsonKey(name: 'service_min') required int serviceMin,
    required StopStatus status,
    @JsonKey(name: 'receipt_status') required ReceiptStatus receiptStatus,
    @JsonKey(name: 'arrived_at') String? arrivedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    StopOutcome? outcome,
    @JsonKey(name: 'quantity_delivered') int? quantityDelivered,
    @JsonKey(name: 'received_by') String? receivedBy,
    @JsonKey(name: 'outcome_note') String? outcomeNote,
  }) = _StopDetail;

  factory StopDetail.fromJson(Map<String, dynamic> json) => _$StopDetailFromJson(json);
}
