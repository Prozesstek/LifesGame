import 'package:shared_preferences/shared_preferences.dart';

import 'save_data.dart';

/// Der Anschluss, hinter dem die Speichertechnik liegt.
///
/// Zwei Methoden, ein Wert. Genau so schmal gehalten, damit Drift später
/// dahinter passt, ohne dass ein Controller, ein Screen oder ein Test sich
/// ändert (ADR-0010). Sobald Drift kommt, entsteht neben
/// [SharedPreferencesSaveStore] eine zweite Implementierung, und `main.dart`
/// wählt eine aus — mehr nicht.
abstract interface class SaveStore {
  /// Liest den Stand. Gibt einen leeren Stand zurück, wenn keiner da ist.
  Future<SaveData> read();

  Future<void> write(SaveData data);
}

/// Speichert den Stand als einen JSON-String.
///
/// Ein einziger Schlüssel, kein Schema, kein Codegen, keine Assets — und
/// derselbe Code auf Web, Android und Desktop. Für drei Objekte ist das die
/// passende Größe.
class SharedPreferencesSaveStore implements SaveStore {
  const SharedPreferencesSaveStore(this._prefs);

  /// Die Instanz wird beim Start geladen und hereingegeben, nicht hier
  /// geholt: So bleibt [read] synchron schnell und `main.dart` hat einen
  /// klaren Ort, an dem das Warten stattfindet.
  final SharedPreferences _prefs;

  /// Der Schlüssel. Ändern heißt: alle bestehenden Stände sind weg.
  static const String _key = 'lifes_game.save.v1';

  static Future<SharedPreferencesSaveStore> open() async {
    return SharedPreferencesSaveStore(await SharedPreferences.getInstance());
  }

  @override
  Future<SaveData> read() async => SaveData.decode(_prefs.getString(_key));

  @override
  Future<void> write(SaveData data) => _prefs.setString(_key, data.encode());
}

/// Speichert nichts und liest nichts.
///
/// Für Tests und für den Fall, dass der Speicher beim Start nicht
/// verfügbar ist: Die App läuft dann ohne Persistenz weiter, statt gar
/// nicht zu starten.
class InMemorySaveStore implements SaveStore {
  InMemorySaveStore([this._data = const SaveData.empty()]);

  SaveData _data;

  /// Wie oft geschrieben wurde. Macht in Tests prüfbar, dass überhaupt
  /// gespeichert wird.
  int writes = 0;

  @override
  Future<SaveData> read() async => _data;

  @override
  Future<void> write(SaveData data) async {
    _data = data;
    writes++;
  }
}
