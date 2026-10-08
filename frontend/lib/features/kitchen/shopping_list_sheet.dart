import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/kitchen_review.dart';
import '../../state/providers.dart';

Future<void> showShoppingList(BuildContext context) => showAppSheet<void>(context, (_) => const _ShoppingList());

/// Shopping list (PRD §6 step 8): tick, remove, add your own, clear ticked.
class _ShoppingList extends ConsumerStatefulWidget {
  const _ShoppingList();

  @override
  ConsumerState<_ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends ConsumerState<_ShoppingList> {
  final _new = TextEditingController();

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_new.text.trim().isEmpty) return;
    await ref.read(reviewActionsProvider).addToShoppingList(_new.text);
    _new.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = ref.watch(shoppingListProvider).value ?? const <ShoppingItem>[];
    final open = items.where((i) => !i.checked).length;
    final actions = ref.read(reviewActionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoLabel(l.shoppingTitle),
        const SizedBox(height: 6),
        Semantics(header: true, child: Text(l.shoppingCount(open), style: AppText.title.copyWith(fontSize: 19))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _new,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: l.shoppingAddHint,
                  filled: true,
                  fillColor: AppColors.lime200,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            RoundIconButton(icon: Icons.add, onTap: _add, tooltip: l.shoppingAdd, size: 44),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.shoppingEmpty, style: AppText.small),
          ),
        for (final item in items)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            value: item.checked,
            onChanged: (v) => actions.setChecked(item, v ?? false),
            title: Text(
              item.name,
              style: AppText.body.copyWith(
                fontSize: 15,
                decoration: item.checked ? TextDecoration.lineThrough : null,
                color: item.checked ? AppColors.textSecondary : AppColors.text,
              ),
            ),
            secondary: IconButton(
              tooltip: l.shoppingRemove(item.name),
              onPressed: () => actions.remove(item),
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
            ),
          ),
        if (items.any((i) => i.checked))
          TextButton(onPressed: actions.clearChecked, child: Text(l.shoppingClearChecked)),
      ],
    );
  }
}
