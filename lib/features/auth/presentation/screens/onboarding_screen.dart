import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String description;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String prefKey = 'has_completed_onboarding_v2';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      imagePath: 'assets/images/onboarding1.jpg',
      title: 'Track Together',
      description: 'Keep all your shared expenses organized in one place.',
    ),
    OnboardingSlideData(
      imagePath: 'assets/images/onboarding2.jpg',
      title: 'Split Fairly',
      description:
          'Divide expenses equally, by amount, or by percentage.',
    ),
    OnboardingSlideData(
      imagePath: 'assets/images/onboarding3.jpg',
      title: 'Settle Easily',
      description:
          'See who owes what and settle up without the confusion.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.prefKey, true);
    if (!mounted) return;
    context.go(Routes.signup);
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: CoSpendMotion.base,
        curve: CoSpendMotion.entrance,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen paged background images ────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemBuilder: (context, index) {
              return _BackgroundPage(slide: _slides[index]);
            },
          ),

          // ── Content overlay (logo bar + dots + button) ─────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Logo + skip bar ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 36,
                          height: 36,
                          errorBuilder: (_, _, _) => Container(
                            width: 36,
                            height: 36,
                            color: CoSpendColors.jadeGreen,
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (!isLast)
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 64, height: 48),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Dots + button ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Column(
                    children: [
                      // Page indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (idx) {
                          final isActive = idx == _currentIndex;
                          return AnimatedContainer(
                            duration: CoSpendMotion.fast,
                            curve: CoSpendMotion.entrance,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 7,
                            width: isActive ? 28 : 7,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),

                      // Next / Get Started button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: CoSpendColors.jadeGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _nextPage,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLast ? "Get Started — It's Free" : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (!isLast) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Log in link on last slide
                      AnimatedSize(
                        duration: CoSpendMotion.fast,
                        curve: CoSpendMotion.entrance,
                        child: isLast
                            ? Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: TextButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    context.go(Routes.login);
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Already have an account? ',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: 'Log in',
                                          style: TextStyle(
                                            color: CoSpendColors.jadeGreen,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Full-bleed background page with gradient overlay + title/description
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundPage extends StatelessWidget {
  const _BackgroundPage({required this.slide});

  final OnboardingSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          slide.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: CoSpendColors.prussianBlue,
          ),
        ),

        // Gradient overlays — top darkens for the logo bar, bottom for text
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.25, 0.55, 1.0],
              colors: [
                Color(0xCC000000), // dark at top for logo bar
                Color(0x00000000), // transparent in middle
                Color(0x66000000), // subtle mid-bottom darkening
                Color(0xEE000000), // deep dark at bottom for text
              ],
            ),
          ),
        ),

        // Title + description anchored to bottom
        Positioned(
          left: 24,
          right: 24,
          bottom: 160, // sits above the dots/button area
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
