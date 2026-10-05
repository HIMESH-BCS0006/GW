import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'sync_models.freezed.dart';
part 'sync_models.g.dart';

@freezed
class SyncOperationItem with _$SyncOperationItem {
  const factory SyncOperationItem({
    @JsonKey(name: 'client_op_id') required String clientOpId,
    @JsonKey(name: 'device_id') required String deviceId,
    @JsonKey(name: 'client_seq') required int clientSeq,
    @JsonKey(name: 'op_type') required String opType,
    required Map<String, dynamic> payload,
    @JsonKey(name: 'client_ts') required String clientTs,
  }) = _SyncOperationItem;

  factory SyncOperationItem.fromJson(Map<String, dynamic> json) =>
      _$SyncOperationItemFromJson(json);
}

@freezed
class SyncBatchRequest with _$SyncBatchRequest {
  const factory SyncBatchRequest({
    required List<SyncOperationItem> operations,
  }) = _SyncBatchRequest;

  factory SyncBatchRequest.fromJson(Map<String, dynamic> json) =>
      _$SyncBatchRequestFromJson(json);
}

@freezed
class SyncOperationResultItem with _$SyncOperationResultItem {
  const factory SyncOperationResultItem({
    @JsonKey(name: 'client_op_id') required String clientOpId,
    required SyncOpResult result,
    String? reason,
  }) = _SyncOperationResultItem;

  factory SyncOperationResultItem.fromJson(Map<String, dynamic> json) =>
      _$SyncOperationResultItemFromJson(json);
}

@freezed
class SyncBatchResponse with _$SyncBatchResponse {
  const factory SyncBatchResponse({
    required List<SyncOperationResultItem> results,
  }) = _SyncBatchResponse;

  factory SyncBatchResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncBatchResponseFromJson(json);
}
