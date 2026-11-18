/// Cloud Sync Provider
///
/// Riverpod provider for managing cloud sync state.
/// Handles periodic sync and manual sync triggers.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cloud_sync_service.dart';
import '../services/firebase_service.dart';
import 'mood_provider.dart';

/// Cloud sync state
class CloudSyncState {
  /// Current sync status
  final SyncStatus status;

  /// Whether cloud is available
  final bool isAvailable;

  /// Whether sync is enabled by user
  final bool syncEnabled;

  /// Last successful sync time
  final DateTime? lastSyncTime;

  /// Error message if any
  final String? error;

  const CloudSyncState({
    this.status = SyncStatus.idle,
    this.isAvailable = false,
    this.syncEnabled = true,
    this.lastSyncTime,
    this.error,
  });

  CloudSyncState copyWith({
    SyncStatus? status,
    bool? isAvailable,
    bool? syncEnabled,
    DateTime? lastSyncTime,
    String? error,
  }) {
    return CloudSyncState(
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error,
    );
  }

  /// Time since last sync (formatted)
  String get lastSyncText {
    if (lastSyncTime == null) return 'Never';
    final diff = DateTime.now().difference(lastSyncTime!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Cloud sync state notifier
class CloudSyncNotifier extends StateNotifier<CloudSyncState> {
  final CloudSyncService _syncService;
  final FirebaseService _firebase;
  final Ref _ref;
  Timer? _syncTimer;

  CloudSyncNotifier(this._ref)
      : _syncService = CloudSyncService(),
        _firebase = FirebaseService.instance,
        super(const CloudSyncState());

  /// Initialize cloud sync
  Future<void> initialize() async {
    final result = await _firebase.initialize();

    state = state.copyWith(
      isAvailable: result == FirebaseInitResult.success,
      error: result == FirebaseInitResult.notConfigured
          ? 'Firebase not configured'
          : null,
    );

    if (state.isAvailable) {
      // Get last sync time
      final lastSync = await _syncService.getLastSyncTime();
      state = state.copyWith(lastSyncTime: lastSync);

      // Start periodic sync if enabled
      if (state.syncEnabled) {
        startPeriodicSync();
      }
    }

    debugPrint(
        'CloudSyncNotifier: Initialized, available: ${state.isAvailable}');
  }

  /// Start periodic sync (every 30 minutes)
  void startPeriodicSync({Duration interval = const Duration(minutes: 30)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncNow());
  }

  /// Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Sync current mood to cloud
  Future<void> syncNow() async {
    if (!state.isAvailable || !state.syncEnabled) return;
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing, error: null);

    try {
      // Get current mood from mood provider
      final moodState = _ref.read(moodProvider);
      final currentMood = moodState.currentMood;

      if (currentMood.confidence > 0) {
        final success = await _syncService.uploadMoodResult(currentMood);

        if (success) {
          await _syncService.updateLastSyncTime();
          state = state.copyWith(
            status: SyncStatus.success,
            lastSyncTime: DateTime.now(),
          );
          debugPrint('CloudSyncNotifier: Sync completed');
        } else {
          state = state.copyWith(
            status: SyncStatus.failed,
            error: 'Failed to upload mood data',
          );
        }
      } else {
        state = state.copyWith(status: SyncStatus.idle);
        debugPrint('CloudSyncNotifier: No mood data to sync');
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.failed,
        error: e.toString(),
      );
      debugPrint('CloudSyncNotifier: Sync failed - $e');
    }
  }

  /// Enable/disable sync
  void setSyncEnabled(bool enabled) {
    state = state.copyWith(syncEnabled: enabled);
    if (enabled && state.isAvailable) {
      startPeriodicSync();
    } else {
      stopPeriodicSync();
    }

    // Save preference
    _syncService.saveSettings({'syncEnabled': enabled});
  }

  @override
  void dispose() {
    stopPeriodicSync();
    super.dispose();
  }
}

/// Provider for Firebase service
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

/// Provider for cloud sync service
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
});

/// Provider for cloud sync state
final cloudSyncProvider =
    StateNotifierProvider<CloudSyncNotifier, CloudSyncState>((ref) {
  return CloudSyncNotifier(ref);
});
