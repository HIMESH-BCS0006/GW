import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/enums.dart';
import '../../core/models/stop_detail.dart';
import '../../core/models/trip_card.dart';
import '../../core/models/trip_stop.dart';

final orderHandoffApiProvider = Provider<OrderHandoffApi>((ref) {
  return OrderHandoffApi(ref.watch(apiClientProvider));
});

class OrderHandoffApi {
  static const _tripHandoffStoragePrefix = 'waypoint_driver_trip_handoffs_';
  static const _secureStorage = FlutterSecureStorage();
  static final Map<String, List<TripHandoff>> _cachedTripHandoffs = {};
  static final Set<String> _loadedTripHandoffDrivers = {};

  final ApiClient _apiClient;

  OrderHandoffApi(this._apiClient);

  static final List<OrderHandoff> _inMemoryHandoffs = [];
  static final List<DriverTrackedStop> _tripQrStops = [];

  Future<OrderHandoff> acceptOrder({
    required StopDetail order,
    required String loaderId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/loading/orders/${Uri.encodeComponent(order.orderId)}/accept',
        data: {'order': order.toJson(), 'loader_id': loaderId},
      );
      final handoff = OrderHandoff.fromJson(_asJsonMap(response.data));
      _inMemoryHandoffs.removeWhere((h) => h.order.orderId == order.orderId);
      _inMemoryHandoffs.add(handoff);
      return handoff;
    } catch (_) {
      // Direct client-side optical encoding fallback
      final now = DateTime.now();
      final qrToken = 'QR-${order.orderId}-${now.millisecondsSinceEpoch}';
      final payloadMap = {
        'order': order.toJson(),
        'loader_id': loaderId,
        'accepted_at': now.toIso8601String(),
        'qr_token': qrToken,
        'qr_payload': qrToken,
      };
      final handoff = OrderHandoff.fromJson(payloadMap);
      _inMemoryHandoffs.removeWhere((h) => h.order.orderId == order.orderId);
      _inMemoryHandoffs.add(handoff);
      return handoff;
    }
  }

  Future<OrderHandoff> getOrderByQr({
    required String qrPayload,
    required String driverId,
    String? vehicleId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/driver/orders/scan',
        data: {
          'qr_payload': qrPayload,
          'driver_id': driverId,
          'vehicle_id': vehicleId,
        },
      );
      final handoff = OrderHandoff.fromJson(_asJsonMap(response.data));
      _rememberHandoff(handoff);
      return handoff;
    } catch (_) {
      // Find matching handoff in memory or parse QR payload
      final match = _inMemoryHandoffs.cast<OrderHandoff?>().firstWhere(
        (h) =>
            h?.qrPayload == qrPayload ||
            h?.qrToken == qrPayload ||
            h?.order.orderId == qrPayload,
        orElse: () => null,
      );
      if (match != null) {
        final handoff = OrderHandoff(
          order: match.order,
          loaderId: match.loaderId,
          acceptedAt: match.acceptedAt,
          qrToken: match.qrToken,
          qrPayload: match.qrPayload,
          scannedAt: DateTime.now(),
          driverId: driverId,
          vehicleId: vehicleId,
        );
        _rememberHandoff(handoff);
        return handoff;
      }
      throw FormatException(
        'Scanned QR code ($qrPayload) does not match any staged orders.',
      );
    }
  }

  Future<List<OrderHandoff>> getDriverOrders() async {
    try {
      final response = await _apiClient.get('/driver/orders');
      final data = response.data;
      if (data is List) {
        return data
            .map((item) => OrderHandoff.fromJson(_asJsonMap(item)))
            .toList(growable: false);
      }
    } catch (_) {}
    return List<OrderHandoff>.unmodifiable(_inMemoryHandoffs);
  }

  Future<List<DriverTrackedStop>> getDriverTrackingStops({
    required String driverId,
  }) async {
    final handoffs = await getDriverOrders();
    final tripHandoffs = await getCachedTripHandoffs(driverId: driverId);
    final stopsByOrder = <String, DriverTrackedStop>{};
    for (final handoff in handoffs) {
      final stop = DriverTrackedStop.fromHandoff(handoff);
      stopsByOrder[_trackingKey(stop.tripId, stop.orderId)] = stop;
    }
    for (final handoff in _inMemoryHandoffs) {
      final stop = DriverTrackedStop.fromHandoff(handoff);
      final key = _trackingKey(stop.tripId, stop.orderId);
      final current = stopsByOrder[key];
      if (current == null || _trackingRank(stop) > _trackingRank(current)) {
        stopsByOrder[key] = stop;
      }
    }
    for (final handoff in tripHandoffs) {
      for (final order in handoff.orders) {
        final stop = DriverTrackedStop.fromTripHandoff(
          tripId: handoff.tripId,
          order: order,
        );
        final key = _trackingKey(stop.tripId, stop.orderId);
        final current = stopsByOrder[key];
        if (current == null || _trackingRank(stop) > _trackingRank(current)) {
          stopsByOrder[key] = stop;
        }
      }
    }
    for (final stop in _tripQrStops) {
      final key = _trackingKey(stop.tripId, stop.orderId);
      final current = stopsByOrder[key];
      if (current == null || _trackingRank(stop) > _trackingRank(current)) {
        stopsByOrder[key] = stop;
      }
    }
    return stopsByOrder.values.toList(growable: false);
  }

  Future<List<TripHandoff>> getCachedTripHandoffs({
    required String driverId,
  }) async {
    await _loadCachedTripHandoffs(driverId);
    return List<TripHandoff>.unmodifiable(
      _cachedTripHandoffs[driverId] ?? const [],
    );
  }

  Future<void> cacheTripHandoffForTracking({
    required TripHandoff handoff,
    required String driverId,
  }) async {
    await _loadCachedTripHandoffs(driverId);
    final handoffs = _cachedTripHandoffs.putIfAbsent(driverId, () => []);
    final existingTripIndex = handoffs.indexWhere(
      (existing) => existing.tripId == handoff.tripId,
    );
    var handoffToCache = handoff;
    if (existingTripIndex == -1) {
      handoffs.add(handoff);
    } else {
      final previousOrders = {
        for (final order in handoffs[existingTripIndex].orders)
          order.orderId: order,
      };
      handoffToCache = handoff.copyWithOrders(
        handoff.orders
            .map((order) {
              final previous = previousOrders[order.orderId];
              if (order.receiptStatus == ReceiptStatus.none &&
                  previous != null &&
                  previous.receiptStatus != ReceiptStatus.none) {
                return order.copyWithReceiptStatus(previous.receiptStatus);
              }
              return order;
            })
            .toList(growable: false),
      );
      handoffs[existingTripIndex] = handoffToCache;
    }
    await _persistCachedTripHandoffs(driverId);

    for (final order in handoffToCache.orders) {
      final stop = DriverTrackedStop.fromTripHandoff(
        tripId: handoff.tripId,
        order: order,
      );
      final key = _trackingKey(stop.tripId, stop.orderId);
      final existingIndex = _tripQrStops.indexWhere(
        (existing) => _trackingKey(existing.tripId, existing.orderId) == key,
      );
      if (existingIndex == -1) {
        _tripQrStops.add(stop);
      } else if (_statusRank(stop.status) >
          _statusRank(_tripQrStops[existingIndex].status)) {
        _tripQrStops[existingIndex] = stop;
      }
    }
  }

  Future<void> _loadCachedTripHandoffs(String driverId) async {
    if (_loadedTripHandoffDrivers.contains(driverId)) return;

    final storageKey =
        '$_tripHandoffStoragePrefix${Uri.encodeComponent(driverId)}';
    final storedValue = await _secureStorage.read(key: storageKey);
    if (storedValue == null || storedValue.isEmpty) {
      _cachedTripHandoffs[driverId] = [];
      _loadedTripHandoffDrivers.add(driverId);
      return;
    }

    final decoded = jsonDecode(storedValue);
    if (decoded is! List || decoded.any((item) => item is! String)) {
      throw const FormatException('Saved driver trip data is invalid.');
    }
    final handoffs = decoded
        .cast<String>()
        .map(TripHandoff.fromQrPayload)
        .toList(growable: true);
    _cachedTripHandoffs[driverId] = handoffs;
    _loadedTripHandoffDrivers.add(driverId);
  }

  Future<void> _persistCachedTripHandoffs(String driverId) async {
    final storageKey =
        '$_tripHandoffStoragePrefix${Uri.encodeComponent(driverId)}';
    final payload = jsonEncode(
      (_cachedTripHandoffs[driverId] ?? const [])
          .map((handoff) => handoff.toQrPayload())
          .toList(growable: false),
    );
    await _secureStorage.write(key: storageKey, value: payload);
  }

  Future<Set<String>> applyReceiptEvent({
    required String driverId,
    required Map<String, dynamic> event,
  }) async {
    final eventType = event['type'];
    if (eventType != 'receipt.confirmed' &&
        eventType != 'receipt.discrepancy') {
      return const {};
    }

    final entity = event['entity'];
    final data = event['data'];
    final payload = event['payload'];
    final receipt = data is Map ? data['receipt'] : null;
    final identifiers = <String>{
      if (entity is Map && entity['id'] is String) entity['id'] as String,
      if (event['stop_id'] is String) event['stop_id'] as String,
      if (event['order_id'] is String) event['order_id'] as String,
      if (payload is Map && payload['stop_id'] is String) payload['stop_id'] as String,
      if (payload is Map && payload['order_id'] is String) payload['order_id'] as String,
      if (data is Map && data['stop_id'] is String) data['stop_id'] as String,
      if (data is Map && data['order_id'] is String) data['order_id'] as String,
      if (receipt is Map && receipt['stop_id'] is String)
        receipt['stop_id'] as String,
    };
    if (identifiers.isEmpty) return const {};

    await _loadCachedTripHandoffs(driverId);
    final receiptStatus = eventType == 'receipt.confirmed'
        ? ReceiptStatus.confirmed
        : ReceiptStatus.discrepancy;
    final completedOrderIds = <String>{};
    var handoffsChanged = false;
    final handoffs = _cachedTripHandoffs[driverId] ?? [];

    for (var tripIndex = 0; tripIndex < handoffs.length; tripIndex++) {
      final handoff = handoffs[tripIndex];
      var tripChanged = false;
      final orders = handoff.orders
          .map((order) {
            if (!identifiers.contains(order.stopId) &&
                !identifiers.contains(order.orderId)) {
              return order;
            }
            if (order.receiptStatus != receiptStatus) {
              handoffsChanged = true;
              tripChanged = true;
            }
            completedOrderIds.add(order.orderId);
            return order.copyWithReceiptStatus(receiptStatus);
          })
          .toList(growable: false);

      if (tripChanged) {
        handoffs[tripIndex] = handoff.copyWithOrders(orders);
      }
    }

    for (var index = 0; index < _tripQrStops.length; index++) {
      final stop = _tripQrStops[index];
      if (identifiers.contains(stop.stopId) ||
          identifiers.contains(stop.orderId)) {
        _tripQrStops[index] = stop.copyWithReceiptStatus(receiptStatus);
        completedOrderIds.add(stop.orderId);
      }
    }

    if (handoffsChanged) {
      await _persistCachedTripHandoffs(driverId);
    }
    return completedOrderIds;
  }

  Future<TripHandoff?> syncTripHandoffFromServer({
    required String tripId,
    required String driverId,
  }) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/load-list');
      final data = response.data;
      if (data is Map && data['delivery_sequence'] is List) {
        final stops = (data['delivery_sequence'] as List)
            .map((s) => _asJsonMap(s))
            .toList(growable: false);
        await _loadCachedTripHandoffs(driverId);
        final handoffs = _cachedTripHandoffs[driverId] ?? [];
        final tripIndex = handoffs.indexWhere((h) => h.tripId == tripId);
        if (tripIndex != -1) {
          final handoff = handoffs[tripIndex];
          var changed = false;
          final updatedOrders = handoff.orders.map((order) {
            final match = stops.firstWhere(
              (s) => s['order_id'] == order.orderId || s['id'] == order.stopId,
              orElse: () => const {},
            );
            if (match.isNotEmpty) {
              final rawReceiptStatus = match['receipt_status'] as String?;
              final rawStatus = match['status'] as String?;
              ReceiptStatus newReceiptStatus = order.receiptStatus;
              if (rawReceiptStatus == 'CONFIRMED' || rawStatus == 'DELIVERED') {
                newReceiptStatus = ReceiptStatus.confirmed;
              } else if (rawReceiptStatus == 'DISCREPANCY' || rawStatus == 'PARTIAL') {
                newReceiptStatus = ReceiptStatus.discrepancy;
              }
              if (newReceiptStatus != order.receiptStatus) {
                changed = true;
                return order.copyWithReceiptStatus(newReceiptStatus);
              }
            }
            return order;
          }).toList(growable: false);

          if (changed) {
            final updatedHandoff = handoff.copyWithOrders(updatedOrders);
            handoffs[tripIndex] = updatedHandoff;
            await _persistCachedTripHandoffs(driverId);
            for (final order in updatedOrders) {
              final stop = DriverTrackedStop.fromTripHandoff(
                tripId: tripId,
                order: order,
              );
              final key = _trackingKey(stop.tripId, stop.orderId);
              final existingIndex = _tripQrStops.indexWhere(
                (existing) =>
                    _trackingKey(existing.tripId, existing.orderId) == key,
              );
              if (existingIndex == -1) {
                _tripQrStops.add(stop);
              } else {
                _tripQrStops[existingIndex] = stop;
              }
            }
            return updatedHandoff;
          }
          return handoff;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> syncAllTripsFromServer({required String driverId}) async {
    await _loadCachedTripHandoffs(driverId);
    final handoffs = _cachedTripHandoffs[driverId] ?? [];
    for (final handoff in handoffs) {
      await syncTripHandoffFromServer(
        tripId: handoff.tripId,
        driverId: driverId,
      );
    }
  }

  void updateTrackedStop(TripStop update) {
    for (var index = 0; index < _tripQrStops.length; index++) {
      if (_tripQrStops[index].stopId == update.id) {
        _tripQrStops[index] = _tripQrStops[index].copyWithUpdate(update);
      }
    }
    for (var index = 0; index < _inMemoryHandoffs.length; index++) {
      final handoff = _inMemoryHandoffs[index];
      if (handoff.order.id != update.id) continue;
      _inMemoryHandoffs[index] = OrderHandoff(
        order: handoff.order.copyWith(
          status: update.status,
          receiptStatus: update.receiptStatus,
          arrivedAt: update.arrivedAt,
          completedAt: update.completedAt,
          outcome: update.outcome,
          quantityDelivered: update.quantityDelivered,
          receivedBy: update.receivedBy,
          outcomeNote: update.outcomeNote,
        ),
        loaderId: handoff.loaderId,
        acceptedAt: handoff.acceptedAt,
        qrToken: handoff.qrToken,
        qrPayload: handoff.qrPayload,
        scannedAt: handoff.scannedAt,
        driverId: handoff.driverId,
        vehicleId: handoff.vehicleId,
      );
    }
  }

  static void _rememberHandoff(OrderHandoff handoff) {
    _inMemoryHandoffs
      ..removeWhere((existing) => existing.order.id == handoff.order.id)
      ..add(handoff);
  }

  static String _trackingKey(String tripId, String orderId) =>
      '$tripId::$orderId';

  static int _statusRank(StopStatus status) {
    switch (status) {
      case StopStatus.pending:
        return 0;
      case StopStatus.arrived:
        return 1;
      case StopStatus.delivered:
      case StopStatus.partial:
      case StopStatus.failed:
      case StopStatus.exception:
      case StopStatus.skipped:
        return 2;
    }
  }

  static int _trackingRank(DriverTrackedStop stop) {
    final receiptRank = switch (stop.receiptStatus) {
      ReceiptStatus.none => 0,
      ReceiptStatus.awaiting => 10,
      ReceiptStatus.confirmed || ReceiptStatus.discrepancy => 20,
    };
    return receiptRank + _statusRank(stop.status);
  }

  static Map<String, dynamic> _asJsonMap(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Invalid order handoff response.');
    }
    return Map<String, dynamic>.from(value);
  }
}

