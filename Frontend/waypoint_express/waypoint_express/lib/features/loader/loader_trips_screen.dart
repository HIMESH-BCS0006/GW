import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_empty_view.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading_view.dart';
import '../../shared/widgets/status_chip.dart';
import 'loader_api.dart';
import 'order_handoff_api.dart';
import 'order_qr_dialog.dart';
import 'report_allocation_screen.dart';

class LoaderTripsScreen extends ConsumerStatefulWidget {
  const LoaderTripsScreen({super.key});

  @override
  ConsumerState<LoaderTripsScreen> createState() => _LoaderTripsScreenState();
}

class _LoaderTripsScreenState extends ConsumerState<LoaderTripsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<TripCard> _trips = const [];
  Brand? _selectedBrand;
  final Set<String> _expandedTripIds = {};
  final Set<String> _confirmingTripIds = {};
  final Map<String, LoadListResponse> _loadLists = {};
  final Map<String, String> _loadListErrors = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadLists.clear();
      _loadListErrors.clear();
    });

    try {
      final auth = ref.read(authControllerProvider);
      var depotId = auth.selectedDepotId;
      if ((depotId == null || depotId.isEmpty) && (auth.user?.depotIds.isNotEmpty ?? false)) {
        depotId = auth.user!.depotIds.first;
      }

      final api = ref.read(loaderApiProvider);
      final trips = await api.getLoadingTrips(depotId: depotId);

      if (!mounted) return;
      setState(() {
        _trips = trips;
        _isLoading = false;
      });

      // Load the actual orders for every current trip.  /loading/trips only
      // returns trip cards; /trips/{id}/load-list contains the order stops.
      await Future.wait(trips.map((trip) => _loadOrdersForTrip(trip)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  Future<void> _loadOrdersForTrip(TripCard trip) async {
    try {
      final api = ref.read(loaderApiProvider);
      final loadList = await api.getTripLoadList(trip.id);

      if (!mounted) return;
      setState(() {
        _loadLists[trip.id] = loadList;
        _loadListErrors.remove(trip.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadListErrors[trip.id] = _friendlyError(e);
      });
    }
  }

  Future<void> _confirmTrip(TripCard trip) async {
    if (_confirmingTripIds.contains(trip.id)) return;

    setState(() => _confirmingTripIds.add(trip.id));
    try {
      final api = ref.read(loaderApiProvider);
      var loadList = _loadLists[trip.id];
      if (loadList == null) {
        await _loadOrdersForTrip(trip);
        loadList = _loadLists[trip.id];
      }
      if (loadList == null) {
        throw FormatException(
          _loadListErrors[trip.id] ?? 'Could not load this trip’s orders.',
        );
      }
      if (loadList.deliverySequence.isEmpty) {
        throw const FormatException(
          'This trip has no assigned orders to include in its QR code.',
        );
      }

      var handoffStatus = trip.status;
      if (trip.status == TripStatus.confirmed) {
        await api.startTripLoading(trip.id);
      }
      try {
        await api.confirmTripLoad(
          tripId: trip.id,
          planVersion: trip.planVersion,
        );
        handoffStatus = TripStatus.loaded;
      } catch (_) {
        handoffStatus = TripStatus.loaded;
      }
      if (!mounted) return;

      final auth = ref.read(authControllerProvider);
      final handoff = TripHandoff.fromTrip(
        trip: trip,
        loaderId: auth.user?.username ?? auth.user?.id ?? 'loader',
        orders: loadList.deliverySequence,
        status: handoffStatus,
      );
      await TripQrPage.show(context, handoff);
      if (mounted) await _loadDashboard();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not confirm trip: ${_friendlyError(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _confirmingTripIds.remove(trip.id));
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    if (message.contains('SocketException') || message.contains('Connection')) {
      return 'Cannot connect to the Waypoint API. Check that the backend/mock server is running and the phone can reach the server.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider.select((s) => s.selectedDepotId), (prev, next) {
      if (prev != next && next != null) {
        _loadDashboard();
      }
    });

    if (_isLoading) {
      return const AppLoadingView(
        message: 'Loading current trips and orders...',
      );
    }

    if (_errorMessage != null) {
      return AppErrorView(
        title: 'Could not load loader dashboard',
        message: _errorMessage!,
        onRetry: _loadDashboard,
      );
    }

    final visibleTrips = _selectedBrand == null
        ? _trips
        : _trips.where((trip) => trip.brand == _selectedBrand).toList();
    final totalOrders = visibleTrips.fold<int>(
      0,
      (total, trip) =>
          total + (_loadLists[trip.id]?.deliverySequence.length ?? 0),
    );

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _buildDashboardHeader(),
          _DashboardSummary(
            tripCount: visibleTrips.length,
            orderCount: totalOrders,
          ),
          const SizedBox(height: 18),
          _buildBrandFilters(),
          const SizedBox(height: 12),
          if (_trips.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: AppEmptyView(
                icon: Icons.inventory_2_outlined,
                title: 'No Assigned Trips',
                message:
                    'There are no trips waiting for loading at this depot.',
              ),
            )
          else if (visibleTrips.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: AppEmptyView(
                icon: Icons.filter_list,
                title: 'No Trips in This Category',
                message: 'Choose another brand filter to view assigned trips.',
              ),
            )
          else ...[
            const Text(
              'Assigned Trips',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'View each trip’s assigned orders and manage its loading status.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            ...visibleTrips.map(_buildTripSection),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    final auth = ref.read(authControllerProvider);
    final deliveryDate = _trips.isEmpty
        ? null
        : AppConfig.formatDate(_trips.first.deliveryDate);

    return Container(
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
                Text(
                  auth.selectedDepotId == null
                      ? 'LOADER DASHBOARD'
                      : 'DEPOT • ${auth.selectedDepotId!.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Welcome Loader',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (deliveryDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Delivery plan • $deliveryDate',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
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
    );
  }

  Widget _buildBrandFilters() {
    final brands = <Brand?>[null, Brand.fresh, Brand.tech, Brand.style];
    final labels = <Brand?, String>{
      null: 'All',
      Brand.fresh: 'Fresh',
      Brand.tech: 'Tech',
      Brand.style: 'Style',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final brand in brands) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  '${labels[brand]} ${brand == null ? _trips.length : _trips.where((trip) => trip.brand == brand).length}',
                ),
                selected: _selectedBrand == brand,
                onSelected: (_) => setState(() => _selectedBrand = brand),
                selectedColor: AppTheme.primaryDark,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: _selectedBrand == brand
                      ? Colors.white
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: _selectedBrand == brand
                      ? AppTheme.primaryDark
                      : const Color(0xFFE2E8F0),
                ),
                showCheckmark: false,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripSection(TripCard trip) {
    final loadList = _loadLists[trip.id];
    final loadError = _loadListErrors[trip.id];
    final isExpanded = _expandedTripIds.contains(trip.id);
    final canConfirmTrip =
        trip.status == TripStatus.confirmed ||
        trip.status == TripStatus.loading ||
        trip.status == TripStatus.loaded ||
        trip.status == TripStatus.blocked;
    final isConfirming = _confirmingTripIds.contains(trip.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFE7F1EF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD5E5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRIP ${trip.tripNo.toString().padLeft(2, '0')}  •  ${trip.vehicleId}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_brandLabel(trip.brand)} • ${trip.district} corridor',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip.fromTripStatus(trip.status),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TripMetric(
                      label: 'STOPS',
                      value: '${trip.stopCount}',
                    ),
                  ),
                  Expanded(
                    child: _TripMetric(
                      label: 'WEIGHT',
                      value:
                          '${_percent(trip.weightUsedKg, trip.weightCapKg)}%',
                    ),
                  ),
                  Expanded(
                    child: _TripMetric(
                      label: 'PAYLOAD',
                      value:
                          '${_percent(trip.volumeUsedM3, trip.volumeCapM3)}%',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canConfirmTrip && !isConfirming
                        ? () => _confirmTrip(trip)
                        : null,
                    icon: isConfirming
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.qr_code_2, size: 18),
                    label: Text(
                      isConfirming ? 'Preparing QR...' : 'Confirm Trip',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      if (isExpanded) {
                        _expandedTripIds.remove(trip.id);
                      } else {
                        _expandedTripIds.add(trip.id);
                      }
                    }),
                    icon: Icon(
                      isExpanded
                          ? Icons.expand_less
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    label: Text(isExpanded ? 'Hide Orders' : 'View Orders'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryDark,
                      side: const BorderSide(color: AppTheme.primaryDark),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
            if (trip.status == TripStatus.blocked) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.brown),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stock shortfall reported (Non-blocking). You can confirm trip loading anytime.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.brown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isExpanded) ...[
              const Divider(height: 22),
              if (loadError != null) ...[
                _TripLoadError(
                  message: loadError,
                  onRetry: () => _loadOrdersForTrip(trip),
                ),
              ] else if (loadList == null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ] else if (loadList.deliverySequence.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No orders are currently listed for this trip.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    const Icon(
                      Icons.list_alt_outlined,
                      size: 18,
                      color: AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${loadList.deliverySequence.length} order${loadList.deliverySequence.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...loadList.deliverySequence.map(
                  (stop) => _buildOrderCard(stop, trip, loadList.planVersion),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(StopDetail stop, TripCard trip, int planVersion) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${stop.seq}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.orderId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stop.outletName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stop.outletId} • ${stop.district}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip.fromStopStatus(stop.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _InfoItem(
                icon: Icons.inventory_2_outlined,
                label: 'Units',
                value: '${stop.orderUnits}',
              ),
              _InfoItem(
                icon: Icons.scale_outlined,
                label: 'Weight',
                value: '${_number(stop.orderWeightKg)} kg',
              ),
              _InfoItem(
                icon: Icons.view_in_ar_outlined,
                label: 'Volume',
                value: '${_number(stop.orderVolumeM3)} m³',
              ),
              _InfoItem(
                icon: Icons.access_time_outlined,
                label: 'Window',
                value:
                    '${AppConfig.formatClockTime(stop.windowOpenTime)} - ${AppConfig.formatClockTime(stop.windowCloseTime)}',
              ),
              if (stop.eta != null)
                _InfoItem(
                  icon: Icons.location_on_outlined,
                  label: 'ETA',
                  value: AppConfig.formatClockTime(stop.eta),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final submitted = await ReportAllocationPage.show(
                  context,
                  trip: trip,
                  stop: stop,
                  planVersion: planVersion,
                );
                if (submitted && mounted) await _loadDashboard();
              },
              icon: const Icon(Icons.report_gmailerrorred_outlined, size: 18),
              label: const Text('Create Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: const BorderSide(color: AppTheme.errorRed),
                minimumSize: const Size.fromHeight(42),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _brandLabel(Brand brand) {
    switch (brand) {
      case Brand.fresh:
        return 'Fresh';
      case Brand.style:
        return 'Style';
      case Brand.tech:
        return 'Tech';
    }
  }

  String _number(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  int _percent(double used, double capacity) {
    if (capacity <= 0) return 0;
    return (used / capacity * 100).round();
  }
}

class _TripMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TripMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DashboardSummary extends StatelessWidget {
  final int tripCount;
  final int orderCount;

  const _DashboardSummary({required this.tripCount, required this.orderCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryTeal, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryValue(
              icon: Icons.local_shipping_outlined,
              value: '$tripCount',
              label: tripCount == 1 ? 'Current Trip' : 'Current Trips',
            ),
          ),
          Container(width: 1, height: 48, color: Colors.white24),
          Expanded(
            child: _SummaryValue(
              icon: Icons.inventory_2_outlined,
              value: '$orderCount',
              label: orderCount == 1 ? 'Current Order' : 'Current Orders',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryValue({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TripLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TripLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            tooltip: 'Retry',
            icon: const Icon(Icons.refresh, size: 19),
            color: AppTheme.primaryDark,
          ),
        ],
      ),
    );
  }
}
