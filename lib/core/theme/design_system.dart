import 'package:flutter/material.dart';
import 'animation_system.dart';

export 'animation_system.dart';

// =============================================================================
// COLOR TOKENS
// =============================================================================

/// Centralized, curated color tokens for CoSpend.
/// Strictly scoped to Prussian Blue, Jade Green, White, Warm Canvas, and Alert Red.
abstract final class CoSpendColors {
  // Primary brand foundation
  static const Color prussianBlue = Color(0xFF0A2542);
  static const Color prussianBlueLight = Color(0xFF133863);
  static const Color prussianBlueMedium = Color(0xFF1E3A5A);
  static const Color prussianBlueTint = Color(0x140A2542); // ~8% opacity
  static const Color prussianBlueMuted = Color(0x240A2542); // ~14% opacity

  // Brand Accent (CTAs, positive states, on-track indicators)
  static const Color jadeGreen = Color(0xFF00BC57);
  static const Color jadeGreenLight = Color(0xFFE6F8EE);
  static const Color jadeGreenDark = Color(0xFF004D25);
  static const Color jadeGreenTint = Color(0x1800BC57); // ~10% opacity

  // Neutral surfaces & Canvas
  static const Color white = Colors.white;
  static const Color canvas = Color(0xFFF7F8FA);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFEEF2F6);
  static const Color textPrimary = Color(0xFF0A2542);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  // Dark mode surfaces (deep navy palette derived from Prussian Blue)
  static const Color darkCanvas = Color(0xFF06182B);
  static const Color darkCard = Color(0xFF0D2845);
  static const Color darkCardElevated = Color(0xFF133863);
  static const Color darkBorder = Color(0xFF1E3A5A);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkTextSubtle = Color(0xFF64748B);

  // Alert & Warning (Strictly reserved for budget breaches & danger actions)
  static const Color alertRed = Color(0xFFEF4444);
  static const Color alertRedLight = Color(0xFFFEF2F2);
  static const Color alertRedTint = Color(0x1AEF4444);

  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberLight = Color(0xFFFEF3C7);
  static const Color warningAmberTint = Color(0x1AF59E0B);
}

// =============================================================================
// TYPOGRAPHY SYSTEM
// =============================================================================

/// Standardized typography hierarchy for CoSpend.
abstract final class CoSpendTypography {
  static const String fontFamily = 'Inter';

  // Display (Large marketing / splash headers)
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    height: 1.18,
    color: CoSpendColors.textPrimary,
  );

  // Headline (Screen titles & modal headers)
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.25,
    color: CoSpendColors.textPrimary,
  );

  // Title (Card headings, flatmate names)
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
    color: CoSpendColors.textPrimary,
  );

  // Body (Standard readable paragraphs & form values)
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: CoSpendColors.textPrimary,
  );

  // Body Small (Helper captions, secondary info)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: CoSpendColors.textMuted,
  );

  // Label (Button text, form labels, chip text)
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: CoSpendColors.textPrimary,
  );

  // Caption (Uppercase section labels, timestamps)
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: CoSpendColors.textMuted,
  );

  // Financial Display (Large hero numbers, e.g. Add Expense & Dashboard Hero)
  static const TextStyle financialDisplay = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    fontFeatures: [FontFeature.tabularFigures()],
    color: CoSpendColors.textPrimary,
  );

  // Financial Amount (Metric cards, transaction lists, budget caps)
  static const TextStyle financialAmount = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    fontFeatures: [FontFeature.tabularFigures()],
    color: CoSpendColors.textPrimary,
  );

  // Theme-aware resolver helpers
  static TextStyle ofDisplay(BuildContext context) => display.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? CoSpendColors.darkTextPrimary
            : CoSpendColors.textPrimary,
      );

  static TextStyle ofHeadline(BuildContext context) => headline.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? CoSpendColors.darkTextPrimary
            : CoSpendColors.textPrimary,
      );

  static TextStyle ofTitle(BuildContext context) => title.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? CoSpendColors.darkTextPrimary
            : CoSpendColors.textPrimary,
      );

  static TextStyle ofBody(BuildContext context) => body.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? CoSpendColors.darkTextPrimary
            : CoSpendColors.textPrimary,
      );

  static TextStyle ofBodySmall(BuildContext context) => bodySmall.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? CoSpendColors.darkTextMuted
            : CoSpendColors.textMuted,
      );

  static TextStyle ofCaption(BuildContext context) => caption.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? CoSpendColors.darkTextMuted
            : CoSpendColors.textMuted,
      );
}

