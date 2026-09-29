import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/motion.dart';

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
      badge: 'FAIR EXPENSES',
      title: 'Track shared bills\nwithout the drama',
      description:
          'Log groceries, utilities, and dining in seconds. Splits stay exact to the paisa — no rounding fights.',
      mockupType: MockupType.splits,
    ),
    OnboardingSlideData(
      badge: 'SMART BUDGETS',
      title: 'Caps the whole flat\ncan actually see',
      description:
          'Set Food, Electricity, and Rent limits. Divide quotas among roommates and get alerts before you overspend.',
      mockupType: MockupType.budgets,
    ),
    OnboardingSlideData(
      badge: 'LIVE ACTIVITY',
      title: 'Know the moment\nsomeone spends',
      description:
          'Every expense lands in a shared feed. Instant in-app alerts keep the household honest without group-chat chaos.',
      mockupType: MockupType.settlement,
    ),
    OnboardingSlideData(
      badge: 'ONE TAP INVITE',
      title: 'One ledger.\nEvery roommate.',
      description:
          'Share a FLAT code from WhatsApp. Everyone joins the same books with live cloud sync.',
      mockupType: MockupType.invite,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        Color(0xFF071525),
                        CoSpendColors.darkCanvas,
                        Color(0xFF04101C),
                      ]
                    : const [
                        Color(0xFFE8F8EF),
                        CoSpendColors.canvas,
                        Color(0xFFF7FAFC),
                      ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: -size.width * 0.28,
            right: -size.width * 0.22,
            child: _GlowOrb(
              diameter: size.width * 0.72,
              color: CoSpendColors.jadeGreen.withValues(alpha: isDark ? 0.16 : 0.18),
            ),
          ),
          Positioned(
            bottom: size.height * 0.18,
            left: -size.width * 0.3,
            child: _GlowOrb(
              diameter: size.width * 0.62,
              color: CoSpendColors.prussianBlue.withValues(alpha: isDark ? 0.22 : 0.08),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'app-logo',
                        child: ClipRRect(
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
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppConstants.appName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                        ),
                      ),
                      const Spacer(),
                      if (!isLast)
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: isDark
                                  ? CoSpendColors.darkTextMuted
                                  : CoSpendColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 64, height: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return _OnboardingPage(slide: slide, active: index == _currentIndex);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    children: [
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
                                  ? CoSpendColors.jadeGreen
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : CoSpendColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
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
                                      style: theme.textTheme.bodyMedium,
                                      children: [
                                        TextSpan(
                                          text: 'Already have an account? ',
                                          style: TextStyle(
                                            color: isDark
                                                ? CoSpendColors.darkTextMuted
                                                : CoSpendColors.textMuted,
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.slide, required this.active});

  final OnboardingSlideData slide;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: FadeSlideIn(
              key: ValueKey(slide.badge),
              offset: const Offset(0, 0.05),
              child: _SlideMockup(
                mockupType: slide.mockupType,
                animate: active,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            key: ValueKey('${slide.badge}-copy'),
            delay: const Duration(milliseconds: 60),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: CoSpendColors.jadeGreen.withValues(alpha: 0.14),
                    borderRadius: CoSpendRadii.pillRadius,
                  ),
                  child: Text(
                    slide.badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: CoSpendColors.jadeGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    height: 1.15,
                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

enum MockupType { splits, budgets, settlement, invite }

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.badge,
    required this.title,
    required this.description,
    required this.mockupType,
  });

  final String badge;
  final String title;
  final String description;
  final MockupType mockupType;
}

class _SlideMockup extends StatelessWidget {
  const _SlideMockup({required this.mockupType, required this.animate});

  final MockupType mockupType;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 280),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
            ),
            boxShadow: isDark ? null : CoSpendShadows.heroBannerShadow,
          ),
          child: switch (mockupType) {
            MockupType.splits => const _SplitsMockup(),
            MockupType.budgets => _BudgetsMockup(animate: animate),
            MockupType.settlement => const _SettlementMockup(),
            MockupType.invite => const _InviteMockup(),
          },
        ),
      ),
    );
  }
}

class _SplitsMockup extends StatelessWidget {
  const _SplitsMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFFF97316),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dinner & Groceries',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  Text(
                    'Paid by Hayat · Split 3 ways',
                    style: TextStyle(fontSize: 12, color: CoSpendColors.textMuted),
                  ),
                ],
              ),
            ),
            const Text(
              'Rs. 15,000',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: _ShareChip(name: 'Hayat', amount: 'Rs. 5,000', color: Color(0xFF10B981))),
            SizedBox(width: 8),
            Expanded(child: _ShareChip(name: 'Ali', amount: 'Rs. 5,000', color: Color(0xFF6366F1))),
            SizedBox(width: 8),
            Expanded(child: _ShareChip(name: 'Ahmed', amount: 'Rs. 5,000', color: Color(0xFFF59E0B))),
          ],
        ),
      ],
    );
  }
}

class _ShareChip extends StatelessWidget {
  const _ShareChip({
    required this.name,
    required this.amount,
    required this.color,
  });

  final String name;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: Text(
              name[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          Text(
            amount,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _BudgetsMockup extends StatelessWidget {
  const _BudgetsMockup({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MeterRow(
          label: 'Food & Dining',
          meta: 'Rs. 18,500 / 25,000',
          pct: 0.74,
          color: CoSpendColors.jadeGreen,
          animate: animate,
        ),
        const SizedBox(height: 22),
        _MeterRow(
          label: 'Electricity & Bills',
          meta: 'Rs. 14,200 / 15,000',
          pct: 0.94,
          color: CoSpendColors.warningAmber,
          animate: animate,
        ),
      ],
    );
  }
}

class _MeterRow extends StatelessWidget {
  const _MeterRow({
    required this.label,
    required this.meta,
    required this.pct,
    required this.color,
    required this.animate,
  });

  final String label;
  final String meta;
  final double pct;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: animate ? pct : pct),
          duration: const Duration(milliseconds: 700),
          curve: CoSpendMotion.entrance,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(meta, style: const TextStyle(fontSize: 11, color: CoSpendColors.textMuted)),
      ],
    );
  }
}

class _SettlementMockup extends StatelessWidget {
  const _SettlementMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CoSpendColors.jadeGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF6366F1),
                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Rs. 4,500',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: CoSpendColors.jadeGreen,
                      ),
                    ),
                    Icon(Icons.south_rounded, color: CoSpendColors.jadeGreen, size: 20),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: CoSpendColors.jadeGreen,
                child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            'Ali pays Hayat — one transfer clears the flat',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _InviteMockup extends StatelessWidget {
  const _InviteMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'YOUR FLAT INVITE CODE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: CoSpendColors.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: CoSpendColors.prussianBlue,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'FLAT-7K29',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_rounded, size: 16, color: CoSpendColors.jadeGreen),
            SizedBox(width: 6),
            Text(
              'Share on WhatsApp in one tap',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
