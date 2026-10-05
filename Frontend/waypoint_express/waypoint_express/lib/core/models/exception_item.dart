import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'exception_item.freezed.dart';
part 'exception_item.g.dart';

@freezed
class ExceptionItem with _$ExceptionItem {
  const factory ExceptionItem({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'stop_id') required String stopId,
    required ExceptionType type,
    String? note,
    @JsonKey(name: 'reported_at') required String reportedAt,
    required ExceptionStatus status,
    ExceptionDecision? decision,
    @JsonKey(name: 'decision_note') String? decisionNote,
    @JsonKey(name: 'decided_by') String? decidedBy,
    @JsonKey(name: 'decided_at') String? decidedAt,
  }) = _ExceptionItem;

  factory ExceptionItem.fromJson(Map<String, dynamic> json) =>
      _$ExceptionItemFromJson(json);
}
