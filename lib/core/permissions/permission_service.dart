/// Permission Service
///
/// Handles permission requests and opens system settings.
/// Tracks permission states using native Android checks via platform channel.
library;

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Keys for storing permission states
class PermissionKeys {
  PermissionKeys._();

  static const String boxName = 'permissions';
  static const String onboardingCompleted = 'onboarding_completed';
}

/// Platform channel for native settings and permission checks
const _settingsChannel = MethodChannel('com.prism.app/settings');

/// Service for managing app permissions
class PermissionService {
  static Box? _box;

  /// Initialize the permission service
  static Future<void> init() async {
    _box = await Hive.openBox(PermissionKeys.boxName);
  }

  /// Get the Hive box
  static Box get box {
    if (_box == null) {
      throw Exception('PermissionService not initialized. Call init() first.');
    }
    return _box!;
  }

  // --- Reset ---

  /// Reset all stored data (useful for testing)
  static Future<void> resetAllData() async {
    await box.clear();
  }

  // --- Push Notification Permission (Standard) ---

  /// Request push notification permission (native dialog)
  static Future<bool> requestPushNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check push notification permission status
  static Future<bool> isPushNotificationGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Open app notification settings
  static Future<bool> openAppNotificationSettings() async {
    try {
      await _settingsChannel.invokeMethod('openAppNotificationSettings');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Accessibility Permission (System Settings) ---

  /// Check if accessibility service is enabled
  static Future<bool> isAccessibilityEnabled() async {
    try {
      final result =
          await _settingsChannel.invokeMethod('isAccessibilityEnabled');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Open accessibility settings
  static Future<bool> openAccessibilitySettings() async {
    try {
      await _settingsChannel.invokeMethod('openAccessibilitySettings');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Notification Listener Permission (System Settings) ---

  /// Check if notification listener is enabled
  static Future<bool> isNotificationListenerEnabled() async {
    try {
      final result =
          await _settingsChannel.invokeMethod('isNotificationListenerEnabled');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Open notification listener settings
  static Future<bool> openNotificationListenerSettings() async {
    try {
      await _settingsChannel.invokeMethod('openNotificationListenerSettings');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- App Usage Permission (System Settings) ---

  /// Check if usage access is granted
  static Future<bool> isUsageAccessGranted() async {
    try {
      final result =
          await _settingsChannel.invokeMethod('isUsageAccessGranted');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Open usage access settings
  static Future<bool> openUsageAccessSettings() async {
    try {
      await _settingsChannel.invokeMethod('openUsageAccessSettings');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Onboarding ---

  /// Check if onboarding is completed
  static bool get isOnboardingCompleted {
    return box.get(PermissionKeys.onboardingCompleted, defaultValue: false);
  }

  /// Set onboarding completed
  static Future<void> setOnboardingCompleted(bool value) async {
    await box.put(PermissionKeys.onboardingCompleted, value);
  }

  // --- Utility ---

  /// Check all permissions and return a map
  static Future<Map<String, bool>> checkAllPermissions() async {
    final results = await Future.wait([
      isPushNotificationGranted(),
      isAccessibilityEnabled(),
      isNotificationListenerEnabled(),
      isUsageAccessGranted(),
    ]);

    return {
      'pushNotification': results[0],
      'accessibility': results[1],
      'notificationListener': results[2],
      'usageAccess': results[3],
    };
  }
}
