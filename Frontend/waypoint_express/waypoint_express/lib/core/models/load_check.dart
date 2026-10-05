import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'load_check.freezed.dart';
part 'load_check.g.dart';

@freezed
class LoadCheck with _$LoadCheck {
  const factory LoadCheck({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'plan_version') required int planVersion,
    @JsonKey(name: 'expected_qty') required int expectedQty,
    @JsonKey(name: 'loaded_qty') required int loadedQty,
    required LoadCheckIssue issue,
    String? note,
    required LoadCheckStatus status,
    LoadCheckResolution? resolution,
    @JsonKey(name: 'reported_by') required String reportedBy,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
  }) = _LoadCheck;

  factory LoadCheck.fromJson(Map<String, dynamic> json) => _$LoadCheckFromJson(json);
}
