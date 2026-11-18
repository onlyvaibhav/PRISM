/// PRISM - Mental Health and Mood Tracking Application
///
/// Application entry point with Riverpod provider scope initialization.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/prism_app.dart';
import 'core/permissions/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize permission service
  await PermissionService.init();

  runApp(
    const ProviderScope(
      child: PrismApp(),
    ),
  );
}
