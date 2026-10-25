import 'package:habits/habits.dart';

/// Wie die Tagesform heisst, wo immer sie steht — Gewohnheiten,
/// Charakter, Eingang zur Grube. **Eine Stelle**, damit drei Bildschirme
/// nicht drei Wortlaute erfinden. Gerechnet wird hier nichts: Die
/// Faktoren kommen aus [DailyForm].
///
/// Wie ein Wert heißt, steht seit ADR-0088 an ihm selbst
/// ([HabitStat.label]) — bis dahin übersetzte diese Klasse „Klarheit“ in
/// „Mana“.
abstract final class DailyFormText {
  /// „+20 %" aus einem Faktor von 1,2.
  static String percent(double factor) => '+${((factor - 1) * 100).round()} %';

  /// „Angriff +20 % · Leben +10 %" — nur, was heute steigt. Null an einem
  /// Tag ohne Häkchen.
  static String? summary(DailyForm form) {
    if (!form.isActive) return null;
    return <String>[
      for (final stat in HabitStat.values)
        if (form.factorFor(stat) > 1)
          '${stat.label} ${percent(form.factorFor(stat))}',
    ].join(' · ');
  }

  /// Was ein einzelnes Häkchen eben gebracht hat, für die Leiste unten.
  static String gainAfterCheck({
    required HabitStat stat,
    required DailyForm vorher,
    required DailyForm nachher,
  }) {
    if (nachher.isInForm && !vorher.isInForm) {
      return 'In Form! Heute alles '
          '${percent(1 + HabitRewards.formAllDone)} dazu';
    }
    if (nachher.factorFor(stat) <= vorher.factorFor(stat)) return '';
    return '${stat.label} heute ${percent(nachher.factorFor(stat))}';
  }
}
