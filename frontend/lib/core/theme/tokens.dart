import 'package:flutter/material.dart';

/// RUVA design tokens (docs/BRANDING/Ruva_Brand_Guide.pdf, "02 — Colour").
/// Forest anchors brand, buttons and active states; lime marks progress and
/// highlights and is never used for text or behind white text.
abstract final class AppColors {
  static const primary = Color(0xFF135D44); // forest-700: buttons, links, headings, ring arc
  static const primaryDark = Color(0xFF11432F); // forest-800: text/icons on lime
  static const primaryMid = Color(0xFF2E7D57); // forest-500: focus rings, gradients
  static const soft = Color(0xFFEEF7EA); // forest-50: chips, selected pills, soft surfaces
  static const accent = Color(0xFFB9F36C); // lime-400: progress highlights (on forest only)
  static const accentSoft = Color(0xFFEEF9DC); // lime-100: input fills
  static const background = Color(0xFFF6FCEF); // mint
  static const cream = Color(0xFFFAFFDE); // logo background
  static const track = Color(0xFFD9EED0); // forest-100: unfilled ring, handles, outlines
  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFF1A2A20); // ink
  static const textSecondary = Color(0xFF4C5A50); // ink-600
  static const muted = Color(0xFF6F7C72); // between brand ink-600/400: 3:1+ for icons on mint
  static const divider = Color(0xFFDCEBD0); // line
  static const inputBorder = Color(0xFFCFF29A); // lime-300
  static const onAccent = Color(0xFF11432F); // icon on the lime current marker
  static const scrim = Color(0x610B2E20); // forest-900 at 38%

  // Semantic — status and feedback only.
  static const success = Color(0xFF2FA866);
  static const warning = Color(0xFFF2A93B);
  static const error = Color(0xFFE8573F);
  static const errorText = Color(0xFFB3401F); // error tone dark enough for text
  static const info = Color(0xFF3D8BD9);

  // Ring phases (PRD §2.2): fat burning = yellow, ketosis = red.
  static const fatBurning = Color(0xFFF2B705);
  static const onFatBurning = Color(0xFF4A3800);
  static const fatBurningIcon = Color(0xFF9A6F00); // darker amber: 4.3:1 on light surfaces
  static const ketosis = Color(0xFFE5484D);
  static const onKetosis = Color(0xFFFFFFFF);
}

/// Two soft layers at forest-700 6–8% (brand guide "Radius, spacing & elevation").
abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0F135D44), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x14135D44), offset: Offset(0, 10), blurRadius: 28),
  ];
  static const button = [BoxShadow(color: Color(0x33135D44), offset: Offset(0, 6), blurRadius: 16)];
  static const sheet = [BoxShadow(color: Color(0x1F0B2E20), offset: Offset(0, -8), blurRadius: 30)];
}