class OrderHandoff {
  final StopDetail order;
  final String loaderId;
  final DateTime acceptedAt;
  final String qrToken;
  final String qrPayload;
  final DateTime? scannedAt;
  final String? driverId;
  final String? vehicleId;

  const OrderHandoff({
    required this.order,
    required this.loaderId,
    required this.acceptedAt,
    required this.qrToken,
    required this.qrPayload,
    this.scannedAt,
    this.driverId,
    this.vehicleId,
  });

  factory OrderHandoff.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    if (order is! Map) {
      throw const FormatException('Order handoff is missing order details.');
    }
    final acceptedAt = json['accepted_at'];
    final qrToken = json['qr_token'];
    final qrPayload = json['qr_payload'];
    final loaderId = json['loader_id'];
    if (acceptedAt is! String ||
        qrToken is! String ||
        qrPayload is! String ||
        loaderId is! String) {
      throw const FormatException('Invalid order handoff data.');
    }

    return OrderHandoff(
      order: StopDetail.fromJson(Map<String, dynamic>.from(order)),
      loaderId: loaderId,
      acceptedAt: DateTime.parse(acceptedAt),
      qrToken: qrToken,
      qrPayload: qrPayload,
      scannedAt: json['scanned_at'] is String
          ? DateTime.parse(json['scanned_at'] as String)
          : null,
      driverId: json['driver_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
    );
  }

