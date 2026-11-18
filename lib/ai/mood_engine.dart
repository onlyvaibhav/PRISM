/// Mood Engine
///
/// Core mood prediction engine that combines behavioral signals
/// with weighted scoring to produce mental health scores and mood predictions.
library;

import '../models/mood_result.dart';
import 'local_model/signal_aggregator.dart';

/// Weights for different signal categories in mood calculation
class MoodWeights {
  /// Screen time weight (25%)
  static const double screenTime = 0.25;

  /// Late night usage weight (15%)
  static const double lateNightUsage = 0.15;

  /// Typing patterns weight (20%)
  static const double typingPatterns = 0.20;

  /// Backspace/correction rate weight (15%)
  static const double backspaceRate = 0.15;

  /// Notification frequency weight (15%)
  static const double notificationFrequency = 0.15;

  /// Messaging app ratio weight (10%)
  static const double messagingRatio = 0.10;
}

/// Core mood prediction engine
class MoodEngine {
  final SignalNormalizer _normalizer;

  /// Create mood engine with optional custom normalizer
  MoodEngine({SignalNormalizer? normalizer})
      : _normalizer = normalizer ?? const SignalNormalizer();

  /// Calculate mood from behavioral signals
  MoodResult calculateMood(BehavioralSignals signals) {
    // If no data, return baseline
    if (!signals.hasData) {
      return MoodResult.fromScore(
        75, // Baseline neutral-positive
        confidence: 0.0,
        factors: {'baseline': 75},
      );
    }

    // Normalize all signals to 0-100 scores
    final normalizedScores = _normalizer.normalizeAll(signals);

    // Calculate weighted score
    final weightedScore = _calculateWeightedScore(normalizedScores, signals);

    // Calculate confidence based on data availability
    final confidence = _calculateConfidence(signals);

    // Round to integer score
    final finalScore = weightedScore.round().clamp(0, 100);

    return MoodResult.fromScore(
      finalScore,
      confidence: confidence,
      factors: normalizedScores,
    );
  }

  double _calculateWeightedScore(
    Map<String, double> normalizedScores,
    BehavioralSignals signals,
  ) {
    double totalWeight = 0;
    double weightedSum = 0;

    // Screen time
    if (signals.screenTime > Duration.zero) {
      final score = normalizedScores['screenTime'] ?? 75;
      weightedSum += score * MoodWeights.screenTime;
      totalWeight += MoodWeights.screenTime;
    }

    // Late night usage
    if (signals.screenTime > Duration.zero) {
      final score = normalizedScores['lateNightUsage'] ?? 75;
      weightedSum += score * MoodWeights.lateNightUsage;
      totalWeight += MoodWeights.lateNightUsage;
    }

    // Typing speed
    if (signals.typingSpeed > 0) {
      final score = normalizedScores['typingSpeed'] ?? 75;
      weightedSum += score * MoodWeights.typingPatterns;
      totalWeight += MoodWeights.typingPatterns;
    }

    // Backspace rate
    if (signals.typingSpeed > 0) {
      final score = normalizedScores['backspaceRate'] ?? 75;
      weightedSum += score * MoodWeights.backspaceRate;
      totalWeight += MoodWeights.backspaceRate;
    }

    // Notification frequency
    if (signals.notificationCount > 0) {
      final score = normalizedScores['notificationFrequency'] ?? 75;
      weightedSum += score * MoodWeights.notificationFrequency;
      totalWeight += MoodWeights.notificationFrequency;

      // Messaging ratio (only if we have notifications)
      final messagingScore = _normalizeMessagingRatio(signals.messagingRatio);
      weightedSum += messagingScore * MoodWeights.messagingRatio;
      totalWeight += MoodWeights.messagingRatio;
    }

    // Avoid division by zero
    if (totalWeight == 0) return 75;

    return weightedSum / totalWeight;
  }

  /// Normalize messaging app ratio (balanced is better)
  double _normalizeMessagingRatio(double ratio) {
    // 30-50% messaging is considered healthy balance
    if (ratio >= 0.3 && ratio <= 0.5) return 100;
    if (ratio < 0.3) return 70 + (ratio * 100); // Low messaging
    return (100 - ((ratio - 0.5) * 100)).clamp(30, 100); // High messaging
  }

  /// Calculate confidence based on how much data we have
  double _calculateConfidence(BehavioralSignals signals) {
    int dataPoints = 0;
    int maxPoints = 6;

    if (signals.screenTime > Duration.zero) dataPoints++;
    if (signals.lateNightUsage > Duration.zero) dataPoints++;
    if (signals.typingSpeed > 0) dataPoints++;
    if (signals.backspaceRate > 0) dataPoints++;
    if (signals.notificationCount > 0) dataPoints++;
    if (signals.appSwitchCount > 0) dataPoints++;

    // Minimum confidence of 0.3 if we have any data
    if (dataPoints == 0) return 0.0;
    return 0.3 + (0.7 * (dataPoints / maxPoints));
  }

  /// Get a trend indicator comparing two results
  MoodTrend getTrend(MoodResult current, MoodResult? previous) {
    if (previous == null) return MoodTrend.stable;

    final diff = current.score - previous.score;
    if (diff > 5) return MoodTrend.improving;
    if (diff < -5) return MoodTrend.declining;
    return MoodTrend.stable;
  }
}

/// Mood trend indicator
enum MoodTrend {
  improving,
  stable,
  declining;

  String get label {
    switch (this) {
      case MoodTrend.improving:
        return 'Improving';
      case MoodTrend.stable:
        return 'Stable';
      case MoodTrend.declining:
        return 'Declining';
    }
  }

  String get emoji {
    switch (this) {
      case MoodTrend.improving:
        return '📈';
      case MoodTrend.stable:
        return '➡️';
      case MoodTrend.declining:
        return '📉';
    }
  }
}
