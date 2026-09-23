import 'package:habits/habits.dart';

/// Wie die Tagesform heisst, wo immer sie steht — Gewohnheiten,
/// Charakter, Eingang zur Grube. **Eine Stelle**, damit drei Bildschirme
/// nicht drei Wortlaute erfinden. Gerechnet wird hier nichts: Die
/// Faktoren kommen aus [DailyForm].
abstract final class DailyFormText {
  /// Der Wert in der Grube, den [stat] heute stärkt. Nicht
  /// [HabitStat.combatLabel]: Klarheit füllt in der Grube das Mana.
  static String pitNameOf(HabitStat stat) => switch (stat) {
    HabitStat.staerke => 'Angriff',
    HabitStat.ausdauer => 'Leben',
    HabitStat.disziplin => 'Abwehr',
    HabitStat.klarheit => 'Mana',
  };

  /// „+20 %" aus einem Faktor von 1,2.
  static String percent(double factor) => '+${((factor - 1) * 100).round()} %';

  /// „Angriff +20 % · Leben +10 %" — nur, was heute steigt. Null an einem
  /// Tag ohne Häkchen.
  static String? summary(DailyForm form) {
    if (!form.isActive) return null;
    return <String>[
      for (final stat in HabitStat.values)
        if (form.factorFor(stat) > 1)
          '${pitNameOf(stat)} ${percent(form.factorFor(stat))}',
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
    return '${pitNameOf(stat)} heute ${percent(nachher.factorFor(stat))}';
  }
}
