import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home/home_screen.dart';
import 'save/save_data.dart';
import 'save/save_providers.dart';
import 'save/save_store.dart';
import 'save/save_watcher.dart';
import 'ui/palette.dart';

/// Startet die App, nachdem der Spielstand gelesen ist.
///
/// **Warum vor `runApp` und nicht danach.** Der Stand ist klein und liegt
/// lokal; ihn zu lesen dauert Millisekunden. Ihn vorher zu lesen erspart
/// jedem Bildschirm einen Ladezustand für Daten, die längst da sind — und
/// erspart vor allem das kurze Aufblitzen eines leeren Standes, das wie
/// verlorener Fortschritt aussieht (ADR-0010).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = await _openStore();
  final saved = await store.read();

  runApp(
    ProviderScope(
      overrides: [
        saveStoreProvider.overrideWithValue(store),
        savedGameProvider.overrideWithValue(saved),
      ],
      child: const SaveWatcher(child: LifesGameApp()),
    ),
  );
}

/// Öffnet den Speicher — oder weicht auf einen aus, der nichts behält.
///
/// Eine App, die nicht startet, weil der Speicher klemmt, ist schlimmer als
/// eine, die diese eine Sitzung nichts behält. Der Fehler wird gemeldet,
/// nicht verschluckt.
Future<SaveStore> _openStore() async {
  try {
    return await SharedPreferencesSaveStore.open();
  } on Exception catch (error) {
    debugPrint('Speicher nicht verfügbar, laufe ohne Persistenz: $error');
    return InMemorySaveStore(const SaveData.empty());
  }
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
