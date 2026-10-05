import 'package:flutter/widgets.dart';

/// The primary two-tone RUVA logo (brand guide "01 — Logo"). Use on white,
/// mint or cream only; minimum 32 px.
class RuvaLogo extends StatelessWidget {
  const RuvaLogo({super.key, this.size = 40, this.semanticLabel = 'RUVA'});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/ruva_logo.png',
    width: size,
    height: size,
    semanticLabel: semanticLabel,
    excludeFromSemantics: semanticLabel == null,
    filterQuality: FilterQuality.medium,
  );
}
