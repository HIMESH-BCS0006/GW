import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
class Trip with _$Trip {
  const factory Trip({
    required String id,
    @JsonKey(name: 'plan_run_id') required String planRunId,
    @JsonKey(name: 'vehicle_id') required String vehicleId,
    @JsonKey(name: 'depot_id') required String depotId,
    @JsonKey(name: 'delivery_date') required String deliveryDate,
    @JsonKey(name: 'trip_no') required int tripNo,
    required Brand brand,
    required String district,
    required TripStatus status,
    @JsonKey(name: 'plan_version') required int planVersion,
    @JsonKey(name: 'depart_time') String? departTime,
    @JsonKey(name: 'est_minutes') required int estMinutes,
    @JsonKey(name: 'est_km') required double estKm,
    @JsonKey(name: 'est_fuel_l') required double estFuelL,
    @JsonKey(name: 'confirmed_by') String? confirmedBy,
    @JsonKey(name: 'confirmed_at') String? confirmedAt,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}
