import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/page_header.dart';

/// Nutrition tab (PRD v1.2 §2.3): food diary, My Kitchen and recipes will
/// live here. Empty until those features are built.
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(l.navNutrition),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
                    child: const AppIconView(AppIcon.nutrition, size: 30, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(l.nutritionEmptyTitle, style: AppText.title, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(l.nutritionEmptyBody, style: AppText.small, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