  bool get accepted => true;
  bool get scanned => scannedAt != null;
}

class DriverTrackedStop {
  final String? stopId;
  final String tripId;
  final String orderId;
  final int seq;
  final String outletName;
  final String outletId;
  final String district;
  final int units;
  final String windowOpenTime;
  final String windowCloseTime;
  final String? eta;
  final StopStatus status;
  final ReceiptStatus receiptStatus;
  final StopOutcome? outcome;
  final int? quantityDelivered;
  final String? receivedBy;
  final String? outcomeNote;

  const DriverTrackedStop({
    required this.stopId,
    required this.tripId,
    required this.orderId,
    required this.seq,
    required this.outletName,
    required this.outletId,
    required this.district,
    required this.units,
    required this.windowOpenTime,
    required this.windowCloseTime,
    required this.eta,
    required this.status,
    required this.receiptStatus,
    required this.outcome,
    required this.quantityDelivered,
    required this.receivedBy,
    required this.outcomeNote,
  });

  factory DriverTrackedStop.fromHandoff(OrderHandoff handoff) {
    final order = handoff.order;
    return DriverTrackedStop(
      stopId: order.id,
      tripId: order.tripId,
      orderId: order.orderId,
      seq: order.seq,
      outletName: order.outletName,
      outletId: order.outletId,
      district: order.district,
      units: order.orderUnits,
      windowOpenTime: order.windowOpenTime,
      windowCloseTime: order.windowCloseTime,
      eta: order.eta,
      status: order.status,
      receiptStatus: order.receiptStatus,
      outcome: order.outcome,
      quantityDelivered: order.quantityDelivered,
      receivedBy: order.receivedBy,
      outcomeNote: order.outcomeNote,
    );
  }

