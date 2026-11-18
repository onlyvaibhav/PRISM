/// Notification Info Model
///
/// Data model for notification metadata from messaging apps.
/// Does NOT store message content - only metadata for mood analysis.
library;

/// Represents metadata from an incoming notification
class NotificationInfo {
  /// Package name of the source app
  final String packageName;

  /// Display name of the app (e.g., "WhatsApp", "Messages")
  final String appName;

  /// Timestamp when notification was received
  final DateTime timestamp;

  /// Category of the app (messaging, sms, social, work)
  final String category;

  /// Notification priority level
  final int priority;

  const NotificationInfo({
    required this.packageName,
    required this.appName,
    required this.timestamp,
    required this.category,
    required this.priority,
  });

  /// Create from platform channel map
  factory NotificationInfo.fromMap(Map<dynamic, dynamic> map) {
    return NotificationInfo(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? 0,
      ),
      category: map['category'] as String? ?? 'other',
      priority: (map['priority'] as int?) ?? 0,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'category': category,
      'priority': priority,
    };
  }

  /// Check if this is from a messaging app
  bool get isMessagingApp => category == 'messaging' || category == 'sms';

  /// Check if this is from a social app
  bool get isSocialApp => category == 'social';

  /// Check if this is from a work app
  bool get isWorkApp => category == 'work';

  @override
  String toString() {
    return 'NotificationInfo(app: $appName, category: $category, time: $timestamp)';
  }
}
