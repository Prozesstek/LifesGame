import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Die Einstellungen** (13.11.2026, AktivesBrett): wie laut die App
/// ist und auf welcher Seite im Kampf die Fähigkeiten liegen.
///
/// **Sie gehören dem Gerät, nicht dem Spielstand.** Wer seinen Stand als
/// Text sichert und auf einem anderen Handy einfügt (ADR-0054), nimmt
/// keine Lautstärke mit — und wer einfügt, verliert seine nicht. Deshalb
/// liegen sie unter einem eigenen Schlüssel neben dem Stand, nicht in
/// `SaveData`.
class Einstellungen {
  const Einstellungen({this.lautstaerke = 1, this.faehigkeitenLinks = false});

  /// 0 (stumm) bis 1 (voll).
  final double lautstaerke;

  /// Ob die Fähigkeiten im Kampf links liegen statt rechts — für alle,
  /// die mit rechts zielen und mit links laufen wollen.
  final bool faehigkeitenLinks;

  Einstellungen copyWith({double? lautstaerke, bool? faehigkeitenLinks}) =>
      Einstellungen(
        lautstaerke: lautstaerke ?? this.lautstaerke,
        faehigkeitenLinks: faehigkeitenLinks ?? this.faehigkeitenLinks,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'lautstaerke': lautstaerke,
    'faehigkeitenLinks': faehigkeitenLinks,
  };

  /// Nachsichtig wie jedes `fromJson` im Projekt (ADR-0010): Was fehlt oder
  /// nicht passt, nimmt den Standard.
  factory Einstellungen.fromJson(Object? json) {
    if (json is! Map) return const Einstellungen();
    final laut = json['lautstaerke'];
    final links = json['faehigkeitenLinks'];
    return Einstellungen(
      lautstaerke: laut is num ? laut.toDouble().clamp(0.0, 1.0) : 1,
      faehigkeitenLinks: links is bool && links,
    );
  }
}

/// Wo die Einstellungen liegen. Der Standard hält sie nur im Speicher —
/// Tests und jeder Aufbau ohne `main.dart`.
abstract interface class EinstellungenSpeicher {
  Einstellungen lesen();
  void schreiben(Einstellungen einstellungen);
}

class EinstellungenImSpeicher implements EinstellungenSpeicher {
  EinstellungenImSpeicher([this._wert = const Einstellungen()]);

  Einstellungen _wert;

  @override
  Einstellungen lesen() => _wert;

  @override
  void schreiben(Einstellungen einstellungen) => _wert = einstellungen;
}

/// In `shared_preferences`, unter einem eigenen Schlüssel.
class EinstellungenInPrefs implements EinstellungenSpeicher {
  EinstellungenInPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const String schluessel = 'einstellungen';

  @override
  Einstellungen lesen() {
    final roh = _prefs.getString(schluessel);
    if (roh == null) return const Einstellungen();
    try {
      return Einstellungen.fromJson(jsonDecode(roh));
    } on FormatException {
      return const Einstellungen();
    }
  }

  @override
  void schreiben(Einstellungen einstellungen) {
    // Ohne Warten: Geht das Schreiben schief, bleibt die Einstellung für
    // diese Sitzung trotzdem stehen.
    _prefs.setString(schluessel, jsonEncode(einstellungen.toJson()));
  }
}

final einstellungenSpeicherProvider = Provider<EinstellungenSpeicher>(
  (ref) => EinstellungenImSpeicher(),
);

/// Die Einstellungen, wie sie gerade gelten. **Gelesen wird beim Bauen
/// aus dem Speicher**, nicht aus einem Startwert — sonst setzte das
/// Einfügen eines Spielstands (ein neuer `ProviderScope`) sie zurück.
final einstellungenProvider =
    NotifierProvider<EinstellungenController, Einstellungen>(
      EinstellungenController.new,
    );

class EinstellungenController extends Notifier<Einstellungen> {
  @override
  Einstellungen build() => ref.watch(einstellungenSpeicherProvider).lesen();

  void setzeLautstaerke(double wert) =>
      _setze(state.copyWith(lautstaerke: wert.clamp(0.0, 1.0)));

  void setzeFaehigkeitenLinks(bool links) =>
      _setze(state.copyWith(faehigkeitenLinks: links));

  void _setze(Einstellungen neu) {
    ref.read(einstellungenSpeicherProvider).schreiben(neu);
    state = neu;
  }
}
