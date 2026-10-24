import 'package:flutter/widgets.dart';

/// The two-tone MagnaVita mark (forest figure, lime leaves). Use on white,
/// mint or cream only; minimum 32 px wide.
class RuvaLogo extends StatelessWidget {
  const RuvaLogo({super.key, this.size = 40, this.semanticLabel = 'MagnaVita'});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/logo.png',
    width: size,
    height: size,
    semanticLabel: semanticLabel,
    excludeFromSemantics: semanticLabel == null,
    filterQuality: FilterQuality.medium,
  );
}
