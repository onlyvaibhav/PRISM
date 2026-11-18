/// PRISM History Screen
///
/// Shows chronological log of daily mood and activity summaries.
/// (Skeleton implementation)
library;

import 'package:flutter/material.dart';
import '../../../app/theme/theme_constants.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrismColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'History',
          style: PrismTypography.headlineMedium.copyWith(
            color: PrismColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(PrismSpacing.md),
        itemCount: 5, // Demo items
        itemBuilder: (context, index) {
          return const _HistoryItemStub();
        },
      ),
    );
  }
}

class _HistoryItemStub extends StatelessWidget {
  const _HistoryItemStub();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: PrismSpacing.md),
      padding: const EdgeInsets.all(PrismSpacing.md),
      decoration: BoxDecoration(
        color: PrismColors.surface,
        borderRadius: BorderRadius.circular(PrismRadius.lg),
        border: Border.all(color: PrismColors.surfaceVariant),
      ),
      child: Row(
        children: [
          // Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: PrismColors.surfaceVariant,
              borderRadius: BorderRadius.circular(PrismRadius.md),
            ),
            child: Column(
              children: [
                Text(
                  'JAN',
                  style: PrismTypography.labelSmall.copyWith(
                    color: PrismColors.textSecondary,
                  ),
                ),
                Text(
                  '24',
                  style: PrismTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: PrismSpacing.md),

          // Mood Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Relaxed',
                      style: PrismTypography.titleMedium.copyWith(
                        color: PrismColors.moodHappy,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: PrismColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(PrismRadius.full),
                      ),
                      child: Text(
                        'Score: 85',
                        style: PrismTypography.labelSmall.copyWith(
                          color: PrismColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Detected moderate typing speed and fewer correction pauses.',
                  style: PrismTypography.bodySmall.copyWith(
                    color: PrismColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
