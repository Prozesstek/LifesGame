import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'combat/combat_screen.dart';

void main() {
  runApp(const ProviderScope(child: LifesGameApp()));
}

class LifesGameApp extends StatelessWidget {
  const LifesGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B8DEF),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Lifes Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0E1119),
        useMaterial3: true,
      ),
      home: const CombatScreen(),
    );
  }
}
