/// Cloud AI Service
///
/// Optional integration for enhanced cloud-based mood prediction.
/// Falls back to local engine if cloud is unavailable.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../local_model/signal_aggregator.dart';
import '../mood_engine.dart';
import '../../models/mood_result.dart';
import '../../services/firebase_service.dart';

/// Cloud AI availability status
enum CloudAIStatus {
  available,
  unavailable,
  disabled,
  error,
}

/// Cloud AI service for enhanced mood prediction
class CloudAIService {
  final FirebaseService _firebase;
  final MoodEngine _localEngine;

  /// Whether to use cloud AI when available
  bool useCloudAI = true;

  CloudAIService({
    FirebaseService? firebase,
    MoodEngine? localEngine,
  })  : _firebase = firebase ?? FirebaseService.instance,
        _localEngine = localEngine ?? MoodEngine();

  /// Check if cloud AI is available
  CloudAIStatus get status {
    if (!useCloudAI) return CloudAIStatus.disabled;
    if (!_firebase.cloudAvailable) return CloudAIStatus.unavailable;
    return CloudAIStatus.available;
  }

  /// Calculate mood using cloud AI with local fallback
  Future<MoodResult> calculateMood(BehavioralSignals signals) async {
    // Try cloud prediction if available
    if (status == CloudAIStatus.available) {
      try {
        final cloudResult = await _getCloudPrediction(signals);
        if (cloudResult != null) {
          debugPrint('CloudAIService: Using cloud prediction');
          return cloudResult;
        }
      } catch (e) {
        debugPrint('CloudAIService: Cloud prediction failed - $e');
      }
    }

    // Fallback to local engine
    debugPrint('CloudAIService: Using local prediction');
    return _localEngine.calculateMood(signals);
  }

  /// Get prediction from cloud (if available)
  /// This is a placeholder for future cloud AI integration
  /// In a real implementation, this would call a Cloud Function or AI endpoint
  Future<MoodResult?> _getCloudPrediction(BehavioralSignals signals) async {
    if (!_firebase.cloudAvailable) return null;

    try {
      // Check if there's a cached cloud prediction
      final userDoc = _firebase.userDoc;
      if (userDoc == null) return null;

      // Get most recent cloud prediction if available
      final predictionDoc =
          await userDoc.collection('predictions').doc('latest').get();

      if (!predictionDoc.exists) return null;

      final data = predictionDoc.data();
      if (data == null) return null;

      // Check if prediction is recent (within last hour)
      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp == null) return null;

      final predictionTime = timestamp.toDate();
      final age = DateTime.now().difference(predictionTime);
      if (age.inHours > 1) return null;

      // Parse cloud prediction
      return MoodResult(
        score: data['score'] as int? ?? 75,
        mood: MoodLabel.values.firstWhere(
          (m) => m.name == data['mood'],
          orElse: () => MoodLabel.neutral,
        ),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.7,
        timestamp: predictionTime,
        factors: data['factors'] != null
            ? Map<String, double>.from(data['factors'] as Map)
            : null,
      );
    } catch (e) {
      debugPrint('CloudAIService: Error getting cloud prediction - $e');
      return null;
    }
  }

  /// Upload signals for cloud processing
  /// Cloud Function would process these and store a prediction
  Future<bool> submitSignalsForProcessing(BehavioralSignals signals) async {
    if (!_firebase.cloudAvailable) return false;

    try {
      final userDoc = _firebase.userDoc;
      if (userDoc == null) return false;

      await userDoc.collection('signal_queue').add({
        'screenTimeMinutes': signals.screenTime.inMinutes,
        'lateNightMinutes': signals.lateNightUsage.inMinutes,
        'typingSpeed': signals.typingSpeed,
        'backspaceRate': signals.backspaceRate,
        'notificationCount': signals.notificationCount,
        'notificationsPerHour': signals.notificationsPerHour,
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('CloudAIService: Signals submitted for cloud processing');
      return true;
    } catch (e) {
      debugPrint('CloudAIService: Failed to submit signals - $e');
      return false;
    }
  }

  /// Enable/disable cloud AI
  void setEnabled(bool enabled) {
    useCloudAI = enabled;
    debugPrint('CloudAIService: Cloud AI ${enabled ? "enabled" : "disabled"}');
  }
}
