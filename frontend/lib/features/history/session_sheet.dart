import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String? _error;
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

    if (_confirmDelete) {
      return Gap16Column(
        children: [
          Semantics(header: true, child: const Text('Delete this session?', style: AppText.title)),
          Text(
            'It will be removed from your history on this phone. This can’t be undone.',
            style: AppText.body.copyWith(color: AppColors.textSecondary),
          ),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'Cancel',
                  outlined: true,
                  onPressed: () => setState(() => _confirmDelete = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: 'Delete',
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
        Semantics(header: true, child: const Text('Session', style: AppText.title)),
        _TimeField(
          label: 'STARTED',
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
            label: 'ENDED',
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
        if (_error != null) Text(_error!, style: AppText.small.copyWith(color: const Color(0xFFB3261E))),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'Delete',
                outlined: true,
                onPressed: () => setState(() => _confirmDelete = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: 'Save',
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
        label: '${label.toLowerCase()} $value. Change',
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