  factory DriverTrackedStop.fromTripHandoff({
    required String tripId,
    required TripHandoffOrder order,
  }) {
    return DriverTrackedStop(
      stopId: order.stopId,
      tripId: tripId,
      orderId: order.orderId,
      seq: order.seq,
      outletName: order.outletName,
      outletId: order.outletId,
      district: order.district,
      units: order.units,
      windowOpenTime: order.windowOpenTime,
      windowCloseTime: order.windowCloseTime,
      eta: order.eta,
      status: StopStatus.pending,
      receiptStatus: order.receiptStatus,
      outcome: null,
      quantityDelivered: null,
      receivedBy: null,
      outcomeNote: null,
    );
  }

  DriverTrackedStop copyWithUpdate(TripStop update) {
    return DriverTrackedStop(
      stopId: stopId,
      tripId: tripId,
      orderId: orderId,
      seq: seq,
      outletName: outletName,
      outletId: outletId,
      district: district,
      units: units,
      windowOpenTime: windowOpenTime,
      windowCloseTime: windowCloseTime,
      eta: eta,
      status: update.status,
      receiptStatus: update.receiptStatus,
      outcome: update.outcome,
      quantityDelivered: update.quantityDelivered,
      receivedBy: update.receivedBy,
      outcomeNote: update.outcomeNote,
    );
  }

