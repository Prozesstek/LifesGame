import 'habit.dart';

/// Eine Gewohnheit an ihrem Platz in der Tagesliste.
class StackedHabit {
  const StackedHabit({
    required this.habit,
    required this.depth,
    required this.isCued,
  });

  final Habit habit;

  /// Wie tief sie in ihrem Stapel hängt: 0 für alles, was an nichts hängt
  /// oder dessen Anker heute nicht auf der Liste steht.
  final int depth;

  /// Ob sie **jetzt dran** ist: selbst noch offen, ihr Anker abgehakt.
  /// Das ist der Moment, für den die Kopplung da ist.
  final bool isCued;
}

/// **Gewohnheiten aneinander koppeln** (ADR-0065) — der Gewohnheitsstapel
/// aus *Die 1%-Methode*: „Nach [bestehende Gewohnheit] mache ich [neue]“.
///
/// Eine Kopplung ist ein Auslöser, der auf eine andere Gewohnheit zeigt
/// statt auf einen Satz. Sie **erzeugt keine Zahl** (wie der Auslöser,
/// ADR-0052) und sperrt nichts: Sie ordnet die Tagesliste und sagt, was
/// als Nächstes dran ist.
abstract final class HabitStacks {
  /// Ob [habitId] an [anchorId] zu hängen einen Kreis schlösse — direkt
  /// (an sich selbst) oder über die Kette der Anker.
  static bool wouldCycle(
    Map<String, String> anchors,
    String habitId,
    String anchorId,
  ) {
    String? cursor = anchorId;
    final gesehen = <String>{};
    while (cursor != null) {
      if (cursor == habitId) return true;
      // Ein Kreis, der schon im Stand steht, darf hier nicht hängen
      // bleiben.
      if (!gesehen.add(cursor)) return true;
      cursor = anchors[cursor];
    }
    return false;
  }

  /// Ordnet [habits] zu Stapeln: jede Gewohnheit direkt unter ihrem
  /// Anker, tiefer eingerückt.
  ///
  /// [habits] kommt schon in der Reihenfolge, die ohne Kopplung gälte.
  /// Sie bleibt für die Wurzeln und für Geschwister unter demselben Anker
  /// erhalten. **Ein Stapel bleibt zusammen**: Er steht oben, solange
  /// irgendein Glied offen ist, und wandert als Ganzes nach unten, wenn
  /// alles erledigt ist — sonst rutschte ein abgehakter Anker von seiner
  /// offenen Folge weg, und genau die soll man dann sehen.
  ///
  /// Ein Anker, der nicht in [habits] steht (gestoppt, heute nicht
  /// fällig), zählt nicht: Die Gewohnheit ist dann selbst eine Wurzel.
  static List<StackedHabit> order(
    List<Habit> habits,
    Map<String, String> anchors, {
    required bool Function(Habit habit) isDone,
  }) {
    final aufListe = <String, Habit>{for (final h in habits) h.id: h};
    final kinder = <String, List<Habit>>{};
    final wurzeln = <Habit>[];
    for (final habit in habits) {
      final anker = anchors[habit.id];
      if (anker != null &&
          aufListe.containsKey(anker) &&
          !wouldCycle(anchors, habit.id, anker)) {
        kinder.putIfAbsent(anker, () => <Habit>[]).add(habit);
      } else {
        wurzeln.add(habit);
      }
    }

    List<StackedHabit> stapel(Habit habit, int depth, {required bool cued}) {
      final erledigt = isDone(habit);
      return <StackedHabit>[
        StackedHabit(habit: habit, depth: depth, isCued: cued && !erledigt),
        for (final kind in kinder[habit.id] ?? const <Habit>[])
          ...stapel(kind, depth + 1, cued: erledigt),
      ];
    }

    final offen = <StackedHabit>[];
    final fertig = <StackedHabit>[];
    for (final wurzel in wurzeln) {
      final glieder = stapel(wurzel, 0, cued: false);
      final alleErledigt = glieder.every((g) => isDone(g.habit));
      (alleErledigt ? fertig : offen).addAll(glieder);
    }
    return List<StackedHabit>.unmodifiable(<StackedHabit>[...offen, ...fertig]);
  }
}
