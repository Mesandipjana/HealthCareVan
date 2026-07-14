import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/alerts/presentation/providers/alerts_provider.dart';
import 'app_logo.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData iconSelected;
  final String route;
  final List<String> roles;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.iconSelected,
    required this.route,
    required this.roles,
  });
}

const _navItems = [
  _NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    iconSelected: Icons.dashboard,
    route: '/dashboard',
    roles: ['admin', 'coordinator', 'supervisor', 'officer'],
  ),
  _NavItem(
    label: 'Mobile Units',
    icon: Icons.directions_bus_outlined,
    iconSelected: Icons.directions_bus,
    route: '/units',
    roles: ['admin', 'coordinator', 'supervisor'],
  ),
  _NavItem(
    label: 'Field Visits',
    icon: Icons.map_outlined,
    iconSelected: Icons.map,
    route: '/visits',
    roles: ['admin', 'coordinator', 'supervisor', 'officer'],
  ),
  _NavItem(
    label: 'Attendance',
    icon: Icons.how_to_reg_outlined,
    iconSelected: Icons.how_to_reg,
    route: '/attendance',
    roles: ['admin', 'supervisor', 'officer'],
  ),
  _NavItem(
    label: 'Service Reports',
    icon: Icons.assignment_outlined,
    iconSelected: Icons.assignment,
    route: '/reports',
    roles: ['admin', 'coordinator', 'supervisor', 'officer'],
  ),
  _NavItem(
    label: 'Referrals',
    icon: Icons.transfer_within_a_station_outlined,
    iconSelected: Icons.transfer_within_a_station,
    route: '/referrals',
    roles: ['admin', 'coordinator', 'supervisor', 'officer'],
  ),
  _NavItem(
    label: 'Inventory',
    icon: Icons.inventory_2_outlined,
    iconSelected: Icons.inventory_2,
    route: '/inventory',
    roles: ['admin', 'coordinator', 'supervisor', 'officer'],
  ),
  _NavItem(
    label: 'Alerts',
    icon: Icons.notifications_outlined,
    iconSelected: Icons.notifications,
    route: '/alerts',
    roles: ['admin', 'coordinator', 'supervisor'],
  ),
  _NavItem(
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    iconSelected: Icons.analytics,
    route: '/analytics',
    roles: ['admin', 'coordinator'],
  ),
  _NavItem(
    label: 'Profile',
    icon: Icons.manage_accounts_outlined,
    iconSelected: Icons.manage_accounts,
    route: '/profile',
    roles: ['admin', 'coordinator', 'supervisor', 'officer'],
  ),
];

class AppSidebar extends ConsumerWidget {
  final String currentRoute;

  const AppSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);
    final role = user?.role ?? '';

    final allowedItems =
        _navItems.where((item) => item.roles.contains(role)).toList();

    return Container(
      width: 240,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                const AppLogoMark(size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HealthOps',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Operations Platform',
                        style: GoogleFonts.inter(
                          color: AppColors.sidebarText,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                _buildSectionLabel('MAIN MENU'),
                const SizedBox(height: 4),
                ...allowedItems.map((item) {
                  final isSelected = currentRoute.startsWith(item.route);
                  final showBadge = item.route == '/alerts' && unreadAlerts > 0;
                  return _buildNavItem(
                    context,
                    item: item,
                    isSelected: isSelected,
                    badge: showBadge ? unreadAlerts : null,
                    onTap: () => context.go(item.route),
                  );
                }),
              ],
            ),
          ),

          // Bottom: User Info
          if (user != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.avatarInitials,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.roleLabel,
                          style: GoogleFonts.inter(
                            color: AppColors.sidebarText,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout,
                        color: AppColors.sidebarText, size: 18),
                    tooltip: 'Sign Out',
                    onPressed: () {
                      ref.read(authProvider.notifier).signOut();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 6, top: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.sidebarText.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required _NavItem item,
    required bool isSelected,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.sidebarSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.iconSelected : item.icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.sidebarIconActive
                      : AppColors.sidebarIcon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.sidebarTextActive
                          : AppColors.sidebarText,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge.toString(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Bottom navigation for mobile
class AppBottomNav extends ConsumerWidget {
  final String currentRoute;

  const AppBottomNav({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = user?.role ?? '';
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);

    final allowedItems =
        _navItems.where((item) => item.roles.contains(role)).toList();
    final visibleItems = allowedItems.take(4).toList();
    final overflowItems = allowedItems.skip(4).toList();

    int selectedIndex = visibleItems.indexWhere(
      (item) => currentRoute.startsWith(item.route),
    );
    if (selectedIndex < 0 &&
        overflowItems.any((item) => currentRoute.startsWith(item.route))) {
      selectedIndex = visibleItems.length;
    }
    if (selectedIndex < 0) selectedIndex = 0;

    return NavigationBar(
      selectedIndex: selectedIndex.clamp(0, visibleItems.length),
      onDestinationSelected: (i) {
        if (i < visibleItems.length) {
          context.go(visibleItems[i].route);
          return;
        }
        showModalBottomSheet<void>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: overflowItems
                  .map(
                    (item) => ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.route);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
      backgroundColor: Colors.white,
      elevation: 8,
      destinations: [
        ...visibleItems.map((item) {
          final showBadge = item.route == '/alerts' && unreadAlerts > 0;
          return NavigationDestination(
            icon: Badge(
              isLabelVisible: showBadge,
              label: Text(unreadAlerts.toString()),
              child: Icon(item.icon),
            ),
            selectedIcon: Icon(item.iconSelected),
            label: item.label,
          );
        }),
        NavigationDestination(
          icon: Badge(
            isLabelVisible:
                overflowItems.any((item) => item.route == '/alerts') &&
                    unreadAlerts > 0,
            label: Text(unreadAlerts.toString()),
            child: const Icon(Icons.more_horiz),
          ),
          selectedIcon: const Icon(Icons.more),
          label: 'More',
        ),
      ],
    );
  }
}
