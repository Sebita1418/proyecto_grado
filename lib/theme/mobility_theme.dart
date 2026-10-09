import 'package:flutter/material.dart';

/// Small set of shared visual tokens for map, planner and mobility sheets.
abstract final class MobilityDesign {
  static const String fontFamily = 'Roboto';
  static const Color brand = Color(0xFF1769E0);
  static const Color ink = Color(0xFF10233F);
  static const Color canvas = Color(0xFFF5F6FA);
  static const Color positive = Color(0xFF16865C);
  static const Color warning = Color(0xFFC27613);
  static const Color danger = Color(0xFFD83B46);

  static const double pageInset = 16;
  static const double compactInset = 12;
  static const double controlSize = 48;
  static const double cardRadius = 16;
  static const double sheetRadius = 24;
  static const double controlRadius = 12;
  static const double floatingElevation = 4;
  static const double panelElevation = 6;
  static double appBarHeight(TextScaler scaler) =>
      scaler.scale(20) > 26 ? 16 + 3 * scaler.scale(20) * 1.2 : kToolbarHeight;
}

abstract final class MobilityTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: MobilityDesign.brand,
          brightness: Brightness.light,
          surface: Colors.white,
        ).copyWith(
          primary: MobilityDesign.brand,
          onPrimary: Colors.white,
          error: MobilityDesign.danger,
          onError: Colors.white,
          outlineVariant: const Color(0xFFDDE3EC),
        );
    final outline = scheme.outlineVariant.withValues(alpha: .72);
    final rounded = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: outline),
    );

    return ThemeData(
      fontFamily: MobilityDesign.fontFamily,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MobilityDesign.canvas,
      textTheme: Typography.material2021().black
          .apply(
            bodyColor: MobilityDesign.ink,
            displayColor: MobilityDesign.ink,
          )
          .copyWith(
            titleLarge: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MobilityDesign.ink,
              height: 1.25,
            ),
            titleMedium: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MobilityDesign.ink,
              height: 1.3,
            ),
            titleSmall: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MobilityDesign.ink,
              height: 1.3,
            ),
            bodyMedium: const TextStyle(
              fontSize: 12,
              color: MobilityDesign.ink,
              height: 1.4,
            ),
            bodySmall: const TextStyle(
              fontSize: 11,
              color: MobilityDesign.ink,
              height: 1.4,
            ),
          )
          .apply(fontFamily: MobilityDesign.fontFamily),
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: MobilityDesign.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: MobilityDesign.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MobilityDesign.cardRadius),
          side: BorderSide(color: outline.withValues(alpha: .55)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 52),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MobilityDesign.controlRadius),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        labelStyle: TextStyle(
          fontFamily: MobilityDesign.fontFamily,
          color: scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: MobilityDesign.fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: outline),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
