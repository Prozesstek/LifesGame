import 'package:habits/habits.dart';

/// Spielt Wochen mit Gewohnheiten durch und zeigt, was dabei herauskommt.
///
/// Gleicher Zweck wie `combat/example/balance_sim.dart`: Wer an
/// `rewards.dart` dreht, soll das Ergebnis sehen und nicht raten müssen.
///
///     dart run example/curve_sim.dart
void main() {
  print('Ertrag und Werte über 90 Tage\n');

  _run('vorbildlich — jeden Tag alle 5', quote: 1.0);
  _run('realistisch — 5 von 7 Tagen', quote: 5 / 7);
  _run('wackelig — jeden zweiten Tag', quote: 0.5);

  // Seit ADR-0064: derselbe Aufwand wie „5 von 7", aber als Plan. Die
  // freien Tage reißen nichts, die Kette wächst an jedem fälligen Tag.
  _run(
    'geplant — Montag bis Freitag, jeden davon',
    quote: 1.0,
    weekdays: const <int>{1, 2, 3, 4, 5},
  );
  // Und was der Rückfall auf die Stufe darunter ausmacht: Wer einmal die
  // Woche vergisst, fiel bis ADR-0064 jedes Mal auf null.
  _run('fast immer — ein Tag je Woche fehlt', quote: 6 / 7);

  print('\nWie lange bis zu einem Wert:');
  for (final stat in HabitStat.values) {
    final rule = StatCurve.ruleFor(stat);
    final bisMax = rule.checksPerPoint * (rule.maxBonus ~/ rule.pointStep);
    print(
      '  ${stat.label.padRight(10)} '
      '${rule.base} bis ${rule.base + rule.maxBonus} '
      '(${stat.combatLabel}) — $bisMax Häkchen bis zum Maximum',
    );
  }
}

/// Hakt [days] Tage lang alle laufenden Gewohnheiten mit Wahrscheinlichkeit
/// [quote] ab — deterministisch, damit zwei Läufe vergleichbar bleiben.
///
/// Mit [weekdays] bekommen alle einen Wochenplan (ADR-0064); abgehakt wird
/// dann nur an fälligen Tagen.
void _run(String label, {required double quote, Set<int>? weekdays}) {
  final chosen = HabitCatalog.all
      .take(HabitRewards.maxActiveHabits)
      .map((t) => t.id)
      .toList();

  var day = const Day(2026, 1, 1);
  var tracker = const HabitTracker.empty();
  for (final id in chosen) {
    tracker = tracker.activate(id, today: day);
    if (weekdays != null) {
      tracker = tracker.setWeekdays(id, weekdays, today: day);
    }
  }

  final marks = <int, HabitTracker>{};

  for (var i = 1; i <= 90; i++) {
    // Deterministisches Muster statt Zufall: Tag i zählt, wenn er in die
    // Quote fällt. Damit ist jeder Lauf reproduzierbar.
    final zaehlt = (i * quote).floor() > ((i - 1) * quote).floor();
    if (zaehlt) {
      for (final id in chosen) {
        if (!tracker.isDueOn(id, day)) continue;
        tracker = tracker.check(id, day).tracker;
      }
    }
    if (i == 7 || i == 30 || i == 90) marks[i] = tracker;
    day = day.next;
  }

  print('$label:');
  for (final entry in marks.entries) {
    final t = entry.value;
    final stats = t.stats;
    print(
      '  Tag ${entry.key.toString().padLeft(2)}  '
      '${t.totalChecks.toString().padLeft(3)} Häkchen  '
      '${t.totalXp.toString().padLeft(5)} XP  '
      '${t.totalGold.toString().padLeft(4)} Gold  '
      'ATK ${stats.attack}  HP ${stats.maxHp}  '
      'DEF ${stats.defense}  EN ${stats.maxEnergy}',
    );
  }
  print('');
}
