import 'package:flutter/material.dart';

/// Clean, professional Material 3 theme for CoSpend:
/// Built with Jade Green (#00BC57), Prussian Blue (#0A2542), and crisp White/Slate (#FFFFFF).
abstract final class AppTheme {
  static const Color jadeGreen = Color(0xFF00BC57);
  static const Color prussianBlue = Color(0xFF0A2542);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color slateLight = Color(0xFFF8FAFC);

  // Status accents
  static const Color roseColor = Color(0xFFEF4444);
  static const Color amberColor = Color(0xFFF59E0B);
  static const Color skyColor = Color(0xFF0EA5E9);

  static const double radius = 16;

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
            surface: prussianBlue,
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
            surfaceContainerLow: slateLight,
            surfaceContainer: Color(0xFFF1F5F9),
            surfaceContainerHigh: Color(0xFFE2E8F0),
            surfaceContainerHighest: Color(0xFFCBD5E1),
            onSurfaceVariant: Color(0xFF475569),
            outline: Color(0xFF94A3B8),
            outlineVariant: Color(0xFFE2E8F0),
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF06182C) : slateLight,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: scheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? scheme.surfaceContainerLow : scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerLow : scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
          vertical: 16,
        ),
        hintStyle: TextStyle(
          fontSize: 14.5,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
        ),
        labelStyle: TextStyle(fontSize: 14.5, color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
        border: _outlineBorder(
          isDark
              ? Colors.white.withValues(alpha: 0.12)
              : scheme.outlineVariant.withValues(alpha: 0.7),
        ),
        enabledBorder: _outlineBorder(
          isDark
              ? Colors.white.withValues(alpha: 0.12)
              : scheme.outlineVariant.withValues(alpha: 0.7),
        ),
        focusedBorder: _outlineBorder(scheme.primary, width: 1.8),
        errorBorder: _outlineBorder(scheme.error),
        focusedErrorBorder: _outlineBorder(scheme.error, width: 1.8),
        errorStyle: TextStyle(fontSize: 12.5, color: scheme.error),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 52),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF071A2E) : pureWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),

      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerLow : scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
