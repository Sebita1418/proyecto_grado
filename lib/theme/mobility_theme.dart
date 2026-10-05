import 'package:flutter/material.dart';

/// Small set of shared visual tokens for map, planner and mobility sheets.
abstract final class MobilityDesign {
  static const Color brand = Color(0xFF1459A6);
  static const Color ink = Color(0xFF172B45);
  static const Color canvas = Color(0xFFF3F7FC);
  static const Color positive = Color(0xFF28754B);
  static const Color warning = Color(0xFF9A5B00);

  static const double pageInset = 16;
  static const double compactInset = 12;
  static const double controlSize = 48;
  static const double cardRadius = 20;
  static const double sheetRadius = 28;
}

abstract final class MobilityTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: MobilityDesign.brand,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    final outline = scheme.outlineVariant.withValues(alpha: .72);
    final rounded = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: outline),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MobilityDesign.canvas,
      textTheme: Typography.material2021().black.apply(
        bodyColor: MobilityDesign.ink,
        displayColor: MobilityDesign.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: rounded,
        enabledBorder: rounded,
        focusedBorder: rounded.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: rounded.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: rounded.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MobilityDesign.sheetRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
