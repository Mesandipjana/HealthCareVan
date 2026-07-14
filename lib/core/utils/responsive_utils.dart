import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ResponsiveUtils {
  ResponsiveUtils._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppConstants.mobileBreakpoint &&
        width < AppConstants.desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;

  static bool showSidebar(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.tabletBreakpoint;

  static double contentPadding(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }

  static int kpiGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 4;
    if (width >= 1100) return 4;
    if (width >= AppConstants.desktopBreakpoint) return 4;
    if (width >= AppConstants.tabletBreakpoint) return 2;
    if (width >= AppConstants.mobileBreakpoint) return 2;
    return 1;
  }

  static int chartGridColumns(BuildContext context) {
    if (isDesktop(context)) return 2;
    return 1;
  }

  static int unitGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 4;
    if (width >= AppConstants.desktopBreakpoint) return 3;
    if (width >= AppConstants.tabletBreakpoint) return 2;
    return 1;
  }

  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }
}
