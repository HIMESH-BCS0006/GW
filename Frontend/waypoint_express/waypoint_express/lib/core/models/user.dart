import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String username,
    required Role role,
    @JsonKey(name: 'depot_ids') @Default([]) List<String> depotIds,
    @JsonKey(name: 'outlet_id') String? outletId,
    @JsonKey(name: 'vehicle_id') String? vehicleId,
    @JsonKey(name: 'display_name') required String displayName,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
