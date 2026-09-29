import 'dart:math';

import 'day.dart';
import 'tracker.dart';

/// Welche Art von Tagesaufgabe (ADR-0055).
///
/// **Nur Gewohnheiten und Rückfrage, keine Grube.** Eine Aufgabe bringt
/// einen Schlüssel, und die Zahl der Schlüssel soll nur an Gewohnheiten
/// und Theorie hängen (ADR-0048): Wer mehr spielt, darf, wird dadurch
/// aber nicht stärker.
enum QuestKind {
  zweiHaekchen,
  dreiHaekchen,
  alles,
  liegengeblieben,
  rueckfrage;

  /// Ob die Aufgabe ums Abhaken geht — von diesen steht immer eine da.
  bool get isHabitCount =>
      this == zweiHaekchen || this == dreiHaekchen || this == alles;
}

/// Eine Tagesaufgabe samt Stand.
class DailyQuest {
  const DailyQuest({
    required this.kind,
    required this.text,
    required this.progress,
    required this.target,
    this.habitName,
  });

  final QuestKind kind;

  /// Um welche Gewohnheit es geht — nur bei [QuestKind.liegengeblieben].
  /// Der Bildschirm zeigt die Aufgabe als Zeichen und braucht dann nur
  /// noch diesen Namen.
  final String? habitName;

  /// Wie sie auf dem Bildschirm steht.
  final String text;

  final int progress;
  final int target;

  /// Die Id, unter der ein Abholen gespeichert wird. Eine Art gibt es je
  /// Tag höchstens einmal, also genügt ihr Name.
  String get id => kind.name;

  bool get isDone => progress >= target;
}

/// Die drei Aufgaben des Tages — aus dem Datum gewürfelt, der Stand aus
/// der Historie gelesen (ADR-0055).
///
/// **Warum es sie gibt.** Die Gewohnheiten zahlen jeden Tag dasselbe, und
/// `runway_sim` zeigt, dass das Neue in Woche 3 und 4 selten wird. Drei
/// kleine, wechselnde Ziele geben jedem Tag etwas Eigenes — wie die
/// Aufgaben bei Duolingo.
///
/// Gespeichert wird nur, **welche abgeholt sind** (`HabitTracker`), so wie
/// bei der Tagestruhe nur der Tag des Öffnens.
abstract final class DailyQuests {
  static const int perDay = 3;

  /// Schlüssel je abgeholter Aufgabe.
  static const int keysPerQuest = 1;

  /// Die Aufgaben für [day].
  ///
  /// [reviewAvailable] sagt, ob es an [day] eine Rückfrage gibt,
  /// [reviewCorrect], ob sie richtig beantwortet ist. Beides kommt aus
  /// `package:theory`, das dieses Package nicht kennt.
  static List<DailyQuest> forDay(
    HabitTracker tracker,
    Day day, {
    required bool reviewAvailable,
    required bool reviewCorrect,
  }) {
    final aktiv = tracker.activeIds.length;
    final erledigt = tracker.completedOn(day);
    final liegen = _liegengeblieben(tracker, day);

    final verfuegbar = <QuestKind>[
      if (aktiv >= 2) QuestKind.zweiHaekchen,
      if (aktiv >= 3) QuestKind.dreiHaekchen,
      if (aktiv >= 1) QuestKind.alles,
      if (liegen != null) QuestKind.liegengeblieben,
      if (reviewAvailable) QuestKind.rueckfrage,
    ]..shuffle(Random(_seed(day)));

    final gewaehlt = <QuestKind>[];
    // Immer eine zum Abhaken, und zwei davon nie zugleich: „Hake 2 ab"
    // neben „Hake 3 ab" wäre eine Aufgabe in zwei Zeilen.
    final ersteHabit = verfuegbar.where((k) => k.isHabitCount).firstOrNull;
    if (ersteHabit != null) gewaehlt.add(ersteHabit);
    for (final kind in verfuegbar) {
      if (gewaehlt.length >= perDay) break;
      if (gewaehlt.contains(kind) || kind.isHabitCount) continue;
      gewaehlt.add(kind);
    }

    return <DailyQuest>[
      for (final kind in gewaehlt)
        switch (kind) {
          QuestKind.zweiHaekchen => DailyQuest(
              kind: kind,
              text: 'Hake 2 Gewohnheiten ab',
              progress: min(erledigt, 2),
              target: 2,
            ),
          QuestKind.dreiHaekchen => DailyQuest(
              kind: kind,
              text: 'Hake 3 Gewohnheiten ab',
              progress: min(erledigt, 3),
              target: 3,
            ),
          QuestKind.alles => DailyQuest(
              kind: kind,
              text: 'Erledige heute alles',
              progress: min(erledigt, aktiv),
              target: aktiv,
            ),
          QuestKind.liegengeblieben => DailyQuest(
              kind: kind,
              text: 'Hol nach, was gestern liegen blieb: ${liegen!.$2}',
              progress: tracker.isChecked(liegen.$1, day) ? 1 : 0,
              target: 1,
              habitName: liegen.$2,
            ),
          QuestKind.rueckfrage => DailyQuest(
              kind: kind,
              text: 'Beantworte die Rückfrage richtig',
              progress: reviewCorrect ? 1 : 0,
              target: 1,
            ),
        },
    ];
  }

  /// Die erste laufende Gewohnheit, die gestern offen blieb — in der
  /// Reihenfolge der Tagesliste. Id und Name, oder null.
  static (String, String)? _liegengeblieben(HabitTracker tracker, Day day) {
    final gestern = day.previous;
    for (final habit in tracker.activeHabitsByPriority) {
      if (!tracker.isChecked(habit.id, gestern)) return (habit.id, habit.name);
    }
    return null;
  }

  /// Derselbe Tag gibt für beide Spieler dieselbe Mischung.
  static int _seed(Day day) => day.year * 10000 + day.month * 100 + day.day;
}
