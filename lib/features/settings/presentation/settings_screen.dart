/// PRISM Settings Screen
///
/// App configuration and privacy controls.
/// (Skeleton implementation)
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/theme_constants.dart';
import '../../tracking/services/app_usage_service.dart';
import '../../tracking/services/typing_monitor_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _navigateToPermissions(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.permissions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrismColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: PrismTypography.headlineMedium.copyWith(
            color: PrismColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(PrismSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            const _SettingsSectionTitle(title: 'Account'),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Profile',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.cloud_upload_outlined,
              title: 'Data Sync (Coming Soon)',
              subtitle: 'Backup your data to the cloud',
              onTap: () {},
              isDestructive: false,
            ),

            const SizedBox(height: PrismSpacing.xl),

            // Privacy & Permissions
            const _SettingsSectionTitle(title: 'Privacy & Permissions'),
            _SettingsTile(
              icon: Icons.security_rounded,
              title: 'Permissions Manager',
              subtitle: 'Manage accessibility & notification access',
              onTap: () => _navigateToPermissions(context),
            ),
            _SettingsTile(
              icon: Icons.visibility_off_outlined,
              title: 'Incognito Mode',
              subtitle: 'Pause analysis temporarily',
              trailing: Switch(
                value: false,
                onChanged: (val) {},
              ),
              onTap: () {},
            ),

            const SizedBox(height: PrismSpacing.xl),

            // Data Control
            const _SettingsSectionTitle(title: 'Data Control'),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Clear Local Data',
              subtitle: 'Delete all stored mood logs',
              onTap: () {},
              isDestructive: true,
            ),

            const SizedBox(height: PrismSpacing.xl),

            // Debug Section
            const _SettingsSectionTitle(title: 'Debug'),
            _SettingsTile(
              icon: Icons.bug_report_outlined,
              title: 'Check App Usage (24h)',
              subtitle: 'View raw usage stats',
              onTap: () async {
                final service = AppUsageService();
                final stats = await service.getDailyUsage();
                // Sort by duration desc
                stats
                    .sort((a, b) => b.usageDuration.compareTo(a.usageDuration));

                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: PrismColors.surface,
                      title: const Text('App Usage (24h)'),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: 400,
                        child: stats.isEmpty
                            ? const Center(
                                child: Text('No data or permission denied'))
                            : ListView.builder(
                                itemCount: stats.length,
                                itemBuilder: (c, i) {
                                  final s = stats[i];
                                  return ListTile(
                                    title: Text(
                                      s.packageName.split('.').last,
                                      style: PrismTypography.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      _formatDuration(s.usageDuration),
                                      style: PrismTypography.bodySmall,
                                    ),
                                  );
                                }),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Close'),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
            _SettingsTile(
              icon: Icons.keyboard_outlined,
              title: 'Typing Monitor (Prototype)',
              subtitle: 'Check for typing events',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const _TypingMonitorDialog(),
                );
              },
            ),

            const SizedBox(height: PrismSpacing.xl),

            Center(
              child: Text(
                'Version 1.0.0 (Alpha)',
                style: PrismTypography.labelSmall.copyWith(
                  color: PrismColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String title;

  const _SettingsSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: PrismSpacing.md, left: PrismSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: PrismTypography.labelSmall.copyWith(
          color: PrismColors.textSecondary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: PrismSpacing.sm),
      decoration: BoxDecoration(
        color: PrismColors.surface,
        borderRadius: BorderRadius.circular(PrismRadius.lg),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PrismRadius.lg),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? PrismColors.error.withAlpha(20)
                : PrismColors.surfaceVariant,
            borderRadius: BorderRadius.circular(PrismRadius.md),
          ),
          child: Icon(
            icon,
            color: isDestructive ? PrismColors.error : PrismColors.textPrimary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: PrismTypography.bodyLarge.copyWith(
            color: isDestructive ? PrismColors.error : PrismColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: PrismTypography.bodySmall.copyWith(
                  color: PrismColors.textSecondary,
                ),
              )
            : null,
        trailing: trailing ??
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: PrismColors.textHint,
            ),
      ),
    );
  }
}

class _TypingMonitorDialog extends StatefulWidget {
  const _TypingMonitorDialog();

  @override
  State<_TypingMonitorDialog> createState() => _TypingMonitorDialogState();
}

class _TypingMonitorDialogState extends State<_TypingMonitorDialog> {
  int _eventCount = 0;
  String _lastPackage = 'None';
  double _typingSpeed = 0.0;
  double _backspaceRate = 0.0;
  int _pauseCount = 0;
  final _service = TypingMonitorService();
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _service.typingEventStream.listen((event) {
      if (mounted) {
        setState(() {
          _eventCount++;
          _lastPackage = event.packageName.isNotEmpty
              ? event.packageName.split('.').last
              : 'Unknown';
          _typingSpeed = event.typingSpeed;
          _backspaceRate = event.backspaceRate;
          _pauseCount = event.pauseCount;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: PrismColors.surface,
        title: const Text('Typing Monitor'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Events: $_eventCount',
              style: PrismTypography.headlineMedium
                  .copyWith(color: PrismColors.primary)),
          const SizedBox(height: 16),
          _buildMetricRow('Speed', '${_typingSpeed.toStringAsFixed(1)} c/s'),
          _buildMetricRow(
              'Backspace Rate', '${_backspaceRate.toStringAsFixed(1)}%'),
          _buildMetricRow('Pauses', '$_pauseCount'),
          _buildMetricRow('Source', _lastPackage),
          const SizedBox(height: 16),
          Text(
            'Type in another app (split screen) to test.',
            style: PrismTypography.bodySmall
                .copyWith(color: PrismColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ]);
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: PrismTypography.bodySmall.copyWith(
                color: PrismColors.textSecondary,
              )),
          Text(value,
              style: PrismTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
