/// PRISM Dashboard Screen
///
/// Main dashboard showing Mental Health Score, Predicted Mood,
/// Weekly Chart, and Permission Warning if any permissions are revoked.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/theme_constants.dart';
import '../../../ai/mood_engine.dart';
import '../../../providers/mood_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/permission_provider.dart';

/// Dashboard screen - main app interface
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh permissions on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionProvider.notifier).refresh();
      // Start notification listener if permission granted
      final permissions = ref.read(permissionProvider);
      if (permissions.notificationListenerEnabled) {
        ref.read(notificationTrackingProvider.notifier).startListening();
      }
      // Start mood engine periodic updates
      ref.read(moodProvider.notifier).startPeriodicUpdates();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh permissions when returning to app
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionProvider.notifier).refresh();
    }
  }

  void _navigateToPermissions() {
    Navigator.of(context).pushNamed(AppRoutes.permissions);
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(permissionProvider);
    final hasAllPermissions = permissionState.hasAllPermissions;

    return Scaffold(
      backgroundColor: PrismColors.background,
      body: SafeArea(
        child: permissionState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: PrismColors.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(PrismSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),

                    const SizedBox(height: PrismSpacing.lg),

                    // Permission Warning Card (if any permission revoked)
                    if (!hasAllPermissions) ...[
                      _PermissionWarningCard(onTap: _navigateToPermissions),
                      const SizedBox(height: PrismSpacing.lg),
                    ],

                    // Mental Health Score Card
                    const _MentalHealthScoreCard(),

                    const SizedBox(height: PrismSpacing.md),

                    // Predicted Mood Card
                    const _PredictedMoodCard(),

                    const SizedBox(height: PrismSpacing.md),

                    // Notification Activity Card
                    const _NotificationActivityCard(),

                    const SizedBox(height: PrismSpacing.md),

                    // Weekly Chart Card
                    const _WeeklyChartCard(),

                    const SizedBox(height: PrismSpacing.xl),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${_getGreeting()}',
              style: PrismTypography.bodyMedium.copyWith(
                color: PrismColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your Wellness',
              style: PrismTypography.headlineLarge.copyWith(
                color: PrismColors.textPrimary,
              ),
            ),
          ],
        ),
        // Profile avatar placeholder
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: PrismColors.surfaceVariant,
            borderRadius: BorderRadius.circular(PrismRadius.md),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: PrismColors.textSecondary,
            size: 24,
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

/// Permission Warning Card - shown when permissions are revoked
class _PermissionWarningCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PermissionWarningCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PrismRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(PrismSpacing.md),
        decoration: BoxDecoration(
          color: PrismColors.warning.withAlpha(25),
          borderRadius: BorderRadius.circular(PrismRadius.lg),
          border: Border.all(
            color: PrismColors.warning.withAlpha(100),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PrismColors.warning.withAlpha(50),
                borderRadius: BorderRadius.circular(PrismRadius.sm),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: PrismColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: PrismSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permissions Required',
                    style: PrismTypography.titleSmall.copyWith(
                      color: PrismColors.warning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Some permissions were revoked. Tap to fix.',
                    style: PrismTypography.bodySmall.copyWith(
                      color: PrismColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: PrismColors.warning,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mental Health Score Card
class _MentalHealthScoreCard extends ConsumerWidget {
  const _MentalHealthScoreCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodState = ref.watch(moodProvider);
    final mood = moodState.currentMood;
    final changeText = moodState.changeText;
    final trend = moodState.trend;

    // Determine trend color
    Color trendColor;
    switch (trend) {
      case MoodTrend.improving:
        trendColor = PrismColors.moodHappy;
        break;
      case MoodTrend.declining:
        trendColor = PrismColors.warning;
        break;
      case MoodTrend.stable:
        trendColor = PrismColors.textSecondary;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PrismSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PrismColors.primary.withAlpha(40),
            PrismColors.secondary.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(PrismRadius.xl),
        border: Border.all(
          color: PrismColors.primary.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mental Health Score',
                style: PrismTypography.titleSmall.copyWith(
                  color: PrismColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(PrismRadius.full),
                ),
                child: Text(
                  changeText,
                  style: PrismTypography.labelSmall.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PrismSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mood.score.toString(),
                style: PrismTypography.displayLarge.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: PrismColors.textPrimary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 4),
                child: Text(
                  '/100',
                  style: PrismTypography.titleMedium.copyWith(
                    color: PrismColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PrismSpacing.sm),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(PrismRadius.full),
            child: LinearProgressIndicator(
              value: mood.score / 100,
              minHeight: 8,
              backgroundColor: PrismColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(mood.mood.colorValue),
              ),
            ),
          ),
          const SizedBox(height: PrismSpacing.sm),
          Text(
            mood.message,
            style: PrismTypography.bodySmall.copyWith(
              color: PrismColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Predicted Mood Card
class _PredictedMoodCard extends ConsumerWidget {
  const _PredictedMoodCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodState = ref.watch(moodProvider);
    final mood = moodState.currentMood;
    final moodColor = Color(mood.mood.colorValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PrismSpacing.lg),
      decoration: BoxDecoration(
        color: PrismColors.surface,
        borderRadius: BorderRadius.circular(PrismRadius.lg),
        border: Border.all(
          color: PrismColors.surfaceVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Mood emoji/icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: moodColor.withAlpha(30),
              borderRadius: BorderRadius.circular(PrismRadius.md),
            ),
            child: Center(
              child: Text(
                mood.mood.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: PrismSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Predicted Mood',
                  style: PrismTypography.bodySmall.copyWith(
                    color: PrismColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mood.mood.label,
                  style: PrismTypography.titleLarge.copyWith(
                    color: moodColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mood.confidence > 0
                      ? 'Confidence: ${(mood.confidence * 100).toInt()}%'
                      : 'Collecting data...',
                  style: PrismTypography.labelSmall.copyWith(
                    color: PrismColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification Activity Card - shows live notification metrics
class _NotificationActivityCard extends ConsumerWidget {
  const _NotificationActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationTrackingProvider);
    final permissionState = ref.watch(permissionProvider);
    final isEnabled = permissionState.notificationListenerEnabled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PrismSpacing.lg),
      decoration: BoxDecoration(
        color: PrismColors.surface,
        borderRadius: BorderRadius.circular(PrismRadius.lg),
        border: Border.all(
          color: PrismColors.surfaceVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: isEnabled
                        ? PrismColors.secondary
                        : PrismColors.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: PrismSpacing.sm),
                  Text(
                    'Notification Activity',
                    style: PrismTypography.titleSmall.copyWith(
                      color: PrismColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (isEnabled && notificationState.isListening)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: PrismColors.moodHappy,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: PrismSpacing.md),
          if (!isEnabled)
            Text(
              'Enable notification access to track messaging patterns',
              style: PrismTypography.bodySmall.copyWith(
                color: PrismColors.textSecondary,
              ),
            )
          else ...[
            // Metrics row
            Row(
              children: [
                Expanded(
                  child: _NotificationMetric(
                    label: 'Today',
                    value: notificationState.todayCount.toString(),
                    icon: Icons.today_rounded,
                  ),
                ),
                const SizedBox(width: PrismSpacing.md),
                Expanded(
                  child: _NotificationMetric(
                    label: 'Per Hour',
                    value: notificationState.notificationsPerHour
                        .toStringAsFixed(1),
                    icon: Icons.speed_rounded,
                  ),
                ),
                const SizedBox(width: PrismSpacing.md),
                Expanded(
                  child: _NotificationMetric(
                    label: 'Top App',
                    value: _shortenAppName(notificationState.mostActiveApp),
                    icon: Icons.apps_rounded,
                  ),
                ),
              ],
            ),
            if (notificationState.recentNotifications.isNotEmpty) ...[
              const SizedBox(height: PrismSpacing.md),
              const Divider(color: PrismColors.surfaceVariant, height: 1),
              const SizedBox(height: PrismSpacing.sm),
              Text(
                'Recent: ${notificationState.recentNotifications.first.appName}',
                style: PrismTypography.labelSmall.copyWith(
                  color: PrismColors.textHint,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _shortenAppName(String name) {
    if (name.length > 8) {
      return '${name.substring(0, 7)}…';
    }
    return name;
  }
}

/// Small metric display widget
class _NotificationMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _NotificationMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: PrismColors.textSecondary, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: PrismTypography.titleMedium.copyWith(
            color: PrismColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: PrismTypography.labelSmall.copyWith(
            color: PrismColors.textHint,
          ),
        ),
      ],
    );
  }
}

/// Weekly Chart Card (Placeholder)
class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PrismSpacing.lg),
      decoration: BoxDecoration(
        color: PrismColors.surface,
        borderRadius: BorderRadius.circular(PrismRadius.lg),
        border: Border.all(
          color: PrismColors.surfaceVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Trend',
                style: PrismTypography.titleSmall.copyWith(
                  color: PrismColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: PrismColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(PrismRadius.sm),
                ),
                child: Text(
                  'This Week',
                  style: PrismTypography.labelSmall.copyWith(
                    color: PrismColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PrismSpacing.lg),
          // Chart placeholder
          const SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ChartBar(label: 'Mon', value: 0.6, color: PrismColors.primary),
                _ChartBar(
                    label: 'Tue', value: 0.75, color: PrismColors.primary),
                _ChartBar(label: 'Wed', value: 0.5, color: PrismColors.primary),
                _ChartBar(
                    label: 'Thu', value: 0.85, color: PrismColors.primary),
                _ChartBar(label: 'Fri', value: 0.7, color: PrismColors.primary),
                _ChartBar(
                    label: 'Sat', value: 0.9, color: PrismColors.secondary),
                _ChartBar(
                    label: 'Sun',
                    value: 0.78,
                    color: PrismColors.secondary,
                    isToday: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single bar in the weekly chart
class _ChartBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isToday;

  const _ChartBar({
    required this.label,
    required this.value,
    required this.color,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 80 * value,
          decoration: BoxDecoration(
            color: isToday ? color : color.withAlpha(150),
            borderRadius: BorderRadius.circular(PrismRadius.sm),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: PrismTypography.labelSmall.copyWith(
            color: isToday ? PrismColors.textPrimary : PrismColors.textHint,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
