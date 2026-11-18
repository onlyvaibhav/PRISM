/// PRISM Insights Screen
///
/// Shows detailed analytics about mood trends and emotional patterns.
/// (Skeleton implementation)
library;

import 'package:flutter/material.dart';
import '../../../app/theme/theme_constants.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrismColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Insights',
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
            // Weekly Emotional Breakdown (Placeholder)
            const _InsightCard(
              title: 'Emotional Makeup',
              child: SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'Pie Chart Placeholder\n(Coming Phase 6)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: PrismColors.textHint),
                  ),
                ),
              ),
            ),

            const SizedBox(height: PrismSpacing.lg),

            // Weekly Trend Graph (Placeholder)
            const _InsightCard(
              title: 'Weekly Mood Trend',
              child: SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Line Chart Placeholder\n(Coming Phase 6)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: PrismColors.textHint),
                  ),
                ),
              ),
            ),

            const SizedBox(height: PrismSpacing.lg),

            // Top Influences
            Text(
              'Top Influences',
              style: PrismTypography.titleLarge.copyWith(
                color: PrismColors.textPrimary,
              ),
            ),
            const SizedBox(height: PrismSpacing.md),
            const _InfluenceItem(
              icon: Icons.access_time_filled_rounded,
              color: PrismColors.secondary,
              label: 'Late Night Screen Time',
              impact: 'Negative Impact',
            ),
            const SizedBox(height: PrismSpacing.sm),
            const _InfluenceItem(
              icon: Icons.chat_bubble_rounded,
              color: PrismColors.primary,
              label: 'Social Interactions',
              impact: 'Positive Impact',
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InsightCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PrismSpacing.lg),
      decoration: BoxDecoration(
        color: PrismColors.surface,
        borderRadius: BorderRadius.circular(PrismRadius.lg),
        border: Border.all(color: PrismColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PrismTypography.titleMedium.copyWith(
              color: PrismColors.textSecondary,
            ),
          ),
          const SizedBox(height: PrismSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfluenceItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String impact;

  const _InfluenceItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.impact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PrismSpacing.md),
      decoration: BoxDecoration(
        color: PrismColors.surface,
        borderRadius: BorderRadius.circular(PrismRadius.md),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PrismSpacing.sm),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(PrismRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: PrismSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: PrismTypography.bodyMedium.copyWith(
                    color: PrismColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  impact,
                  style: PrismTypography.labelSmall.copyWith(
                    color: PrismColors.textSecondary,
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
