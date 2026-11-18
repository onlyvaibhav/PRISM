/// Cloud Sync Service
///
/// Handles syncing mood data to Firebase Firestore.
/// Privacy-first: only aggregated mood scores are synced, no raw tracking data.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/mood_result.dart';
import 'firebase_service.dart';

/// Sync status
enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
  offline,
}

/// Cloud sync service for mood data
class CloudSyncService {
  final FirebaseService _firebase;

  CloudSyncService({FirebaseService? firebase})
      : _firebase = firebase ?? FirebaseService.instance;

  /// Check if cloud sync is available
  bool get isAvailable => _firebase.cloudAvailable;

  /// Upload a mood result to Firestore
  Future<bool> uploadMoodResult(MoodResult mood) async {
    if (!isAvailable) {
      debugPrint('CloudSyncService: Cloud not available');
      return false;
    }

    try {
      final collection = _firebase.moodHistoryCollection;
      if (collection == null) return false;

      // Use date as document ID for easy querying
      final docId = _formatDate(mood.timestamp);

      await collection.doc(docId).set({
        'score': mood.score,
        'mood': mood.mood.name,
        'confidence': mood.confidence,
        'timestamp': Timestamp.fromDate(mood.timestamp),
        'factors': mood.factors,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('CloudSyncService: Uploaded mood for $docId');
      return true;
    } catch (e) {
      debugPrint('CloudSyncService: Upload failed - $e');
      return false;
    }
  }

  /// Upload multiple mood results
  Future<int> uploadMoodHistory(List<MoodResult> moods) async {
    if (!isAvailable) return 0;

    int successCount = 0;
    for (final mood in moods) {
      if (await uploadMoodResult(mood)) {
        successCount++;
      }
    }
    return successCount;
  }

  /// Get mood history from Firestore
  Future<List<MoodResult>> getMoodHistory({int limit = 30}) async {
    if (!isAvailable) return [];

    try {
      final collection = _firebase.moodHistoryCollection;
      if (collection == null) return [];

      final snapshot = await collection
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MoodResult(
          score: data['score'] as int? ?? 75,
          mood: MoodLabel.values.firstWhere(
            (m) => m.name == data['mood'],
            orElse: () => MoodLabel.neutral,
          ),
          confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
          timestamp:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          factors: data['factors'] != null
              ? Map<String, double>.from(data['factors'] as Map)
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('CloudSyncService: Get history failed - $e');
      return [];
    }
  }

  /// Save user settings to Firestore
  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    if (!isAvailable) return false;

    try {
      await _firebase.userDoc?.collection('settings').doc('preferences').set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('CloudSyncService: Settings saved');
      return true;
    } catch (e) {
      debugPrint('CloudSyncService: Save settings failed - $e');
      return false;
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    if (!isAvailable) return null;

    try {
      final doc =
          await _firebase.userDoc?.collection('settings').doc('sync').get();

      if (doc?.exists ?? false) {
        final timestamp = doc!.data()?['lastSyncTime'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime() async {
    if (!isAvailable) return;

    try {
      await _firebase.userDoc?.collection('settings').doc('sync').set({
        'lastSyncTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSyncService: Update sync time failed - $e');
    }
  }

  /// Format date for document ID
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