// =============================================================================
// SPACING SCALE
// =============================================================================

/// Consistent 4px-baseline spacing scale.
abstract final class CoSpendSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;

  // Standard EdgeInsets helpers
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
}

// =============================================================================
// RADII & GEOMETRY
// =============================================================================

/// Standardized corner radii (Cards/Inputs = 12px, Pills/Buttons = 999px).
abstract final class CoSpendRadii {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double pill = 999.0;

  // Backward compatibility alias
  static const double card = medium;

  static final BorderRadius smallRadius = BorderRadius.circular(small);
  static final BorderRadius mediumRadius = BorderRadius.circular(medium);
  static final BorderRadius largeRadius = BorderRadius.circular(large);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
  static final BorderRadius cardRadius = BorderRadius.circular(card);
}

// =============================================================================
// ELEVATION & SHADOWS
// =============================================================================

/// Subtle Prussian-Blue-tinted shadows for fintech depth.
abstract final class CoSpendShadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x060A2542),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

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

  static const List<BoxShadow> softCard = [
    BoxShadow(
      color: Color(0x0C0A2542),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardSubtle = [
    BoxShadow(
      color: Color(0x080A2542),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x2800BC57),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> ctaGlow = [
    BoxShadow(
      color: Color(0x2800BC57),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

// =============================================================================
// ANIMATION CONSTANTS
// =============================================================================

/// Centralized animation durations and curves.
abstract final class CoSpendAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 450);

  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEntrance = Curves.easeOutCubic;
  static const Curve curveBounce = Curves.easeOutBack;
  static const Curve curveExit = Curves.easeInCubic;
}

// =============================================================================
// REUSABLE COMPONENTS
// =============================================================================

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
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 120),
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
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    if (isReducedMotionEnabled(context)) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
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

/// Standardized 12px rounded card with soft Prussian-tinted shadow.
class CoSpendCard extends StatelessWidget {
  const CoSpendCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CoSpendSpacing.md),
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
    final cardBg =
        color ?? (isDark ? CoSpendColors.darkCard : CoSpendColors.white);
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

/// Base button supporting primary, secondary, and text variants with tactile bounce.
class CoSpendButton extends StatelessWidget {
  const CoSpendButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52.0,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = backgroundColor ??
        (isDark ? CoSpendColors.jadeGreen : CoSpendColors.jadeGreen);
    final fg = foregroundColor ?? Colors.white;

    Widget child = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: onPressed == null ? bg.withValues(alpha: 0.4) : bg,
        borderRadius: CoSpendRadii.pillRadius,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: onPressed != null && bg == CoSpendColors.jadeGreen && !isDark
            ? CoSpendShadows.floating
            : null,
      ),
      alignment: Alignment.center,
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            )
          : Row(
              mainAxisSize:
                  isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: fg, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: fg,
                  ),
                ),
              ],
            ),
    );

    if (isFullWidth) {
      child = SizedBox(width: double.infinity, child: child);
    }

    return Semantics(
      button: true,
      label: label,
      enabled: !isLoading && onPressed != null,
      child: BouncingButton(
        onTap: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}

/// Primary action button in solid Jade Green.
class CoSpendPrimaryButton extends StatelessWidget {
  const CoSpendPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CoSpendButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      height: height,
      backgroundColor: CoSpendColors.jadeGreen,
      foregroundColor: Colors.white,
    );
  }
}

/// Secondary action button in Prussian Blue outline or subtle tinted background.
class CoSpendSecondaryButton extends StatelessWidget {
  const CoSpendSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CoSpendButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      height: height,
      backgroundColor: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
      foregroundColor:
          isDark ? CoSpendColors.white : CoSpendColors.prussianBlue,
      borderColor: isDark ? CoSpendColors.darkBorder : CoSpendColors.border,
    );
  }
}

/// Circular or rounded icon button with tinted background container.
class CoSpendIconButton extends StatelessWidget {
  const CoSpendIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.color = CoSpendColors.prussianBlue,
    this.tooltip,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color color;
  final String? tooltip;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticLabel ?? tooltip ?? 'Action';

