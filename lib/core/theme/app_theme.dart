import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The small, intentionally restrained palette used throughout Zindagi+.
class AppColors {
  AppColors._();

  static const background = Color(0xFF0F1115);
  static const surface = Color(0xFF181C22);
  static const surfaceHigh = Color(0xFF232932);
  static const emerald = Color(0xFF43D6A2);
  static const mint = Color(0xFF9AF4D0);
  static const cyan = Color(0xFF63DDF4);
  static const blue = Color(0xFF6D8CFF);
  static const textPrimary = Color(0xFFF5F7F8);
  static const textSecondary = Color(0xFFABB4C0);
  static const textTertiary = Color(0xFF737D89);
  static const error = Color(0xFFFF7983);
  static const warning = Color(0xFFFFC76B);
  static const success = emerald;
  static const info = blue;

  // Kept as aliases so existing features retain their business/UI contracts.
  static const primary = emerald;
  static const primaryLight = mint;
  static const primaryDark = Color(0xFF16785A);
  static const accent = emerald;
  static const divider = Color(0xFF303842);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emerald,
        secondary: AppColors.cyan,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    final text = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface.withValues(alpha: .82),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.mint),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: _inputBorder(AppColors.divider),
        enabledBorder: _inputBorder(AppColors.divider),
        focusedBorder: _inputBorder(AppColors.mint, 1.4),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, 1.4),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface.withValues(alpha: .78), elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: color, width: width));
}
