import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/fasting_session.dart';
import '../../domain/milestone.dart';
import '../../state/providers.dart';
import '../ring/fasting_ring.dart';

Widget _buttonRow(List<Widget> buttons) => Row(
  children: [
    for (var i = 0; i < buttons.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: buttons[i])],
  ],
);

/// Shared uncertainty notice (FR-13), shown on every milestone view.
class DisclaimerBox extends StatelessWidget {
  const DisclaimerBox({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.track),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1),
          child: AppIconView(AppIcon.info, size: 18, color: AppColors.deep),
        ),
        SizedBox(width: 10),
        Expanded(child: Text(milestoneDisclaimer, style: AppText.small)),
      ],
    ),
  );
}

class MilestoneHeader extends StatelessWidget {
  const MilestoneHeader({super.key, required this.milestone});
  final Milestone milestone;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.pale, shape: BoxShape.circle),
        child: AppIconView(
          milestoneIcon(milestone.kind, detailed: true),
          size: 26,
          color: AppColors.deep,
          strokeWidth: 1.8,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(milestone.title, style: AppText.title)),
            Text(milestone.window, style: AppText.dateLine.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ],
  );
}

Future<void> showMilestoneSheet(
  BuildContext context, {
  required Milestone milestone,
  required VoidCallback onReadMore,
}) => showAppSheet<void>(
  context,
  (ctx) => Gap16Column(
    children: [
      MilestoneHeader(milestone: milestone),
      Text(milestone.body, style: AppText.body),
      const DisclaimerBox(),
      _buttonRow([
        PillButton(
          label: 'Read more',
          outlined: true,
          onPressed: () {
            Navigator.pop(ctx);
            onReadMore();
          },
        ),
        PillButton(label: 'Close', onPressed: () => Navigator.pop(ctx)),
      ]),
    ],
  ),
);

/// Returns the ended session if the user confirmed.
Future<FastingSession?> showEndSheet(BuildContext context) => showAppSheet<FastingSession>(
  context,
  (ctx) => Consumer(
    builder: (ctx, ref, _) {
      final s = ref.watch(activeSessionProvider).value;
      final now = ref.watch(nowProvider).value ?? DateTime.now();
      return Gap16Column(
        children: [
          Semantics(header: true, child: const Text('End this session?', style: AppText.title)),
          Text.rich(
            TextSpan(
              style: AppText.body.copyWith(color: AppColors.textSecondary),
              children: [
                const TextSpan(text: 'Recorded so far: '),
                TextSpan(
                  text: s == null ? '0 h 0 m' : formatHoursMinutes(s.elapsedAt(now)),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text),
                ),
                const TextSpan(text: '. You can end a session whenever you choose. It will be saved to your history.'),
              ],
            ),
          ),
          _buttonRow([
            PillButton(label: 'Cancel', outlined: true, onPressed: () => Navigator.pop(ctx)),
            PillButton(
              label: 'End session',
              onPressed: () async {
                final ended = await ref.read(activeSessionProvider.notifier).end();
                if (ctx.mounted) Navigator.pop(ctx, ended);
              },
            ),
          ]),
        ],
      );
    },
  ),
);

Future<void> showEditStartSheet(BuildContext context, {required DateTime startedAt}) =>
    showAppSheet<void>(context, (ctx) => _EditStartSheet(initial: TimeOfDay.fromDateTime(startedAt.toLocal())));

class _EditStartSheet extends ConsumerStatefulWidget {
  const _EditStartSheet({required this.initial});
  final TimeOfDay initial;

  @override
  ConsumerState<_EditStartSheet> createState() => _EditStartSheetState();
}

class _EditStartSheetState extends ConsumerState<_EditStartSheet> {
  late TimeOfDay _time = widget.initial;
  String? _error;

  DateTime _resolved() =>
      resolveStartFromClockTime(hour: _time.hour, minute: _time.minute, now: ref.read(clockProvider)());

  Future<void> _pick() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t == null) return;
    setState(() {
      _time = t;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final use24h = ref.watch(settingsProvider).value?.use24HourTime ?? false;
    final start = _resolved();
    final display = MaterialLocalizations.of(context).formatTimeOfDay(_time, alwaysUse24HourFormat: use24h);
    return Gap16Column(
      children: [
        Semantics(header: true, child: const Text('Edit start time', style: AppText.title)),
        Text(
          'Forgot to press Start? Set when you actually began. The ring, remaining time and history update after you save.',
          style: AppText.body.copyWith(fontSize: 14, height: 21 / 14, color: AppColors.textSecondary),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('STARTED AT', style: AppText.overline.copyWith(fontSize: 12, letterSpacing: 0.96)),
            const SizedBox(height: 6),
            Semantics(
              button: true,
              label: 'Started at $display. Change time',
              excludeSemantics: true,
              child: Material(
                color: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pick,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.centerLeft,
                    child: Text(display, style: AppText.cardValue),
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          _error ?? 'Will start ${formatShortDay(start)} at ${formatClock(start, use24h: use24h)}.',
          style: AppText.small.copyWith(color: _error == null ? AppColors.textSecondary : const Color(0xFFB3261E)),
        ),
        _buttonRow([
          PillButton(label: 'Cancel', outlined: true, onPressed: () => Navigator.pop(context)),
          PillButton(
            label: 'Save',
            onPressed: () async {
              final error = await ref.read(activeSessionProvider.notifier).editStart(_resolved());
              if (!context.mounted) return;
              if (error == null) {
                Navigator.pop(context);
              } else {
                setState(() => _error = error);
              }
            },
          ),
        ]),
      ],
    );
  }
}
