import 'package:habits/habits.dart';

/// Wie der Auslöser einer Gewohnheit auf der Startseite steht. Die Kachel
/// auf dem Gewohnheiten-Bildschirm zeigt eine Kopplung über die Einrückung.
///
/// Ein Anker (ADR-0065) steht als „Nach: Zähne putzen“, ein Satz
/// (ADR-0052) so, wie er eingegeben wurde. Beides zugleich gibt es nicht;
/// das stellt `HabitTracker.setAnchor` sicher.
abstract final class CueText {
  static String? lineFor(HabitTracker tracker, String habitId) {
    final anker = tracker.anchorFor(habitId);
    final name = anker == null ? null : tracker.definitionFor(anker)?.name;
    if (name != null) return 'Nach: $name';
    return tracker.cueFor(habitId);
  }
}
