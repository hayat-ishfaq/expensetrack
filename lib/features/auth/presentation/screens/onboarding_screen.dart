import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String prefKey = 'has_completed_onboarding_v2';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingSlideData> _slides = const [
    OnboardingSlideData(
      badge: 'FAIR SPLITS',
      badgeColor: Color(0xFF6366F1),
      title: 'Split Shared Expenses\nWithout the Drama',
      description:
          'Log flat groceries, utilities, and dining in seconds. FlatSplit splits bills equally or with custom amounts without paisa drift.',
      mockupType: MockupType.splits,
    ),
    OnboardingSlideData(
      badge: 'SMART BUDGETS',
      badgeColor: Color(0xFF10B981),
      title: 'Category Limits &\nIndividual Quotas',
      description:
          'Set overall spending caps for Food, Electricity, and Rent. Divide budgets among flatmates with automatic alerts when limits are spent.',
      mockupType: MockupType.budgets,
    ),
    OnboardingSlideData(
      badge: 'MINIMAL TRANSFERS',
      badgeColor: Color(0xFFF59E0B),
      title: 'Settle Debts in\na Single Tap',
      description:
          'Our settlement algorithm eliminates reciprocal IOUs to compute the fewest possible bank or cash transfers between roommates.',
      mockupType: MockupType.settlement,
    ),
    OnboardingSlideData(
      badge: 'ROOMMATE SYNC',
      badgeColor: Color(0xFF3B82F6),
      title: 'One Shared Ledger\nFor All Flatmates',
      description:
          'Share your flat invite code with one tap. Everyone stays on the exact same page with live cloud sync and zero confusion.',
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
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
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
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: App Branding & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 32,
                          height: 32,
                          errorBuilder: (_, _, _) => Container(
                            width: 32,
                            height: 32,
                            color: scheme.primary,
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
                        'FlatSplit',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  if (_currentIndex < _slides.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // PageView Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Visual Feature Card
                        _SlideMockup(mockupType: slide.mockupType),
                        const SizedBox(height: 32),

                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: slide.badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            slide.badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: slide.badgeColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Animated Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (idx) {
                      final isActive = idx == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: isActive ? 24 : 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? scheme.primary
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_currentIndex < _slides.length - 1)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _nextPage,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _completeOnboarding,
                        child: const Text(
                          'Get Started — It\'s Free',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.go(Routes.login);
                      },
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum MockupType { splits, budgets, settlement, invite }

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.description,
    required this.mockupType,
  });

  final String badge;
  final Color badgeColor;
  final String title;
  final String description;
  final MockupType mockupType;
}

class _SlideMockup extends StatelessWidget {
  const _SlideMockup({required this.mockupType});

  final MockupType mockupType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF141C2E) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : scheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      height: 210,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: switch (mockupType) {
        MockupType.splits => _buildSplitsMockup(scheme, theme),
        MockupType.budgets => _buildBudgetsMockup(scheme, theme),
        MockupType.settlement => _buildSettlementMockup(scheme, theme),
        MockupType.invite => _buildInviteMockup(scheme, theme),
      },
    );
  }

  Widget _buildSplitsMockup(ColorScheme scheme, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFF6366F1),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dinner & Groceries',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Text(
                    'Paid by Hayat • Split 3 ways',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Text(
              'Rs. 15,000',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _avatarShare('Hayat', 'Rs. 5,000', const Color(0xFF10B981)),
            _avatarShare('Ali', 'Rs. 5,000', const Color(0xFF6366F1)),
            _avatarShare('Ahmed', 'Rs. 5,000', const Color(0xFFF59E0B)),
          ],
        ),
      ],
    );
  }

  Widget _avatarShare(String name, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(
              name[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(amount, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildBudgetsMockup(ColorScheme scheme, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _meterRow(
          label: 'Food & Dining',
          spent: 'Rs. 18,500',
          budget: 'Rs. 25,000',
          pct: 0.74,
          color: const Color(0xFF10B981),
          status: 'On track',
        ),
        const SizedBox(height: 16),
        _meterRow(
          label: 'Electricity & Bills',
          spent: 'Rs. 14,200',
          budget: 'Rs. 15,000',
          pct: 0.94,
          color: const Color(0xFFF59E0B),
          status: '94% limit',
        ),
      ],
    );
  }

  Widget _meterRow({
    required String label,
    required String spent,
    required String budget,
    required double pct,
    required Color color,
    required String status,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$spent / $budget', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text('${(pct * 100).toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildSettlementMockup(ColorScheme scheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF6366F1),
                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Rs. 4,500', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF10B981))),
                    Icon(Icons.arrow_forward_rounded, color: Color(0xFF10B981), size: 16),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF10B981),
                child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Ali pays Hayat to settle all flat accounts',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteMockup(ColorScheme scheme, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'YOUR FLAT INVITE CODE',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            'FLAT-7K29',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.0,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_rounded, size: 14, color: Colors.grey),
            SizedBox(width: 6),
            Text('Share via WhatsApp or Messages', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
