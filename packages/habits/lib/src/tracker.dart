import 'catalog.dart';
import 'character_stats.dart';
import 'day.dart';
import 'habit.dart';
import 'rewards.dart';

/// Was ein Häkchen eingebracht hat — inklusive des daraus folgenden
/// neuen Standes.
class CheckResult {
  const CheckResult({
    required this.habitId,
    required this.day,
    required this.streak,
    required this.multiplier,
    required this.xpGained,
    required this.goldGained,
    required this.reachedMilestone,
    required this.wasAlreadyChecked,
    required this.tracker,
  });

  final String habitId;
  final Day day;

  /// Länge der Streak **einschließlich** dieses Häkchens. Der erste Tag
  /// ist 1, nicht 0.
  final int streak;

  final double multiplier;
  final int xpGained;
  final int goldGained;

  /// Der Meilenstein, den genau dieses Häkchen erreicht hat. Null, wenn es
  /// keiner war — die Oberfläche soll nur dann feiern, wenn es etwas zu
  /// feiern gibt.
  final StreakMilestone? reachedMilestone;

  /// Ob an diesem Tag schon abgehakt war. Dann hat sich nichts geändert.
  final bool wasAlreadyChecked;

  final HabitTracker tracker;
}

/// Welche Gewohnheiten laufen und an welchen Tagen sie erledigt wurden.
///
/// Unveränderlich: Jede Änderung gibt einen neuen Tracker zurück.
///
/// Erfahrung und Gold werden **abgeleitet**, nicht mitgezählt. Dieselbe
/// Entscheidung wie bei `TheoryProgress`: Ein versehentliches Häkchen
/// lässt sich damit zurücknehmen, ohne dass ein Zähler auseinanderläuft.
class HabitTracker {
  HabitTracker({
    List<String> activeIds = const <String>[],
    Map<String, Set<Day>> checks = const <String, Set<Day>>{},
  })  : _activeIds = List<String>.unmodifiable(activeIds),
        _checks = _frozen(checks);

  const HabitTracker.empty()
      : _activeIds = const <String>[],
        _checks = const <String, Set<Day>>{};

  /// Liest einen gespeicherten Stand.
  ///
  /// **Nachsichtig mit Absicht.** Was hier ankommt, hat eine ältere
  /// Programmversion geschrieben: Vorlagen können umbenannt oder entfernt
  /// worden sein, ein Tag kann unlesbar sein. Nichts davon darf den
  /// Ladevorgang abbrechen, denn der Preis wäre der gesamte Fortschritt
  /// des Nutzers. Unbekanntes wird übersprungen, nicht geworfen — dieselbe
  /// Entscheidung wie in [HabitCatalog.byNames].
  ///
  /// Die Gegenprobe dazu ist ein Test, nicht eine Ausnahme:
  /// `test/persistence_test.dart` prüft, dass ein voller Stand
  /// unverändert durch [toJson] und zurück kommt.
  factory HabitTracker.fromJson(Map<String, Object?> json) {
    final ids = <String>[];
    final rawIds = json['activeIds'];
    if (rawIds is List) {
      for (final id in rawIds) {
        if (id is String && HabitCatalog.byId(id) != null) ids.add(id);
      }
    }

    final checks = <String, Set<Day>>{};
    final rawChecks = json['checks'];
    if (rawChecks is Map) {
      for (final entry in rawChecks.entries) {
        final habitId = entry.key;
        final days = entry.value;
        if (habitId is! String || days is! List) continue;

        final parsed = <Day>{};
        for (final day in days) {
          if (day is! String) continue;
          final value = Day.tryParse(day);
          if (value != null) parsed.add(value);
        }
        if (parsed.isNotEmpty) checks[habitId] = parsed;
      }
    }

    // Die Obergrenze wird beim Laden erzwungen, nicht nur beim Anlegen:
    // Ein Stand aus einer Version mit anderer Grenze darf sie nicht
    // unterlaufen.
    final begrenzt = ids.length > HabitRewards.maxActiveHabits
        ? ids.sublist(0, HabitRewards.maxActiveHabits)
        : ids;

    return HabitTracker(activeIds: begrenzt, checks: checks);
  }

  final List<String> _activeIds;

