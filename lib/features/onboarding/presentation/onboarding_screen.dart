/// Onboarding Screen
///
/// 3-slide onboarding flow introducing PRISM features and requesting consent.
library;

import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/theme_constants.dart';

/// Onboarding data model
class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

/// Onboarding slides content
const List<OnboardingSlide> _slides = [
  OnboardingSlide(
    title: 'Welcome to PRISM',
    description:
        'Your personal mental wellness companion that helps you understand and track your emotional health through intelligent, privacy-first insights.',
    icon: Icons.psychology_rounded,
    iconColor: PrismColors.primary,
  ),
  OnboardingSlide(
    title: 'Smart Mood Tracking',
    description:
        'PRISM uses on-device AI to analyze patterns in your digital behavior — like app usage and typing patterns — to predict your mood without reading your personal content.',
    icon: Icons.insights_rounded,
    iconColor: PrismColors.secondary,
  ),
  OnboardingSlide(
    title: 'Privacy First',
    description:
        'Your data stays on your device. We never store raw messages or keystrokes. Only anonymized behavioral summaries are used, and you control what gets shared.',
    icon: Icons.security_rounded,
    iconColor: PrismColors.moodHappy,
  ),
];

/// Main onboarding screen widget
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: PrismDurations.normal,
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.permissions);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrismColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(PrismSpacing.md),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: PrismTypography.labelLarge.copyWith(
                      color: PrismColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _OnboardingPage(slide: _slides[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PrismSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _PageIndicator(isActive: index == _currentPage),
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(PrismSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PrismColors.primary,
                    foregroundColor: PrismColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PrismRadius.md),
                    ),
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                    style: PrismTypography.titleMedium.copyWith(
                      color: PrismColors.background,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: PrismSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// Individual onboarding page content
class _OnboardingPage extends StatelessWidget {
  final OnboardingSlide slide;

  const _OnboardingPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PrismSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: slide.iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(PrismRadius.xl),
            ),
            child: Icon(
              slide.icon,
              size: 70,
              color: slide.iconColor,
            ),
          ),

          const SizedBox(height: PrismSpacing.xl),

          // Title
          Text(
            slide.title,
            style: PrismTypography.headlineLarge.copyWith(
              color: PrismColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: PrismSpacing.md),

          // Description
          Text(
            slide.description,
            style: PrismTypography.bodyLarge.copyWith(
              color: PrismColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Page indicator dot
class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PrismDurations.fast,
      margin: const EdgeInsets.symmetric(horizontal: PrismSpacing.xs),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? PrismColors.primary : PrismColors.surfaceVariant,
        borderRadius: BorderRadius.circular(PrismRadius.full),
      ),
    );
  }
}
