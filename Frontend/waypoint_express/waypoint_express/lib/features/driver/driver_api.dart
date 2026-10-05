import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/token_storage.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';

final driverApiProvider = Provider<DriverApi>((ref) {
  return DriverApi(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// API service for Driver field execution operations.
class DriverApi {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  DriverApi(this._apiClient, this._tokenStorage);

  /// Watches receipt events and reconnects when the event stream disconnects.
  Stream<Map<String, dynamic>> watchReceiptEvents() async* {
    while (true) {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw StateError('A signed-in driver is required to watch receipts.');
      }

      final streamDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.activeBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: Duration.zero,
        ),
      );

      try {
        final response = await streamDio.get<ResponseBody>(
          '/events/stream',
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'Accept': 'text/event-stream',
              'Authorization': 'Bearer $token',
            },
          ),
        );
        final body = response.data;
        if (body == null) {
          throw const FormatException('Receipt event stream has no response.');
        }

        await for (final event in _decodeServerSentEvents(body.stream)) {
          yield event;
        }
        await Future<void>.delayed(const Duration(seconds: 15));
      } on DioException {
        await Future<void>.delayed(const Duration(seconds: 15));
      } finally {
        streamDio.close(force: true);
      }
    }
  }

  Stream<Map<String, dynamic>> _decodeServerSentEvents(
    Stream<List<int>> bytes,
  ) async* {
    final dataLines = <String>[];
    await for (final line
        in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.isEmpty) {
        if (dataLines.isNotEmpty) {
          final decoded = jsonDecode(dataLines.join('\n'));
          if (decoded is! Map) {
            throw const FormatException('Invalid receipt event payload.');
          }
          yield Map<String, dynamic>.from(decoded);
          dataLines.clear();
        }
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    if (dataLines.isNotEmpty) {
      final decoded = jsonDecode(dataLines.join('\n'));
      if (decoded is! Map) {
        throw const FormatException('Invalid receipt event payload.');
      }
      yield Map<String, dynamic>.from(decoded);
    }
  }

  /// Fetches trips assigned to the logged-in driver's vehicle.
  Future<List<TripCard>> getDriverTrips() async {
    final response = await _apiClient.get('/driver/trips');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Invalid driver trips response.');
    }
    return data
        .map(
          (item) => TripCard.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  /// Starts the delivery route (transitions trip from LOADED to IN_PROGRESS).
  Future<Trip> startTrip({
    required String tripId,
    required int planVersion,
  }) async {
    final response = await _apiClient.post(
      '/trips/$tripId/start',
      data: {
        'plan_version': planVersion,
      },
    );
    return Trip.fromJson(_asJsonMap(response.data));
  }

  /// Records arrival at an outlet stop.
  Future<TripStop> arriveStop(String stopId) async {
    final response = await _apiClient.post('/stops/$stopId/arrive');
    return TripStop.fromJson(_asJsonMap(response.data));
  }

  /// Records delivery outcome (delivered, partial, refused, closed) per Decision D20.
  Future<TripStop> recordStopOutcome({
    required String stopId,
    required String outcome,
    int? quantityDelivered,
    String? receivedBy,
    String? outcomeNote,
    String? completedAt,
  }) async {
    final response = await _apiClient.post(
      '/stops/$stopId/outcome',
      data: {
        'outcome': outcome,
        if (quantityDelivered != null) 'quantity_delivered': quantityDelivered,
        if (receivedBy != null && receivedBy.isNotEmpty)
          'received_by': receivedBy,
        if (outcomeNote != null && outcomeNote.isNotEmpty)
          'outcome_note': outcomeNote,
        if (completedAt != null && completedAt.isNotEmpty)
          'completed_at': completedAt,
      },
    );
    return TripStop.fromJson(_asJsonMap(response.data));
  }

  /// Reports a sudden road block, access issue, or vehicle breakdown.
  Future<ExceptionItem> reportStopException({
    required String stopId,
    required String type,
    String? note,
    String? clientTs,
  }) async {
    final response = await _apiClient.post(
      '/stops/$stopId/exception',
      data: {
        'type': type,
        if (note != null && note.isNotEmpty) 'note': note,
        if (clientTs != null && clientTs.isNotEmpty) 'client_ts': clientTs,
      },
    );
    return ExceptionItem.fromJson(_asJsonMap(response.data));
  }

  /// Marks a trip as completed upon return to depot.
  Future<Trip> completeTrip(String tripId) async {
    final response = await _apiClient.post('/trips/$tripId/complete');
    return Trip.fromJson(_asJsonMap(response.data));
  }

  /// Submits an offline batch of recorded operations for monotonic replay.
  Future<SyncBatchResponse> syncOfflineBatch(SyncBatchRequest batch) async {
    final response = await _apiClient.post(
      '/sync',
      data: batch.toJson(),
    );
    return SyncBatchResponse.fromJson(_asJsonMap(response.data));
  }

  static Map<String, dynamic> _asJsonMap(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Invalid response data from server.');
    }
    return Map<String, dynamic>.from(value);
  }
}
