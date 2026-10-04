import 'day.dart';

/// Der Timer einer Gewohnheit mit Zeitziel (ADR-0067).
///
/// **Gerechnet wird aus der Startzeit, nicht aus Ticks.** [runningSince]
/// ist ein Zeitpunkt; wie viel gelaufen ist, ergibt sich erst mit der
/// Uhr von jetzt ([secondsAt]). Damit läuft der Timer weiter, wenn das
/// Blatt zu ist, der Browser im Hintergrund liegt oder die App neu lädt —
/// ein Zähler, der jede Sekunde eins hochzählt, bliebe dort stehen.
///
/// **Es gibt höchstens einen.** Er gehört zu einer Gewohnheit und einem
/// Tag. Ganze Minuten wandern beim Anhalten in den Tagesfortschritt des
/// Trackers; hier bleibt nur der Rest unter einer Minute
/// ([carriedSeconds]), damit eine Pause keine angefangene Minute kostet.
class HabitTimer {
  const HabitTimer({
    required this.habitId,
    required this.day,
    this.carriedSeconds = 0,
    this.runningSince,
  });

  final String habitId;

  /// Der Tag, an dem er gestartet wurde — und dem die Zeit gehört, auch
  /// wenn er über Mitternacht läuft.
  final Day day;

  /// Sekunden, die schon gelaufen und noch **nicht** als ganze Minute
  /// verbucht sind. Immer unter sechzig.
  final int carriedSeconds;

  /// Seit wann er läuft, in UTC. Null heißt angehalten.
  final DateTime? runningSince;

  bool get isRunning => runningSince != null;

  bool isFor(String habitId, Day day) {
    return this.habitId == habitId && this.day == day;
  }

  /// Die unverbuchten Sekunden bis [now].
  ///
  /// Eine zurückgestellte Uhr ergibt null gelaufene Sekunden, nie
  /// negative — sonst nähme sie verbuchte Zeit wieder weg.
  int secondsAt(DateTime now) {
    final seit = runningSince;
    if (seit == null) return carriedSeconds;
    final gelaufen = now.toUtc().difference(seit).inSeconds;
    return carriedSeconds + (gelaufen < 0 ? 0 : gelaufen);
  }

  /// Derselbe Timer, ab [now] laufend.
  HabitTimer startedAt(DateTime now) {
    return HabitTimer(
      habitId: habitId,
      day: day,
      carriedSeconds: carriedSeconds,
      runningSince: now.toUtc(),
    );
  }

  /// Derselbe Timer, angehalten, mit [seconds] als Rest.
  HabitTimer pausedWith(int seconds) {
    return HabitTimer(habitId: habitId, day: day, carriedSeconds: seconds);
  }

  Map<String, Object?> toJson() {
    final seit = runningSince;
    return <String, Object?>{
      'habit': habitId,
      'day': day.toString(),
      if (carriedSeconds > 0) 'carried': carriedSeconds,
      if (seit != null) 'since': seit.millisecondsSinceEpoch,
    };
  }

  /// Liest einen gespeicherten Timer. Null bei allem, was nicht passt —
  /// ein verlorener Timer kostet höchstens eine angefangene Minute.
  static HabitTimer? fromJson(Object? json) {
    if (json is! Map) return null;
    final habitId = json['habit'];
    final rawDay = json['day'];
    if (habitId is! String || rawDay is! String) return null;
    final day = Day.tryParse(rawDay);
    if (day == null) return null;

    final carried = json['carried'];
    final since = json['since'];
    return HabitTimer(
      habitId: habitId,
      day: day,
      carriedSeconds:
          carried is int && carried > 0 && carried < 60 ? carried : 0,
      runningSince: since is int
          ? DateTime.fromMillisecondsSinceEpoch(since, isUtc: true)
          : null,
    );
  }
}
