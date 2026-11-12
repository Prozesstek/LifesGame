import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// **Deutsche Silbentrennung** für den Blocksatz im Lernbuch.
///
/// Flutter kennt kein `hyphens: auto`: Es bricht an einem weichen
/// Trennstrich (U+00AD) zwar um, zeichnet aber keinen Strich (12.11.2026
/// gerendert). Deshalb rechnet die App selbst, **wo** getrennt werden darf
/// — mit dem Verfahren von Liang und den TeX-Mustern für Deutsch
/// (`assets/Silbentrennung/`, MIT) —, und `Blocksatz` setzt am
/// Zeilenende den sichtbaren Strich.
///
/// Reine Rechnung: [Silbentrennung.aus] nimmt die Muster als Text,
/// [trenne] gibt das Wort mit weichen Trennstrichen zurück.
class Silbentrennung {
  Silbentrennung._(this._muster, this._laengstes);

  /// Liest die Muster einer `.pat.txt`: je Zeile eines, Ziffern zwischen
  /// den Buchstaben.
  factory Silbentrennung.aus(String muster) {
    final karte = <String, List<int>>{};
    var laengstes = 0;
    for (final roh in muster.split(RegExp(r'\s+'))) {
      if (roh.isEmpty) continue;
      final buchstaben = StringBuffer();
      final werte = <int>[0];
      for (final rune in roh.runes) {
        final zeichen = String.fromCharCode(rune);
        final ziffer = int.tryParse(zeichen);
        if (ziffer != null) {
          werte[werte.length - 1] = ziffer;
        } else {
          buchstaben.write(zeichen);
          werte.add(0);
        }
      }
      final schluessel = buchstaben.toString();
      karte[schluessel] = werte;
      if (schluessel.length > laengstes) laengstes = schluessel.length;
    }
    return Silbentrennung._(karte, laengstes);
  }

  final Map<String, List<int>> _muster;
  final int _laengstes;

  /// Der weiche Trennstrich.
  static const String weich = '­';

  /// So viele Buchstaben bleiben mindestens vor und nach einer Trennung.
  static const int linksMindestens = 2;
  static const int rechtsMindestens = 2;

  /// Kürzere Wörter werden nicht getrennt.
  static const int abLaenge = 6;

  /// [wort] mit weichen Trennstrichen an jeder erlaubten Stelle. Satzzeichen
  /// davor und dahinter bleiben, wie sie sind; ein Wort mit Ziffern oder
  /// eigenem Bindestrich bleibt ganz.
  String trenne(String wort) {
    final m = RegExp(
      r'^([^\p{L}]*)(\p{L}+)([^\p{L}]*)$',
      unicode: true,
    ).firstMatch(wort);
    if (m == null) return wort;
    final kern = m.group(2)!;
    if (kern.length < abLaenge) return wort;
    final stellen = _stellen(kern.toLowerCase());
    final out = StringBuffer(m.group(1) ?? '');
    for (var i = 0; i < kern.length; i++) {
      if (stellen.contains(i)) out.write(weich);
      out.write(kern[i]);
    }
    out.write(m.group(3) ?? '');
    return out.toString();
  }

  /// Die Stellen in [wort], vor denen getrennt werden darf.
  Set<int> _stellen(String wort) {
    final w = '.$wort.';
    final punkte = List<int>.filled(w.length + 1, 0);
    for (var start = 0; start < w.length; start++) {
      final ende = w.length < start + _laengstes
          ? w.length
          : start + _laengstes;
      for (var stop = start + 1; stop <= ende; stop++) {
        final werte = _muster[w.substring(start, stop)];
        if (werte == null) continue;
        for (var k = 0; k < werte.length; k++) {
          if (werte[k] > punkte[start + k]) punkte[start + k] = werte[k];
        }
      }
    }
    // punkte[i + 1] steht zwischen w[i] und w[i + 1]; w[0] ist der Punkt.
    return <int>{
      for (var i = linksMindestens; i <= wort.length - rechtsMindestens; i++)
        if (punkte[i + 1].isOdd) i,
    };
  }

  /// Die Muster für Deutsch, sobald sie geladen sind — bis dahin `null`,
  /// und der Text steht ohne Trennung (`Blocksatz` hört darauf).
  static final ValueNotifier<Silbentrennung?> deutsch =
      ValueNotifier<Silbentrennung?>(null);

  static Future<void>? _laden;

  /// Lädt die Muster einmal; jeder weitere Aufruf wartet auf dasselbe.
  static Future<void> ladeDeutsch([AssetBundle? bundle]) =>
      _laden ??= _ladeDeutsch(bundle ?? rootBundle);

  static Future<void> _ladeDeutsch(AssetBundle bundle) async {
    try {
      final text = await bundle.loadString(pfad);
      deutsch.value = Silbentrennung.aus(text);
    } on FlutterError catch (fehler) {
      // Ohne Muster bleibt der Blocksatz ohne Trennung — lesbar, nur
      // weiter gesperrt. Kein Grund, die Seite nicht zu zeigen.
      debugPrint('Silbentrennung nicht geladen: $fehler');
    }
  }

  static const String pfad = 'assets/Silbentrennung/hyph-de-1996.pat.txt';
}
