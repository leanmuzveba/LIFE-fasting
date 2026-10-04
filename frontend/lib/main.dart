import 'package:flutter/material.dart';

void main() => runApp(const LifeFastingApp());

class LifeFastingApp extends StatelessWidget {
  const LifeFastingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Fasting Companion',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Fasting Companion'))),
    );
  }
}
