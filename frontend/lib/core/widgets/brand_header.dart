import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme/app_theme.dart';
import 'ruva_logo.dart';

/// Logo + "RUVA" row at the top of the Today screen.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        const RuvaLogo(size: 36, semanticLabel: null),
        const SizedBox(width: 8),
        Semantics(header: true, child: Text(context.l10n.appName, style: AppText.brand)),
      ],
    ),
  );
}
