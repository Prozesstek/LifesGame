import 'habit.dart';
import 'rewards.dart';

/// Die Kampfwerte, die sich aus den abgehakten Gewohnheiten ergeben.
///
/// Das ist die Stelle, an der sich der Kern-Loop des Konzepts schließt:
/// Was im Alltag passiert, steht hier als Zahl. Der Kampf bekommt diese
/// Werte übergeben — er fragt nie nach Gewohnheiten, und `package:habits`
/// weiß nichts von `package:combat`.
class CharacterStats {
  const CharacterStats(this._checksByStat);

  const CharacterStats.fresh() : _checksByStat = const <HabitStat, int>{};

  /// Erledigte Häkchen je Charakterwert, über die gesamte Historie.
  final Map<HabitStat, int> _checksByStat;

  int checksFor(HabitStat stat) => _checksByStat[stat] ?? 0;

  int bonusFor(HabitStat stat) => StatCurve.bonusFor(stat, checksFor(stat));

  int valueFor(HabitStat stat) {
    return StatCurve.ruleFor(stat).base + bonusFor(stat);
  }

  /// Wie viele Häkchen noch bis zum nächsten Punkt fehlen. 0 am Deckel.
  int checksToNextPoint(HabitStat stat) {
    return StatCurve.checksToNextPoint(stat, checksFor(stat));
  }

  bool isAtCap(HabitStat stat) {
    return bonusFor(stat) >= StatCurve.ruleFor(stat).maxBonus;
  }

  int get attack => valueFor(HabitStat.staerke);

  int get maxHp => valueFor(HabitStat.ausdauer);

  int get defense => valueFor(HabitStat.disziplin);

  int get maxEnergy => valueFor(HabitStat.klarheit);

  /// Gesamtzahl aller Häkchen — für die Anzeige „so oft hast du geliefert“.
  int get totalChecks {
    return _checksByStat.values.fold(0, (sum, count) => sum + count);
  }
}
