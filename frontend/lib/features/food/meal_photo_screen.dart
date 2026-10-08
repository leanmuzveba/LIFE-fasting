import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/sheet.dart';
import '../../data/meal_photo_api.dart';
import '../../domain/food.dart';
import '../../domain/meal_estimate.dart';
import '../../state/providers.dart';
import 'food_labels.dart';

/// Takes or picks a photo, downscaled for upload. Overridden in tests.
final mealPhotoPickerProvider = Provider<Future<Uint8List?> Function(ImageSource)>(
  (ref) => (source) async {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    return file?.readAsBytes();
  },
);

enum _Phase { picking, estimating, review, failed }

/// Photo → AI estimate → you check and edit every item → log (PRD §3: AI
/// entries are reviewed before saving). Estimates are clearly labelled.
class MealPhotoScreen extends ConsumerStatefulWidget {
  const MealPhotoScreen({super.key, required this.day, required this.meal});

  final DateTime day;
  final Meal meal;

  @override
  ConsumerState<MealPhotoScreen> createState() => _MealPhotoScreenState();
}

class _MealPhotoScreenState extends ConsumerState<MealPhotoScreen> {
  _Phase _phase = _Phase.picking;
  Uint8List? _photo;
  List<EstimatedItem> _items = [];
  String _note = '';
  String? _error;
  late Meal _meal = widget.meal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _take(ImageSource.camera));
  }

  Future<void> _take(ImageSource source) async {
    final l = context.l10n;
    setState(() => _phase = _Phase.picking);
    final Uint8List? bytes;
    try {
      bytes = await ref.read(mealPhotoPickerProvider)(source);
    } catch (_) {
      if (mounted) _fail(l.photoCameraError);
      return;
    }
    if (!mounted) return;
    if (bytes == null) {
      // Cancelled: leave if nothing was taken yet, else keep the last photo.
      if (_photo == null) Navigator.of(context).pop();
      setState(() => _phase = _items.isEmpty ? _Phase.failed : _Phase.review);
      return;
    }
    setState(() {
      _photo = bytes;
      _phase = _Phase.estimating;
    });
    await _estimate();
  }

  Future<void> _estimate() async {
    final l = context.l10n;
    final api = await ref.read(mealPhotoApiProvider.future);
    if (!mounted) return;
    if (api == null) return _fail(l.photoNoKey);
    setState(() => _phase = _Phase.estimating);
    try {
      final est = await api.estimate(_photo!);
      if (!mounted) return;
      if (!est.isFood || est.items.isEmpty) return _fail(l.photoNotFood);
      setState(() {
        _items = est.items;
        _note = est.note;
        _phase = _Phase.review;
      });
    } on MealPhotoKeyException {
      if (mounted) _fail(l.photoKeyError);
    } catch (_) {
      if (mounted) _fail(l.photoOffline);
    }
  }

  void _fail(String message) => setState(() {
    _error = message;
    _phase = _Phase.failed;
  });

  Future<void> _rename(int i) async {
    final name = await showAppSheet<String>(context, (_) => _RenameSheet(initial: _items[i].name));
    if (name != null && name.trim().isNotEmpty && mounted) {
      setState(() => _items[i] = _items[i].withName(name.trim()));
    }
  }

  Future<void> _log() async {
    final l = context.l10n;
    final d = widget.day;
    final now = ref.read(clockProvider)().toLocal();
    final isToday = now.year == d.year && now.month == d.month && now.day == d.day;
    final at = isToday ? now : DateTime(d.year, d.month, d.day, mealDefaultHour(_meal));
    await ref.read(foodActionsProvider).logEstimate(_items, meal: _meal, at: at, label: l.photoLabel);
    if (!mounted) return;
    showRuvaSnack(context, l.photoLogged(_items.length, mealLabel(l, _meal)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = _items.fold(0.0, (a, i) => a + (i.nutrients[Nutrient.energy] ?? 0));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ScreenHeader(
              title: l.photoTitle,
              large: true,
              subtitle: l.addFoodTo(mealLabel(l, _meal), DateFormat('EEE, d MMM').format(widget.day)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_photo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(_photo!, height: 220, fit: BoxFit.cover, semanticLabel: l.photoYourPhoto),
                    ),
                  const SizedBox(height: 16),
                  switch (_phase) {
                    _Phase.picking => const SizedBox.shrink(),
                    _Phase.estimating => Column(
                      children: [
                        const LinearProgressIndicator(),
                        const SizedBox(height: 10),
                        Text(l.photoEstimating, style: AppText.small),
                      ],
                    ),
                    _Phase.failed => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(_error ?? '', textAlign: TextAlign.center, style: AppText.body),
                        const SizedBox(height: 12),
                        if (_photo != null && _error != l.photoNotFood)
                          TextButton(onPressed: _estimate, child: Text(l.recipesRetry)),
                      ],
                    ),
                    _Phase.review => _review(l, total),
                  },
                  const SizedBox(height: 12),
                  if (_phase != _Phase.estimating)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                          onPressed: () => _take(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(l.photoRetake),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                          onPressed: () => _take(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(l.photoGallery),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(l.photoPrivacy, textAlign: TextAlign.center, style: AppText.small.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _review(AppLocalizations l, double total) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.track),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(l.photoCheck, style: AppText.small.copyWith(fontSize: 13))),
          ],
        ),
      ),
      if (_note.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(_note, style: AppText.small.copyWith(fontStyle: FontStyle.italic)),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: MonoLabel(l.photoItems(_items.length))),
          Text('${l.diaryKcal(formatNutrient(total))} ${l.diaryEst}', style: AppText.cardValue.copyWith(fontSize: 15)),
        ],
      ),
      const SizedBox(height: 10),
      for (final (i, item) in _items.indexed) ...[
        RuvaCard(
          bordered: true,
          padding: const EdgeInsets.fromLTRB(18, 10, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(item.name, style: AppText.cardValue.copyWith(fontSize: 15))),
                  IconButton(
                    tooltip: l.photoRename(item.name),
                    onPressed: () => _rename(i),
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  ),
                  IconButton(
                    tooltip: l.photoRemove(item.name),
                    onPressed: () => setState(() => _items = [..._items]..removeAt(i)),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Text(
                [
                  for (final n in Nutrient.macros)
                    if (item.nutrients[n] case final v?) '${nutrientLabel(l, n)} ${formatNutrient(v)} ${n.unit}',
                ].join(' · '),
                style: AppText.small.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ValueStepper(
                  label: '${formatNutrient(item.grams)} g',
                  minusTooltip: l.addFoodLess,
                  plusTooltip: l.addFoodMore,
                  onMinus: item.grams > 10 ? () => setState(() => _items[i] = item.withGrams(item.grams - 10)) : null,
                  onPlus: () => setState(() => _items[i] = item.withGrams(item.grams + 10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
      MonoLabel(l.addFoodMeal),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final m in Meal.values)
            RuvaChip(label: mealLabel(l, m), selected: _meal == m, onTap: () => setState(() => _meal = m)),
        ],
      ),
      const SizedBox(height: 16),
      PrimaryButton(label: l.photoAdd(_items.length, mealLabel(l, _meal)), onPressed: _items.isEmpty ? null : _log),
    ],
  );
}

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.initial});
  final String initial;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Gap16Column(
      children: [
        RuvaTextField(controller: _name, label: l.customName, bold: true, autofocus: true),
        PrimaryButton(label: l.save, onPressed: () => Navigator.pop(context, _name.text)),
      ],
    );
  }
}
