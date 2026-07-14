import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/mobile_units/presentation/screens/units_list_screen.dart';
import '../../features/mobile_units/presentation/screens/unit_detail_screen.dart';
import '../../features/field_visits/presentation/screens/visits_list_screen.dart';
import '../../features/field_visits/presentation/screens/start_visit_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/service_reporting/presentation/screens/reports_list_screen.dart';
import '../../features/service_reporting/presentation/screens/new_report_screen.dart';
import '../../features/referrals/presentation/screens/referrals_list_screen.dart';
import '../../features/referrals/presentation/screens/new_referral_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/alerts/presentation/screens/alerts_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';
import '../../shared/widgets/app_sidebar.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../core/utils/responsive_utils.dart';

class ShellLayout extends StatelessWidget {
  final Widget child;
  final String location;

  const ShellLayout({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final showSidebar = ResponsiveUtils.showSidebar(context);

    // Dynamic title mapping based on location
    String title = 'Operations Platform';
    if (location.startsWith('/dashboard')) title = 'Platform Summary Dashboard';
    if (location.startsWith('/units')) title = 'Mobile Healthcare Units';
    if (location.startsWith('/visits')) title = 'Field Visit Logs';
    if (location.startsWith('/attendance')) title = 'Staff Attendance';
    if (location.startsWith('/reports')) title = 'Service Reports';
    if (location.startsWith('/referrals')) title = 'Referral Cases';
    if (location.startsWith('/inventory')) title = 'Stock Inventory';
    if (location.startsWith('/alerts')) title = 'Platform Alerts';
    if (location.startsWith('/analytics')) title = 'Analytics Hub';
    if (location.startsWith('/profile')) title = 'Profile Settings';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showSidebar) AppSidebar(currentRoute: location),
            Expanded(
              child: Column(
                children: [
                  AppTopBar(title: title),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !showSidebar
          ? SafeArea(
              top: false,
              child: AppBottomNav(currentRoute: location),
            )
          : null,
    );
  }
}

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return ShellLayout(
          location: state.uri.toString(),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/units',
          builder: (context, state) => const UnitsListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return UnitDetailScreen(unitId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/visits',
          builder: (context, state) => const VisitsListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const StartVisitScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/attendance',
          builder: (context, state) => const AttendanceScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const NewReportScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/referrals',
          builder: (context, state) => const ReferralsListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const NewReferralScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryScreen(),
        ),
        GoRoute(
          path: '/alerts',
          builder: (context, state) => const AlertsScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileSettingsScreen(),
        ),
      ],
    ),
  ],
);
