/// PRISM Route Generator
///
/// Handles route generation and navigation logic.
library;

import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/permissions_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import 'app_routes.dart';

/// Generates routes for the PRISM app
class RouteGenerator {
  RouteGenerator._();

  /// Generates a route based on the given [RouteSettings]
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);

      case AppRoutes.onboarding:
        return _buildRoute(const OnboardingScreen(), settings);

      case AppRoutes.permissions:
        return _buildRoute(const PermissionsScreen(), settings);

      case AppRoutes.dashboard:
        return _buildRoute(const DashboardScreen(), settings);

      case AppRoutes.insights:
        return _buildRoute(
          const _PlaceholderScreen(title: 'Insights'),
          settings,
        );

      case AppRoutes.history:
        return _buildRoute(
          const _PlaceholderScreen(title: 'History'),
          settings,
        );

      case AppRoutes.settings:
        return _buildRoute(
          const _PlaceholderScreen(title: 'Settings'),
          settings,
        );

      default:
        return _buildRoute(
          const _PlaceholderScreen(title: 'Not Found'),
          settings,
        );
    }
  }

  /// Builds a [MaterialPageRoute] with a smooth fade transition
  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}

/// Placeholder screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
