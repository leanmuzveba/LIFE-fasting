import 'package:flutter/material.dart';

/// Design tokens taken from the Home mockup (Fasting Companion UI).
/// Hex values are approximations of the LIFE look, per the PRD.
abstract final class AppColors {
  static const sky = Color(0xFF65BFE8); // primary, active ring
  static const deep = Color(0xFF246B8E); // headings, buttons
  static const pale = Color(0xFFEAF7FC); // soft surfaces, chips
  static const background = Color(0xFFF5FBFE);
  static const track = Color(0xFFD8EDF6); // unfilled ring
  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFF203443);
  static const textSecondary = Color(0xFF526775);
  static const muted = Color(0xFF7A93A1); // upcoming marker icons
  static const divider = Color(0xFFE3F0F6);
  static const inputBorder = Color(0xFFC5DCE7);
  static const dashed = Color(0xFFB9D3E0);
  static const onSky = Color(0xFF0F3A52); // icon on the current marker
  static const scrim = Color(0x61102634); // rgba(16,38,52,0.38)
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0D203443), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x12246B8E), offset: Offset(0, 6), blurRadius: 18),
  ];
  static const button = [BoxShadow(color: Color(0x40246B8E), offset: Offset(0, 6), blurRadius: 16)];
  static const sheet = [BoxShadow(color: Color(0x1F102634), offset: Offset(0, -8), blurRadius: 30)];
}
