import 'package:flutter/material.dart';

import 'design_system.dart';

/// Premium fintech Material 3 theme for CoSpend.
/// Inspired by Revolut, Monarch Money, and Apple Wallet.
/// Built with Jade Green (#00BC57), Prussian Blue (#0A2542), and off-white canvas (#F5F7FA).
abstract final class AppTheme {
  static const Color jadeGreen = CoSpendColors.jadeGreen;
  static const Color prussianBlue = CoSpendColors.prussianBlue;
  static const Color pureWhite = CoSpendColors.white;
  static const Color canvasLight = CoSpendColors.canvas;
  static const Color canvasDark = CoSpendColors.darkCanvas;

  // Status accents
  static const Color roseColor = CoSpendColors.alertRed;
  static const Color amberColor = CoSpendColors.warningAmber;

  static const double cardRadius = CoSpendRadii.card;
  static const double pillRadius = CoSpendRadii.pill;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = isDark
        ? const ColorScheme(
            brightness: Brightness.dark,
            primary: jadeGreen,
            onPrimary: pureWhite,
            primaryContainer: Color(0xFF004D25),
            onPrimaryContainer: Color(0xFF6EFEA8),
            secondary: Color(0xFF38BDF8),
            onSecondary: prussianBlue,
            secondaryContainer: Color(0xFF0E335B),
            onSecondaryContainer: Color(0xFFBAE6FD),
            tertiary: Color(0xFF34D399),
            onTertiary: prussianBlue,
            error: roseColor,
            onError: pureWhite,
            surface: Color(0xFF0D2845),
            onSurface: pureWhite,
            surfaceContainerLowest: Color(0xFF061629),
            surfaceContainerLow: Color(0xFF0E2F54),
            surfaceContainer: Color(0xFF133863),
            surfaceContainerHigh: Color(0xFF1A4575),
            surfaceContainerHighest: Color(0xFF245288),
            onSurfaceVariant: Color(0xFFCBD5E1),
            outline: Color(0xFF335075),
            outlineVariant: Color(0xFF183B64),
          )
        : const ColorScheme(
            brightness: Brightness.light,
            primary: jadeGreen,
            onPrimary: pureWhite,
            primaryContainer: Color(0xFFE4F9EE),
            onPrimaryContainer: Color(0xFF004D25),
            secondary: prussianBlue,
            onSecondary: pureWhite,
            secondaryContainer: Color(0xFFEBF1F7),
            onSecondaryContainer: prussianBlue,
            tertiary: Color(0xFF059669),
            onTertiary: pureWhite,
            error: roseColor,
            onError: pureWhite,
            surface: pureWhite,
            onSurface: prussianBlue,
            surfaceContainerLowest: pureWhite,
            surfaceContainerLow: canvasLight,
            surfaceContainer: Color(0xFFF1F5F9),
            surfaceContainerHigh: Color(0xFFE2E8F0),
            surfaceContainerHighest: Color(0xFFCBD5E1),
            onSurfaceVariant: Color(0xFF64748B),
            outline: Color(0xFF94A3B8),
            outlineVariant: Color(0xFFE2E8F0),
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? canvasDark : canvasLight,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? CoSpendColors.darkCard : pureWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CoSpendRadii.card),
          side: BorderSide(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
            width: 0.8,
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? CoSpendColors.darkCard : pureWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: scheme.onSurfaceVariant,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0A223D) : pureWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
        ),
        labelStyle: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: scheme.secondary,
        ),
        border: _outlineBorder(
          isDark ? CoSpendColors.darkBorder : CoSpendColors.border,
        ),
        enabledBorder: _outlineBorder(
          isDark ? CoSpendColors.darkBorder : CoSpendColors.border,
        ),
        focusedBorder: _outlineBorder(prussianBlue, width: 1.8),
        errorBorder: _outlineBorder(scheme.error),
        focusedErrorBorder: _outlineBorder(scheme.error, width: 1.8),
        errorStyle: TextStyle(fontSize: 12, color: scheme.error),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: jadeGreen,
          foregroundColor: pureWhite,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: const StadiumBorder(),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 50),
          backgroundColor: jadeGreen,
          foregroundColor: pureWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: const StadiumBorder(),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          foregroundColor: isDark ? pureWhite : prussianBlue,
          side: BorderSide(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.border,
            width: 1,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: const StadiumBorder(),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: prussianBlue,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(
          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.border,
          width: 1,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF071A2E) : pureWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: jadeGreen.withValues(alpha: 0.12),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            letterSpacing: isSelected ? 0.1 : 0,
            color: isSelected
                ? jadeGreen
                : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: isSelected
                ? jadeGreen
                : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
          );
        }),
      ),

      dividerTheme: DividerThemeData(
        color: isDark
            ? CoSpendColors.darkBorder
            : CoSpendColors.borderLight,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? CoSpendColors.darkCard : pureWhite,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(cardRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
