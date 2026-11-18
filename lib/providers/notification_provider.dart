/// Notification Provider
///
/// Riverpod provider for managing notification tracking state.
/// Exposes notification counts and patterns for the dashboard.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/tracking/models/notification_info.dart';
import '../features/tracking/services/notification_service.dart';

/// State class for notification tracking
class NotificationTrackingState {
  /// Total notifications received today
  final int todayCount;

  /// Notifications per hour rate
  final double notificationsPerHour;

  /// Count by app name
  final Map<String, int> countByApp;

  /// Count by category (messaging, social, work, etc.)
  final Map<String, int> countByCategory;

  /// Most recent notifications
  final List<NotificationInfo> recentNotifications;

  /// Whether the listener is active
  final bool isListening;

  const NotificationTrackingState({
    this.todayCount = 0,
    this.notificationsPerHour = 0.0,
    this.countByApp = const {},
    this.countByCategory = const {},
    this.recentNotifications = const [],
    this.isListening = false,
  });

  NotificationTrackingState copyWith({
    int? todayCount,
    double? notificationsPerHour,
    Map<String, int>? countByApp,
    Map<String, int>? countByCategory,
    List<NotificationInfo>? recentNotifications,
    bool? isListening,
  }) {
    return NotificationTrackingState(
      todayCount: todayCount ?? this.todayCount,
      notificationsPerHour: notificationsPerHour ?? this.notificationsPerHour,
      countByApp: countByApp ?? this.countByApp,
      countByCategory: countByCategory ?? this.countByCategory,
      recentNotifications: recentNotifications ?? this.recentNotifications,
      isListening: isListening ?? this.isListening,
    );
  }

  /// Get most active app
  String get mostActiveApp {
    if (countByApp.isEmpty) return 'None';
    return countByApp.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get messaging notification count
  int get messagingCount => countByCategory['messaging'] ?? 0;

  /// Get social notification count
  int get socialCount => countByCategory['social'] ?? 0;
}

/// Notifier for notification tracking state
class NotificationTrackingNotifier
    extends StateNotifier<NotificationTrackingState> {
  final NotificationService _service;
  StreamSubscription<NotificationInfo>? _subscription;

  NotificationTrackingNotifier(this._service)
      : super(const NotificationTrackingState());

  /// Start listening to notification events
  void startListening() {
    if (state.isListening) return;

    _subscription = _service.notificationInfoStream.listen(
      _onNotification,
      onError: (error) {
        debugPrint('NotificationTrackingNotifier: Error - $error');
      },
    );

    state = state.copyWith(isListening: true);
    debugPrint('NotificationTrackingNotifier: Started listening');
  }

  /// Stop listening to notification events
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(isListening: false);
    debugPrint('NotificationTrackingNotifier: Stopped listening');
  }

  void _onNotification(NotificationInfo info) {
    debugPrint('NotificationTrackingNotifier: Received - $info');

    // Update counts
    final newCountByApp = Map<String, int>.from(state.countByApp);
    newCountByApp[info.appName] = (newCountByApp[info.appName] ?? 0) + 1;

    final newCountByCategory = Map<String, int>.from(state.countByCategory);
    newCountByCategory[info.category] =
        (newCountByCategory[info.category] ?? 0) + 1;

    // Add to recent notifications (keep last 20)
    final recentList = [info, ...state.recentNotifications];
    if (recentList.length > 20) {
      recentList.removeLast();
    }

    // Calculate new rate
    final hourlyRate = _service.getNotificationsPerHour(
      since: const Duration(hours: 1),
    );

    state = state.copyWith(
      todayCount: state.todayCount + 1,
      notificationsPerHour: hourlyRate,
      countByApp: newCountByApp,
      countByCategory: newCountByCategory,
      recentNotifications: recentList,
    );
  }

  /// Reset daily counts (call at midnight or on app start)
  void resetDailyCounts() {
    state = state.copyWith(
      todayCount: 0,
      countByApp: {},
      countByCategory: {},
      recentNotifications: [],
    );
    _service.clearNotifications();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

/// Service provider (singleton)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// State provider for notification tracking
final notificationTrackingProvider = StateNotifierProvider<
    NotificationTrackingNotifier, NotificationTrackingState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationTrackingNotifier(service);
});
