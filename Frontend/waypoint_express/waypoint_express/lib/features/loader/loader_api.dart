import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/models.dart';

final loaderApiProvider = Provider<LoaderApi>((ref) {
  return LoaderApi(ref.watch(apiClientProvider));
});

/// API calls used by the warehouse loader dashboard.
///
/// The loader flow is:
/// 1. GET /loading/trips?depot_id=&lt;active depot&gt;
/// 2. GET /trips/&lt;trip id&gt;/load-list for each current trip
///
/// The second endpoint supplies the actual order/stop information that is
/// displayed on the loader dashboard.
class LoaderApi {
  final ApiClient _apiClient;

  LoaderApi(this._apiClient);

  Future<List<TripCard>> getLoadingTrips({String? depotId}) async {
    final response = await _apiClient.get(
      '/loading/trips',
      queryParameters: {
        if (depotId != null && depotId.isNotEmpty) 'depot_id': depotId,
      },
    );

    final data = response.data;
    if (data is! List) {
      throw const FormatException('Invalid loading trips response.');
    }

    return data
        .map(
          (item) => TripCard.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<LoadListResponse> getTripLoadList(String tripId) async {
    final response = await _apiClient.get('/trips/$tripId/load-list');
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid trip load list response.');
    }
    return LoadListResponse.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Trip> startTripLoading(String tripId) async {
    final response = await _apiClient.post('/trips/$tripId/load-start');
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid start load response.');
    }
    return Trip.fromJson(Map<String, dynamic>.from(data));
  }

  Future<LoadCheck> reportLoadCheck({
    required String tripId,
    required String orderId,
    required int planVersion,
    required int expectedQty,
    required int loadedQty,
    required String issue,
    String? note,
  }) async {
    final response = await _apiClient.post(
      '/trips/$tripId/load-checks',
      data: {
        'order_id': orderId,
        'plan_version': planVersion,
        'expected_qty': expectedQty,
        'loaded_qty': loadedQty,
        'issue': issue,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid load-check response.');
    }
    return LoadCheck.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Trip> confirmTripLoad({
    required String tripId,
    required int planVersion,
  }) async {
    final response = await _apiClient.post(
      '/trips/$tripId/load-confirm',
      data: {
        'plan_version': planVersion,
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid load confirmation response.');
    }
    return Trip.fromJson(Map<String, dynamic>.from(data));
  }
}
