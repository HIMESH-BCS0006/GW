import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'api_requests.freezed.dart';
part 'api_requests.g.dart';

@freezed
class CreateLoadCheckRequest with _$CreateLoadCheckRequest {
  const factory CreateLoadCheckRequest({
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'plan_version') required int planVersion,
    @JsonKey(name: 'expected_qty') required int expectedQty,
    @JsonKey(name: 'loaded_qty') required int loadedQty,
    required LoadCheckIssue issue,
    String? note,
    @JsonKey(name: 'client_op_id') String? clientOpId,
  }) = _CreateLoadCheckRequest;

  factory CreateLoadCheckRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateLoadCheckRequestFromJson(json);
}

@freezed
class ConfirmLoadRequest with _$ConfirmLoadRequest {
  const factory ConfirmLoadRequest({
    @JsonKey(name: 'plan_version') required int planVersion,
  }) = _ConfirmLoadRequest;

  factory ConfirmLoadRequest.fromJson(Map<String, dynamic> json) =>
      _$ConfirmLoadRequestFromJson(json);
}

@freezed
class StartTripRequest with _$StartTripRequest {
  const factory StartTripRequest({
    @JsonKey(name: 'plan_version') required int planVersion,
    @JsonKey(name: 'client_op_id') String? clientOpId,
  }) = _StartTripRequest;

  factory StartTripRequest.fromJson(Map<String, dynamic> json) =>
      _$StartTripRequestFromJson(json);
}

@freezed
class RecordStopOutcomeRequest with _$RecordStopOutcomeRequest {
  const factory RecordStopOutcomeRequest({
    required StopOutcome outcome,
    @JsonKey(name: 'quantity_delivered') int? quantityDelivered,
    @JsonKey(name: 'received_by') String? receivedBy,
    @JsonKey(name: 'outcome_note') String? outcomeNote,
    @JsonKey(name: 'completed_at') required String completedAt,
    @JsonKey(name: 'client_op_id') String? clientOpId,
  }) = _RecordStopOutcomeRequest;

  factory RecordStopOutcomeRequest.fromJson(Map<String, dynamic> json) =>
      _$RecordStopOutcomeRequestFromJson(json);
}

@freezed
class RecordStopExceptionRequest with _$RecordStopExceptionRequest {
  const factory RecordStopExceptionRequest({
    required ExceptionType type,
    String? note,
    @JsonKey(name: 'client_op_id') String? clientOpId,
    @JsonKey(name: 'client_seq') int? clientSeq,
    @JsonKey(name: 'client_ts') String? clientTs,
    @JsonKey(name: 'plan_version') int? planVersion,
  }) = _RecordStopExceptionRequest;

  factory RecordStopExceptionRequest.fromJson(Map<String, dynamic> json) =>
      _$RecordStopExceptionRequestFromJson(json);
}
