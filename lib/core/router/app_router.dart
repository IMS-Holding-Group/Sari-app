import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ui/view_models/app_state_view_model.dart';
import '../../ui/views/auth/login_screen.dart';
import '../../ui/views/navigation/main_wrapper_screen.dart';
import '../../ui/views/dashboard/home_dashboard_screen.dart';
import '../../ui/views/monitoring/live_monitoring_screen.dart';
import '../../ui/views/ai_risk/ai_risk_detection_screen.dart';
import '../../ui/views/alerts/alerts_center_screen.dart';
import '../../ui/views/heatmap/risk_heatmap_screen.dart';
import '../../ui/views/reports/reports_screen.dart';
import '../../ui/views/devices/device_management_screen.dart';
import '../../ui/views/emergency/emergency_control_screen.dart';
import '../../ui/views/profile/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRouter createRouter(AppStateViewModel state) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: state.isLoggedIn ? '/app/home' : '/login',
    refreshListenable: state,
    redirect: (context, routerState) {
      final loggingIn = routerState.matchedLocation == '/login';
      if (!state.isLoggedIn && !loggingIn) {
        return '/login';
      }
      if (state.isLoggedIn && loggingIn) {
        return '/app/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainWrapperScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/app/home',
            builder: (context, state) => const HomeDashboardScreen(),
          ),
          GoRoute(
            path: '/app/monitoring',
            builder: (context, state) => const LiveMonitoringScreen(),
          ),
          GoRoute(
            path: '/app/ai-risk',
            builder: (context, state) => const AIRiskDetectionScreen(),
          ),
          GoRoute(
            path: '/app/alerts',
            builder: (context, state) => const AlertsCenterScreen(),
          ),
          GoRoute(
            path: '/app/heatmap',
            builder: (context, state) => const RiskHeatmapScreen(),
          ),
          GoRoute(
            path: '/app/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/devices',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeviceManagementScreen(),
      ),
      GoRoute(
        path: '/emergency',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EmergencyControlScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
