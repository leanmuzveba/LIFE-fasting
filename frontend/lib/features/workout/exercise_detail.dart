import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../domain/activity.dart';
import '../../domain/profile.dart';
import '../../domain/workout.dart';
import '../../state/providers.dart';
import 'exercise_picker.dart';
import 'progress_screen.dart';

/// Opens [x]'s page; with [onAdd], it has an "Add to workout" button.
Future<void> showExerciseDetail(BuildContext context, LibraryExercise x, {VoidCallback? onAdd}) => Navigator.of(context)
    .push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseDetailScreen(exercise: x, onAdd: onAdd),
      ),
    );

/// How to do an exercise (photos, steps, muscles) and how you've done it.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exercise, this.onAdd});
  final LibraryExercise exercise;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final x = exercise;
    final imperial = ref.watch(settingsProvider).value?.units == UnitSystem.imperial;
    final past = ref.watch(exerciseHistoryProvider).value?[x.id] ?? const [];
    final pb = personalBests(past.map((p) => p.$2));
    final series = oneRepMaxSeries(past);
    String set(SetLog s) => '${formatLoad(s.kg!, imperial: imperial)} × ${s.reps}';
    final body = AppText.body.copyWith(fontSize: 14.5);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          children: [
            ScreenHeader(title: x.name, subtitle: exerciseSubtitle(x)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (x.images.isNotEmpty) ...[_Demo(exercise: x), const SizedBox(height: 14)],
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in [x.level, ?x.equipment, x.category])
                        RuvaChip(label: tag.capitalised(), selected: false, dense: true, outlined: true),
                    ],
                  ),
                  if (onAdd != null) ...[
                    const SizedBox(height: 16),
                    PrimaryButton(label: l.exerciseAddToWorkout, onPressed: onAdd),
                  ],
                  const SizedBox(height: 22),
                  MonoLabel(l.exerciseYours),
                  const SizedBox(height: 8),
                  if (past.isEmpty)
                    Text(l.exerciseNoHistory, style: AppText.small)
                  else
                    RuvaCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pb.heaviest case final h?) Text(l.exerciseHeaviest(set(h)), style: body),
                          if (pb.strongest case final s?)
                            Text(
                              l.exerciseBest1rm(formatLoad(oneRepMax(s.kg!, s.reps), imperial: imperial), set(s)),
                              style: body,
                            ),
                          if (series.length >= 2) ...[
                            const SizedBox(height: 14),
                            OneRepMaxChart(series: series, imperial: imperial),
                          ],
                          if (pb.heaviest != null) const SizedBox(height: 10),
                          for (final (at, e) in past.take(5))
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${formatShortDay(at)} · ${e.describe(imperial: imperial).substring(e.name.length).trim()}',
                                style: AppText.small,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (x.primary.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    MonoLabel(l.exerciseMuscles),
                    const SizedBox(height: 8),
                    Text(x.primary.join(', ').capitalised(), style: body),
                    if (x.secondary.isNotEmpty) Text(l.exerciseAlsoWorks(x.secondary.join(', ')), style: AppText.small),
                  ],
                  if (x.instructions.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    MonoLabel(l.exerciseHow),
                    const SizedBox(height: 8),
                    for (final (i, step) in x.instructions.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text('${i + 1}.', style: AppText.cardValue.copyWith(fontSize: 15)),
                            ),
                            Expanded(child: Text(step, style: body)),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  Text(l.exerciseSource, style: AppText.small.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The start and end photos, swapping so the movement shows.
class _Demo extends StatefulWidget {
  const _Demo({required this.exercise});
  final LibraryExercise exercise;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  var _frame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final n = widget.exercise.images.length;
    if (n > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) => setState(() => _frame = (_frame + 1) % n));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final x = widget.exercise;
    final offline = Container(
      color: AppColors.cream,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Text(l.exercisePhotosOffline, textAlign: TextAlign.center, style: AppText.small),
    );
    return Semantics(
      image: true,
      label: l.exercisePhotos(x.name),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: IndexedStack(
            index: _frame,
            sizing: StackFit.expand,
            children: [
              // All stay loaded, so swapping never flickers.
              for (var i = 0; i < x.images.length; i++)
                Image.network(
                  x.imageUrl(i),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => offline,
                  loadingBuilder: (_, child, p) =>
                      p == null ? child : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
