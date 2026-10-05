import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/offline/connectivity_service.dart';
import '../theme/app_theme.dart';

class OfflineBanner extends ConsumerWidget {
  final VoidCallback? onSyncNow;

  const OfflineBanner({
    super.key,
    this.onSyncNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netState = ref.watch(connectivityServiceProvider);

    Color bg;
    Color fg;
    IconData icon;
    String text;

    switch (netState.syncStatus) {
      case SyncStatus.online:
        bg = AppTheme.successGreen.withValues(alpha: 0.12);
        fg = const Color(0xFF047857);
        icon = Icons.check_circle_outline;
        text = netState.isSimulatedOffline ? 'Simulated Online' : 'Online';
        break;
      case SyncStatus.offline:
        bg = AppTheme.warningAmber.withValues(alpha: 0.15);
        fg = const Color(0xFFB45309);
        icon = Icons.cloud_off_outlined;
        final pending = netState.pendingCount;
        text = pending > 0
            ? 'Offline ($pending pending action${pending > 1 ? 's' : ''})'
            : (netState.isSimulatedOffline ? 'Offline (Simulated)' : 'Offline mode');
        break;
      case SyncStatus.syncing:
        bg = AppTheme.infoBlue.withValues(alpha: 0.15);
        fg = const Color(0xFF1D4ED8);
        icon = Icons.sync;
        text = 'Syncing operations with server...';
        break;
      case SyncStatus.needsAttention:
        bg = AppTheme.errorRed.withValues(alpha: 0.15);
        fg = const Color(0xFFB91C1C);
        icon = Icons.warning_amber_rounded;
        text = netState.attentionMessage ?? 'Needs attention: Conflict detected';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: fg.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (netState.pendingCount > 0 && onSyncNow != null && netState.isOnline) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSyncNow,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: fg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Sync now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
