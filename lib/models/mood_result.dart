/// Mood Result Model
///
/// Data model for mood prediction output from the AI Mood Engine.
/// Contains mental health score, predicted mood label, and confidence level.
library;

/// Represents the result of mood prediction
class MoodResult {
  /// Mental health score (0-100)
  final int score;

  /// Predicted mood label
  final MoodLabel mood;

  /// Confidence level (0.0 - 1.0)
  final double confidence;

  /// Timestamp of prediction
  final DateTime timestamp;

  /// Optional breakdown of contributing factors
  final Map<String, double>? factors;

  const MoodResult({
    required this.score,
    required this.mood,
    required this.confidence,
    required this.timestamp,
    this.factors,
  });

  /// Create a default/empty result
  factory MoodResult.empty() {
    return MoodResult(
      score: 75,
      mood: MoodLabel.neutral,
      confidence: 0.0,
      timestamp: DateTime.now(),
    );
  }

  /// Create from a calculated score
  factory MoodResult.fromScore(
    int score, {
    double confidence = 0.5,
    Map<String, double>? factors,
  }) {
    return MoodResult(
      score: score.clamp(0, 100),
      mood: MoodLabel.fromScore(score),
      confidence: confidence.clamp(0.0, 1.0),
      timestamp: DateTime.now(),
      factors: factors,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'mood': mood.name,
      'confidence': confidence,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (factors != null) 'factors': factors,
    };
  }

  /// Create from stored map
  factory MoodResult.fromMap(Map<String, dynamic> map) {
    return MoodResult(
      score: map['score'] as int? ?? 75,
      mood: MoodLabel.values.firstWhere(
        (m) => m.name == map['mood'],
        orElse: () => MoodLabel.neutral,
      ),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      factors: map['factors'] != null
          ? Map<String, double>.from(map['factors'] as Map)
          : null,
    );
  }

  /// Get a user-friendly message based on score
  String get message {
    if (score >= 80) return 'Great progress! Keep up the good work.';
    if (score >= 60) return 'You\'re doing well. Stay mindful.';
    if (score >= 40) return 'Take a moment to relax and breathe.';
    if (score >= 20) return 'Consider taking a break from screens.';
    return 'It might help to step away and rest.';
  }

  /// Get the score change indicator text
  String getChangeText(int previousScore) {
    final diff = score - previousScore;
    if (diff > 0) return '+$diff%';
    if (diff < 0) return '$diff%';
    return '0%';
  }

  @override
  String toString() => 'MoodResult(score: $score, mood: ${mood.label})';
}

/// Mood labels with associated display properties
enum MoodLabel {
  happy(
    label: 'Happy & Relaxed',
    emoji: '😊',
    colorValue: 0xFF4CAF50, // Green
    minScore: 80,
  ),
  neutral(
    label: 'Neutral',
    emoji: '😐',
    colorValue: 0xFF5C6BC0, // Blue
    minScore: 60,
  ),
  stressed(
    label: 'Stressed',
    emoji: '😟',
    colorValue: 0xFFFF9800, // Orange
    minScore: 40,
  ),
  anxious(
    label: 'Anxious',
    emoji: '😰',
    colorValue: 0xFFE53935, // Red
    minScore: 20,
  ),
  veryLow(
    label: 'Very Low',
    emoji: '😢',
    colorValue: 0xFFB71C1C, // Dark Red
    minScore: 0,
  );

  final String label;
  final String emoji;
  final int colorValue;
  final int minScore;

  const MoodLabel({
    required this.label,
    required this.emoji,
    required this.colorValue,
    required this.minScore,
  });

  /// Get mood label from score
  static MoodLabel fromScore(int score) {
    if (score >= 80) return MoodLabel.happy;
    if (score >= 60) return MoodLabel.neutral;
    if (score >= 40) return MoodLabel.stressed;
    if (score >= 20) return MoodLabel.anxious;
    return MoodLabel.veryLow;
  }
}
