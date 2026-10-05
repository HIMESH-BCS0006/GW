import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_controller.dart';
import '../models/enums.dart';
import '../../features/auth/login_screen.dart';
import '../../features/loader/loader_shell_screen.dart';
import '../../features/loader/loader_trips_screen.dart';
import '../../features/driver/driver_shell_screen.dart';
import '../../features/driver/driver_trips_screen.dart';
import '../../features/driver/driver_track_screen.dart';
import '../../features/driver/driver_history_screen.dart';
import '../../features/driver/order_qr_scanner_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final isLoggingIn = state.matchedLocation == '/login';

      if (auth.isInitial) {
        // App is still restoring session
        return null;
      }

      if (!auth.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // If user is authenticated and on login screen or root, route to their role shell
      if (isLoggingIn || state.matchedLocation == '/') {
        if (auth.user?.role == Role.driver) {
          return '/driver';
        } else if (auth.user?.role == Role.loader) {
          return '/loader';
        }
      }

      // Scope enforcement: prevent cross-role screen access
      if (auth.user?.role == Role.driver &&
          state.matchedLocation.startsWith('/loader')) {
        return '/driver';
      }
      if (auth.user?.role == Role.loader &&
          state.matchedLocation.startsWith('/driver')) {
        return '/loader';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final auth = ref.read(authControllerProvider);
          if (auth.user?.role == Role.driver) return '/driver';
          if (auth.user?.role == Role.loader) return '/loader';
          return '/login';
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => LoaderShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/loader',
            builder: (context, state) => const LoaderTripsScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => DriverShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/driver',
            builder: (context, state) => const DriverTripsScreen(),
          ),
          GoRoute(
            path: '/driver/history',
            builder: (context, state) => const DriverHistoryScreen(),
          ),
          GoRoute(
            path: '/driver/track',
            builder: (context, state) => const DriverTrackScreen(),
          ),
          GoRoute(
            path: '/driver/scan',
            builder: (context, state) =>
                const OrderQrScannerScreen(embedded: true),
          ),
        ],
      ),
    ],
  );
});
