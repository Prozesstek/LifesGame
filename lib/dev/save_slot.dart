import 'package:shared_preferences/shared_preferences.dart';

/// Welcher Spielstand gerade geladen ist.
///
/// **Das ist die Sperre, die Ziel 7 schützt.** `ziele.md` verlangt für den
/// 30-Tage-Nachweis „kein Sonderrecht, keine Testdaten, keine Abkürzung über
/// den Debugger". Ein Entwicklermodus ist genau das — deshalb arbeitet er
/// nicht auf demselben Stand, sondern auf einem zweiten Schlüssel.
///
/// Der echte Stand ist damit nicht bloß „möglichst nicht" betroffen,
/// sondern technisch unerreichbar: Solange [SaveSlot.dev] aktiv ist, liest
/// und schreibt die App ausschließlich `lifes_game.save.dev.v1`.
enum SaveSlot {
  /// Der echte Spielstand. Der einzige, der für Ziel 7 zählt.
  real('lifes_game.save.v1', 'Echter Stand'),

  /// Der Sandkasten des Entwicklermodus.
  dev('lifes_game.save.dev.v1', 'Dev-Stand');

  const SaveSlot(this.storageKey, this.label);

  /// Der Schlüssel in `shared_preferences`. Ändern heißt: der Stand unter
  /// dem alten Schlüssel ist unerreichbar.
  final String storageKey;

  final String label;

  bool get isDev => this == SaveSlot.dev;
}

/// Merkt sich über Neustarts hinweg, welcher Stand geladen werden soll.
///
/// Bewusst **außerhalb** des Spielstands: Die Wahl des Standes kann nicht
/// in dem Stand liegen, den sie auswählt.
abstract final class SaveSlotStore {
  static const String _key = 'lifes_game.active_slot';

  static Future<SaveSlot> read(SharedPreferences prefs) async {
    final name = prefs.getString(_key);
    for (final slot in SaveSlot.values) {
      if (slot.name == name) return slot;
    }
    return SaveSlot.real;
  }

  static Future<void> write(SharedPreferences prefs, SaveSlot slot) {
    return prefs.setString(_key, slot.name);
  }
}
