import 'balance.dart';

/// Ergebnis der Timing-Eingabe des Spielers.
///
/// Wichtig: Die Logik **misst** kein Timing. Sie bekommt das Ergebnis als
/// Eingabe. Ob das Fenster in Flame, in einem Test oder in einer Simulation
/// bestimmt wurde, ist ihr gleichgueltig (ADR-0002).
enum TimedHit {
  /// Kein Tap oder ausserhalb des Fensters.
  none,

  /// Im aeusseren Fenster.
  good,

  /// Im inneren Fenster.
  perfect;

  /// Schadensfaktor gemaess Balance. Gedeckelt, damit Fingerfertigkeit
  /// Habits nicht ersetzt.
  double factor(Balance balance) => switch (this) {
        TimedHit.none => balance.timedHitNone,
        TimedHit.good => balance.timedHitGood,
        TimedHit.perfect => balance.timedHitPerfect,
      };
}
