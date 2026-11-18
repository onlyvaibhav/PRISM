/// Permission Provider
///
/// Riverpod provider for managing permission states reactively.
/// Uses native Android permission checks via platform channel.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permissions/permission_service.dart';

/// State class for all permissions
class PermissionState {
  final bool pushNotificationGranted;
  final bool accessibilityEnabled;
  final bool notificationListenerEnabled;
  final bool usageAccessGranted;
  final bool onboardingCompleted;
  final bool isLoading;

  const PermissionState({
    this.pushNotificationGranted = false,
    this.accessibilityEnabled = false,
    this.notificationListenerEnabled = false,
    this.usageAccessGranted = false,
    this.onboardingCompleted = false,
    this.isLoading = true,
  });

  /// Check if at least one tracking permission is enabled
  bool get hasAnyTrackingPermission =>
      accessibilityEnabled || notificationListenerEnabled || usageAccessGranted;

  /// Check if all core permissions are granted
  bool get hasAllPermissions =>
      pushNotificationGranted &&
      accessibilityEnabled &&
      notificationListenerEnabled &&
      usageAccessGranted;

  PermissionState copyWith({
    bool? pushNotificationGranted,
    bool? accessibilityEnabled,
    bool? notificationListenerEnabled,
    bool? usageAccessGranted,
    bool? onboardingCompleted,
    bool? isLoading,
  }) {
    return PermissionState(
      pushNotificationGranted:
          pushNotificationGranted ?? this.pushNotificationGranted,
      accessibilityEnabled: accessibilityEnabled ?? this.accessibilityEnabled,
      notificationListenerEnabled:
          notificationListenerEnabled ?? this.notificationListenerEnabled,
      usageAccessGranted: usageAccessGranted ?? this.usageAccessGranted,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for permission state management
class PermissionNotifier extends StateNotifier<PermissionState> {
  PermissionNotifier() : super(const PermissionState()) {
    _loadState();
  }

  /// Load permission states from native checks
  Future<void> _loadState() async {
    state = state.copyWith(isLoading: true);

    final permissions = await PermissionService.checkAllPermissions();

    state = PermissionState(
      pushNotificationGranted: permissions['pushNotification'] ?? false,
      accessibilityEnabled: permissions['accessibility'] ?? false,
      notificationListenerEnabled: permissions['notificationListener'] ?? false,
      usageAccessGranted: permissions['usageAccess'] ?? false,
      onboardingCompleted: PermissionService.isOnboardingCompleted,
      isLoading: false,
    );
  }

  /// Refresh all permission states
  Future<void> refresh() async {
    await _loadState();
  }

  /// Request push notification permission
  Future<bool> requestPushNotification() async {
    final granted = await PermissionService.requestPushNotificationPermission();
    state = state.copyWith(pushNotificationGranted: granted);
    return granted;
  }

  /// Open accessibility settings
  Future<void> openAccessibilitySettings() async {
    await PermissionService.openAccessibilitySettings();
  }

  /// Open notification listener settings
  Future<void> openNotificationListenerSettings() async {
    await PermissionService.openNotificationListenerSettings();
  }

  /// Open usage access settings
  Future<void> openUsageAccessSettings() async {
    await PermissionService.openUsageAccessSettings();
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    await PermissionService.setOnboardingCompleted(true);
    state = state.copyWith(onboardingCompleted: true);
  }
}

/// Provider for permission state
final permissionProvider =
    StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
  return PermissionNotifier();
});
