import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/recipe.dart';
import '../../state/providers.dart';

/// Write or edit your own recipe: name, optional type/time/servings,
/// ingredient rows (matched against My Kitchen) and steps.
class RecipeFormScreen extends ConsumerStatefulWidget {
  const RecipeFormScreen({super.key, this.existing});
  final Recipe? existing;

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _Row {
  _Row([String name = '', String amount = ''])
    : name = TextEditingController(text: name),
      amount = TextEditingController(text: amount);
  final TextEditingController name, amount;
  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  late final Recipe? _e = widget.existing;
  late final _name = TextEditingController(text: _e?.name ?? '');
  late final _category = TextEditingController(text: _e?.category ?? '');
  late final _minutes = TextEditingController(text: _e?.minutes?.toString() ?? '');
  late final _servings = TextEditingController(text: _e?.servings?.toString() ?? '');
  late final _steps = TextEditingController(text: _e?.steps.join('\n') ?? '');
  late final List<_Row> _rows = [
    for (final i in _e?.ingredients ?? const <RecipeIngredient>[]) _Row(i.name, i.measure),
    if (_e == null || _e.ingredients.isEmpty) _Row(),
  ];
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _category, _minutes, _servings, _steps]) {
      c.dispose();
    }
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final ingredients = [
      for (final r in _rows)
        if (r.name.text.trim().isNotEmpty) RecipeIngredient(r.name.text.trim(), r.amount.text.trim()),
    ];
    if (_name.text.trim().isEmpty) return setState(() => _error = l.myRecipeNeedName);
    if (ingredients.isEmpty) return setState(() => _error = l.myRecipeNeedIngredient);
    int? whole(TextEditingController c) => switch (int.tryParse(c.text.trim())) {
      final v? when v > 0 => v,
      _ => null,
    };
    await ref
        .read(recipeActionsProvider)
        .saveMine(
          Recipe(
            id: _e?.id ?? 'mine:',
            name: _name.text.trim(),
            category: _category.text.trim(),
            minutes: whole(_minutes),
            servings: whole(_servings),
            ingredients: ingredients,
            steps: [
              for (final s in _steps.text.split('\n'))
                if (s.trim().isNotEmpty) s.trim(),
            ],
          ),
        );
    if (!mounted) return;
    showRuvaSnack(context, l.myRecipeSaved(_name.text.trim()));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const number = TextInputType.number;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ScreenHeader(title: _e == null ? l.myRecipeNew : l.myRecipeEditTitle, large: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Gap16Column(
                children: [
                  RuvaTextField(controller: _name, label: l.myRecipeName, bold: true),
                  RuvaTextField(controller: _category, label: l.myRecipeCategory, hint: l.myRecipeCategoryHint),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RuvaTextField(controller: _minutes, label: l.myRecipeMinutes, keyboardType: number),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RuvaTextField(controller: _servings, label: l.myRecipeServings, keyboardType: number),
                      ),
                    ],
                  ),
                  MonoLabel(l.myRecipeIngredients),
                  for (final (i, r) in _rows.indexed)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: r.name,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _field(l.myRecipeIngredient),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(controller: r.amount, decoration: _field(l.myRecipeAmount)),
                        ),
                        IconButton(
                          tooltip: l.myRecipeRemoveIngredient,
                          onPressed: _rows.length == 1 ? null : () => setState(() => _rows.removeAt(i).dispose()),
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: () => setState(() => _rows.add(_Row())),
                      icon: const Icon(Icons.add),
                      label: Text(l.myRecipeAddIngredient),
                    ),
                  ),
                  RuvaTextField(controller: _steps, label: l.myRecipeSteps, hint: l.myRecipeStepsHint, maxLines: 8),
                  if (_error != null) Text(_error!, style: AppText.small.copyWith(color: AppColors.errorText)),
                  PrimaryButton(label: l.myRecipeSave, onPressed: _save),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _field(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.lime200,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
  );
}
