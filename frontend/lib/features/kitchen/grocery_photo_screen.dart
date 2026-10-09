import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/sheet.dart';
import '../../data/meal_photo_api.dart';
import '../../domain/kitchen.dart';
import '../../state/providers.dart';
import '../food/meal_photo_screen.dart' show mealPhotoPickerProvider;
import 'kitchen_labels.dart';

/// Photo of your groceries → Gemini lists the items → you check, edit and
/// untick before anything is added to My Kitchen.
class GroceryPhotoScreen extends ConsumerStatefulWidget {
  const GroceryPhotoScreen({super.key});

  @override
  ConsumerState<GroceryPhotoScreen> createState() => _GroceryPhotoScreenState();
}

class _GroceryPhotoScreenState extends ConsumerState<GroceryPhotoScreen> {
  Uint8List? _photo;
  bool _busy = false;
  String? _error;
  List<SpottedItem> _items = [];
  final Set<int> _skip = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _take(ImageSource.camera));
  }

  Future<void> _take(ImageSource source) async {
    final l = context.l10n;
    final Uint8List? bytes;
    try {
      bytes = await ref.read(mealPhotoPickerProvider)(source);
    } catch (_) {
      if (mounted) setState(() => _error = l.photoCameraError);
      return;
    }
    if (!mounted) return;
    if (bytes == null) {
      if (_photo == null) Navigator.of(context).pop();
      return;
    }
    final api = await ref.read(mealPhotoApiProvider.future);
    if (!mounted) return;
    if (api == null) return setState(() => _error = l.photoNoKey);
    setState(() {
      _photo = bytes;
      _busy = true;
      _error = null;
    });
    try {
      final items = await api.groceries(bytes);
      if (!mounted) return;
      setState(() {
        _items = items;
        _skip.clear();
        _busy = false;
        _error = items.isEmpty ? l.groceryNone : null;
      });
    } on MealPhotoKeyException {
      if (mounted) _fail(l.photoKeyError);
    } catch (_) {
      if (mounted) _fail(l.photoOffline);
    }
  }

  void _fail(String message) => setState(() {
    _busy = false;
    _error = message;
  });

  Future<void> _edit(int i) async {
    final edited = await showAppSheet<SpottedItem>(context, (_) => _EditSheet(item: _items[i]));
    if (edited != null && mounted) setState(() => _items[i] = edited);
  }

  Future<void> _add() async {
    final l = context.l10n;
    final now = ref.read(clockProvider)();
    final local = now.toLocal();
    final actions = ref.read(kitchenActionsProvider);
    var added = 0;
    for (final (i, it) in _items.indexed) {
      if (_skip.contains(i)) continue;
      final error = await actions.save(
        Ingredient(
          name: it.name,
          categories: it.categories.isEmpty ? {IngredientCategory.pantry} : it.categories,
          quantity: it.quantity,
          unit: it.unit,
          state: it.state,
          purchasedOn: DateTime(local.year, local.month, local.day),
          notes: l.groceryNote,
          createdAt: now.toUtc(),
          updatedAt: now.toUtc(),
        ),
      );
      if (error == null) added++;
    }
    if (!mounted) return;
    showRuvaSnack(context, l.groceryAdded(added));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final count = _items.length - _skip.length;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ScreenHeader(title: l.groceryTitle, large: true, subtitle: l.kitchenTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_photo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(_photo!, height: 200, fit: BoxFit.cover, semanticLabel: l.groceryPhoto),
                    ),
                  const SizedBox(height: 14),
                  if (_busy) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(l.groceryLooking, textAlign: TextAlign.center, style: AppText.small),
                  ] else if (_error != null)
                    Text(_error!, textAlign: TextAlign.center, style: AppText.body)
                  else if (_items.isNotEmpty) ...[
                    Text(l.groceryCheck, style: AppText.small.copyWith(fontSize: 13)),
                    const SizedBox(height: 10),
                    RuvaCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, it) in _items.indexed)
                            CheckboxListTile(
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.primary,
                              value: !_skip.contains(i),
                              onChanged: (v) => setState(() => v == true ? _skip.remove(i) : _skip.add(i)),
                              title: Text(it.name, style: AppText.cardValue.copyWith(fontSize: 15)),
                              subtitle: Text(
                                [
                                  formatQuantity(it.quantity, it.unit),
                                  stateLabel(l, it.state),
                                  ...it.categories.map((c) => categoryLabel(l, c)),
                                ].join(' · '),
                                style: AppText.small.copyWith(fontSize: 12.5),
                              ),
                              secondary: IconButton(
                                tooltip: l.photoRename(it.name),
                                onPressed: () => _edit(i),
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(label: l.groceryAdd(count), onPressed: count == 0 ? null : _add),
                  ],
                  const SizedBox(height: 10),
                  if (!_busy)
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
                  Text(l.photoPrivacy, textAlign: TextAlign.center, style: AppText.small.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fix a spotted item's name, amount or unit.
class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.item});
  final SpottedItem item;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _qty = TextEditingController(text: formatQuantity(widget.item.quantity, '').trim());
  late String _unit = widget.item.unit;

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Gap16Column(
      children: [
        RuvaTextField(controller: _name, label: l.ingredientName, bold: true),
        RuvaTextField(
          controller: _qty,
          label: l.ingredientQuantity,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final u in kitchenUnits)
              RuvaChip(label: u, outlined: true, selected: _unit == u, onTap: () => setState(() => _unit = u)),
          ],
        ),
        PrimaryButton(
          label: l.save,
          onPressed: () {
            final q = double.tryParse(_qty.text.trim().replaceAll(',', '.'));
            if (_name.text.trim().isEmpty || q == null || q <= 0) return;
            Navigator.pop(
              context,
              SpottedItem(
                name: _name.text.trim(),
                quantity: q,
                unit: _unit,
                categories: widget.item.categories,
                state: widget.item.state,
              ),
            );
          },
        ),
      ],
    );
  }
}
