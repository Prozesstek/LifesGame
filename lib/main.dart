import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home/home_screen.dart';
import 'save/save_data.dart';
import 'save/save_providers.dart';
import 'save/save_store.dart';
import 'save/save_watcher.dart';
import 'ui/palette.dart';
import 'ui/phone_frame.dart';

/// Startet die App, nachdem der Spielstand gelesen ist.
///
/// **Warum vor `runApp` und nicht danach.** Der Stand ist klein und liegt
/// lokal; ihn zu lesen dauert Millisekunden. Ihn vorher zu lesen erspart
/// jedem Bildschirm einen Ladezustand für Daten, die längst da sind — und
/// erspart vor allem das kurze Aufblitzen eines leeren Standes, das wie
/// verlorener Fortschritt aussieht (ADR-0010).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _lockPortrait();

  final store = await _openStore();
  final saved = await store.read();

  runApp(
    ProviderScope(
      overrides: [
        saveStoreProvider.overrideWithValue(store),
        savedGameProvider.overrideWithValue(saved),
      ],
      child: const PhoneFrame(child: SaveWatcher(child: LifesGameApp())),
    ),
  );
}

/// Legt die App auf Hochformat fest.
///
/// **Das Ziel ist ein Handy, das man mit einer Hand hält** (`konzept.md`
/// Abschnitt 5). Querformat wäre kein zweites Layout, sondern ein zweites
/// Produkt: Der Kampfbildschirm stapelt Gegner, Log und vier Knöpfe
/// untereinander, und die Tagesliste lebt vom Scrollen. Beides ergibt quer
/// keinen Sinn.
///
/// **Im Web wird gar nicht erst gefragt**, und das ist keine Sparmaßnahme:
/// Ein Desktop-Browser hat keine Orientierung, die sich sperren ließe. Der
/// Aufruf lief dort ins Leere und hat — weil er vor `runApp` stand — den
/// Start der App verhindert. Ergebnis war eine schwarze Seite ohne jede
/// Fehlermeldung. Details in `docs/context/gotchas.md`.
///
/// Für die Form beim Entwickeln ist [PhoneFrame] zuständig, nicht diese
/// Funktion.
Future<void> _lockPortrait() async {
  if (kIsWeb) return;

  try {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } on PlatformException catch (error) {
    // Eine App, die nicht startet, weil sich der Bildschirm nicht drehen
    // lässt, ist schlimmer als eine, die sich drehen lässt.
    debugPrint('Hochformat konnte nicht festgelegt werden: $error');
  }
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
