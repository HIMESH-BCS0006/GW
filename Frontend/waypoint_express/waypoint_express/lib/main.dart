import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_controller.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: WaypointExpressApp(),
    ),
  );
}

class WaypointExpressApp extends ConsumerStatefulWidget {
  const WaypointExpressApp({super.key});

  @override
  ConsumerState<WaypointExpressApp> createState() => _WaypointExpressAppState();
}

class _WaypointExpressAppState extends ConsumerState<WaypointExpressApp> {
  @override
  void initState() {
    super.initState();
    // Attempt session restoration on app start using stored JWT
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Waypoint Express',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}