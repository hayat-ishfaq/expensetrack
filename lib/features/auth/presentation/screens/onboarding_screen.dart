import 'package:concentric_transition/concentric_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Slide Data Model
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.bgColor,
    required this.textColor,
    required this.subtextColor,
    required this.badgeIcon,
    required this.badgeLabel,
  });

  final String imagePath;
  final String title;
  final String description;
  final Color bgColor;
  final Color textColor;
  final Color subtextColor;
  final IconData badgeIcon;
  final String badgeLabel;
}

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding Screen with Concentric Transition
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String prefKey = 'has_completed_onboarding_v2';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;

  static const List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      imagePath: 'assets/images/onboarding1.jpg',
      title: 'Track Together',
      description: 'Keep all your shared expenses organized in one place.',
      bgColor: Color(0xFF0A2542), // Prussian Blue
      textColor: Colors.white,
      subtextColor: Color(0xD9FFFFFF),
      badgeIcon: Icons.receipt_long_rounded,
      badgeLabel: 'SHARED EXPENSES',
    ),
    OnboardingSlideData(
      imagePath: 'assets/images/onboarding2.jpg',
      title: 'Split Fairly',
      description: 'Divide expenses equally, by amount, or by percentage.',
      bgColor: Color(0xFF00BC57), // Jade Green
      textColor: Color(0xFF062916), // Deep Forest Green for high contrast
      subtextColor: Color(0xD9062916),
      badgeIcon: Icons.pie_chart_rounded,
      badgeLabel: 'FLEXIBLE SPLITS',
    ),
    OnboardingSlideData(
      imagePath: 'assets/images/onboarding3.jpg',
      title: 'Settle Easily',
      description: 'See who owes what and settle up without the confusion.',
      bgColor: Colors.white, // Crisp White Canvas
      textColor: Color(0xFF0A2542), // Prussian Blue
      subtextColor: Color(0xFF475569), // Slate Muted
      badgeIcon: Icons.handshake_rounded,
      badgeLabel: 'INSTANT SETTLEMENT',
    ),
  ];

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.prefKey, true);
    if (!mounted) return;
    context.go(Routes.signup);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final currentSlide = _slides[_currentIndex];
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // ── Concentric Page View Animated Background & Pages ───────────────
          ConcentricPageView(
            colors: _slides.map((s) => s.bgColor).toList(),
            radius: (screenWidth * 0.085).clamp(32.0, 42.0),
            verticalPosition: 0.82,
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeInOutCubic,
            scaleFactor: 0.12,
            opacityFactor: 1.2,
            itemCount: _slides.length,
            onChange: (index) {
              setState(() => _currentIndex = index);
              HapticFeedback.selectionClick();
            },
            onFinish: _completeOnboarding,
            nextButtonBuilder: (context) {
              return Center(
                child: Icon(
                  isLast ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
                  size: isLast ? 28 : 22,
                ),
              );
            },
            itemBuilder: (index) {
              final slide = _slides[index % _slides.length];
              return _OnboardingSlideContent(
                slide: slide,
                screenHeight: screenHeight,
                screenWidth: screenWidth,
              );
            },
          ),

          // ── Top Navigation Bar (Logo + App Name + Skip) ───────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 34,
                        height: 34,
                        errorBuilder: (_, _, _) => Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: CoSpendColors.jadeGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.4,
                        color: currentSlide.textColor,
                      ),
                    ),
                    const Spacer(),
                    if (!isLast)
                      TextButton(
                        onPressed: _completeOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: currentSlide.textColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: currentSlide.subtextColor,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 50, height: 36),
                  ],
                ),
              ),
            ),
          ),

          // ── Dots Indicator (Positioned above the concentric button) ────────
          Positioned(
            bottom: (screenHeight * 0.19).clamp(120.0, 180.0),
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (idx) {
                final isActive = idx == _currentIndex;
                return AnimatedContainer(
                  duration: CoSpendMotion.fast,
                  curve: CoSpendMotion.entrance,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isActive ? 24 : 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? currentSlide.textColor
                        : currentSlide.textColor.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),

          // ── Log in link anchored at the bottom ─────────────────────────────
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go(Routes.login);
                  },
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: currentSlide.subtextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: currentSlide.textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide Content Widget (Image Card + Pill Badge + Title + Description)
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingSlideContent extends StatelessWidget {
  const _OnboardingSlideContent({
    required this.slide,
    required this.screenHeight,
    required this.screenWidth,
  });

  final OnboardingSlideData slide;
  final double screenHeight;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final cardHeight = (screenHeight * 0.35).clamp(200.0, 320.0);
    final cardWidth = (screenWidth * 0.88).clamp(280.0, 420.0);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Spacer for top app bar
          const SizedBox(height: 52),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Hero Image Card with subtle shadow & border ────────────
                Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: slide.textColor.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22.5),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          slide.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: CoSpendColors.prussianBlueLight,
                            child: const Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        // Soft depth gradient at the bottom of the card
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.2),
                                ],
                                stops: const [0.65, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Pill Category Badge ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: slide.textColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: slide.textColor.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        slide.badgeIcon,
                        size: 13,
                        color: slide.textColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        slide.badgeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: slide.textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Title ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    slide.title,
                    style: TextStyle(
                      fontSize: (screenHeight * 0.034).clamp(24.0, 32.0),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                      height: 1.15,
                      color: slide.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 8),

                // ── Description ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    slide.description,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      color: slide.subtextColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),

          // Bottom spacing to leave area for concentric button & dots
          SizedBox(height: (screenHeight * 0.22).clamp(140.0, 200.0)),
        ],
      ),
    );
  }
}
