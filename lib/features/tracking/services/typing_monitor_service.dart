/// Typing Monitor Service
///
/// Listens to typing events from the Android accessibility service
/// and provides processed metrics for mood analysis.
///
/// Privacy: Only behavioral patterns are tracked, no raw text content.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/typing_metrics.dart';

/// Service for monitoring typing patterns from the accessibility service
class TypingMonitorService {
  static const EventChannel _eventChannel =
      EventChannel('com.prism.app/typing_events');

  Stream<dynamic>? _rawStream;
  StreamController<TypingEvent>? _eventController;
  StreamSubscription<dynamic>? _subscription;

  // Session tracking
  final List<TypingEvent> _recentEvents = [];
  final List<TypingEvent> _completedSessions = [];
  static const int _maxRecentEvents = 100;
  static const int _maxCompletedSessions = 50;

  /// Stream of processed typing events
  Stream<TypingEvent> get typingEventStream {
    _eventController ??= StreamController<TypingEvent>.broadcast(
      onListen: _startListening,
      onCancel: _checkStopListening,
    );
    return _eventController!.stream;
  }

  /// Start listening to the raw event channel
  void _startListening() {
    if (_subscription != null) return;

    _rawStream ??= _eventChannel.receiveBroadcastStream();
    _subscription = _rawStream!.listen(
      _handleRawEvent,
      onError: (error) {
        debugPrint('TypingMonitorService error: $error');
      },
    );
    debugPrint('TypingMonitorService: Started listening');
  }

  /// Check if we should stop listening
  void _checkStopListening() {
    if (_eventController?.hasListener == false) {
      _subscription?.cancel();
      _subscription = null;
      debugPrint('TypingMonitorService: Stopped listening');
    }
  }

  /// Handle raw event from EventChannel
  void _handleRawEvent(dynamic data) {
    if (data is! Map) return;

    try {
      final event = TypingEvent.fromMap(data);
      _processEvent(event);
    } catch (e) {
      debugPrint('TypingMonitorService: Error parsing event: $e');
    }
  }

  /// Process and store the typing event
  void _processEvent(TypingEvent event) {
    // Add to recent events
    _recentEvents.add(event);
    if (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeAt(0);
    }

    // If session ended, store in completed sessions
    if (event.isSessionEnd) {
      _completedSessions.add(event);
      if (_completedSessions.length > _maxCompletedSessions) {
        _completedSessions.removeAt(0);
      }
      debugPrint('TypingMonitorService: Session completed - $event');
    }

    // Emit the event
    _eventController?.add(event);
  }

  /// Get the most recent typing event
  TypingEvent? get latestEvent =>
      _recentEvents.isNotEmpty ? _recentEvents.last : null;

  /// Get recent completed session metrics
  List<TypingEvent> get completedSessions =>
      List.unmodifiable(_completedSessions);

  /// Calculate aggregated metrics for a time period
  TypingMetricsSummary getSummary({Duration? period}) {
    final now = DateTime.now();
    final periodStart = period != null ? now.subtract(period) : null;

    // Filter sessions by time period
    final sessions = periodStart != null
        ? _completedSessions
            .where((s) => s.timestamp.isAfter(periodStart))
            .toList()
        : _completedSessions;

    if (sessions.isEmpty) {
      return TypingMetricsSummary.empty();
    }

    // Aggregate metrics
    int totalChars = 0;
    int totalBackspaces = 0;
    int totalPauses = 0;
    Duration totalDuration = Duration.zero;
    double totalSpeed = 0;
    double totalBackspaceRate = 0;

    for (final session in sessions) {
      totalChars += session.charCount;
      totalBackspaces += session.backspaceCount;
      totalPauses += session.pauseCount;
      totalDuration += session.sessionDuration;
      totalSpeed += session.typingSpeed;
      totalBackspaceRate += session.backspaceRate;
    }

    return TypingMetricsSummary(
      totalTypingTime: totalDuration,
      totalCharacters: totalChars,
      totalBackspaces: totalBackspaces,
      totalPauses: totalPauses,
      averageTypingSpeed:
          sessions.isNotEmpty ? totalSpeed / sessions.length : 0,
      averageBackspaceRate:
          sessions.isNotEmpty ? totalBackspaceRate / sessions.length : 0,
      sessionCount: sessions.length,
      periodStart: sessions.first.timestamp,
      periodEnd: sessions.last.timestamp,
    );
  }

  /// Get daily summary (last 24 hours)
  TypingMetricsSummary get dailySummary =>
      getSummary(period: const Duration(hours: 24));

  /// Get hourly summary (last hour)
  TypingMetricsSummary get hourlySummary =>
      getSummary(period: const Duration(hours: 1));

  /// Clean up resources
  void dispose() {
    _subscription?.cancel();
    _eventController?.close();
    _recentEvents.clear();
    _completedSessions.clear();
  }
}
