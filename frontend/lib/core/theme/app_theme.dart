import 'package:flutter/material.dart';

import 'tokens.dart';

/// RUVA type system (brand guide "03 — Typography"): Lexend for headings,
/// numbers, buttons and nav; DM Sans for body and UI copy; JetBrains Mono for
/// small uppercase eyebrows and data captions.
abstract final class AppFonts {
  static const display = 'Lexend';
  static const body = 'DM Sans';
  static const mono = 'JetBrains Mono';
}

abstract final class AppText {
  static const brand = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.primary,
  );
  static const dateLine = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Eyebrow: small uppercase label.
  static const overline = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );
  static const cardValue = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    fontFeatures: tabular,
  );
  static const cardSub = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const title = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    height: 23 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );
  static const small = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    height: 19 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Buttons and text links.
  static const link = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  static const tabular = [FontFeature.tabularFigures()];
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    secondary: AppColors.accent,
    onSecondary: AppColors.primaryDark,
    surface: AppColors.white,
    onSurface: AppColors.text,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.body,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(bodyMedium: AppText.body, titleLarge: AppText.title),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppText.link,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: AppText.body.copyWith(color: AppColors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.white,
      modalBarrierColor: AppColors.scrim,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      showDragHandle: false,
    ),
  );
}
