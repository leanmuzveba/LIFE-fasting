import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/page_header.dart';
import '../../domain/milestone.dart';
import '../home/home_sheets.dart';

/// Full milestone explanation with uncertainty notes ("Read more").
class MilestoneDetailScreen extends StatelessWidget {
  const MilestoneDetailScreen({super.key, required this.milestone});
  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(l.milestoneTitle),
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
                  Text(l.milestoneMarkerNote, style: AppText.small),
                  const SizedBox(height: 12),
                  Text(
                    milestone.reviewStatus != ReviewStatus.reviewed
                        ? l.milestoneDraft
                        : milestone.sourceReference == null
                        ? l.milestoneReviewed
                        : l.milestoneReviewedSource(milestone.sourceReference!),
                    style: AppText.small.copyWith(fontStyle: FontStyle.italic),
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
