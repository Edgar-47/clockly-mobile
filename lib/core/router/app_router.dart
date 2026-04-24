import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/attendance/screens/attendance_history_screen.dart';
import '../../features/employees/screens/employees_screen.dart';
import '../../features/tickets/screens/tickets_screen.dart';
import '../../features/tickets/screens/create_ticket_screen.dart';
import '../../features/tickets/screens/ticket_detail_screen.dart';
import '../../features/business/screens/business_selector_screen.dart';
import '../../features/kiosk/screens/kiosk_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/subscriptions/screens/subscriptions_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that require manager-or-above role.
const _managerRoutes = {'/dashboard', '/employees'};

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<Object?>(null);

  ref.listen(authProvider, (_, next) {
    authListenable.value = next;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: authListenable,
    initialLocation: '/attendance',
    redirect: (context, state) {
      final auth = ref.read(authProvider).valueOrNull;

      // Still initializing — show nothing while session restores
      if (auth == null || !auth.isInitialized) return null;

      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';

      // Not authenticated → login (except if already on login)
      if (!auth.isAuthenticated) {
        return isLoginRoute ? null : '/login';
      }

      // Already authenticated → skip login
      if (isLoginRoute) return '/attendance';

      // Role guard: manager-or-above routes
      if (_managerRoutes.any((r) => location.startsWith(r))) {
        final session = auth.session;
        if (session != null && !session.isManagerOrAbove) {
          // Employee trying to access admin route → redirect to attendance
          return '/attendance';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/kiosk',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const KioskScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/attendance',
            builder: (_, __) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/attendance/history',
            builder: (_, __) => const AttendanceHistoryScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/employees',
            builder: (_, __) => const EmployeesScreen(),
          ),
          GoRoute(
            path: '/tickets',
            builder: (_, __) => const TicketsScreen(),
          ),
          GoRoute(
            path: '/tickets/create',
            builder: (_, __) => const CreateTicketScreen(),
          ),
          GoRoute(
            path: '/tickets/:id',
            builder: (_, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) {
                return const _InvalidParamScreen(message: 'Ticket no válido');
              }
              return TicketDetailScreen(ticketId: id);
            },
          ),
          GoRoute(
            path: '/business',
            builder: (_, __) => const BusinessSelectorScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (_, __) => const SubscriptionsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _NotFoundScreen(error: state.error),
  );
});

// ---------------------------------------------------------------------------

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.link_off_rounded, size: 64, color: Colors.black26),
              const SizedBox(height: 24),
              Text(
                'Página no encontrada',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'La ruta a la que intentas acceder no existe o no tienes permisos.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: () => context.go('/attendance'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvalidParamScreen extends StatelessWidget {
  const _InvalidParamScreen({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.black26),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
