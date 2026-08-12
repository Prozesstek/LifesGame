import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home/home_screen.dart';
import 'ui/palette.dart';

void main() {
  runApp(const ProviderScope(child: LifesGameApp()));
}

class LifesGameApp extends StatelessWidget {
  const LifesGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Palette.accent,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Lifes Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: Palette.background,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
