import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/fasting_session.dart';
import '../../state/providers.dart';

Future<void> showSessionSheet(BuildContext context, FastingSession session) =>
    showAppSheet<void>(context, (_) => _SessionSheet(session: session));

class _SessionSheet extends ConsumerStatefulWidget {
  const _SessionSheet({required this.session});
  final FastingSession session;

  @override
  ConsumerState<_SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends ConsumerState<_SessionSheet> {
  late DateTime _start = widget.session.startedAt.toLocal();
  late DateTime? _end = widget.session.endedAt?.toLocal();
  SessionTimeError? _error;
  bool _confirmDelete = false;

  Future<DateTime?> _pick(DateTime initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final use24h = ref.watch(settingsProvider).value?.use24HourTime ?? false;
    String label(DateTime t) => '${formatShortDay(t)}, ${formatClock(t, use24h: use24h)}';
    final l = context.l10n;

    if (_confirmDelete) {
      return Gap16Column(
        children: [
          Semantics(header: true, child: Text(l.deleteSessionTitle, style: AppText.title)),
          Text(l.deleteSessionBody, style: AppText.body.copyWith(color: AppColors.textSecondary)),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: l.cancel,
                  outlined: true,
                  onPressed: () => setState(() => _confirmDelete = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: l.delete,
                  onPressed: () async {
                    await ref.read(sessionActionsProvider).delete(widget.session);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Gap16Column(
      children: [
        Semantics(header: true, child: Text(l.sessionTitle, style: AppText.title)),
        _TimeField(
          label: l.sessionStarted,
          value: label(_start),
          onTap: () async {
            final t = await _pick(_start);
            if (t == null) return;
            setState(() {
              _start = t;
              _error = null;
            });
          },
        ),
        if (_end != null)
          _TimeField(
            label: l.sessionEnded,
            value: label(_end!),
            onTap: () async {
              final t = await _pick(_end!);
              if (t == null) return;
              setState(() {
                _end = t;
                _error = null;
              });
            },
          ),
        if (_error != null) Text(_error!.message(l), style: AppText.small.copyWith(color: const Color(0xFFB3261E))),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: l.delete,
                outlined: true,
                onPressed: () => setState(() => _confirmDelete = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: l.save,
                onPressed: () async {
                  final error = await ref
                      .read(sessionActionsProvider)
                      .save(widget.session.copyWith(startedAt: _start.toUtc(), endedAt: () => _end?.toUtc()));
                  if (!context.mounted) return;
                  if (error == null) {
                    Navigator.pop(context);
                  } else {
                    setState(() => _error = error);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: AppText.overline.copyWith(fontSize: 12, letterSpacing: 0.96)),
      const SizedBox(height: 6),
      Semantics(
        button: true,
        label: context.l10n.timeFieldSemantics(label.toLowerCase(), value),
        excludeSemantics: true,
        child: Material(
          color: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppText.cardValue.copyWith(fontSize: 17)),
            ),
          ),
        ),
      ),
    ],
  );
}
