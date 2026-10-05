import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'trip_card.freezed.dart';
part 'trip_card.g.dart';

@freezed
class TripCard with _$TripCard {
  const factory TripCard({
    required String id,
    @JsonKey(name: 'plan_run_id') required String planRunId,
    @JsonKey(name: 'delivery_date') required String deliveryDate,
    @JsonKey(name: 'trip_no') required int tripNo,
    required Brand brand,
    required String district,
    @JsonKey(name: 'depot_id') required String depotId,
    @JsonKey(name: 'vehicle_id') required String vehicleId,
    @JsonKey(name: 'vehicle_type') required VehicleType vehicleType,
    @JsonKey(name: 'vehicle_temp') required TemperatureRequirement vehicleTemp,
    @JsonKey(name: 'stop_count') required int stopCount,
    @JsonKey(name: 'depart_time') String? departTime,
    @JsonKey(name: 'plan_version') required int planVersion,
    required TripStatus status,
    @JsonKey(name: 'weight_used_kg') required double weightUsedKg,
    @JsonKey(name: 'weight_cap_kg') required double weightCapKg,
    @JsonKey(name: 'volume_used_m3') required double volumeUsedM3,
    @JsonKey(name: 'volume_cap_m3') required double volumeCapM3,
  }) = _TripCard;

  factory TripCard.fromJson(Map<String, dynamic> json) => _$TripCardFromJson(json);
}
