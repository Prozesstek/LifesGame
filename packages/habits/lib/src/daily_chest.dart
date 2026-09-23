import 'day.dart';
import 'rewards.dart';

/// Was eine geöffnete Tagestruhe enthält.
class ChestContent {
  const ChestContent({
    required this.tier,
    required this.gold,
    required this.freezes,
  });

  final ChestTier tier;
  final int gold;

  /// Wie viele Streak-Eis darin liegen.
  final int freezes;
}

/// **Die Tagestruhe** (ADR-0044): wer heute jede laufende Gewohnheit
/// erledigt, öffnet sie — einmal je Tag.
///
/// **Gewürfelt aus dem Datum**, nicht beim Öffnen. Der Inhalt eines Tages
/// steht damit fest: Ein Neustart würfelt nicht neu, und gespeichert
/// werden muss nur, *dass* geöffnet wurde. Gold und Eis werden daraus
/// gerechnet, wie alles andere (ADR-0008). Beide Spieler haben am selben
/// Tag dieselbe Truhe — ein Schatz ist dann etwas, worüber man redet.
abstract final class DailyChest {
  static const Day _epoche = Day(1970, 1, 1);

  static ChestContent forDay(Day day) {
    final wurf = _Wurf(_epoche.daysUntil(day));
    final gesamt = ChestTier.values.fold<int>(0, (s, t) => s + t.weight);
    var rest = wurf.next() * gesamt;
    var stufe = ChestTier.values.last;
    for (final t in ChestTier.values) {
      if (rest < t.weight) {
        stufe = t;
        break;
      }
      rest -= t.weight;
    }
    final spanne = stufe.goldMax - stufe.goldMin;
    final gold = stufe.goldMin + (wurf.next() * (spanne + 1)).floor();
    return ChestContent(
      tier: stufe,
      gold: gold > stufe.goldMax ? stufe.goldMax : gold,
      freezes: stufe.freezes,
    );
  }
}

/// Ein kleiner, vorhersagbarer Würfel (Park–Miller) — derselbe wie für
/// die Stufen des Tages in `package:action_combat`, das dieses Package
/// nicht kennen darf.
///
/// **Nicht `dart:math`:** Dessen Folge zu einem Startwert ist zwischen
/// Plattformen nicht zugesagt, und im Browser rechnet Dart mit
/// Gleitkommazahlen. Diese Rechnung bleibt unter 2⁵³ und ergibt überall
/// dieselbe Truhe.
class _Wurf {
  _Wurf(int tag) : _zustand = (tag.abs() * 6007 + 7727) % _m {
    if (_zustand == 0) _zustand = 1;
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
