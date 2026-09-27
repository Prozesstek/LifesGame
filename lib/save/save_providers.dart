import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'save_data.dart';
import 'save_store.dart';

/// Wohin gespeichert wird.
///
/// Standardmäßig nirgendwohin: Tests und Widget-Tests laufen damit ohne
/// Plattform-Kanäle. `main.dart` überschreibt den Provider mit dem echten
/// Speicher.
final saveStoreProvider = Provider<SaveStore>((ref) => InMemorySaveStore());

/// Der Stand, mit dem die App gestartet ist.
///
/// Bewusst ein einfacher Wert und kein `Future`: Gelesen wird **einmal**
/// vor `runApp`, danach ist der Stand da. Damit bleiben alle Controller
/// synchron, und kein Bildschirm braucht einen Ladezustand für Daten, die
/// längst im Speicher liegen.
final savedGameProvider = Provider<SaveData>((ref) => const SaveData.empty());

/// Ersetzt den Spielstand und startet die App damit neu (ADR-0054).
///
/// **Ein Neustart von innen, kein „bitte neu laden“.** Der Stand wird
/// einmal gelesen, und jeder Controller baut seinen Anfangszustand
/// daraus. Würde nur der Speicher überschrieben, schriebe die laufende App
/// beim nächsten Häkchen ihren alten Stand darüber. `main.dart`
/// überschreibt den Provider; ohne Überschreibung passiert nichts.
final saveImporterProvider = Provider<Future<void> Function(SaveData)>(
  (ref) => (_) async {},
);