  /// Je Gewohnheit die Tage, an denen sie erledigt wurde.
  final Map<String, Set<Day>> _checks;

  /// Der Stand als JSON.
  ///
  /// Gespeichert wird nur, was der Nutzer getan hat: welche Gewohnheiten
  /// laufen und an welchen Tagen sie erledigt wurden. Erfahrung, Gold und
  /// Charakterwerte stehen **nicht** hier — sie werden abgeleitet
  /// (ADR-0008). Wären sie gespeichert, gäbe es zwei Wahrheiten, und die
  /// eine würde irgendwann von der anderen abweichen.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'activeIds': _activeIds,
      'checks': <String, Object?>{
        for (final entry in _checks.entries)
          entry.key: (entry.value.toList()..sort())
              .map((day) => day.toString())
              .toList(),
      },
    };
  }

  static Map<String, Set<Day>> _frozen(Map<String, Set<Day>> checks) {
    return Map<String, Set<Day>>.unmodifiable(<String, Set<Day>>{
      for (final entry in checks.entries)
        entry.key: Set<Day>.unmodifiable(entry.value),
    });
  }

  // --- Welche Gewohnheiten laufen ---

  List<String> get activeIds => _activeIds;

  /// Die laufenden Vorlagen in der Reihenfolge, in der sie gewählt wurden.
  /// Unbekannte Ids werden übersprungen (siehe [HabitCatalog.byNames]).
  List<HabitTemplate> get activeTemplates {
    final templates = <HabitTemplate>[];
    for (final id in _activeIds) {
      final template = HabitCatalog.byId(id);
      if (template != null) templates.add(template);
    }
    return List<HabitTemplate>.unmodifiable(templates);
  }

  bool isActive(String habitId) => _activeIds.contains(habitId);

  bool get isFull => _activeIds.length >= HabitRewards.maxActiveHabits;

  bool canActivate(String habitId) {
    if (isActive(habitId)) return false;
    if (isFull) return false;
    return HabitCatalog.byId(habitId) != null;
  }

  /// Nimmt eine Vorlage in die tägliche Liste auf.
  ///
  /// Gibt unverändert zurück, wenn [canActivate] false ist — die
  /// Oberfläche fragt vorher und schaltet den Knopf ab.
  HabitTracker activate(String habitId) {
    if (!canActivate(habitId)) return this;
    return HabitTracker(
      activeIds: <String>[..._activeIds, habitId],
      checks: _checks,
    );
  }

  /// Nimmt eine Vorlage aus der täglichen Liste.
  ///
  /// Die Historie bleibt erhalten, und damit auch die Charakterwerte:
  /// Was einmal getan wurde, ist getan. Sonst würde jeder Wechsel der
  /// Gewohnheiten den Charakter schwächen und niemand traute sich, etwas
  /// Neues auszuprobieren.
  HabitTracker deactivate(String habitId) {
    if (!isActive(habitId)) return this;
    return HabitTracker(
      activeIds: _activeIds.where((id) => id != habitId).toList(),
      checks: _checks,
    );
  }

  // --- Abhaken ---

  bool isChecked(String habitId, Day day) {
    return _checks[habitId]?.contains(day) ?? false;
  }

  int checksFor(String habitId) => _checks[habitId]?.length ?? 0;

  /// Wie viele der laufenden Gewohnheiten an [day] erledigt sind.
  int completedOn(Day day) {
    return _activeIds.where((id) => isChecked(id, day)).length;
  }

  bool isDayComplete(Day day) {
    return _activeIds.isNotEmpty && completedOn(day) == _activeIds.length;
  }

  /// Hakt eine Gewohnheit für [day] ab.
  ///
  /// Wirft, wenn die Gewohnheit gar nicht läuft — das wäre ein Fehler in
  /// der Oberfläche, kein Nutzerfehler. Ein zweites Häkchen am selben Tag
  /// ist dagegen harmlos und ändert nichts.
  CheckResult check(String habitId, Day day) {
    if (!isActive(habitId)) {
      throw StateError('Gewohnheit "$habitId" läuft nicht.');
    }

    if (isChecked(habitId, day)) {
      final streak = streakEndingAt(habitId, day);
      return CheckResult(
        habitId: habitId,
        day: day,
        streak: streak,
        multiplier: HabitRewards.multiplierFor(streak),
        xpGained: 0,
        goldGained: 0,
        reachedMilestone: null,
        wasAlreadyChecked: true,
        tracker: this,
      );
    }

    final next = HabitTracker(
      activeIds: _activeIds,
      checks: <String, Set<Day>>{
        ..._checks,
        habitId: <Day>{...?_checks[habitId], day},
      },
    );

    final streak = next.streakEndingAt(habitId, day);
    final before = streak - 1;

    return CheckResult(
      habitId: habitId,
      day: day,
      streak: streak,
      multiplier: HabitRewards.multiplierFor(streak),
      xpGained: HabitRewards.xpFor(streak),
      goldGained: HabitRewards.goldFor(streak),
      reachedMilestone: _milestoneCrossedBy(before, streak),
      wasAlreadyChecked: false,
      tracker: next,
    );
  }

  /// Nimmt ein Häkchen zurück. Erfahrung und Gold sind abgeleitet und
  /// verschwinden dadurch von allein.
  HabitTracker uncheck(String habitId, Day day) {
    if (!isChecked(habitId, day)) return this;
    final remaining = <Day>{...?_checks[habitId]}..remove(day);
    final next = <String, Set<Day>>{..._checks};
    if (remaining.isEmpty) {
      next.remove(habitId);
    } else {
      next[habitId] = remaining;
    }
    return HabitTracker(activeIds: _activeIds, checks: next);
  }

  static StreakMilestone? _milestoneCrossedBy(int before, int after) {
    for (final milestone in HabitRewards.streakMilestones) {
      if (before < milestone.days && after >= milestone.days) return milestone;
    }
    return null;
  }

  // --- Streaks ---

  /// Länge der ununterbrochenen Kette, die an [day] endet. 0, wenn an
  /// [day] nicht abgehakt wurde.
  int streakEndingAt(String habitId, Day day) {
    final days = _checks[habitId];
    if (days == null || days.isEmpty) return 0;

    var streak = 0;
    var cursor = day;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.previous;
    }
    return streak;
  }

  /// Die Streak, die heute noch zählt.
  ///
  /// Ist heute abgehakt, endet die Kette heute. Ist sie es nicht, endet
  /// sie gestern — eine Streak stirbt erst, wenn der Tag vorbei ist, nicht
  /// beim Aufwachen. Das Konzept verlangt, dass Verpassen keine Strafe
  /// ist; sie am Morgen zu löschen wäre eine.
  int currentStreak(String habitId, Day today) {
    if (isChecked(habitId, today)) return streakEndingAt(habitId, today);
    return streakEndingAt(habitId, today.previous);
  }

  /// Der Multiplikator, den das nächste Häkchen an [today] brächte.
  double nextMultiplier(String habitId, Day today) {
    if (isChecked(habitId, today)) {
      return HabitRewards.multiplierFor(streakEndingAt(habitId, today));
    }
    return HabitRewards.multiplierFor(currentStreak(habitId, today) + 1);
  }

  // --- Ertrag ---

  /// Gesamte Erfahrung aus allen Häkchen, mit dem Multiplikator, der am
  /// jeweiligen Tag galt.
  int get totalXp {
    var sum = 0;
    for (final days in _checks.values) {
      final sorted = days.toList()..sort();
      var streak = 0;
      Day? previous;
      for (final day in sorted) {
        streak =
            previous != null && previous.daysUntil(day) == 1 ? streak + 1 : 1;
        sum += HabitRewards.xpFor(streak);
        previous = day;
      }
    }
    return sum;
  }

  int get totalGold => totalChecks * HabitRewards.goldPerCheck;

  int get totalChecks {
    return _checks.values.fold(0, (sum, days) => sum + days.length);
  }

  /// Die Kampfwerte, die sich aus der gesamten Historie ergeben.
  CharacterStats get stats {
    final counts = <HabitStat, int>{};
    for (final entry in _checks.entries) {
      final template = HabitCatalog.byId(entry.key);
      if (template == null) continue;
      counts[template.stat] = (counts[template.stat] ?? 0) + entry.value.length;
    }
    return CharacterStats(counts);
  }
}
