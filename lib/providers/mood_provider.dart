/// Mood Provider
///
/// Riverpod provider for mood state management.
/// Combines signals from tracking services and runs mood engine.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/local_model/signal_aggregator.dart';
import '../ai/mood_engine.dart';
import '../features/tracking/services/app_usage_service.dart';
import '../models/mood_result.dart';
import 'notification_provider.dart';

/// State class for mood tracking
class MoodState {
  /// Current mood result
  final MoodResult currentMood;

  /// Previous mood for trend comparison
  final MoodResult? previousMood;

  /// Current behavioral signals
  final BehavioralSignals signals;

  /// Whether mood calculation is in progress
  final bool isCalculating;

  /// Last update timestamp
  final DateTime? lastUpdated;

  const MoodState({
    required this.currentMood,
    this.previousMood,
    this.signals = const BehavioralSignals(),
    this.isCalculating = false,
    this.lastUpdated,
  });

  MoodState copyWith({
    MoodResult? currentMood,
    MoodResult? previousMood,
    BehavioralSignals? signals,
    bool? isCalculating,
    DateTime? lastUpdated,
  }) {
    return MoodState(
      currentMood: currentMood ?? this.currentMood,
      previousMood: previousMood ?? this.previousMood,
      signals: signals ?? this.signals,
      isCalculating: isCalculating ?? this.isCalculating,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get mood trend
  MoodTrend get trend {
    if (previousMood == null) return MoodTrend.stable;
    final diff = currentMood.score - previousMood!.score;
    if (diff > 5) return MoodTrend.improving;
    if (diff < -5) return MoodTrend.declining;
    return MoodTrend.stable;
  }

  /// Get score change percentage text
  String get changeText {
    if (previousMood == null) return '+0%';
    return currentMood.getChangeText(previousMood!.score);
  }
}

/// Mood state notifier
class MoodNotifier extends StateNotifier<MoodState> {
  final MoodEngine _engine;
  final AppUsageService _appUsageService;
  final Ref _ref;
  Timer? _updateTimer;

  MoodNotifier(this._ref)
      : _engine = MoodEngine(),
        _appUsageService = AppUsageService(),
        super(MoodState(currentMood: MoodResult.empty()));

  /// Start periodic mood updates
  void startPeriodicUpdates({Duration interval = const Duration(minutes: 5)}) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(interval, (_) => calculateMood());
    // Calculate immediately on start
    calculateMood();
  }

  /// Stop periodic updates
  void stopPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Calculate mood from current signals
  Future<void> calculateMood() async {
    if (state.isCalculating) return;

    state = state.copyWith(isCalculating: true);

    try {
      // Gather signals from various sources
      final signals = await _gatherSignals();

      // Calculate mood using engine
      final newMood = _engine.calculateMood(signals);

      // Update state with new mood
      state = MoodState(
        currentMood: newMood,
        previousMood:
            state.currentMood.confidence > 0 ? state.currentMood : null,
        signals: signals,
        isCalculating: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint(
          'MoodNotifier: Calculated mood - Score: ${newMood.score}, Mood: ${newMood.mood.label}');
    } catch (e) {
      debugPrint('MoodNotifier: Error calculating mood - $e');
      state = state.copyWith(isCalculating: false);
    }
  }

  /// Gather behavioral signals from tracking services
  Future<BehavioralSignals> _gatherSignals() async {
    // Get app usage data
    Duration screenTime = Duration.zero;
    Duration lateNightUsage = Duration.zero;

    try {
      final usageList = await _appUsageService.getDailyUsage();
      for (final usage in usageList) {
        screenTime += usage.usageDuration;
      }
      // Estimate late night usage as 20% of total if after 11 PM
      final now = DateTime.now();
      if (now.hour >= 23 || now.hour < 6) {
        lateNightUsage = screenTime * 0.2;
      }
    } catch (e) {
      debugPrint('MoodNotifier: Error getting app usage - $e');
    }

    // Get notification data from provider
    final notificationState = _ref.read(notificationTrackingProvider);

    // TODO: Get typing data from typing service when implemented
    // For now using placeholder values
    const typingSpeed = 0.0;
    const backspaceRate = 0.0;

    return BehavioralSignals(
      screenTime: screenTime,
      lateNightUsage: lateNightUsage,
      typingSpeed: typingSpeed,
      backspaceRate: backspaceRate,
      notificationCount: notificationState.todayCount,
      notificationsPerHour: notificationState.notificationsPerHour,
      messagingAppNotifications: notificationState.messagingCount,
    );
  }

  /// Force recalculation with updated signals
  Future<void> refresh() async {
    await calculateMood();
  }

  @override
  void dispose() {
    stopPeriodicUpdates();
    super.dispose();
  }
}

/// Provider for mood engine (singleton)
final moodEngineProvider = Provider<MoodEngine>((ref) {
  return MoodEngine();
});

/// Provider for mood state
final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  return MoodNotifier(ref);
});
