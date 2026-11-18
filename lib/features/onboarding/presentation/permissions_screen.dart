/// Permissions Setup Screen
///
/// Screen for requesting all required permissions using native Android dialogs.
/// Permissions: Push Notifications, Accessibility, Notification Listener, Usage Access
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/theme_constants.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../providers/permission_provider.dart';

/// Permissions screen for requesting user consent
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with WidgetsBindingObserver {
  /// Check if this is being accessed from dashboard (already completed onboarding)
  bool get _isFromDashboard => PermissionService.isOnboardingCompleted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh permission states when app resumes from settings
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionProvider.notifier).refresh();
    }
  }

  Future<void> _handlePushNotification() async {
    final notifier = ref.read(permissionProvider.notifier);
    await notifier.requestPushNotification();
  }

  Future<void> _handleAccessibility() async {
    final notifier = ref.read(permissionProvider.notifier);
    await notifier.openAccessibilitySettings();
  }

  Future<void> _handleNotificationListener() async {
    final notifier = ref.read(permissionProvider.notifier);
    await notifier.openNotificationListenerSettings();
  }

  Future<void> _handleUsageAccess() async {
    final notifier = ref.read(permissionProvider.notifier);
    await notifier.openUsageAccessSettings();
  }

  void _proceedToDashboard() {
    if (!PermissionService.isOnboardingCompleted) {
      ref.read(permissionProvider.notifier).completeOnboarding();
    }

    // If accessed from dashboard, pop back; otherwise replace navigation
    if (_isFromDashboard && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(permissionProvider);
    final canProceed = permissionState.hasAllPermissions;

    return Scaffold(
      backgroundColor: PrismColors.background,
      body: SafeArea(
        child: permissionState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: PrismColors.primary),
              )
            : Padding(
                padding: const EdgeInsets.all(PrismSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button (only when from dashboard)
                    if (_isFromDashboard) ...[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: PrismColors.textPrimary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: PrismSpacing.md),
                    ] else ...[
                      const SizedBox(height: PrismSpacing.md),
                    ],

                    // Header
                    Text(
                      _isFromDashboard
                          ? 'Fix Permissions'
                          : 'Setup Permissions',
                      style: PrismTypography.headlineLarge.copyWith(
                        color: PrismColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: PrismSpacing.sm),

                    Text(
                      _isFromDashboard
                          ? 'Some permissions were revoked. Please re-enable them.'
                          : 'PRISM needs these permissions to track your mental wellness.',
                      style: PrismTypography.bodyMedium.copyWith(
                        color: PrismColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: PrismSpacing.lg),

                    // Permission Cards - Scrollable
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // 1. Push Notifications
                            _PermissionCard(
                              icon: Icons.notifications_active_rounded,
                              title: 'Push Notifications',
                              description:
                                  'Receive daily wellness reminders and insights.',
                              isGranted:
                                  permissionState.pushNotificationGranted,
                              isRequired: false,
                              onTap: _handlePushNotification,
                            ),

                            const SizedBox(height: PrismSpacing.md),

                            // 2. Accessibility Service
                            _PermissionCard(
                              icon: Icons.accessibility_new_rounded,
                              title: 'Accessibility Service',
                              description:
                                  'Analyze typing patterns to detect mood changes. No text is stored.',
                              isGranted: permissionState.accessibilityEnabled,
                              isRequired: true,
                              onTap: _handleAccessibility,
                            ),

                            const SizedBox(height: PrismSpacing.md),

                            // 3. Notification Listener
                            _PermissionCard(
                              icon: Icons.chat_bubble_rounded,
                              title: 'Notification Listener',
                              description:
                                  'Read notification sentiment. Messages are never stored.',
                              isGranted:
                                  permissionState.notificationListenerEnabled,
                              isRequired: true,
                              onTap: _handleNotificationListener,
                            ),

                            const SizedBox(height: PrismSpacing.md),

                            // 4. App Usage Access
                            _PermissionCard(
                              icon: Icons.bar_chart_rounded,
                              title: 'App Usage Access',
                              description:
                                  'Monitor app usage patterns to understand your habits.',
                              isGranted: permissionState.usageAccessGranted,
                              isRequired: true,
                              onTap: _handleUsageAccess,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: PrismSpacing.md),

                    // Privacy notice
                    Container(
                      padding: const EdgeInsets.all(PrismSpacing.md),
                      decoration: BoxDecoration(
                        color: PrismColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(PrismRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            color: PrismColors.moodHappy,
                            size: 20,
                          ),
                          const SizedBox(width: PrismSpacing.sm),
                          Expanded(
                            child: Text(
                              'All data stays on your device. Please grant all permissions to continue.',
                              style: PrismTypography.labelSmall.copyWith(
                                color: PrismColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: PrismSpacing.md),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: canProceed ? _proceedToDashboard : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canProceed
                              ? PrismColors.primary
                              : PrismColors.surfaceVariant,
                          foregroundColor: canProceed
                              ? PrismColors.background
                              : PrismColors.textHint,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(PrismRadius.md),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: PrismTypography.titleMedium.copyWith(
                            color: canProceed
                                ? PrismColors.background
                                : PrismColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: PrismSpacing.md),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Permission card with native action
class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final bool isRequired;
  final VoidCallback onTap;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.isRequired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isGranted ? null : onTap,
      borderRadius: BorderRadius.circular(PrismRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(PrismSpacing.md),
        decoration: BoxDecoration(
          color: PrismColors.surface,
          borderRadius: BorderRadius.circular(PrismRadius.lg),
          border: Border.all(
            color:
                isGranted ? PrismColors.moodHappy : PrismColors.surfaceVariant,
            width: isGranted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isGranted
                    ? PrismColors.moodHappy.withAlpha(25)
                    : PrismColors.surfaceVariant,
                borderRadius: BorderRadius.circular(PrismRadius.md),
              ),
              child: Icon(
                icon,
                color: isGranted
                    ? PrismColors.moodHappy
                    : PrismColors.textSecondary,
                size: 22,
              ),
            ),

            const SizedBox(width: PrismSpacing.md),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: PrismTypography.titleSmall.copyWith(
                          color: PrismColors.textPrimary,
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: PrismSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PrismColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required',
                            style: PrismTypography.labelSmall.copyWith(
                              color: PrismColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: PrismTypography.bodySmall.copyWith(
                      color: PrismColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: PrismSpacing.sm),

            // Status icon
            Icon(
              isGranted
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: isGranted ? PrismColors.moodHappy : PrismColors.textHint,
              size: isGranted ? 24 : 16,
            ),
          ],
        ),
      ),
    );
  }
}
