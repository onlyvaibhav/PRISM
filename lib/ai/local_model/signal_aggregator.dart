/// Signal Aggregator
///
/// Collects and normalizes behavioral signals from tracking services
/// for use in mood prediction.
library;

/// Aggregated behavioral signals for mood analysis
class BehavioralSignals {
  // App Usage Signals
  final Duration screenTime;
  final Duration lateNightUsage; // Usage after 11 PM
  final int appSwitchCount;

  // Typing Signals
  final double typingSpeed; // chars per second
  final double backspaceRate; // percentage
  final int pauseCount;

  // Notification Signals
  final int notificationCount;
  final double notificationsPerHour;
  final int messagingAppNotifications;

  const BehavioralSignals({
    this.screenTime = Duration.zero,
    this.lateNightUsage = Duration.zero,
    this.appSwitchCount = 0,
    this.typingSpeed = 0.0,
    this.backspaceRate = 0.0,
    this.pauseCount = 0,
    this.notificationCount = 0,
    this.notificationsPerHour = 0.0,
    this.messagingAppNotifications = 0,
  });

  /// Create empty signals (baseline)
  factory BehavioralSignals.empty() => const BehavioralSignals();

  /// Check if we have enough data to make a prediction
  bool get hasData =>
      screenTime > Duration.zero || notificationCount > 0 || typingSpeed > 0;

  /// Get screen time in hours
  double get screenTimeHours => screenTime.inMinutes / 60.0;

  /// Get late night usage in hours
  double get lateNightHours => lateNightUsage.inMinutes / 60.0;

  /// Get messaging notification ratio
  double get messagingRatio {
    if (notificationCount == 0) return 0;
    return messagingAppNotifications / notificationCount;
  }

  @override
  String toString() {
    return 'BehavioralSignals(screenTime: ${screenTimeHours.toStringAsFixed(1)}h, '
        'notifications: $notificationCount, typingSpeed: ${typingSpeed.toStringAsFixed(1)})';
  }
}

/// Normalizes raw signals to 0-100 scores
class SignalNormalizer {
  const SignalNormalizer();

  /// Normalize screen time (lower is better)
  /// <2h = 100, 2-4h = 75-50, 4-6h = 50-25, >6h = <25
  double normalizeScreenTime(Duration screenTime) {
    final hours = screenTime.inMinutes / 60.0;
    if (hours <= 2) return 100;
    if (hours <= 4) return 100 - ((hours - 2) * 25);
    if (hours <= 6) return 50 - ((hours - 4) * 12.5);
    return (25 - ((hours - 6) * 5)).clamp(0, 25);
  }

  /// Normalize late night usage (lower is better)
  /// 0 = 100, <30min = 75, <1h = 50, >1h = decreasing
  double normalizeLateNightUsage(Duration lateNightUsage) {
    final minutes = lateNightUsage.inMinutes;
    if (minutes == 0) return 100;
    if (minutes <= 30) return 75;
    if (minutes <= 60) return 50;
    return (50 - ((minutes - 60) * 0.5)).clamp(0, 50);
  }

  /// Normalize typing speed variance (stable is better)
  /// Baseline around 3-5 chars/sec is considered normal
  double normalizeTypingSpeed(double speed) {
    if (speed <= 0) return 75; // No data, neutral
    if (speed >= 3 && speed <= 6) return 100; // Optimal range
    if (speed < 3) return 60 + (speed * 10); // Slow typing
    return (100 - ((speed - 6) * 10)).clamp(30, 100); // Fast typing
  }

  /// Normalize backspace rate (lower is better)
  /// <5% = 100, 5-10% = 75-50, 10-20% = 50-25, >20% = <25
  double normalizeBackspaceRate(double rate) {
    if (rate <= 5) return 100;
    if (rate <= 10) return 100 - ((rate - 5) * 10);
    if (rate <= 20) return 50 - ((rate - 10) * 2.5);
    return (25 - ((rate - 20) * 1)).clamp(0, 25);
  }

  /// Normalize notification frequency (moderate is better)
  /// <5/hr = 100, 5-15/hr = 85-60, 15-25/hr = 60-40, >25 = decreasing
  double normalizeNotificationFrequency(double perHour) {
    if (perHour <= 5) return 100;
    if (perHour <= 15) return 100 - ((perHour - 5) * 4);
    if (perHour <= 25) return 60 - ((perHour - 15) * 2);
    return (40 - ((perHour - 25) * 2)).clamp(0, 40);
  }

  /// Normalize all signals and return individual scores
  Map<String, double> normalizeAll(BehavioralSignals signals) {
    return {
      'screenTime': normalizeScreenTime(signals.screenTime),
      'lateNightUsage': normalizeLateNightUsage(signals.lateNightUsage),
      'typingSpeed': normalizeTypingSpeed(signals.typingSpeed),
      'backspaceRate': normalizeBackspaceRate(signals.backspaceRate),
      'notificationFrequency':
          normalizeNotificationFrequency(signals.notificationsPerHour),
    };
  }
}
