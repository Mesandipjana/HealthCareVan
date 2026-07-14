import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Blue Palette
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primarySurface = Color(0xFFE3F2FD);

  // Secondary / Accent
  static const Color secondary = Color(0xFF0288D1);
  static const Color secondaryLight = Color(0xFF29B6F6);

  // Background & Surface
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF718096);
  static const Color textDisabled = Color(0xFFCBD5E0);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF276749);
  static const Color successBg = Color(0xFFE6FFFA);
  static const Color successLight = Color(0xFF38A169);

  static const Color warning = Color(0xFF744210);
  static const Color warningBg = Color(0xFFFEFCBF);
  static const Color warningLight = Color(0xFFD69E2E);

  static const Color error = Color(0xFF742A2A);
  static const Color errorBg = Color(0xFFFFF5F5);
  static const Color errorLight = Color(0xFFE53E3E);

  static const Color info = Color(0xFF2B6CB0);
  static const Color infoBg = Color(0xFFEBF8FF);
  static const Color infoLight = Color(0xFF3182CE);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF0F4F8);

  // Sidebar (dark blue)
  static const Color sidebarBg = Color(0xFF0F2044);
  static const Color sidebarHover = Color(0xFF1A3360);
  static const Color sidebarSelected = Color(0xFF1E40AF);
  static const Color sidebarText = Color(0xFFCBD5E0);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarIcon = Color(0xFF718096);
  static const Color sidebarIconActive = Color(0xFF93C5FD);
  static const Color sidebarBadge = Color(0xFF3B82F6);

  // Role Badge Colors
  static const Color adminColor = Color(0xFF1565C0);
  static const Color adminBg = Color(0xFFDBEAFE);
  static const Color coordinatorColor = Color(0xFF276749);
  static const Color coordinatorBg = Color(0xFFD1FAE5);
  static const Color supervisorColor = Color(0xFF92400E);
  static const Color supervisorBg = Color(0xFFFDE68A);
  static const Color officerColor = Color(0xFF553C9A);
  static const Color officerBg = Color(0xFFEDE9FE);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
  ];

  // KPI Card Accent Colors
  static const Color kpiBlue = Color(0xFF3B82F6);
  static const Color kpiBlueBg = Color(0xFFEFF6FF);
  static const Color kpiGreen = Color(0xFF10B981);
  static const Color kpiGreenBg = Color(0xFFECFDF5);
  static const Color kpiOrange = Color(0xFFF59E0B);
  static const Color kpiOrangeBg = Color(0xFFFFFBEB);
  static const Color kpiPurple = Color(0xFF8B5CF6);
  static const Color kpiPurpleBg = Color(0xFFF5F3FF);
  static const Color kpiRed = Color(0xFFEF4444);
  static const Color kpiRedBg = Color(0xFFFEF2F2);
  static const Color kpiTeal = Color(0xFF06B6D4);
  static const Color kpiTealBg = Color(0xFFECFEFF);
}