  DriverTrackedStop copyWithReceiptStatus(ReceiptStatus status) {
    return DriverTrackedStop(
      stopId: stopId,
      tripId: tripId,
      orderId: orderId,
      seq: seq,
      outletName: outletName,
      outletId: outletId,
      district: district,
      units: units,
      windowOpenTime: windowOpenTime,
      windowCloseTime: windowCloseTime,
      eta: eta,
      status: this.status,
      receiptStatus: status,
      outcome: outcome,
      quantityDelivered: quantityDelivered,
      receivedBy: receivedBy,
      outcomeNote: outcomeNote,
    );
  }
}

class TripHandoff {
  static const String qrPrefix = 'WAYPOINT-TRIP:';

  final String tripId;
  final int tripNo;
  final String vehicleId;
  final String depotId;
  final String loaderId;
  final TripStatus? status;
  final List<TripHandoffOrder> orders;

  const TripHandoff({
    required this.tripId,
    required this.tripNo,
    required this.vehicleId,
    required this.depotId,
    required this.loaderId,
    this.status,
    required this.orders,
  });

  factory TripHandoff.fromQrPayload(String payload) {
    if (!payload.startsWith(qrPrefix)) {
      throw const FormatException('This is not a Waypoint trip QR code.');
    }

    final decoded = jsonDecode(payload.substring(qrPrefix.length));
    if (decoded is! Map) {
      throw const FormatException('Invalid trip QR data.');
    }
    final json = Map<String, dynamic>.from(decoded);
    final tripId = json['trip_id'];
    final tripNo = json['trip_no'];
    final vehicleId = json['vehicle_id'];
    final depotId = json['depot_id'];
    final loaderId = json['loader_id'];
    final statusValue = json['status'];
    final ordersJson = json['orders'];

    if (tripId is! String ||
        tripNo is! int ||
        vehicleId is! String ||
        depotId is! String ||
        loaderId is! String ||
        (statusValue != null && statusValue is! String) ||
        ordersJson is! List ||
        ordersJson.isEmpty ||
        ordersJson.any((order) => order is! Map)) {
      throw const FormatException('Incomplete trip QR data.');
    }

    return TripHandoff(
      tripId: tripId,
      tripNo: tripNo,
      vehicleId: vehicleId,
      depotId: depotId,
      loaderId: loaderId,
      status: statusValue == null ? null : _tripStatusFromJson(statusValue),
      orders: ordersJson
          .map(
            (order) => TripHandoffOrder.fromJson(
              Map<String, dynamic>.from(order as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  String toQrPayload() {
    return '$qrPrefix${jsonEncode({'trip_id': tripId, 'trip_no': tripNo, 'vehicle_id': vehicleId, 'depot_id': depotId, 'loader_id': loaderId, if (status != null) 'status': _tripStatusToJson(status!), 'orders': orders.map((order) => order.toJson()).toList()})}';
  }

  factory TripHandoff.fromTrip({
    required TripCard trip,
    required String loaderId,
    required List<StopDetail> orders,
    TripStatus? status,
  }) {
    return TripHandoff(
      tripId: trip.id,
      tripNo: trip.tripNo,
      vehicleId: trip.vehicleId,
      depotId: trip.depotId,
      loaderId: loaderId,
      status: status ?? trip.status,
      orders: orders.map(TripHandoffOrder.fromStop).toList(growable: false),
    );
  }

  TripHandoff copyWithOrders(List<TripHandoffOrder> orders) {
    return TripHandoff(
      tripId: tripId,
      tripNo: tripNo,
      vehicleId: vehicleId,
      depotId: depotId,
      loaderId: loaderId,
      status: status,
      orders: orders,
    );
  }

  static TripStatus _tripStatusFromJson(String value) {
    switch (value) {
      case 'DRAFT':
        return TripStatus.draft;
      case 'CONFIRMED':
        return TripStatus.confirmed;
      case 'LOADING':
        return TripStatus.loading;
      case 'LOADED':
        return TripStatus.loaded;
      case 'IN_PROGRESS':
        return TripStatus.inProgress;
      case 'COMPLETED':
        return TripStatus.completed;
      case 'BLOCKED':
        return TripStatus.blocked;
      case 'CANCELLED':
        return TripStatus.cancelled;
      default:
        throw const FormatException('Invalid trip status in trip QR.');
    }
  }

  static String _tripStatusToJson(TripStatus status) {
    switch (status) {
      case TripStatus.draft:
        return 'DRAFT';
      case TripStatus.confirmed:
        return 'CONFIRMED';
      case TripStatus.loading:
        return 'LOADING';
      case TripStatus.loaded:
        return 'LOADED';
      case TripStatus.inProgress:
        return 'IN_PROGRESS';
      case TripStatus.completed:
        return 'COMPLETED';
      case TripStatus.blocked:
        return 'BLOCKED';
      case TripStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class TripHandoffOrder {
  final String? stopId;
  final ReceiptStatus receiptStatus;
  final String orderId;
  final int seq;
  final String outletName;
  final String outletId;
  final String district;
  final int units;
  final String windowOpenTime;
  final String windowCloseTime;
  final String? eta;

  const TripHandoffOrder({
    this.stopId,
    this.receiptStatus = ReceiptStatus.none,
    required this.orderId,
    required this.seq,
    required this.outletName,
    required this.outletId,
    required this.district,
    required this.units,
    required this.windowOpenTime,
    required this.windowCloseTime,
    this.eta,
  });

  factory TripHandoffOrder.fromStop(StopDetail stop) {
    return TripHandoffOrder(
      stopId: stop.id,
      receiptStatus: stop.receiptStatus,
      orderId: stop.orderId,
      seq: stop.seq,
      outletName: stop.outletName,
      outletId: stop.outletId,
      district: stop.district,
      units: stop.orderUnits,
      windowOpenTime: stop.windowOpenTime,
      windowCloseTime: stop.windowCloseTime,
      eta: stop.eta,
    );
  }

  factory TripHandoffOrder.fromJson(Map<String, dynamic> json) {
    final stopId = json['x'];
    final receiptStatusValue = json['r'];
    final orderId = json['i'];
    final seq = json['s'];
    final outletName = json['n'];
    final outletId = json['l'];
    final district = json['d'];
    final units = json['u'];
    final windowOpenTime = json['wo'];
    final windowCloseTime = json['wc'];

    if ((stopId != null && stopId is! String) ||
        (receiptStatusValue != null && receiptStatusValue is! String) ||
        orderId is! String ||
        seq is! int ||
        outletName is! String ||
        outletId is! String ||
        district is! String ||
        units is! int ||
        windowOpenTime is! String ||
        windowCloseTime is! String ||
        (json['e'] != null && json['e'] is! String)) {
      throw const FormatException('Invalid order details in trip QR.');
    }

    return TripHandoffOrder(
      stopId: stopId as String?,
      receiptStatus: _receiptStatusFromJson(receiptStatusValue),
      orderId: orderId,
      seq: seq,
      outletName: outletName,
      outletId: outletId,
      district: district,
      units: units,
      windowOpenTime: windowOpenTime,
      windowCloseTime: windowCloseTime,
      eta: json['e'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (stopId != null) 'x': stopId,
    if (receiptStatus != ReceiptStatus.none)
      'r': _receiptStatusToJson(receiptStatus),
    'i': orderId,
    's': seq,
    'n': outletName,
    'l': outletId,
    'd': district,
    'u': units,
    'wo': windowOpenTime,
    'wc': windowCloseTime,
    if (eta != null) 'e': eta,
  };

  TripHandoffOrder copyWithReceiptStatus(ReceiptStatus status) {
    return TripHandoffOrder(
      stopId: stopId,
      receiptStatus: status,
      orderId: orderId,
      seq: seq,
      outletName: outletName,
      outletId: outletId,
      district: district,
      units: units,
      windowOpenTime: windowOpenTime,
      windowCloseTime: windowCloseTime,
      eta: eta,
    );
  }

  static ReceiptStatus _receiptStatusFromJson(Object? value) {
    switch (value) {
      case 'AWAITING':
        return ReceiptStatus.awaiting;
      case 'CONFIRMED':
        return ReceiptStatus.confirmed;
      case 'DISCREPANCY':
        return ReceiptStatus.discrepancy;
      case null:
      case 'NONE':
        return ReceiptStatus.none;
      default:
        throw const FormatException('Invalid receipt status in trip QR.');
    }
  }

  static String _receiptStatusToJson(ReceiptStatus status) {
    switch (status) {
      case ReceiptStatus.none:
        return 'NONE';
      case ReceiptStatus.awaiting:
        return 'AWAITING';
      case ReceiptStatus.confirmed:
        return 'CONFIRMED';
      case ReceiptStatus.discrepancy:
        return 'DISCREPANCY';
    }
  }
}
