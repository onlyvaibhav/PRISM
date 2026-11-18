/// PRISM Splash Screen
///
/// Calm animated startup screen with PRISM branding.
/// Auto-navigates to onboarding or dashboard based on completion status.
library;

import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/theme_constants.dart';
import '../../../core/permissions/permission_service.dart';

/// Splash screen with animated PRISM logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Pulse animation (subtle breathing effect)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() async {
    // Start fade and scale together
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();

    // Start pulse after initial animation
    await Future.delayed(const Duration(milliseconds: 600));
    _pulseController.repeat(reverse: true);

    // Navigate after showing splash for 3 seconds total
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      // Check if onboarding is already completed
      final route = PermissionService.isOnboardingCompleted
          ? AppRoutes.dashboard
          : AppRoutes.onboarding;
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrismColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _fadeController,
            _scaleController,
            _pulseController,
          ]),
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value * _pulseAnimation.value,
                child: child,
              ),
            );
          },
          child: const _SplashContent(),
        ),
      ),
    );
  }
}

/// Splash screen content with logo and app name
class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PrismColors.primary,
                PrismColors.primaryLight,
              ],
            ),
            borderRadius: BorderRadius.circular(PrismRadius.xl),
            boxShadow: [
              BoxShadow(
                color: PrismColors.primary.withAlpha(76),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.psychology_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: PrismSpacing.lg),

        // App Name
        Text(
          'PRISM',
          style: PrismTypography.displayLarge.copyWith(
            color: PrismColors.primary,
            letterSpacing: 4,
          ),
        ),

        const SizedBox(height: PrismSpacing.sm),

        // Tagline
        Text(
          'Your Mental Wellness Companion',
          style: PrismTypography.bodyLarge.copyWith(
            color: PrismColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
