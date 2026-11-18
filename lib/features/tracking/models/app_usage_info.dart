class AppUsageInfo {
  final String packageName;
  final String appName; // Optional, requires package manager to fetch label
  final Duration usageDuration;
  final DateTime lastTimeUsed;

  AppUsageInfo({
    required this.packageName,
    this.appName = '',
    required this.usageDuration,
    required this.lastTimeUsed,
  });

  factory AppUsageInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppUsageInfo(
      packageName: map['packageName'] as String,
      usageDuration:
          Duration(milliseconds: map['totalTimeInForeground'] as int),
      lastTimeUsed:
          DateTime.fromMillisecondsSinceEpoch(map['lastTimeUsed'] as int),
    );
  }

  @override
  String toString() {
    return 'AppUsageInfo(pkg: $packageName, duration: ${usageDuration.inMinutes}m, last: $lastTimeUsed)';
  }
}
