import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/page_header.dart';
import '../../domain/milestone.dart';
import '../home/home_sheets.dart';

/// Full milestone explanation with uncertainty notes ("Read more").
class MilestoneDetailScreen extends StatelessWidget {
  const MilestoneDetailScreen({super.key, required this.milestone});
  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader('Milestone'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  MilestoneHeader(milestone: milestone),
                  const SizedBox(height: 16),
                  Text(milestone.body, style: AppText.body),
                  const SizedBox(height: 16),
                  const DisclaimerBox(),
                  const SizedBox(height: 16),
                  const Text(
                    'The position of this marker is a visual reference for elapsed time. It is not proof that '
                    'anything has happened in your body, and reaching it is not a goal or a health achievement.',
                    style: AppText.small,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    milestone.reviewStatus == ReviewStatus.reviewed
                        ? 'Content reviewed${milestone.sourceReference == null ? '' : ' · ${milestone.sourceReference}'}'
                        : 'Draft educational copy — awaiting review by a qualified health professional.',
                    style: AppText.small.copyWith(fontStyle: FontStyle.italic, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
