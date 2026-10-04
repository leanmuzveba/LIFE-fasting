import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Bottom sheet frame from the mockup: grab handle, 24px sides, 16px gaps.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (ctx) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 28 + MediaQuery.viewInsetsOf(ctx).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          builder(ctx),
        ],
      ),
    ),
  ),
);

/// Vertical list with the mockup's 16px gap between children.
class Gap16Column extends StatelessWidget {
  const Gap16Column({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 16), children[i]],
    ],
  );
}
