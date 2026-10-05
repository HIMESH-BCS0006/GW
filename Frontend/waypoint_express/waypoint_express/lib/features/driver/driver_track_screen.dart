import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/models/models.dart';
import '../../shared/theme/app_theme.dart';
import '../loader/order_handoff_api.dart';
import 'driver_api.dart';
import 'stop_outcome_validator.dart';

class DriverTrackScreen extends ConsumerStatefulWidget {
  const DriverTrackScreen({super.key});

  @override
  ConsumerState<DriverTrackScreen> createState() => _DriverTrackScreenState();
}

class _DriverTrackScreenState extends ConsumerState<DriverTrackScreen> {
  List<TripCard> _trips = const [];
  List<TripHandoff> _scannedTrips = const [];
  List<DriverTrackedStop> _receivedOrders = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _summaryWarning;
  String? _updatingStopId;
  StreamSubscription<Map<String, dynamic>>? _receiptSubscription;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadTracking();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollRefresh();
    });
    _receiptSubscription = ref
        .read(driverApiProvider)
        .watchReceiptEvents()
        .listen(
          _handleReceiptEvent,
          onError: (_) {},
        );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _receiptSubscription?.cancel();
    super.dispose();
  }

  Future<void> _pollRefresh() async {
    if (!mounted) return;
    try {
      final handoffApi = ref.read(orderHandoffApiProvider);
      await handoffApi.syncAllTripsFromServer(driverId: _driverId);
      final results = await Future.wait([
        handoffApi.getCachedTripHandoffs(driverId: _driverId),
        handoffApi.getDriverTrackingStops(driverId: _driverId),
      ]);
      if (!mounted) return;
      setState(() {
        _scannedTrips = results[0] as List<TripHandoff>;
        _receivedOrders = results[1] as List<DriverTrackedStop>;
      });
    } catch (_) {}
  }

  Future<void> _handleReceiptEvent(Map<String, dynamic> event) async {
    final completedOrderIds = await ref
        .read(orderHandoffApiProvider)
        .applyReceiptEvent(driverId: _driverId, event: event);
    if (completedOrderIds.isEmpty || !mounted) return;

    final refreshedStops = await ref
        .read(orderHandoffApiProvider)
        .getDriverTrackingStops(driverId: _driverId);
    if (!mounted) return;
    setState(() => _receivedOrders = refreshedStops);
  }

  Future<void> _loadTracking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final handoffApi = ref.read(orderHandoffApiProvider);
      final results = await Future.wait([
        handoffApi.getCachedTripHandoffs(driverId: _driverId),
        handoffApi.getDriverTrackingStops(driverId: _driverId),
      ]);
      List<TripCard> trips = const [];
      String? summaryWarning;
      try {
        trips = await ref.read(driverApiProvider).getDriverTrips();
      } catch (error) {
        summaryWarning = error.toString().replaceFirst('Exception: ', '');
      }
      if (!mounted) return;
      setState(() {
        _scannedTrips = results[0] as List<TripHandoff>;
        _receivedOrders = results[1] as List<DriverTrackedStop>;
        _trips = trips;
        _summaryWarning = summaryWarning;
        _errorMessage = trips.isEmpty && _scannedTrips.isEmpty
            ? summaryWarning
            : null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String get _driverId {
    final user = ref.read(authControllerProvider).user;
    return user?.id ?? user?.username ?? 'driver';
  }

  List<DriverTrackedStop> _ordersForTrip(String tripId) {
    final orders =
        _receivedOrders.where((stop) => stop.tripId == tripId).toList()
          ..sort((a, b) {
            final sequence = a.seq.compareTo(b.seq);
            return sequence != 0 ? sequence : a.orderId.compareTo(b.orderId);
          });
    return orders;
  }

  List<DriverTrackedStop> _ordersForHandoff(TripHandoff handoff) {
    final availableOrders = _ordersForTrip(handoff.tripId);
    return handoff.orders.map((order) {
      for (final available in availableOrders) {
        if (available.orderId == order.orderId) return available;
      }
      return DriverTrackedStop.fromTripHandoff(
        tripId: handoff.tripId,
        order: order,
      );
    }).toList()..sort((a, b) => a.seq.compareTo(b.seq));
  }

  TripStatus? _statusForTrip(String tripId) {
    for (final trip in _trips) {
      if (trip.id == tripId) return trip.status;
    }
    return null;
  }

  int _completedStops(List<DriverTrackedStop> orders) {
    return orders.where((stop) {
      final status = stop.status;
      return status == StopStatus.delivered ||
          status == StopStatus.partial ||
          status == StopStatus.failed ||
          stop.receiptStatus == ReceiptStatus.confirmed ||
          stop.receiptStatus == ReceiptStatus.discrepancy;
    }).length;
  }

  Future<void> _arriveAtStop(DriverTrackedStop stop) async {
    final stopId = stop.stopId;
    if (stopId == null) return;
    setState(() => _updatingStopId = stopId);
    try {
      final updated = await ref.read(driverApiProvider).arriveStop(stopId);
      if (!mounted) return;
      ref.read(orderHandoffApiProvider).updateTrackedStop(updated);
      _replaceStop(updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Arrived at stop ${stop.seq}.')));
    } catch (error) {
      if (!mounted) return;
      _showActionError('Could not record arrival', error);
    } finally {
      if (mounted) setState(() => _updatingStopId = null);
    }
  }

  Future<void> _updateStopOutcome(DriverTrackedStop stop) async {
    final submission = await showDialog<_StopOutcomeSubmission>(
      context: context,
      builder: (_) => _StopOutcomeDialog(order: stop),
    );
    if (submission == null || !mounted) return;

    final stopId = stop.stopId;
    if (stopId == null) return;
    setState(() => _updatingStopId = stopId);
    try {
      final updated = await ref
          .read(driverApiProvider)
          .recordStopOutcome(
            stopId: stopId,
            outcome: submission.outcome.name,
            quantityDelivered: submission.quantityDelivered,
            receivedBy: submission.receivedBy,
            outcomeNote: submission.note,
            completedAt: _colomboTimestamp(),
          );
      if (!mounted) return;
      ref.read(orderHandoffApiProvider).updateTrackedStop(updated);
      _replaceStop(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stop ${stop.seq} updated: ${_outcomeLabel(submission.outcome)}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showActionError('Could not update stop status', error);
    } finally {
      if (mounted) setState(() => _updatingStopId = null);
    }
  }

  void _showTripHandoverQr(TripCard trip, List<DriverTrackedStop> stops) {
    final payload = _driverHandoverPayload({
      'type': 'trip_handover',
      'trip_id': trip.id,
      'trip_no': trip.tripNo,
      'vehicle_id': trip.vehicleId,
      'delivery_date': trip.deliveryDate,
      'orders': stops.map(_stopQrData).toList(growable: false),
    });
    _showHandoverQr(
      title: 'Trip Handover QR',
      subtitle: 'Trip ${trip.tripNo} • ${stops.length} stops',
      payload: payload,
      instructions:
          'Show this code to the shop manager to view the trip handover details. '
          'Use the QR on each stop to confirm that individual order.',
    );
  }

  void _showStopHandoverQr(DriverTrackedStop stop) {
    if (stop.stopId == null) {
      _showActionError(
        'Cannot create handover QR',
        const FormatException(
          'This order does not contain a backend stop ID. Scan a trip QR that includes stop IDs.',
        ),
      );
      return;
    }
    final payload = _driverHandoverPayload({
      'type': 'stop_handover',
      ..._stopQrData(stop),
    });
    _showHandoverQr(
      title: 'Order Handover QR',
      subtitle: 'Stop ${stop.seq} • ${stop.orderId}',
      payload: payload,
      instructions:
          'Show this code to the shop manager for this order. '
          'The manager’s receipt system must submit the receipt against this stop.',
    );
  }

  void _showHandoverQr({
    required String title,
    required String subtitle,
    required String payload,
    required String instructions,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                instructions,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _stopQrData(DriverTrackedStop stop) => {
    'stop_id': stop.stopId,
    'trip_id': stop.tripId,
    'order_id': stop.orderId,
    'sequence': stop.seq,
    'outlet_id': stop.outletId,
    'outlet_name': stop.outletName,
    'district': stop.district,
    'ordered_units': stop.units,
  };

  String _driverHandoverPayload(Map<String, dynamic> data) =>
      'WAYPOINT-DRIVER-HANDOVER:${jsonEncode({'version': 1, ...data})}';

  void _replaceStop(TripStop updated) {
    setState(() {
      _receivedOrders = _receivedOrders
          .map((stop) {
            if (stop.stopId != updated.id) return stop;
            return stop.copyWithUpdate(updated);
          })
          .toList(growable: false);
    });
  }

  void _showActionError(String action, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$action: ${error.toString().replaceFirst('Exception: ', '')}',
        ),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.cloud_off, size: 44, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          const Text(
            'Could not load trip tracking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadTracking,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTracking,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryTeal, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.route_outlined, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Tracking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Follow each order stop in delivery sequence and record its status.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sequenced Stop Preview',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (_summaryWarning != null && _scannedTrips.isNotEmpty) ...[
            Text(
              'Showing saved scanned-trip details. The latest trip status could not be refreshed: $_summaryWarning',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_trips.isEmpty && _scannedTrips.isEmpty)
            const _EmptyTrackingCard(
              message: 'No assigned trips to track',
              icon: Icons.route_outlined,
            )
          else ...[
            ..._scannedTrips.map(_buildScannedTripCard),
            ..._trips
                .where(
                  (trip) => !_scannedTrips.any(
                    (handoff) => handoff.tripId == trip.id,
                  ),
                )
                .map(_buildTripCard),
          ],
          const SizedBox(height: 8),
          const Text(
            'Stops are shown in the planned order. GPS mapping is not available in the current trip and stop data.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedTripCard(TripHandoff handoff) {
    final orders = _ordersForHandoff(handoff);
    final stopCount = handoff.orders.length;
    final completedStops = _completedStops(orders);
    final isAllCompleted = stopCount > 0 && completedStops == stopCount;
    final progress = stopCount == 0
        ? 0.0
        : (completedStops / stopCount).clamp(0.0, 1.0);
    final status = isAllCompleted
        ? TripStatus.completed
        : (_statusForTrip(handoff.tripId) ?? handoff.status);
    final districts = handoff.orders.map((order) => order.district).toSet();
    final route = districts.isEmpty
        ? handoff.depotId
        : '${handoff.depotId} → ${districts.join(' → ')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Trip ${handoff.tripNo} • ${handoff.vehicleId}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (status == null)
                  const _StopStatusBadge(
                    label: 'SCANNED',
                    color: AppTheme.infoBlue,
                  )
                else
                  _TripStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$route • $stopCount ${stopCount == 1 ? 'stop' : 'stops'}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery progress',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$completedStops / $stopCount complete',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppTheme.surfaceVariant,
                color: completedStops == stopCount && stopCount > 0
                    ? AppTheme.successGreen
                    : AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < orders.length; index++)
              _buildStopCard(orders[index], isLast: index == orders.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(TripCard trip) {
    final orders = _ordersForTrip(trip.id);
    final completedStops = _completedStops(orders);
    final displayedStops = orders.isEmpty ? trip.stopCount : orders.length;
    final expectedStops = displayedStops;
    final isAllCompleted = expectedStops > 0 && completedStops == expectedStops;
    final tripStatus = isAllCompleted ? TripStatus.completed : trip.status;
    final progress = expectedStops == 0
        ? 0.0
        : (completedStops / expectedStops).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Trip ${trip.tripNo} • ${trip.vehicleId}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                _TripStatusBadge(status: tripStatus),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${trip.brand.name} • ${trip.district} • $displayedStops stops',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: orders.isEmpty
                    ? null
                    : () => _showTripHandoverQr(trip, orders),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Show Trip Handover QR'),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery progress',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$completedStops / $displayedStops complete',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppTheme.surfaceVariant,
                color: completedStops == displayedStops && displayedStops > 0
                    ? AppTheme.successGreen
                    : AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const _EmptyTrackingCard(
                message:
                    'No handed-over orders are available for this trip yet.',
                icon: Icons.inventory_2_outlined,
                compact: true,
              )
            else ...[
              for (var index = 0; index < orders.length; index++)
                _buildStopCard(
                  orders[index],
                  isLast: index == orders.length - 1,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStopCard(DriverTrackedStop stop, {required bool isLast}) {
    final isUpdating = _updatingStopId == stop.stopId;
    final handoverComplete =
        stop.receiptStatus == ReceiptStatus.confirmed ||
        stop.receiptStatus == ReceiptStatus.discrepancy;
    final isComplete = _isCompleted(stop.status) || handoverComplete;
    final statusColor = _trackedStopStatusColor(stop);
    final canArrive = stop.stopId != null && stop.status == StopStatus.pending;
    final canUpdate = stop.stopId != null && stop.status == StopStatus.arrived;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: isComplete
                      ? AppTheme.successGreen
                      : stop.status == StopStatus.arrived
                      ? AppTheme.infoBlue
                      : AppTheme.primaryDark,
                  child: isComplete
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${stop.seq}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: AppTheme.surfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: stop.status == StopStatus.arrived
                      ? AppTheme.infoBlue.withValues(alpha: 0.35)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stop.outletName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _StopStatusBadge(
                        label: _stopStatusLabel(stop),
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${stop.orderId} • ${stop.outletId}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _StopDetail(
                        icon: Icons.schedule,
                        label: 'ETA ${stop.eta ?? '--'}',
                      ),
                      _StopDetail(
                        icon: Icons.inventory_2_outlined,
                        label: '${stop.units} units',
                      ),
                      _StopDetail(
                        icon: Icons.access_time,
                        label: '${stop.windowOpenTime}–${stop.windowCloseTime}',
                      ),
                    ],
                  ),
                  if (stop.outcome != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      '${_outcomeLabel(stop.outcome!)}'
                      '${stop.quantityDelivered == null ? '' : ' • ${stop.quantityDelivered} units'}'
                      '${stop.receivedBy == null || stop.receivedBy!.isEmpty ? '' : ' • received by ${stop.receivedBy}'}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (handoverComplete)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.successGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            stop.receiptStatus == ReceiptStatus.discrepancy
                                ? 'Shop receipt completed with discrepancy'
                                : 'Order handover complete',
                            style: const TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (stop.stopId != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showStopHandoverQr(stop),
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('Show Order Handover QR'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (canArrive || canUpdate)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isUpdating
                            ? null
                            : () => canArrive
                                  ? _arriveAtStop(stop)
                                  : _updateStopOutcome(stop),
                        icon: isUpdating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                canArrive
                                    ? Icons.location_on_outlined
                                    : Icons.check_circle_outline,
                              ),
                        label: Text(
                          isUpdating
                              ? 'Updating...'
                              : canArrive
                              ? 'Mark Arrival'
                              : 'Update Status',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  if (stop.stopId == null)
                    const Text(
                      'This saved trip QR does not include a stop reference. Scan a newly generated trip QR to record stop updates.',
                      style: TextStyle(color: AppTheme.errorRed, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopOutcomeSubmission {
  final StopOutcome outcome;
  final int? quantityDelivered;
  final String? receivedBy;
  final String? note;

  const _StopOutcomeSubmission({
    required this.outcome,
    required this.quantityDelivered,
    required this.receivedBy,
    required this.note,
  });
}

class _StopOutcomeDialog extends StatefulWidget {
  final DriverTrackedStop order;

  const _StopOutcomeDialog({required this.order});

  @override
  State<_StopOutcomeDialog> createState() => _StopOutcomeDialogState();
}

class _StopOutcomeDialogState extends State<_StopOutcomeDialog> {
  final _quantityController = TextEditingController();
  final _receiverController = TextEditingController();
  final _noteController = TextEditingController();
  StopOutcome _outcome = StopOutcome.delivered;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '${widget.order.units}';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _receiverController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectOutcome(StopOutcome outcome) {
    setState(() {
      _outcome = outcome;
      _validationError = null;
      if (outcome == StopOutcome.delivered) {
        _quantityController.text = '${widget.order.units}';
      } else if (outcome == StopOutcome.partial) {
        _quantityController.text = widget.order.units > 1
            ? '${widget.order.units - 1}'
            : '';
      } else {
        _quantityController.text = '0';
      }
    });
  }

  void _submit() {
    final quantity = int.tryParse(_quantityController.text);
    final completedAt = _colomboTimestamp();
    final validation = StopOutcomeValidator.validate(
      outcome: _outcome,
      orderedUnits: widget.order.units,
      quantityDelivered: quantity,
      receivedBy: _receiverController.text,
      completedAt: completedAt,
    );
    if (!validation.isValid) {
      setState(() => _validationError = validation.error);
      return;
    }

    Navigator.of(context).pop(
      _StopOutcomeSubmission(
        outcome: _outcome,
        quantityDelivered:
            _outcome == StopOutcome.refused || _outcome == StopOutcome.closed
            ? 0
            : quantity,
        receivedBy: _receiverController.text.trim().isEmpty
            ? null
            : _receiverController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Stop ${widget.order.seq}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.order.orderId} • ${widget.order.units} ordered units',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            RadioGroup<StopOutcome>(
              groupValue: _outcome,
              onChanged: (value) {
                if (value != null) _selectOutcome(value);
              },
              child: Column(
                children: [
                  for (final outcome in StopOutcome.values)
                    RadioListTile<StopOutcome>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(_outcomeLabel(outcome)),
                      value: outcome,
                    ),
                ],
              ),
            ),
            if (_outcome == StopOutcome.delivered ||
                _outcome == StopOutcome.partial) ...[
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity delivered',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _receiverController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Received by',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 8),
              Text(
                _validationError!,
                style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save Status')),
      ],
    );
  }
}

class _EmptyTrackingCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool compact;

  const _EmptyTrackingCard({
    required this.message,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 22),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textMuted, size: compact ? 22 : 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StopDetail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _TripStatusBadge extends StatelessWidget {
  final TripStatus status;

  const _TripStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == TripStatus.inProgress
        ? AppTheme.infoBlue
        : status == TripStatus.completed
        ? AppTheme.successGreen
        : AppTheme.textSecondary;

    return _StopStatusBadge(
      label: status.name
          .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
          .toUpperCase(),
      color: color,
    );
  }
}

class _StopStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StopStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

bool _isCompleted(StopStatus status) =>
    status == StopStatus.delivered ||
    status == StopStatus.partial ||
    status == StopStatus.failed;

Color _statusColor(StopStatus status) {
  if (_isCompleted(status)) return AppTheme.successGreen;
  if (status == StopStatus.arrived) return AppTheme.infoBlue;
  if (status == StopStatus.exception) return AppTheme.errorRed;
  return AppTheme.textSecondary;
}

String _stopStatusLabel(DriverTrackedStop stop) {
  if (stop.receiptStatus == ReceiptStatus.confirmed) {
    return 'HANDOVER COMPLETE';
  }
  if (stop.receiptStatus == ReceiptStatus.discrepancy) {
    return 'RECEIPT ISSUE';
  }
  if (stop.outcome != null) return _outcomeLabel(stop.outcome!);
  return stop.status.name.toUpperCase();
}

Color _trackedStopStatusColor(DriverTrackedStop stop) {
  if (stop.receiptStatus == ReceiptStatus.confirmed) {
    return AppTheme.successGreen;
  }
  if (stop.receiptStatus == ReceiptStatus.discrepancy) {
    return AppTheme.errorRed;
  }
  return _statusColor(stop.status);
}

String _outcomeLabel(StopOutcome outcome) {
  switch (outcome) {
    case StopOutcome.delivered:
      return 'Delivered';
    case StopOutcome.partial:
      return 'Partial';
    case StopOutcome.refused:
      return 'Refused';
    case StopOutcome.closed:
      return 'Closed';
  }
}

String _colomboTimestamp() {
  final time = DateTime.now().toUtc().add(
    const Duration(hours: 5, minutes: 30),
  );
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${twoDigits(time.month)}-${twoDigits(time.day)}'
      'T${twoDigits(time.hour)}:${twoDigits(time.minute)}:${twoDigits(time.second)}'
      '+05:30';
}
