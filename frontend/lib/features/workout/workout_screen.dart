import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/activity.dart';
import '../../domain/profile.dart';
import '../../domain/workout.dart';
import '../../state/providers.dart';
import 'exercise_detail.dart';
import 'exercise_picker.dart';

/// "12:34", or "1:02:03" past an hour.
String formatClockDuration(Duration d) {
  final s = d.inSeconds.clamp(0, 359999);
  String two(int n) => n.toString().padLeft(2, '0');
  return s >= 3600 ? '${s ~/ 3600}:${two(s ~/ 60 % 60)}:${two(s % 60)}' : '${s ~/ 60}:${two(s % 60)}';
}

/// The strength session in progress: exercises, each set's weight and reps
/// (tick it off when done) and the rest timer between sets.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Future<void> _add() async {
    final picked = await showExercisePicker(context);
    if (picked != null) await ref.read(workoutProvider.notifier).addExercise(picked.$1, libraryId: picked.$2);
  }

  Future<void> _finish() async {
    final l = context.l10n;
    final saved = await ref.read(workoutProvider.notifier).finish();
    if (!mounted) return;
    if (saved == null) {
      showRuvaSnack(context, l.workoutNothingDone);
      return;
    }
    showRuvaSnack(context, l.workoutSaved(saved.minutes, saved.exercises.fold(0, (n, x) => n + x.sets)));
    Navigator.pop(context);
  }

  Future<void> _discard() => showAppSheet<void>(
    context,
    (ctx) => Gap16Column(
      children: [
        Semantics(header: true, child: Text(ctx.l10n.workoutDiscardTitle, style: AppText.title)),
        Text(ctx.l10n.workoutDiscardBody, style: AppText.body.copyWith(color: AppColors.textSecondary)),
        Row(
          children: [
            Expanded(
              child: PillButton(label: ctx.l10n.cancel, outlined: true, onPressed: () => Navigator.pop(ctx)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: ctx.l10n.workoutDiscard,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(workoutProvider.notifier).discard();
                  if (mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Vibrate when the rest is over, if you're looking at the screen.
    ref.listen(nowProvider, (prev, next) {
      final until = ref.read(workoutProvider).value?.restUntil;
      final (a, b) = (prev?.value, next.value);
      if (until != null && a != null && b != null && a.isBefore(until) && !b.isBefore(until)) {
        HapticFeedback.vibrate();
      }
    });
    final w = ref.watch(workoutProvider).value;
    final now = ref.watch(nowProvider).value ?? ref.read(clockProvider)();
    final imperial = ref.watch(settingsProvider).value?.units == UnitSystem.imperial;
    final history = ref.watch(exerciseHistoryProvider).value ?? const {};
    if (w == null) return const Scaffold(body: SizedBox.shrink());
    final resting = w.restUntil != null && w.restUntil!.isAfter(now);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ScreenHeader(
                title: l.workoutTitle,
                subtitle: l.workoutElapsed(formatClockDuration(now.difference(w.startedAt)), w.doneSets),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (w.exercises.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(l.workoutEmpty, textAlign: TextAlign.center, style: AppText.body),
                    ),
                  for (final (i, x) in w.exercises.indexed) ...[
                    _ExerciseCard(
                      index: i,
                      exercise: x,
                      // The session before this one (this one isn't saved yet).
                      last: history[exerciseKey(x)]?.first.$2,
                      imperial: imperial,
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _add,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l.workoutAddExercise),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(label: l.workoutFinish, onPressed: w.doneSets == 0 ? null : _finish),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _discard,
                    style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
                    child: Text(l.workoutDiscard),
                  ),
                ],
              ),
            ),
            if (resting) _RestBar(left: w.restUntil!.difference(now)),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.index, required this.exercise, required this.last, required this.imperial});
  final int index;
  final Exercise exercise;
  final Exercise? last;
  final bool imperial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final n = ref.read(workoutProvider.notifier);
    final head = AppText.small.copyWith(fontSize: 12, fontWeight: FontWeight.w600);
    return RuvaCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(exercise.name, style: AppText.cardValue.copyWith(fontSize: 16))),
              if (ref.watch(exerciseLibraryProvider).value?.where((x) => x.id == exercise.libraryId).firstOrNull
                  case final x?)
                IconButton(
                  tooltip: l.exerciseAbout(exercise.name),
                  icon: const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                  onPressed: () => showExerciseDetail(context, x),
                ),
              IconButton(
                tooltip: l.workoutRemoveExercise(exercise.name),
                icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                onPressed: () => n.removeExercise(index),
              ),
            ],
          ),
          if (last != null)
            Text(l.workoutLastTime(last!.describe(imperial: imperial)), style: AppText.small.copyWith(fontSize: 12.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(width: 36, child: Text(l.workoutSet, style: head)),
              Expanded(
                child: Text(imperial ? 'lb' : 'kg', style: head, textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text(l.workoutReps, style: head, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 96),
            ],
          ),
          for (final (j, s) in exercise.log.indexed)
            Row(
              key: ValueKey('set-$index-$j-${exercise.log.length}'),
              children: [
                SizedBox(width: 36, child: Text('${j + 1}', style: AppText.cardValue.copyWith(fontSize: 15))),
                Expanded(
                  child: _NumberField(
                    value: s.kg == null ? '' : formatLoad(s.kg!, imperial: imperial).split(' ').first,
                    decimal: true,
                    label: '${l.workoutSet} ${j + 1}, ${imperial ? 'lb' : 'kg'}',
                    onChanged: (v) {
                      final x = double.tryParse(v.replaceAll(',', '.'));
                      n.updateSet(index, j, s.copyWith(kg: () => x == null ? null : (imperial ? x * 0.45359237 : x)));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    value: '${s.reps}',
                    label: '${l.workoutSet} ${j + 1}, ${l.workoutReps}',
                    onChanged: (v) {
                      final r = int.tryParse(v);
                      if (r != null && r > 0) n.updateSet(index, j, s.copyWith(reps: r));
                    },
                  ),
                ),
                IconButton(
                  tooltip: s.done ? l.workoutSetDone(j + 1) : l.workoutSetTodo(j + 1),
                  isSelected: s.done,
                  icon: Icon(
                    s.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: s.done ? AppColors.primary : AppColors.muted,
                  ),
                  onPressed: () => n.toggleDone(index, j),
                ),
                IconButton(
                  tooltip: l.workoutRemoveSet(j + 1),
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.muted),
                  onPressed: () => n.removeSet(index, j),
                ),
              ],
            ),
          TextButton.icon(
            onPressed: () => n.addSet(index),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.workoutAddSet),
          ),
        ],
      ),
    );
  }
}

