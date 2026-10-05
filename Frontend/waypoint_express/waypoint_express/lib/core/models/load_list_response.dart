import 'package:freezed_annotation/freezed_annotation.dart';
import 'trip_card.dart';
import 'stop_detail.dart';

part 'load_list_response.freezed.dart';
part 'load_list_response.g.dart';

@freezed
class LoadListResponse with _$LoadListResponse {
  const factory LoadListResponse({
    @JsonKey(name: 'plan_version') required int planVersion,
    required TripCard trip,
    @JsonKey(name: 'delivery_sequence') required List<StopDetail> deliverySequence,
    @JsonKey(name: 'reverse_load_order') required List<StopDetail> reverseLoadOrder,
  }) = _LoadListResponse;

  factory LoadListResponse.fromJson(Map<String, dynamic> json) =>
      _$LoadListResponseFromJson(json);
}
