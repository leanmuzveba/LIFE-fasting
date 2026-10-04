import 'package:flutter/material.dart';

import 'tokens.dart';

/// Named text styles from the mockup. letterSpacing in em × fontSize.
abstract final class AppText {
  static const _f = 'Manrope';

  static const brand = TextStyle(
    fontFamily: _f,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.17,
    color: AppColors.deep,
  );
  static const dateLine = TextStyle(
    fontFamily: _f,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const overline = TextStyle(
    fontFamily: _f,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
    color: AppColors.textSecondary,
  );
  static const cardValue = TextStyle(fontFamily: _f, fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text);
  static const cardSub = TextStyle(
    fontFamily: _f,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const title = TextStyle(
    fontFamily: _f,
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontFamily: _f,
    fontSize: 15,
    height: 23 / 15,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );
  static const small = TextStyle(
    fontFamily: _f,
    fontSize: 13,
    height: 19 / 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const link = TextStyle(fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deep);
  static const tabular = [FontFeature.tabularFigures()];
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.deep,
    onPrimary: AppColors.white,
    secondary: AppColors.sky,
    surface: AppColors.white,
    onSurface: AppColors.text,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(bodyMedium: AppText.body, titleLarge: AppText.title),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.deep,
        textStyle: AppText.link,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.white,
      modalBarrierColor: AppColors.scrim,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      showDragHandle: false,
    ),
  );
}
