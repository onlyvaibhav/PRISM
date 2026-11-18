/// PRISM App
///
/// Root MaterialApp widget with theme and routing configuration.
/// Checks onboarding status to determine initial route.
library;

import 'package:flutter/material.dart';

import '../core/permissions/permission_service.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'theme/prism_theme.dart';

/// Root widget for the PRISM application
class PrismApp extends StatelessWidget {
  const PrismApp({super.key});

  /// Determine initial route based on onboarding status
  String get _initialRoute {
    if (PermissionService.isOnboardingCompleted) {
      return AppRoutes.dashboard;
    }
    return AppRoutes.splash;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRISM',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: PrismTheme.darkTheme,

      // Routing - skip to dashboard if onboarding completed
      initialRoute: _initialRoute,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
