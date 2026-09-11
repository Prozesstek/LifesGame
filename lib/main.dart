import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dev/dev_controller.dart';
import 'dev/dev_screen.dart';
import 'dev/save_slot.dart';
import 'habits/day_watcher.dart';
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

  final prefs = await _openPrefs();
  final slot = prefs == null ? SaveSlot.real : await SaveSlotStore.read(prefs);

  final store = await _openStore(prefs, slot);
  final saved = await store.read();

  runApp(
    ProviderScope(
      overrides: [
        saveStoreProvider.overrideWithValue(store),
        savedGameProvider.overrideWithValue(saved),
        activeSlotProvider.overrideWithValue(slot),
        // Ohne Typangabe: Riverpod 3 exportiert `Override` nicht
        // (`gotchas.md`). Der Typ wird korrekt abgeleitet.
        if (prefs != null) ...[
          slotSwitcherProvider.overrideWithValue(
            (SaveSlot ziel) => SaveSlotStore.write(prefs, ziel),
          ),
          devSaveEraserProvider.overrideWithValue(
            () => prefs.remove(SaveSlot.dev.storageKey),
          ),
        ],
      ],
      child: const PhoneFrame(
        child: SaveWatcher(child: DayWatcher(child: LifesGameApp())),
      ),
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

/// Öffnet den Speicher — oder gibt null zurück, wenn er klemmt.
///
/// Eine App, die nicht startet, weil der Speicher klemmt, ist schlimmer als
/// eine, die diese eine Sitzung nichts behält. Der Fehler wird gemeldet,
/// nicht verschluckt.
Future<SharedPreferences?> _openPrefs() async {
  try {
    return await SharedPreferences.getInstance();
  } on Exception catch (error) {
    debugPrint('Speicher nicht verfügbar, laufe ohne Persistenz: $error');
    return null;
  }
}

/// Der Stand, der zum gewählten Slot gehört.
///
/// **Der Slot bestimmt den Schlüssel, sonst nichts.** Ist der
/// Entwicklermodus auf `dev` geschaltet, fasst die App den echten Stand für
/// die ganze Sitzung nicht an — das ist die Sperre, die den 30-Tage-
/// Nachweis aus `ziele.md` schützt (ADR-0021).
Future<SaveStore> _openStore(SharedPreferences? prefs, SaveSlot slot) async {
  if (prefs == null) return InMemorySaveStore(const SaveData.empty());
  return SharedPreferencesSaveStore(prefs, key: slot.storageKey);
}

class LifesGameApp extends StatelessWidget {
  const LifesGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lifes Game',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: const HomeScreen(),
    );
  }

  /// **`Brightness.light`, obwohl der Grund dunkel ist.**
  ///
  /// Das sieht falsch aus und ist es nicht: Die Helligkeit eines Themes
  /// entscheidet, welche Farbe Material für Text ohne eigene Angabe
  /// wählt — und der steht in dieser App fast immer auf einer
  /// Pergamentfläche, nicht auf dem Leder dahinter. Mit `dark` wäre jeder
  /// nicht ausdrücklich gefärbte Text weiß auf Beige und damit
  /// unsichtbar.
  ///
  /// Das Leder kommt über [ThemeData.scaffoldBackgroundColor] herein.
  /// Was direkt darauf steht — die Namen unter den Bereichskreisen, die
  /// Zahlen im Kampf — färbt sich ausdrücklich mit
  /// [Palette.textOnDark]; das sind wenige Stellen, und sie sind in
  /// `palette.dart` benannt.
  static ThemeData _theme() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: Palette.accent,
          brightness: Brightness.light,
        ).copyWith(
          primary: Palette.accent,
          onPrimary: Palette.surface,
          secondary: Palette.accent,
          onSecondary: Palette.surface,
          surface: Palette.surface,
          onSurface: Palette.text,
          surfaceContainerHighest: Palette.surfaceRaised,
          error: Palette.enemy,
          onError: Palette.surface,
          outline: Palette.surfaceRaised,
        );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: Palette.background,
      useMaterial3: true,

      // Die Kopfzeile ist selbst eine Pergamentfläche. Ohne diese beiden
      // Zeilen bliebe ihr Titel in der Standardfarbe des Schemas und
      // stünde je nach Bildschirm hell auf hell.
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.surface,
        foregroundColor: Palette.text,
        elevation: 0,
      ),

      // Blätter und Dialoge sind Pergament wie alles andere. Material
      // würde sie sonst aus dem Schema tönen und dabei leicht daneben
      // liegen.
      dialogTheme: const DialogThemeData(backgroundColor: Palette.surface),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.surface,
      ),

      // Der Hinweis auf einen gesperrten Bereich (ADR-0020) steht als
      // einziges auf dunklem Grund über allem anderen.
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Palette.backgroundRaised,
        contentTextStyle: TextStyle(color: Palette.textOnDark),
      ),

      dividerTheme: const DividerThemeData(color: Palette.surfaceRaised),
      iconTheme: const IconThemeData(color: Palette.text),
    );
  }
}
