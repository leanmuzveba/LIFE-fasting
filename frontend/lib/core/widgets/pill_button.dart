import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Rounded full-width button from the mockup.
/// `large` = 54px primary CTA (Start/End fast); default = 48px sheet button.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.large = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final height = large ? 54.0 : 48.0;
    final shape = StadiumBorder(side: outlined ? const BorderSide(color: AppColors.deep, width: 1.5) : BorderSide.none);
    final style = TextStyle(
      fontFamily: 'Manrope',
      fontSize: large ? 17 : 15,
      fontWeight: FontWeight.w800,
      color: outlined ? AppColors.deep : AppColors.white,
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Container(
        height: height,
        decoration: large && !outlined
            ? const ShapeDecoration(shape: StadiumBorder(), shadows: AppShadows.button)
            : null,
        child: Material(
          color: outlined ? AppColors.white : AppColors.deep,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Text(label, style: style, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