    Widget button = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Center(
        child: BouncingButton(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return Semantics(
      button: true,
      label: effectiveLabel,
      enabled: onPressed != null,
      child: button,
    );
  }
}

/// Theme-aware text field with 12px corner radius.
class CoSpendTextField extends StatelessWidget {
  const CoSpendTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : CoSpendColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        filled: true,
        fillColor: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: isDark
                    ? CoSpendColors.darkTextMuted
                    : CoSpendColors.textMuted,
                size: 20,
              )
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: CoSpendRadii.cardRadius,
          borderSide: BorderSide(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: CoSpendRadii.cardRadius,
          borderSide: BorderSide(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: CoSpendRadii.cardRadius,
          borderSide: const BorderSide(
            color: CoSpendColors.prussianBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: CoSpendRadii.cardRadius,
          borderSide: const BorderSide(
            color: CoSpendColors.alertRed,
          ),
        ),
      ),
    );
  }
}

/// Hero monetary amount input field with bold "Rs." prefix and tabular digits.
class CoSpendAmountField extends StatelessWidget {
  const CoSpendAmountField({
    super.key,
    required this.controller,
    this.onChanged,
    this.currencyPrefix = 'Rs.',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String currencyPrefix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CoSpendCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AMOUNT',
            style: CoSpendTypography.ofCaption(context),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currencyPrefix,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? CoSpendColors.jadeGreen
                      : CoSpendColors.prussianBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  label: 'Expense amount in Pakistani Rupees',
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: onChanged,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stadium pill filter or tag chip with active and inactive states.
class CoSpendChip extends StatelessWidget {
  const CoSpendChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isSelected
        ? (isDark ? CoSpendColors.prussianBlueLight : CoSpendColors.prussianBlue)
        : (isDark ? CoSpendColors.darkCard : CoSpendColors.white);
    final fg = isSelected
        ? Colors.white
        : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted);
    final border = isSelected
        ? Border.all(color: bg)
        : Border.all(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          );

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label filter',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          child: BouncingButton(
            onTap: onTap,
            child: AnimatedContainer(
              duration: isReducedMotionEnabled(context)
                  ? Duration.zero
                  : CoSpendAnimations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: CoSpendRadii.pillRadius,
                border: border,
                boxShadow: isSelected && !isDark ? CoSpendShadows.subtle : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small status badge pill (e.g. "CONFIGURED", "EXCEEDED", "OWNER").
class CoSpendBadge extends StatelessWidget {
  const CoSpendBadge({
    super.key,
    required this.label,
    this.color = CoSpendColors.jadeGreen,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: CoSpendRadii.pillRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

/// Standardized uppercase section header with optional trailing action.
class CoSpendSectionHeader extends StatelessWidget {
  const CoSpendSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color:
                  isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CoSpendColors.jadeGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias for SectionLabel.
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
    return CoSpendSectionHeader(title: text, padding: padding);
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

/// Animated smooth progress bar with threshold color transitions.
class CoSpendProgressBar extends StatelessWidget {
  const CoSpendProgressBar({
    super.key,
    required this.percentUsed,
    this.height = 8.0,
  });

  final double percentUsed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clampedRatio = (percentUsed / 100.0).clamp(0.0, 1.0);
    final isExceeded = percentUsed > 100.0;
    final progressColor = isExceeded
        ? CoSpendColors.alertRed
        : (percentUsed >= 80.0
            ? CoSpendColors.warningAmber
            : CoSpendColors.jadeGreen);
    final statusText = isExceeded
        ? 'Exceeded limit'
        : (percentUsed >= 80.0 ? 'Approaching limit' : 'On track');
    final duration = isReducedMotionEnabled(context)
        ? Duration.zero
        : CoSpendAnimations.slow;

    return Semantics(
      label: 'Budget progress',
      value: '${percentUsed.toStringAsFixed(0)}% used, $statusText',
      child: ClipRRect(
        borderRadius: CoSpendRadii.pillRadius,
        child: Stack(
          children: [
            Container(
              height: height,
              color: CoSpendColors.borderLight,
            ),
            TweenAnimationBuilder<double>(
              duration: duration,
              curve: CoSpendAnimations.curveEntrance,
              tween: Tween<double>(begin: 0, end: clampedRatio),
              builder: (context, value, child) => FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: height,
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
    );
  }
}

/// Financial 2x2 metric card for dashboards.
class CoSpendStatCard extends StatelessWidget {
  const CoSpendStatCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    this.subtitle,
    this.color = CoSpendColors.prussianBlue,
    this.onTap,
  });

  final String title;
  final String amount;
  final IconData icon;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CoSpendCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TintedIcon(
                icon: icon,
                color: color,
                containerSize: 34,
                size: 18,
              ),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: CoSpendColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              fontFeatures: [FontFeature.tabularFigures()],
              color: CoSpendColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: CoSpendColors.textSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Universal modal bottom sheet with drag handle, title, and close button.
abstract final class CoSpendBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    String? subtitle,
    Widget? trailing,
    double maxHeightFraction = 0.88,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CoSpendBottomSheetScaffold(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        maxHeightFraction: maxHeightFraction,
        child: child,
      ),
    );
  }
}

/// Scaffolding for bottom sheets enforcing 12px corners and consistent header.
class CoSpendBottomSheetScaffold extends StatelessWidget {
  const CoSpendBottomSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.maxHeightFraction = 0.88,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final Widget? trailing;
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeightFraction,
      ),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? CoSpendColors.darkBorder : CoSpendColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : CoSpendColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Close',
                color: isDark
                    ? CoSpendColors.darkTextMuted
                    : CoSpendColors.textMuted,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Flexible(child: child),
        ],
      ),
    );
  }
}

/// Universal dialog card with 12px corners and soft shadow.
class CoSpendDialog extends StatelessWidget {
  const CoSpendDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: CoSpendCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TintedIcon(
                  icon: isDestructive
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
                  color: isDestructive
                      ? CoSpendColors.alertRed
                      : CoSpendColors.prussianBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : CoSpendColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? CoSpendColors.darkTextMuted
                    : CoSpendColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    cancelLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CoSpendButton(
                  label: confirmLabel,
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm?.call();
                  },
                  isFullWidth: false,
                  height: 42,
                  backgroundColor: isDestructive
                      ? CoSpendColors.alertRed
                      : CoSpendColors.jadeGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmering placeholder box with smooth animation.
class CoSpendSkeleton extends StatefulWidget {
  const CoSpendSkeleton({
    super.key,
    this.height = 16.0,
    this.width,
    this.radius = 8.0,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<CoSpendSkeleton> createState() => _CoSpendSkeletonState();
}

class _CoSpendSkeletonState extends State<CoSpendSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? CoSpendColors.darkCardElevated
        : CoSpendColors.surfaceMuted;
    final highlightColor = isDark
        ? CoSpendColors.darkBorder
        : CoSpendColors.white;

    if (isReducedMotionEnabled(context)) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: Color.lerp(baseColor, highlightColor, _controller.value),
              borderRadius: BorderRadius.circular(widget.radius),
            ),
          );
        },
      ),
    );
  }
}

