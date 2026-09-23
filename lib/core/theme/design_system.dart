import 'package:flutter/material.dart';

/// Centralized design tokens and reusable visual primitives for CoSpend.
abstract final class CoSpendColors {
  // Primary brand palette
  static const Color prussianBlue = Color(0xFF0A2542);
  static const Color prussianBlueLight = Color(0xFF133863);
  static const Color prussianBlueTint = Color(0x140A2542); // ~8% opacity
  static const Color prussianBlueMuted = Color(0x240A2542); // ~14% opacity

  static const Color jadeGreen = Color(0xFF00BC57);
  static const Color jadeGreenLight = Color(0xFFE6F8EE);
  static const Color jadeGreenTint = Color(0x1800BC57); // ~10% opacity

  // Neutral surfaces
  static const Color white = Colors.white;
  static const Color canvas = Color(0xFFF7F8FA);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFEEF2F6);
  static const Color textPrimary = Color(0xFF0A2542);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  // Dark mode surfaces
  static const Color darkCanvas = Color(0xFF06182B);
  static const Color darkCard = Color(0xFF0D2845);
  static const Color darkBorder = Color(0xFF1E3A5A);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Status / warning (Reserved ONLY for budget limits / alerts)
  static const Color alertRed = Color(0xFFEF4444);
  static const Color alertRedLight = Color(0xFFFEF2F2);
  static const Color alertRedTint = Color(0x1AEF4444);

  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberTint = Color(0x1AF59E0B);
}

/// Standardized elevation shadows with soft Prussian-Blue tinting.
abstract final class CoSpendShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0C0A2542),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x040A2542),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> cardSubtle = [
    BoxShadow(
      color: Color(0x080A2542),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> softCard = [
    BoxShadow(
      color: Color(0x0C0A2542),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x2800BC57),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

/// Standard corner radii.
abstract final class CoSpendRadii {
  static const double card = 12.0;
  static const double pill = 999.0;

  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
}

/// Standardized section label (e.g., "FLAT SETTINGS", "SUBCATEGORIES").
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
  });

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
        ),
      ),
    );
  }
}

/// Icon inside a soft ~10-12% opacity circular background container.
class TintedIcon extends StatelessWidget {
  const TintedIcon({
    super.key,
    required this.icon,
    this.color = CoSpendColors.prussianBlue,
    this.size = 20,
    this.containerSize = 38,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double containerSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size),
    );
  }
}

/// Standardized 12px rounded card with soft Prussian-tinted shadow.
class CoSpendCard extends StatelessWidget {
  const CoSpendCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.onTap,
    this.borderColor,
    this.hasShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = color ?? (isDark ? CoSpendColors.darkCard : CoSpendColors.white);
    final border = borderColor != null
        ? Border.all(color: borderColor!, width: 1)
        : (isDark
            ? Border.all(color: CoSpendColors.darkBorder, width: 1)
            : Border.all(color: CoSpendColors.borderLight, width: 1));

    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: CoSpendRadii.cardRadius,
        border: border,
        boxShadow: (hasShadow && !isDark) ? CoSpendShadows.card : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return BouncingButton(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

/// Tactile scale-down animation on tap (~0.97).
class BouncingButton extends StatefulWidget {
  const BouncingButton({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Sliding single-track segmented control styled in Prussian Blue.
class CoSpendSegmentedControl<T> extends StatelessWidget {
  const CoSpendSegmentedControl({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCanvas : CoSpendColors.surfaceMuted,
        borderRadius: CoSpendRadii.pillRadius,
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
        ),
      ),
      child: Row(
        children: items.entries.map((entry) {
          final isSelected = entry.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? CoSpendColors.prussianBlueLight : CoSpendColors.prussianBlue)
                      : Colors.transparent,
                  borderRadius: CoSpendRadii.pillRadius,
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: CoSpendColors.prussianBlue.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Hero Budget Card styled in deep Prussian Blue gradient.
class HeroBudgetCard extends StatelessWidget {
  const HeroBudgetCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.percentUsed,
    required this.progressText,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String amountText;
  final double percentUsed;
  final String progressText;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clampedRatio = (percentUsed / 100.0).clamp(0.0, 1.0);
    final isExceeded = percentUsed > 100.0;
    final progressColor = isExceeded
        ? CoSpendColors.alertRed
        : (percentUsed >= 80.0
            ? CoSpendColors.warningAmber
            : CoSpendColors.jadeGreen);

    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: CoSpendRadii.cardRadius,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A2542),
              Color(0xFF133863),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: CoSpendColors.prussianBlue.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: CoSpendColors.jadeGreen,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFF93C5FD),
                      ),
                    ),
                  ],
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            Text(
              amountText,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 16),
            // Animated Progress Bar
            ClipRRect(
              borderRadius: CoSpendRadii.pillRadius,
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: clampedRatio),
                    builder: (context, value, child) => FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: CoSpendRadii.pillRadius,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  '${percentUsed.toStringAsFixed(0)}% used',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isExceeded ? CoSpendColors.alertRed : Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
