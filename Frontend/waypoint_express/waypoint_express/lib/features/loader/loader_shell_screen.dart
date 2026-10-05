import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/mobile_scaffold.dart';
import '../../shared/widgets/offline_banner.dart';

class LoaderShellScreen extends ConsumerWidget {
  final Widget child;

  const LoaderShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return MobileScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Waypoint Loader'),
            Text(
              '${user?.displayName ?? 'Loader'} • ${authState.selectedDepotId ?? 'No Depot'}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (user != null && user.depotIds.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.warehouse_outlined, size: 22),
              tooltip: 'Switch Depot',
              initialValue: authState.selectedDepotId,
              onSelected: (depot) {
                ref.read(authControllerProvider.notifier).selectDepot(depot);
              },
              itemBuilder: (context) => user.depotIds.map((depot) {
                final isSelected = depot == authState.selectedDepotId;
                return PopupMenuItem<String>(
                  value: depot,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        size: 18,
                        color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        depot,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
