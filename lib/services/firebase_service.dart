/// Firebase Service
///
/// Core Firebase initialization and service management.
/// Handles Firebase App initialization, anonymous auth, and Firestore access.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase initialization result
enum FirebaseInitResult {
  success,
  failed,
  notConfigured,
}

/// Core Firebase service for PRISM
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  bool _initialized = false;
  String? _userId;

  /// Check if Firebase is initialized
  bool get isInitialized => _initialized;

  /// Get current user ID (anonymous)
  String? get userId => _userId;

  /// Get Firestore instance
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Get Auth instance
  FirebaseAuth get auth => FirebaseAuth.instance;

  /// Initialize Firebase
  /// Returns success status - gracefully handles missing config
  Future<FirebaseInitResult> initialize() async {
    if (_initialized) return FirebaseInitResult.success;

    try {
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('FirebaseService: Initialized successfully');

      // Sign in anonymously for privacy-first approach
      await _signInAnonymously();

      return FirebaseInitResult.success;
    } on FirebaseException catch (e) {
      debugPrint('FirebaseService: Firebase error - ${e.message}');
      if (e.code == 'core/not-initialized') {
        return FirebaseInitResult.notConfigured;
      }
      return FirebaseInitResult.failed;
    } catch (e) {
      debugPrint('FirebaseService: Failed to initialize - $e');
      return FirebaseInitResult.failed;
    }
  }

  /// Sign in anonymously (no user data required)
  Future<void> _signInAnonymously() async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser != null) {
        _userId = currentUser.uid;
        debugPrint('FirebaseService: Already signed in as $_userId');
        return;
      }

      final credential = await auth.signInAnonymously();
      _userId = credential.user?.uid;
      debugPrint('FirebaseService: Signed in anonymously as $_userId');
    } catch (e) {
      debugPrint('FirebaseService: Anonymous auth failed - $e');
    }
  }

  /// Get user document reference
  DocumentReference? get userDoc {
    if (_userId == null) return null;
    return firestore.collection('users').doc(_userId);
  }

  /// Get mood history collection reference
  CollectionReference? get moodHistoryCollection {
    return userDoc?.collection('mood_history');
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
      _userId = null;
      debugPrint('FirebaseService: Signed out');
    } catch (e) {
      debugPrint('FirebaseService: Sign out failed - $e');
    }
  }

  /// Check if cloud features are available
  bool get cloudAvailable => _initialized && _userId != null;
}
