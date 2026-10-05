import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/models/models.dart';
import 'driver_api.dart';
import '../loader/order_handoff_api.dart';
import 'order_qr_scanner_screen.dart';

class DriverTripsScreen extends ConsumerStatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  ConsumerState<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends ConsumerState<DriverTripsScreen> {
  List<TripCard> _trips = const [];
  List<OrderHandoff> _orders = const [];
  List<TripHandoff> _scannedTrips = const [];
  String? _loadError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final driverApi = ref.read(driverApiProvider);
      final trips = await driverApi.getDriverTrips();

      if (mounted) {
        setState(() => _trips = trips);
      }

      final handoffApi = ref.read(orderHandoffApiProvider);
      final user = ref.read(authControllerProvider).user;
      final driverId = user?.id ?? user?.username ?? 'driver';
      await handoffApi.syncAllTripsFromServer(driverId: driverId);
      final orders = await handoffApi.getDriverOrders();
      final scannedTrips = await handoffApi.getCachedTripHandoffs(
        driverId: driverId,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _scannedTrips = scannedTrips;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<void> _startTrip(TripCard trip) async {
    try {
      await ref
          .read(driverApiProvider)
          .startTrip(tripId: trip.id, planVersion: trip.planVersion);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip ${trip.id} started! Route IN_PROGRESS.')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start trip: $e')),
      );
    }
  }

  Future<void> _scan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OrderQrScannerScreen()),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DRIVER DASHBOARD',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Welcome, ${user?.username ?? 'Driver'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (user?.vehicleId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Vehicle • ${user!.vehicleId}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/123.png',
                    width: 94,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryTeal, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner,
                    color: Colors.white, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Handover',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vehicle ${user?.vehicleId ?? '--'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.qr_code_scanner, size: 25),
              label: const Text('Scan Loader Order QR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          if (_trips.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Assigned Trips',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Trips allocated to your vehicle for today\'s delivery run.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            ..._trips.map((trip) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.local_shipping,
                                  color: AppTheme.primaryDark),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trip ${trip.tripNo} • ${trip.id}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    '${trip.brand} • ${trip.district} • ${trip.stopCount} stops',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: trip.status == TripStatus.inProgress
                                    ? Colors.blue.shade100
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                trip.status.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: trip.status == TripStatus.inProgress
                                      ? Colors.blue.shade900
                                      : Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (trip.status == TripStatus.loaded) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _startTrip(trip),
                              icon: const Icon(Icons.navigation),
                              label: const Text('Start Route (Depart Depot)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryDark,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )),
          ] else if (!_isLoading && _loadError == null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 38,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No assigned trips yet',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your dashboard is ready. Assigned trips will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_loadError != null) ...[
            const SizedBox(height: 20),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off, color: AppTheme.errorRed),
                    const SizedBox(height: 6),
                    const Text(
                      'Could not load assigned trips',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_scannedTrips.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Scanned Trip Details',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ..._scannedTrips.map(
              (trip) {
                final isCompleted = trip.orders.isNotEmpty &&
                    trip.orders.every(
                      (o) =>
                          o.receiptStatus == ReceiptStatus.confirmed ||
                          o.receiptStatus == ReceiptStatus.discrepancy,
                    );
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCompleted
                          ? AppTheme.successGreen.withValues(alpha: 0.15)
                          : AppTheme.primaryLight,
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.route_outlined,
                        color: isCompleted
                            ? AppTheme.successGreen
                            : AppTheme.primaryDark,
                      ),
                    ),
                    title: Text(
                      'Trip ${trip.tripNo} • ${trip.vehicleId}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${trip.orders.length} orders • ${trip.depotId}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.successGreen,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DriverTripHandoffScreen(handoff: trip),
                        ),
                      );
                      _refresh();
                    },
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Received Orders',
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Orders already verified and handed over to this driver.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          if (_loadError != null && _orders.isNotEmpty)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Could not refresh received orders: $_loadError',
                  style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                ),
              ),
            ),
          if (_isLoading && _orders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_loadError != null && _orders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off,
                        color: AppTheme.textMuted, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'Could not load received orders',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_orders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_2, size: 42, color: AppTheme.textMuted),
                    SizedBox(height: 10),
                    Text('No orders scanned yet',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text(
                        'Ask the loader to accept an order and show its QR code. Pull down to refresh.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ..._orders.map(_orderCard),
        ],
      ),
    );
  }

  Widget _orderCard(OrderHandoff handoff) {
    final order = handoff.order;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.inventory_2_outlined),
        ),
        title: Text(order.orderId,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
            '${order.outletName}\n${order.orderUnits} units • ${order.orderWeightKg} kg'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => DriverOrderDetailScreen(handoff: handoff)),
        ),
      ),
    );
  }
}
