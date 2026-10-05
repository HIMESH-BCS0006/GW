import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

enum SyncStatus {
  online,
  offline,
  syncing,
  needsAttention,
}

class NetworkState {
  final bool isOnline;
  final bool isSimulatedOffline;
  final SyncStatus syncStatus;
  final int pendingCount;
  final String? attentionMessage;

  const NetworkState({
    required this.isOnline,
    required this.isSimulatedOffline,
    this.syncStatus = SyncStatus.online,
    this.pendingCount = 0,
    this.attentionMessage,
  });

  NetworkState copyWith({
    bool? isOnline,
    bool? isSimulatedOffline,
    SyncStatus? syncStatus,
    int? pendingCount,
    String? attentionMessage,
    bool clearAttention = false,
  }) {
    return NetworkState(
      isOnline: isOnline ?? this.isOnline,
      isSimulatedOffline: isSimulatedOffline ?? this.isSimulatedOffline,
      syncStatus: syncStatus ?? this.syncStatus,
      pendingCount: pendingCount ?? this.pendingCount,
      attentionMessage: clearAttention ? null : (attentionMessage ?? this.attentionMessage),
    );
  }
}

final connectivityServiceProvider = StateNotifierProvider<ConnectivityService, NetworkState>((ref) {
  return ConnectivityService();
});

class ConnectivityService extends StateNotifier<NetworkState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService()
      : super(NetworkState(
          isOnline: !AppConfig.simulatedOffline,
          isSimulatedOffline: AppConfig.simulatedOffline,
        )) {
    _init();
  }

  void _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasRealConnection = results.any((r) => r != ConnectivityResult.none);
    final effectiveOnline = hasRealConnection && !AppConfig.simulatedOffline;

    state = state.copyWith(
      isOnline: effectiveOnline,
      isSimulatedOffline: AppConfig.simulatedOffline,
      syncStatus: effectiveOnline ? SyncStatus.online : SyncStatus.offline,
    );
  }

  void toggleSimulatedOffline(bool simulateOffline) {
    AppConfig.simulatedOffline = simulateOffline;
    state = state.copyWith(
      isSimulatedOffline: simulateOffline,
      isOnline: !simulateOffline && state.isOnline,
      syncStatus: simulateOffline ? SyncStatus.offline : SyncStatus.online,
    );
  }

  void updateSyncStatus(SyncStatus status, {int? pendingCount, String? attentionMessage}) {
    state = state.copyWith(
      syncStatus: status,
      pendingCount: pendingCount ?? state.pendingCount,
      attentionMessage: attentionMessage,
      clearAttention: attentionMessage == null,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
