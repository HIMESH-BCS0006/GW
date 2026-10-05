import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'trip_stop.freezed.dart';
part 'trip_stop.g.dart';

@freezed
class TripStop with _$TripStop {
  const factory TripStop({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'order_id') required String orderId,
    required int seq,
    String? eta,
    @JsonKey(name: 'service_start_est') String? serviceStartEst,
    @JsonKey(name: 'service_min') required int serviceMin,
    required StopStatus status,
    @JsonKey(name: 'receipt_status') required ReceiptStatus receiptStatus,
    @JsonKey(name: 'arrived_at') String? arrivedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    StopOutcome? outcome,
    @JsonKey(name: 'quantity_delivered') int? quantityDelivered,
    @JsonKey(name: 'received_by') String? receivedBy,
    @JsonKey(name: 'outcome_note') String? outcomeNote,
    @JsonKey(name: 'device_ts') String? deviceTs,
  }) = _TripStop;

  factory TripStop.fromJson(Map<String, dynamic> json) => _$TripStopFromJson(json);
}
