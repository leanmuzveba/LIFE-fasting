import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

void main() => runApp(const LifeFastingApp());

class LifeFastingApp extends StatelessWidget {
  const LifeFastingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fasting Companion',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const Scaffold(body: Center(child: Text('Fasting Companion'))),
    );
  }
}