/// A small number box that keeps its own text while you type.
class _NumberField extends StatefulWidget {
  const _NumberField({required this.value, required this.label, required this.onChanged, this.decimal = false});
  final String value;
  final String label;
  final ValueChanged<String> onChanged;
  final bool decimal;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _c = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    child: TextField(
      controller: _c,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
      style: AppText.cardValue.copyWith(fontSize: 15),
      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
      onChanged: widget.onChanged,
    ),
  );
}

/// Counts down the rest between sets; ±15 s changes this and later rests.
class _RestBar extends ConsumerWidget {
  const _RestBar({required this.left});
  final Duration left;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final n = ref.read(workoutProvider.notifier);
    final total = ref.watch(restSecondsProvider).value ?? defaultRestSeconds;
    const onForest = AppColors.white;
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: (left.inMilliseconds / (total * 1000)).clamp(0.0, 1.0),
            color: AppColors.accent,
            backgroundColor: AppColors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '${l.restTitle} ${formatClockDuration(left + const Duration(milliseconds: 999))}',
                    style: AppText.title.copyWith(color: onForest, fontSize: 20),
                  ),
                ),
              ),
              IconButton(
                tooltip: l.restLess,
                color: onForest,
                icon: const Icon(Icons.remove),
                onPressed: () => n.adjustRest(-15),
              ),
              IconButton(
                tooltip: l.restMore,
                color: onForest,
                icon: const Icon(Icons.add),
                onPressed: () => n.adjustRest(15),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                onPressed: n.skipRest,
                child: Text(l.restSkip),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
