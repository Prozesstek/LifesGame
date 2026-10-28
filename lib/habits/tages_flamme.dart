import 'package:habits/habits.dart';

/// Wie ein Tag der Woche unter der großen Flamme steht.
enum FlammenTag {
  /// Etwas war abgehakt — der Tag hat die Kette getragen.
  brennt,

  /// Ein Streak-Eis hat ihn gedeckt (ADR-0036).
  eis,

  /// Nichts abgehakt, nichts gedeckt — ein Ruhetag oder ein verpasster.
  leer,

  /// Heute: Er zündet gerade.
  heute,

  /// Liegt noch vor uns.
  kommt,
}

/// **Die große Flamme in der Mitte** (28.10.2026, Frederik: „immer wenn
/// die erste Gewohnheit am Tag abgehakt wird in der Mitte des Screens die
/// Flamme einen Tag höher tickt … so wie bei Duolingo“).
///
/// Reine Rechnung aus zwei Ständen des Trackers, vorher und nachher —
/// dieselben, aus denen `HaekchenMoment` liest. **Sie erzeugt keine
/// Zahl**: Die Tageskette rechnet der Tracker (ADR-0055), hier steht nur,
/// was die Einblendung zeigt.
class TagesFlamme {
  const TagesFlamme({
    required this.vorher,
    required this.nachher,
    required this.woche,
  });

  /// Die Flamme dieses Häkchens — oder null, wenn es nicht das erste des
  /// Tages ist. Nur das erste trägt den Tag in die Kette.
  static TagesFlamme? aus({
    required HabitTracker vorher,
    required HabitTracker nachher,
    required Day heute,
  }) {
    if (vorher.hasCheckOn(heute) || !nachher.hasCheckOn(heute)) return null;
    return TagesFlamme(
      vorher: vorher.currentDayStreak(heute),
      nachher: nachher.currentDayStreak(heute),
      woche: wocheVon(nachher, heute),
    );
  }

  /// Die Woche von [heute], Montag bis Sonntag.
  static List<FlammenTag> wocheVon(HabitTracker tracker, Day heute) {
    final tage = <FlammenTag>[];
    var tag = heute.startOfWeek;
    for (var i = 0; i < 7; i++, tag = tag.next) {
      tage.add(switch (tag) {
        _ when tag == heute => FlammenTag.heute,
        _ when tag > heute => FlammenTag.kommt,
        _ when tracker.hasCheckOn(tag) => FlammenTag.brennt,
        _ when tracker.isFrozen(tag) => FlammenTag.eis,
        _ => FlammenTag.leer,
      });
    }
    return List<FlammenTag>.unmodifiable(tage);
  }

  /// Die Kette, bevor heute etwas abgehakt war — sie lebt noch, wenn
  /// gestern sie getragen hat. 0, wenn es noch keine gab.
  final int vorher;

  /// Die Kette mit heute.
  final int nachher;

  /// Montag bis Sonntag; genau ein Tag ist [FlammenTag.heute].
  final List<FlammenTag> woche;

  /// Ob die Zahl rollt. Beim allerersten Tag steht vorher nichts da, und
  /// die Eins springt einfach auf.
  bool get rollt => vorher > 0 && vorher != nachher;
}
