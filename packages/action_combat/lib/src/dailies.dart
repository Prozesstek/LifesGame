import 'stage.dart';

/// Die vier Stufen des Tages — wie die Fraktal-Dailies in Guild Wars 2.
///
/// **Jede zahlt einmal am Tag ein Viertel ihres Erstsieg-Betrags**
/// (`LadderRewards.dailyShare`), auch wenn sie längst geschafft ist. Das
/// ist wiederholbare Belohnung aus dem Kampf, und genau die hatte
/// ADR-0032 ausgeschlossen; ADR-0040 erlaubt sie, weil sie wie die
/// Gewohnheiten **je Tag gedeckelt** ist und nur an Tagen mit einem
/// Häkchen zahlt. Die Häkchen-Bedingung prüft die App, sie kennt die
/// Gewohnheiten; hier steht nur, welche vier es sind.
///
/// **Gewürfelt aus dem Tag, nicht aus der Uhr.** Beide Spieler bekommen
/// am selben Tag dieselben relativen Plätze: eine leichte, zwei mittlere,
/// eine von ganz oben — jeweils aus dem, was man geschafft hat. Wer gleich
/// weit ist, spielt dieselben vier, und darüber lässt sich reden.
abstract final class PitDailies {
  /// So viele Stufen je Tag.
  static const int perDay = 4;

  /// Die Bänder, aus denen gewürfelt wird, als Anteil der höchsten
  /// geschafften Stufe: leicht, mittel, mittel, oben.
  static const List<(double, double)> bands = <(double, double)>[
    (0.0, 0.3),
    (0.3, 0.7),
    (0.3, 0.7),
    (0.7, 1.0),
  ];

  /// Die Stufen des Tages [dayNumber] (Tage seit dem 1.1.1970) für jemanden,
  /// der bis [highestDefeated] gekommen ist — aufsteigend, ohne doppelte.
  /// Leer, solange nichts geschafft ist.
  static List<int> forDay(int dayNumber, int highestDefeated) {
    final hoechste = highestDefeated.clamp(0, PitStage.count);
    if (hoechste == 0) return const <int>[];
    if (hoechste <= perDay) {
      return <int>[for (var s = 1; s <= hoechste; s++) s];
    }

    final wurf = _Wurf(dayNumber);
    final gewaehlt = <int>{};
    for (final (von, bis) in bands) {
      final anteil = von + (bis - von) * wurf.next();
      var stufe = (anteil * hoechste).ceil().clamp(1, hoechste);
      stufe = _naechsteFreie(stufe, gewaehlt, hoechste);
      gewaehlt.add(stufe);
    }
    return gewaehlt.toList()..sort();
  }

  /// [stufe], oder die nächste freie daneben — erst nach unten, dann nach
  /// oben, damit „ganz oben" nicht über das Geschaffte hinausrutscht.
  static int _naechsteFreie(int stufe, Set<int> belegt, int hoechste) {
    for (var abstand = 0; abstand < hoechste; abstand++) {
      final unten = stufe - abstand;
      if (unten >= 1 && !belegt.contains(unten)) return unten;
      final oben = stufe + abstand;
      if (oben <= hoechste && !belegt.contains(oben)) return oben;
    }
    return stufe;
  }
}

/// Ein kleiner, vorhersagbarer Würfel (Park–Miller).
///
/// **Nicht `dart:math`:** Dessen Folge zu einem Startwert ist zwischen
/// Plattformen nicht zugesagt, und im Browser rechnet Dart mit
/// Gleitkommazahlen. Diese Rechnung bleibt unter 2⁵³ und ergibt überall
/// dieselben vier Stufen.
class _Wurf {
  _Wurf(int tag) : _zustand = (tag.abs() * 7919 + 104729) % _m {
    if (_zustand == 0) _zustand = 1;
    // Die ersten Würfe aufeinanderfolgender Tage liegen dicht beieinander.
    for (var i = 0; i < 3; i++) {
      next();
    }
  }

  static const int _m = 2147483647;
  static const int _a = 48271;
  int _zustand;

  /// Eine Zahl in [0, 1).
  double next() {
    _zustand = (_zustand * _a) % _m;
    return (_zustand - 1) / (_m - 1);
  }
}
