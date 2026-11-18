/// Notification Service
///
/// Flutter service to receive and process notification events from the
/// Android NotificationListenerService. Tracks notification patterns
/// from messaging apps for mood analysis.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/notification_info.dart';

/// Service for receiving notification events from Android
class NotificationService {
  static const EventChannel _eventChannel =
      EventChannel('com.prism.app/notification_events');

  Stream<dynamic>? _stream;

  // Notification tracking state
  final List<NotificationInfo> _recentNotifications = [];
  static const int _maxStoredNotifications = 100;

  /// Stream of raw notification events from Android
  Stream<dynamic> get notificationStream {
    _stream ??= _eventChannel.receiveBroadcastStream();
    return _stream!;
  }

  /// Stream of parsed NotificationInfo objects
  Stream<NotificationInfo> get notificationInfoStream {
    return notificationStream.map((event) {
      if (event is Map) {
        final info = NotificationInfo.fromMap(event);
        _addNotification(info);
        return info;
      }
      throw Exception('Invalid notification event format');
    });
  }

  void _addNotification(NotificationInfo info) {
    _recentNotifications.add(info);
    // Keep only recent notifications
    if (_recentNotifications.length > _maxStoredNotifications) {
      _recentNotifications.removeAt(0);
    }
  }

  /// Get notifications from the last N hours
  List<NotificationInfo> getNotificationsSince(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return _recentNotifications
        .where((n) => n.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Get notification count per app in the last N hours
  Map<String, int> getNotificationCountByApp({Duration? since}) {
    final notifications =
        since != null ? getNotificationsSince(since) : _recentNotifications;

    final counts = <String, int>{};
    for (final notification in notifications) {
      counts[notification.appName] = (counts[notification.appName] ?? 0) + 1;
    }
    return counts;
  }

  /// Get notification count per category
  Map<String, int> getNotificationCountByCategory({Duration? since}) {
    final notifications =
        since != null ? getNotificationsSince(since) : _recentNotifications;

    final counts = <String, int>{};
    for (final notification in notifications) {
      counts[notification.category] = (counts[notification.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Get total notification count for a time period
  int getTotalNotificationCount({Duration? since}) {
    if (since == null) return _recentNotifications.length;
    return getNotificationsSince(since).length;
  }

  /// Calculate notifications per hour for a time period
  double getNotificationsPerHour({Duration? since}) {
    final duration = since ?? const Duration(hours: 24);
    final count = getTotalNotificationCount(since: duration);
    final hours = duration.inMinutes / 60;
    return hours > 0 ? count / hours : 0;
  }

  /// Get all tracked notifications (for debugging)
  List<NotificationInfo> get allNotifications =>
      List.unmodifiable(_recentNotifications);

  /// Clear stored notifications
  void clearNotifications() {
    _recentNotifications.clear();
    debugPrint('NotificationService: Cleared all stored notifications');
  }
}
