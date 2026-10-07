import 'package:flutter/material.dart';

/// App-wide Material 3 theme: an indigo-violet ink palette with a calm
/// paper-white light mode and a deep charcoal dark mode.
final class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF5B5FEF);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final background = isDark ? const Color(0xFF101014) : const Color(0xFFF6F6FB);
    final textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.outline),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor:
            isDark ? scheme.surfaceContainerHigh : scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? scheme.onSurface : scheme.onInverseSurface,
        ),
        actionTextColor: isDark ? scheme.primary : scheme.onInverseSurface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? scheme.surfaceContainerHigh : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelTextStyle: WidgetStatePropertyAll(textTheme.bodyLarge),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHighest : Colors.white,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
        ),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : scheme.outlineVariant.withValues(alpha: 0.7),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.25),
        selectionHandleColor: scheme.primary,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final color = scheme.onSurface;
    TextStyle base(
      double size, {
      FontWeight weight = FontWeight.w400,
      double? spacing,
      double? height,
    }) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height,
        color: color,
      );
    }

    return TextTheme(
      displaySmall: base(34, weight: FontWeight.w700, spacing: -0.9),
      headlineMedium: base(28, weight: FontWeight.w700, spacing: -0.6),
      headlineSmall: base(23, weight: FontWeight.w600, spacing: -0.4),
      titleLarge: base(20, weight: FontWeight.w600, spacing: -0.3),
      titleMedium: base(16.5, weight: FontWeight.w600, spacing: -0.2),
      titleSmall: base(14, weight: FontWeight.w600, spacing: -0.1),
      bodyLarge: base(16, height: 1.5),
      bodyMedium: base(14, height: 1.45),
      bodySmall: base(12.5, height: 1.4),
      labelLarge: base(14.5, weight: FontWeight.w600, spacing: 0.1),
      labelMedium: base(12.5, weight: FontWeight.w500, spacing: 0.1),
      labelSmall: base(11, weight: FontWeight.w600, spacing: 0.5),
    ).apply(bodyColor: color, displayColor: color);
  }
}
