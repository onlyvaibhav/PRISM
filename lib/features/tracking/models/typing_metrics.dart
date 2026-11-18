/// Typing Metrics Model
///
/// Data model for typing behavioral patterns collected from the
/// accessibility service. Used for mood analysis.
///
/// Privacy: No raw text content is stored - only behavioral metrics.
library;

/// Represents a typing event or session metrics snapshot
class TypingEvent {
  final String eventType; // 'typing' or 'sessionEnd'
  final DateTime timestamp;
  final String packageName;
  final int lengthDelta;
  final bool isBackspace;

  // Session metrics
  final Duration sessionDuration;
  final int charCount;
  final int backspaceCount;
  final int pauseCount;

  // Calculated metrics
  final double typingSpeed; // chars per second
  final double backspaceRate; // corrections per 100 chars

  const TypingEvent({
    required this.eventType,
    required this.timestamp,
    required this.packageName,
    required this.lengthDelta,
    required this.isBackspace,
    required this.sessionDuration,
    required this.charCount,
    required this.backspaceCount,
    required this.pauseCount,
    required this.typingSpeed,
    required this.backspaceRate,
  });

  /// Create from EventChannel data
  factory TypingEvent.fromMap(Map<dynamic, dynamic> map) {
    return TypingEvent(
      eventType: map['eventType'] as String? ?? 'typing',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      packageName: map['packageName'] as String? ?? '',
      lengthDelta: map['lengthDelta'] as int? ?? 0,
      isBackspace: map['isBackspace'] as bool? ?? false,
      sessionDuration:
          Duration(milliseconds: map['sessionDurationMs'] as int? ?? 0),
      charCount: map['charCount'] as int? ?? 0,
      backspaceCount: map['backspaceCount'] as int? ?? 0,
      pauseCount: map['pauseCount'] as int? ?? 0,
      typingSpeed: (map['typingSpeed'] as num?)?.toDouble() ?? 0.0,
      backspaceRate: (map['backspaceRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Check if this is a session end event
  bool get isSessionEnd => eventType == 'sessionEnd';

  /// Get a behavioral assessment based on metrics
  TypingBehavior get behavior {
    // High backspace rate may indicate frustration or uncertainty
    if (backspaceRate > 30) {
      return TypingBehavior.erratic;
    }
    // Very slow typing with many pauses may indicate distraction or fatigue
    if (typingSpeed < 1.0 && pauseCount > 3) {
      return TypingBehavior.hesitant;
    }
    // Fast typing with low errors indicates focused state
    if (typingSpeed > 3.0 && backspaceRate < 10) {
      return TypingBehavior.focused;
    }
    // Normal typing pattern
    return TypingBehavior.normal;
  }

  @override
  String toString() {
    return 'TypingEvent($eventType, speed: ${typingSpeed.toStringAsFixed(1)} c/s, '
        'backspace: ${backspaceRate.toStringAsFixed(1)}%, pauses: $pauseCount)';
  }
}

/// Behavioral assessment based on typing patterns
enum TypingBehavior {
  /// Normal typing pattern
  normal,

  /// Fast, accurate typing - indicates focus
  focused,

  /// Slow typing with many pauses - indicates distraction or fatigue
  hesitant,

  /// High error rate - indicates frustration or stress
  erratic,
}

/// Aggregated typing metrics for a time period
class TypingMetricsSummary {
  final Duration totalTypingTime;
  final int totalCharacters;
  final int totalBackspaces;
  final int totalPauses;
  final double averageTypingSpeed;
  final double averageBackspaceRate;
  final int sessionCount;
  final DateTime periodStart;
  final DateTime periodEnd;

  const TypingMetricsSummary({
    required this.totalTypingTime,
    required this.totalCharacters,
    required this.totalBackspaces,
    required this.totalPauses,
    required this.averageTypingSpeed,
    required this.averageBackspaceRate,
    required this.sessionCount,
    required this.periodStart,
    required this.periodEnd,
  });

  /// Create an empty summary
  factory TypingMetricsSummary.empty() {
    final now = DateTime.now();
    return TypingMetricsSummary(
      totalTypingTime: Duration.zero,
      totalCharacters: 0,
      totalBackspaces: 0,
      totalPauses: 0,
      averageTypingSpeed: 0,
      averageBackspaceRate: 0,
      sessionCount: 0,
      periodStart: now,
      periodEnd: now,
    );
  }

  /// Calculate overall behavioral score (0-100, higher = more stable)
  double get behavioralScore {
    if (sessionCount == 0) return 50.0;

    // Lower backspace rate is better (max 50 points)
    final errorScore = (50 - (averageBackspaceRate / 2)).clamp(0, 50);

    // Moderate typing speed is ideal (max 30 points)
    // 2-4 chars/sec is optimal
    final speedScore = averageTypingSpeed >= 2 && averageTypingSpeed <= 4
        ? 30.0
        : (30 - (averageTypingSpeed - 3).abs() * 5).clamp(0, 30);

    // Fewer pauses per session is better (max 20 points)
    final pausesPerSession = totalPauses / sessionCount;
    final pauseScore = (20 - pausesPerSession * 2).clamp(0, 20);

    return (errorScore + speedScore + pauseScore).toDouble();
  }

  @override
  String toString() {
    return 'TypingMetricsSummary(sessions: $sessionCount, '
        'avgSpeed: ${averageTypingSpeed.toStringAsFixed(1)} c/s, '
        'score: ${behavioralScore.toStringAsFixed(0)})';
  }
}
