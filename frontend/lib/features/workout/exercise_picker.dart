import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../domain/workout.dart';
import '../../state/providers.dart';
import 'exercise_detail.dart';

String equipmentLabel(AppLocalizations l, EquipmentGroup g) => switch (g) {
  EquipmentGroup.freeWeights => l.equipFreeWeights,
  EquipmentGroup.machines => l.equipMachines,
  EquipmentGroup.bodyweight => l.equipBodyweight,
  EquipmentGroup.other => l.equipOther,
};

/// "Chest · barbell".
String exerciseSubtitle(LibraryExercise x) =>
    [if (x.primary.isNotEmpty) x.primary.join(', '), ?x.equipment].join(' · ').capitalised();

extension Capitalised on String {
  String capitalised() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}

/// Picks an exercise: (name, library id — null for your own).
Future<(String, String?)?> showExercisePicker(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<(String, String?)>(builder: (_) => const _ExercisePickerScreen()));

/// The library to browse: tap an exercise to see how it's done.
Future<void> showExerciseLibrary(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _ExercisePickerScreen(browse: true)));

class _ExercisePickerScreen extends ConsumerStatefulWidget {
  const _ExercisePickerScreen({this.browse = false});
  final bool browse;

  @override
  ConsumerState<_ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<_ExercisePickerScreen> {
  final _search = TextEditingController();
  EquipmentGroup? _group; // null = all

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final library = ref.watch(exerciseLibraryProvider).value ?? const <LibraryExercise>[];
    final history = ref.watch(exerciseHistoryProvider).value ?? const {};
    final q = _search.text.trim().toLowerCase();
    bool matches(LibraryExercise x) =>
        (_group == null || x.group == _group) &&
        (q.isEmpty || x.name.toLowerCase().contains(q) || x.primary.any((m) => m.contains(q)));
    final byId = {for (final x in library) x.id: x};
    // Yours first: library exercises you've logged, then ones you named yourself.
    final yours = [
      for (final MapEntry(:key, :value) in history.entries)
        if (byId[key] case final x? when matches(x))
          (x.name, x.id, exerciseSubtitle(x))
        else if (!byId.containsKey(key) && _group == null && (q.isEmpty || key.contains(q)))
          (value.first.$2.name, null, ''),
    ];
    final yourIds = {for (final y in yours) ?y.$2};
    final rest = [
      for (final x in library)
        if (!yourIds.contains(x.id) && matches(x)) x,
    ];
    final exact = q.isEmpty || yours.any((y) => y.$1.toLowerCase() == q) || rest.any((x) => x.name.toLowerCase() == q);

    void pick(String name, String? id) => Navigator.pop(context, (name, id));
    void detail(LibraryExercise x) => showExerciseDetail(
      context,
      x,
      onAdd: widget.browse
          ? null
          : () {
              Navigator.pop(context); // the detail page
              pick(x.name, x.id);
            },
    );
    Widget tile(String name, String? id, String subtitle) {
      final x = byId[id];
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(name, style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: subtitle.isEmpty ? null : Text(subtitle, style: AppText.small),
        trailing: widget.browse
            ? (x == null ? null : const Icon(Icons.chevron_right, color: AppColors.muted))
            : x == null
            ? const Icon(Icons.add_circle_outline, color: AppColors.primary)
            : IconButton(
                tooltip: l.exerciseAbout(name),
                icon: const Icon(Icons.info_outline, color: AppColors.primary),
                onPressed: () => detail(x),
              ),
        onTap: widget.browse ? (x == null ? null : () => detail(x)) : () => pick(name, id),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverToBoxAdapter(child: ScreenHeader(title: widget.browse ? l.libraryTitle : l.pickerTitle)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.list(
                children: [
                  TextField(
                    controller: _search,
                    autofocus: !widget.browse,
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.pickerSearch),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final g in [null, ...EquipmentGroup.values])
                        RuvaChip(
                          label: g == null ? l.pickerAll : equipmentLabel(l, g),
                          selected: g == _group,
                          dense: true,
                          outlined: true,
                          onTap: () => setState(() => _group = g),
                        ),
                    ],
                  ),
                  if (!exact && !widget.browse) ...[
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      title: Text(l.pickerOwn(_search.text.trim())),
                      onTap: () => Navigator.pop(context, (_search.text.trim(), null)),
                    ),
                  ],
                  if (yours.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    MonoLabel(l.pickerYours),
                    for (final (name, id, sub) in yours) tile(name, id, sub),
                  ],
                  const SizedBox(height: 12),
                  MonoLabel(_group == null ? l.pickerAll : equipmentLabel(l, _group!)),
                  if (rest.isEmpty && yours.isEmpty) Text(l.pickerNone, style: AppText.small),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.builder(
                itemCount: rest.length,
                itemBuilder: (_, i) => tile(rest[i].name, rest[i].id, exerciseSubtitle(rest[i])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
