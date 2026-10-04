import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Title row for secondary screens; shows a back button when one is possible.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: EdgeInsets.fromLTRB(canPop ? 8 : 20, 16, 12, 8),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            if (canPop)
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const AppIconView(AppIcon.back, color: AppColors.deep),
              ),
            Expanded(
              child: Semantics(header: true, child: Text(title, style: AppText.title.copyWith(fontSize: 22))),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
