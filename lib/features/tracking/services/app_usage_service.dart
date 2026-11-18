import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/app_usage_info.dart';

class AppUsageService {
  static const MethodChannel _platform =
      MethodChannel('com.prism.app/settings');

  /// Fetches app usage stats for the given time range.
  /// [start] and [end] are DateTime objects.
  Future<List<AppUsageInfo>> getAppUsage(DateTime start, DateTime end) async {
    try {
      final List<dynamic>? result = await _platform.invokeMethod(
        'getAppUsageStats',
        {
          'start': start.millisecondsSinceEpoch,
          'end': end.millisecondsSinceEpoch,
        },
      );

      if (result == null) return [];

      return result
          .cast<Map<dynamic, dynamic>>()
          .map((map) => AppUsageInfo.fromMap(map))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('Failed to get app usage: ${e.message}');
      return [];
    }
  }

  /// Helper to get usage for the last 24 hours
  Future<List<AppUsageInfo>> getDailyUsage() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));
    return getAppUsage(start, now);
  }
}