/// Theme-aware empty state with tinted circular icon.
class CoSpendEmptyState extends StatelessWidget {
  const CoSpendEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TintedIcon(
              icon: icon,
              color: isDark ? CoSpendColors.jadeGreen : CoSpendColors.prussianBlue,
              containerSize: 56,
              size: 28,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : CoSpendColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? CoSpendColors.darkTextMuted
                    : CoSpendColors.textMuted,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              CoSpendPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Theme-aware error state with alert red tinted icon and retry action.
class CoSpendErrorState extends StatelessWidget {
  const CoSpendErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TintedIcon(
              icon: Icons.error_outline_rounded,
              color: CoSpendColors.alertRed,
              containerSize: 56,
              size: 28,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : CoSpendColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? CoSpendColors.darkTextMuted
                    : CoSpendColors.textMuted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              CoSpendSecondaryButton(
                label: 'Try again',
                onPressed: onRetry,
                isFullWidth: false,
                height: 44,
              ),
            ],
          ],
        ),
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
            child: Semantics(
              button: true,
              selected: isSelected,
              label: entry.value,
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: isReducedMotionEnabled(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? CoSpendColors.prussianBlueLight
                            : CoSpendColors.prussianBlue)
                        : Colors.transparent,
                    borderRadius: CoSpendRadii.pillRadius,
                    boxShadow: isSelected && !isDark
                        ? [
                            BoxShadow(
                              color: CoSpendColors.prussianBlue
                                  .withValues(alpha: 0.2),
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
                          : (isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted),
                    ),
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
            Semantics(
              label: 'Budget progress',
              value: '${percentUsed.toStringAsFixed(0)}% used, $progressText',
              child: ClipRRect(
                borderRadius: CoSpendRadii.pillRadius,
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    TweenAnimationBuilder<double>(
                      duration: isReducedMotionEnabled(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 600),
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
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    progressText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
