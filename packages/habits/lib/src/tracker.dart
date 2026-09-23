import 'catalog.dart';
import 'character_stats.dart';
import 'daily_chest.dart';
import 'daily_form.dart';
import 'day.dart';
import 'habit.dart';
import 'rewards.dart';
import 'streak_freeze.dart';
import 'week_summary.dart';

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
    this.progress = 1,
    this.required = 1,
  });

  final String habitId;
  final Day day;

  /// Länge der Streak **einschließlich** dieses Häkchens. Der erste Tag
  /// ist 1, nicht 0. Bei noch unfertigem Tagesziel ist es die Kette, die
  /// gestern endete — heute ist ja noch nichts geschafft.
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

  /// Wie weit das Tagesziel nach diesem Schritt gefüllt ist. Ohne Ziel
  /// ist das 1 von 1.
  final int progress;

  /// Wie viel für ein Häkchen nötig ist.
  final int required;

  /// Ob der Tag damit als erledigt zählt. Nur dann gibt es Erfahrung,
  /// Gold und eine Streak.
  bool get isComplete => progress >= required;

  final HabitTracker tracker;
}

/// Welche Gewohnheiten laufen und an welchen Tagen sie erledigt wurden.
///
/// Unveränderlich: Jede Änderung gibt einen neuen Tracker zurück.
///
/// Erfahrung und Gold werden **abgeleitet**, nicht mitgezählt. Dieselbe
/// Entscheidung wie bei `TheoryProgress`: Ein versehentliches Häkchen
/// lässt sich damit zurücknehmen, ohne dass ein Zähler auseinanderläuft.
///
/// Seit ADR-0028 hält der Tracker außerdem die **eigenen Gewohnheiten**
/// des Spielers. Sie sind Nutzerzustand und gehören damit hierher — der
/// [HabitCatalog] bleibt reiner Inhalt.
class HabitTracker {
  HabitTracker({
    List<String> activeIds = const <String>[],
    Map<String, Set<Day>> checks = const <String, Set<Day>>{},
    Map<String, Map<Day, int>> progress = const <String, Map<Day, int>>{},
    List<CustomHabit> custom = const <CustomHabit>[],
    Set<Day> frozenDays = const <Day>{},
    Set<Day> openedChests = const <Day>{},
  })  : _activeIds = List<String>.unmodifiable(activeIds),
        _checks = _frozenChecks(checks),
        _progress = _frozenProgress(progress),
        _custom = List<CustomHabit>.unmodifiable(custom),
        _frozenDays = Set<Day>.unmodifiable(frozenDays),
        _openedChests = Set<Day>.unmodifiable(openedChests);

  const HabitTracker.empty()
      : _activeIds = const <String>[],
        _checks = const <String, Set<Day>>{},
        _progress = const <String, Map<Day, int>>{},
        _custom = const <CustomHabit>[],
        _frozenDays = const <Day>{},
        _openedChests = const <Day>{};

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
    // Zuerst die eigenen Gewohnheiten: Ohne sie wäre unten nicht zu
    // entscheiden, ob eine aktive Id ins Leere zeigt.
    final custom = <CustomHabit>[];
    final rawCustom = json['custom'];
    if (rawCustom is List) {
      final seen = <String>{};
      for (final entry in rawCustom) {
        final habit = CustomHabit.fromJson(entry);
        if (habit != null && seen.add(habit.id)) custom.add(habit);
      }
    }
    final customIds = <String>{for (final habit in custom) habit.id};

    bool bekannt(String id) {
      return HabitCatalog.byId(id) != null || customIds.contains(id);
    }

    final ids = <String>[];
    final rawIds = json['activeIds'];
    if (rawIds is List) {
      for (final id in rawIds) {
        if (id is String && bekannt(id)) ids.add(id);
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

    final progress = <String, Map<Day, int>>{};
    final rawProgress = json['progress'];
    if (rawProgress is Map) {
      for (final entry in rawProgress.entries) {
        final habitId = entry.key;
        final days = entry.value;
        if (habitId is! String || days is! Map) continue;

        final parsed = <Day, int>{};
        for (final tag in days.entries) {
          final key = tag.key;
          final value = tag.value;
          if (key is! String || value is! int || value <= 0) continue;
          final day = Day.tryParse(key);
          // Ein Tag, der schon abgehakt ist, hat keinen Teilfortschritt
          // mehr — die Invariante wird beim Laden erzwungen, nicht nur
          // beim Schreiben.
          if (day == null || (checks[habitId]?.contains(day) ?? false)) {
            continue;
          }
          parsed[day] = value;
        }
        if (parsed.isNotEmpty) progress[habitId] = parsed;
      }
    }

    final frozen = <Day>{};
    final rawFrozen = json['frozen'];
    if (rawFrozen is List) {
      for (final entry in rawFrozen) {
        if (entry is! String) continue;
        final day = Day.tryParse(entry);
        // Ein abgehakter Tag braucht keine Deckung. Die Invariante wird
        // beim Laden erzwungen, nicht nur beim Setzen — sonst zählte ein
        // älterer Stand ein Eis, das nichts tut.
        if (day == null) continue;
        if (checks.values.any((days) => days.contains(day))) continue;
        frozen.add(day);
      }
    }

    final truhen = <Day>{};
    final rawChests = json['chests'];
    if (rawChests is List) {
      for (final entry in rawChests) {
        if (entry is! String) continue;
        final day = Day.tryParse(entry);
        if (day != null) truhen.add(day);
      }
    }

    // Die Obergrenze wird beim Laden erzwungen, nicht nur beim Anlegen:
    // Ein Stand aus einer Version mit anderer Grenze darf sie nicht
    // unterlaufen.
    final begrenzt = ids.length > HabitRewards.maxActiveHabits
        ? ids.sublist(0, HabitRewards.maxActiveHabits)
        : ids;

    return HabitTracker(
      activeIds: begrenzt,
      checks: checks,
      progress: progress,
      custom: custom,
      frozenDays: frozen,
      openedChests: truhen,
    );
  }

  final List<String> _activeIds;

  /// Je Gewohnheit die Tage, an denen sie erledigt wurde.
  final Map<String, Set<Day>> _checks;

  /// Je Gewohnheit der angefangene, **noch nicht fertige** Tag.
  ///
  /// Gegenstück zu [_checks] und nie gleichzeitig mit ihm besetzt: Sobald
  /// ein Ziel voll ist, wandert der Tag hinüber und der Zähler
  /// verschwindet. Damit bleibt [_checks] die einzige Wahrheit darüber,
  /// was zählt — Streaks, Erfahrung und Charakterwerte müssen den Zähler
  /// gar nicht kennen.
  final Map<String, Map<Day, int>> _progress;

  /// Die selbst angelegten Gewohnheiten, in der Reihenfolge des Anlegens.
  final List<CustomHabit> _custom;

  /// Die Tage, die mit einem Streak-Eis gedeckt sind.
  ///
  /// Eine **Historie**, kein Bestand — dieselbe Bauform wie die Häkchen
  /// und wie `Loadout.soldIds`. Wie viele Eis noch da sind, wird daraus
  /// gerechnet ([freezesLeft]); ein gespeicherter Bestand könnte von der
  /// Historie abweichen, eine Historie *ist* der Bestand.
  final Set<Day> _frozenDays;

  /// Die Tage, an denen die Tagestruhe geöffnet wurde (ADR-0044).
  ///
  /// Wieder eine **Historie**: Der Inhalt eines Tages steht über
  /// [DailyChest.forDay] fest, Gold und Eis werden daraus gerechnet.
  final Set<Day> _openedChests;

  /// Der Stand als JSON.
  ///
  /// Gespeichert wird nur, was der Nutzer getan hat: welche Gewohnheiten
  /// laufen, an welchen Tagen sie erledigt wurden, was er selbst angelegt
  /// hat und was heute halb fertig ist. Erfahrung, Gold und
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
      if (_progress.isNotEmpty)
        'progress': <String, Object?>{
          for (final entry in _progress.entries)
            entry.key: <String, Object?>{
              for (final day in entry.value.keys.toList()..sort())
                day.toString(): entry.value[day],
            },
        },
      if (_custom.isNotEmpty)
        'custom': <Object?>[for (final habit in _custom) habit.toJson()],
      if (_frozenDays.isNotEmpty)
        'frozen': <Object?>[
          for (final day in _frozenDays.toList()..sort()) day.toString(),
        ],
      if (_openedChests.isNotEmpty)
        'chests': <Object?>[
          for (final day in _openedChests.toList()..sort()) day.toString(),
        ],
    };
  }

  static Map<String, Set<Day>> _frozenChecks(Map<String, Set<Day>> checks) {
    return Map<String, Set<Day>>.unmodifiable(<String, Set<Day>>{
      for (final entry in checks.entries)
        entry.key: Set<Day>.unmodifiable(entry.value),
    });
  }

  static Map<String, Map<Day, int>> _frozenProgress(
    Map<String, Map<Day, int>> progress,
  ) {
    return Map<String, Map<Day, int>>.unmodifiable(<String, Map<Day, int>>{
      for (final entry in progress.entries)
        if (entry.value.isNotEmpty)
          entry.key: Map<Day, int>.unmodifiable(entry.value),
    });
  }

  // --- Welche Gewohnheiten es gibt ---

  /// Die eigenen Gewohnheiten des Spielers.
  List<CustomHabit> get customHabits => _custom;

  /// Löst eine Id auf — erst im Katalog, dann bei den eigenen.
  ///
  /// **Die einzige Stelle, die das tut.** Wer eine Id in etwas Anzeigbares
  /// verwandeln will, fragt hier; sonst driften Katalog und Spielstand
  /// auseinander, und genau das war der Fall aus `gotchas.md`, bei dem ein
  /// Platz belegt war und im Kampf nichts ankam.
  Habit? definitionFor(String habitId) {
    final template = HabitCatalog.byId(habitId);
    if (template != null) return template;
    for (final habit in _custom) {
      if (habit.id == habitId) return habit;
    }
    return null;
  }

  /// Wie viele eigene Gewohnheiten es schon gibt.
  int get customCount => _custom.length;

  /// Ob bei [slots] verfügbaren Plätzen noch eine dazu darf.
  bool canAddCustom(int slots) => _custom.length < slots;

  /// Legt eine eigene Gewohnheit an.
  ///
  /// Gibt unverändert zurück, wenn kein Platz frei ist oder die Id schon
  /// vergeben wäre — die Oberfläche fragt vorher mit [canAddCustom].
  HabitTracker addCustom(CustomHabit habit, {required int slots}) {
    if (!canAddCustom(slots)) return this;
    if (definitionFor(habit.id) != null) return this;
    return _copyWith(custom: <CustomHabit>[..._custom, habit]);
  }

  /// Bessert Name, Begründung oder Priorität einer eigenen Gewohnheit nach.
  ///
  /// Wert, Schwierigkeit und Ziel lassen sich bewusst nicht ändern:
  /// Erfahrung und Charakterwerte werden aus der Historie gerechnet, eine
  /// nachträgliche Änderung schriebe also die Vergangenheit um
  /// ([CustomHabit.editable]).
  HabitTracker editCustom(
    String habitId, {
    String? name,
    String? why,
    HabitPriority? priority,
  }) {
    var geaendert = false;
    final next = <CustomHabit>[
      for (final habit in _custom)
        if (habit.id == habitId)
          () {
            geaendert = true;
            return habit.editable(name: name, why: why, priority: priority);
          }()
        else
          habit,
    ];
    return geaendert ? _copyWith(custom: next) : this;
  }

  // --- Welche Gewohnheiten laufen ---

  List<String> get activeIds => _activeIds;

  /// Die laufenden Gewohnheiten in der Reihenfolge, in der sie gewählt
  /// wurden. Unbekannte Ids werden übersprungen.
  List<Habit> get activeHabits {
    final habits = <Habit>[];
    for (final id in _activeIds) {
      final habit = definitionFor(id);
      if (habit != null) habits.add(habit);
    }
    return List<Habit>.unmodifiable(habits);
  }

  /// Dieselbe Liste, nach Priorität sortiert — Wichtiges oben.
  ///
  /// Stabil: Bei gleicher Priorität bleibt die Reihenfolge des Wählens.
  /// Die Priorität ordnet nur, sie bewertet nicht (ADR-0028).
  List<Habit> get activeHabitsByPriority {
    final habits = activeHabits.toList();
    final rang = <String, int>{
      for (var i = 0; i < habits.length; i++) habits[i].id: i,
    };
    habits.sort((a, b) {
      final byPriority = b.priority.rank.compareTo(a.priority.rank);
      if (byPriority != 0) return byPriority;
      return rang[a.id]!.compareTo(rang[b.id]!);
    });
    return List<Habit>.unmodifiable(habits);
  }

  /// Die Tagesliste für [day]: **offene oben, erledigte unten**, in jeder
  /// Hälfte nach [activeHabitsByPriority]. Wer abhakt, sieht die Kachel
  /// nach unten wandern — was oben steht, ist das, was noch zu tun ist.
  List<Habit> dailyListOn(Day day) {
    final sortiert = activeHabitsByPriority;
    return List<Habit>.unmodifiable(<Habit>[
      ...sortiert.where((h) => !isChecked(h.id, day)),
      ...sortiert.where((h) => isChecked(h.id, day)),
    ]);
  }

  bool isActive(String habitId) => _activeIds.contains(habitId);

  bool get isFull => _activeIds.length >= HabitRewards.maxActiveHabits;

  bool canActivate(String habitId) {
    if (isActive(habitId)) return false;
    if (isFull) return false;
    return definitionFor(habitId) != null;
  }

  /// Nimmt eine Gewohnheit in die tägliche Liste auf.
  ///
  /// Gibt unverändert zurück, wenn [canActivate] false ist — die
  /// Oberfläche fragt vorher und schaltet den Knopf ab.
  HabitTracker activate(String habitId) {
    if (!canActivate(habitId)) return this;
    return _copyWith(activeIds: <String>[..._activeIds, habitId]);
  }

  /// Nimmt eine Gewohnheit aus der täglichen Liste.
  ///
  /// Die Historie bleibt erhalten, und damit auch die Charakterwerte:
  /// Was einmal getan wurde, ist getan. Sonst würde jeder Wechsel der
  /// Gewohnheiten den Charakter schwächen und niemand traute sich, etwas
  /// Neues auszuprobieren.
  ///
  /// Aus demselben Grund verschwindet eine eigene Gewohnheit dabei
  /// **nicht**: Sie bleibt in [customHabits] und lässt sich wieder
  /// aufnehmen. Es gibt bewusst kein Löschen — gelöscht wäre ihre Historie
  /// keinem Wert mehr zuzuordnen.
  HabitTracker deactivate(String habitId) {
    if (!isActive(habitId)) return this;
    return _copyWith(
      activeIds: _activeIds.where((id) => id != habitId).toList(),
    );
  }

  // --- Abhaken ---

  bool isChecked(String habitId, Day day) {
    return _checks[habitId]?.contains(day) ?? false;
  }

  int checksFor(String habitId) => _checks[habitId]?.length ?? 0;

  /// Wie weit das Tagesziel an [day] gefüllt ist.
  ///
  /// Ein erledigter Tag meldet die volle Zahl, nicht den Zähler — der ist
  /// beim Abhaken weggefallen.
  int progressOn(String habitId, Day day) {
    if (isChecked(habitId, day)) return requiredFor(habitId);
    return _progress[habitId]?[day] ?? 0;
  }

  /// Wie viel für ein Häkchen nötig ist. 1 für alles ohne Tagesziel.
  int requiredFor(String habitId) {
    return definitionFor(habitId)?.requiredProgress ?? 1;
  }

  /// Wie viele der laufenden Gewohnheiten an [day] erledigt sind.
  int completedOn(Day day) {
    return _activeIds.where((id) => isChecked(id, day)).length;
  }

  bool isDayComplete(Day day) {
    return _activeIds.isNotEmpty && completedOn(day) == _activeIds.length;
  }

  /// Die Tagesform an [day]: die dort abgehakten **laufenden**
  /// Gewohnheiten, gezählt je Charakterwert. Eine gestoppte Gewohnheit
  /// zählt nicht mehr — sonst wäre sie ein Knopf, der nichts mehr kostet.
  DailyForm formOn(Day day) {
    final jeWert = <HabitStat, int>{};
    for (final id in _activeIds) {
      if (!isChecked(id, day)) continue;
      final stat = definitionFor(id)?.stat;
      if (stat == null) continue;
      jeWert[stat] = (jeWert[stat] ?? 0) + 1;
    }
    return DailyForm(checksByStat: jeWert, isInForm: isDayComplete(day));
  }

  /// Füllt ein Tagesziel um einen Schritt auf.
  ///
  /// Für alles ohne Ziel ist das dasselbe wie [check] — ein Schritt, und
  /// der Tag ist voll. Erst der Schritt, der das Ziel erreicht, bringt
  /// Erfahrung, Gold und Streak: Halb getan ist nicht getan, sonst wäre
  /// die Streak nichts mehr wert.
  CheckResult advance(String habitId, Day day) {
    if (!isActive(habitId)) {
      throw StateError('Gewohnheit "$habitId" läuft nicht.');
    }
    if (isChecked(habitId, day)) return check(habitId, day);

    final required = requiredFor(habitId);
    final step = definitionFor(habitId)?.goal?.step ?? 1;
    final erreicht = (_progress[habitId]?[day] ?? 0) + step;
    if (erreicht >= required) return check(habitId, day);

    return CheckResult(
      habitId: habitId,
      day: day,
      streak: currentStreak(habitId, day),
      multiplier: nextMultiplier(habitId, day),
      xpGained: 0,
      goldGained: 0,
      reachedMilestone: null,
      wasAlreadyChecked: false,
      progress: erreicht,
      required: required,
      tracker: _copyWith(progress: _withProgress(habitId, day, erreicht)),
    );
  }

  /// Hakt eine Gewohnheit für [day] ab — unabhängig davon, wie weit ein
  /// Tagesziel gefüllt war.
  ///
  /// Wirft, wenn die Gewohnheit gar nicht läuft — das wäre ein Fehler in
  /// der Oberfläche, kein Nutzerfehler. Ein zweites Häkchen am selben Tag
  /// ist dagegen harmlos und ändert nichts.
  CheckResult check(String habitId, Day day) {
    if (!isActive(habitId)) {
      throw StateError('Gewohnheit "$habitId" läuft nicht.');
    }

    final required = requiredFor(habitId);
    final difficulty =
        definitionFor(habitId)?.difficulty ?? HabitDifficulty.mittel;

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
        progress: required,
        required: required,
        tracker: this,
      );
    }

    final next = _copyWith(
      checks: <String, Set<Day>>{
        ..._checks,
        habitId: <Day>{...?_checks[habitId], day},
      },
      // Der angefangene Tag ist erledigt, sein Zähler damit erledigt.
      progress: _withoutProgress(habitId, day),
      // Ein Tag, an dem etwas steht, braucht keine Deckung — das Eis
      // kommt zurück. Im Spiel kann der Fall nicht eintreten (gedeckt
      // wird nur die Vergangenheit, abgehakt nur heute); die Invariante
      // steht hier trotzdem, weil sie sonst nur in der Oberfläche stünde.
      frozenDays: _frozenDays.contains(day)
          ? (<Day>{..._frozenDays}..remove(day))
          : null,
    );

    final streak = next.streakEndingAt(habitId, day);
    final before = streak - 1;

    return CheckResult(
      habitId: habitId,
      day: day,
      streak: streak,
      multiplier: HabitRewards.multiplierFor(streak),
      xpGained: HabitRewards.xpFor(streak, difficulty),
      goldGained: HabitRewards.goldFor(streak),
      reachedMilestone: _milestoneCrossedBy(before, streak),
      wasAlreadyChecked: false,
      progress: required,
      required: required,
      tracker: next,
    );
  }

  /// Nimmt ein Häkchen zurück. Erfahrung und Gold sind abgeleitet und
  /// verschwinden dadurch von allein.
  ///
  /// Der Teilfortschritt geht mit: Wer zurücknimmt, fängt den Tag neu an.
  /// „3 von 5" stehen zu lassen wäre ein halber Widerruf.
  HabitTracker uncheck(String habitId, Day day) {
    final hatteFortschritt = (_progress[habitId]?[day] ?? 0) > 0;
    if (!isChecked(habitId, day)) {
      if (!hatteFortschritt) return this;
      return _copyWith(progress: _withoutProgress(habitId, day));
    }

    final remaining = <Day>{...?_checks[habitId]}..remove(day);
    final next = <String, Set<Day>>{..._checks};
    if (remaining.isEmpty) {
      next.remove(habitId);
    } else {
      next[habitId] = remaining;
    }
    return _copyWith(checks: next, progress: _withoutProgress(habitId, day));
  }

  /// Der Zähler mit [value] an [day] — und ohne alles, was älter ist.
  ///
  /// **Teilfortschritt wandert nicht in den nächsten Tag.** Wer gestern
  /// drei von fünf Gläsern getrunken hat, fängt heute bei null an; sonst
  /// summierte sich eine Woche halber Tage zu einem geschenkten Häkchen.
  Map<String, Map<Day, int>> _withProgress(String habitId, Day day, int value) {
    return <String, Map<Day, int>>{
      ..._progress,
      habitId: <Day, int>{
        for (final entry
            in _progress[habitId]?.entries ?? const <MapEntry<Day, int>>[])
          if (entry.key > day) entry.key: entry.value,
        day: value,
      },
    };
  }

  Map<String, Map<Day, int>> _withoutProgress(String habitId, Day day) {
    final tage = _progress[habitId];
    if (tage == null || !tage.containsKey(day)) return _progress;

    final next = <String, Map<Day, int>>{..._progress};
    final remaining = <Day, int>{...tage}..remove(day);
    if (remaining.isEmpty) {
      next.remove(habitId);
    } else {
      next[habitId] = remaining;
    }
    return next;
  }

  /// Eine Kopie mit einzelnen ausgetauschten Feldern.
  ///
  /// Ersetzt das frühere Bauen per Konstruktor: Ein Feld, das nur an einer
  /// Stelle vergessen wird, ist der Fallstrick aus `gotchas.md` — und
  /// `copyWith` kann keines vergessen.
  HabitTracker _copyWith({
    List<String>? activeIds,
    Map<String, Set<Day>>? checks,
    Map<String, Map<Day, int>>? progress,
    List<CustomHabit>? custom,
    Set<Day>? frozenDays,
    Set<Day>? openedChests,
  }) {
    return HabitTracker(
      activeIds: activeIds ?? _activeIds,
      checks: checks ?? _checks,
      progress: progress ?? _progress,
      custom: custom ?? _custom,
      frozenDays: frozenDays ?? _frozenDays,
      openedChests: openedChests ?? _openedChests,
    );
  }

  static StreakMilestone? _milestoneCrossedBy(int before, int after) {
    for (final milestone in HabitRewards.streakMilestones) {
      if (before < milestone.days && after >= milestone.days) return milestone;
    }
    return null;
  }

  // --- Streaks ---

  /// Länge der ununterbrochenen Kette, die an [day] endet. 0, wenn an
  /// [day] weder abgehakt noch ein Streak-Eis gelegt wurde.
  ///
  /// **Ein gedeckter Tag trägt die Kette, verlängert sie aber nicht**
  /// ([StreakFreeze]). Eine Kette über dreißig Kalendertage mit einem Eis
  /// darin ist neunundzwanzig lang — das Eis bewahrt, was da war, und
  /// schenkt nichts dazu.
  int streakEndingAt(String habitId, Day day) {
    final days = _checks[habitId];
    if (days == null || days.isEmpty) return 0;

    var streak = 0;
    var cursor = day;
    while (true) {
      if (days.contains(cursor)) {
        streak++;
      } else if (!_frozenDays.contains(cursor)) {
        break;
      }
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

  /// Ob die Kette von [previous] nach [day] durchläuft.
  ///
  /// Entweder folgen die Tage direkt aufeinander, oder jeder Tag
  /// dazwischen ist mit einem Streak-Eis gedeckt. **Die einzige Stelle,
  /// die das entscheidet** — [streakEndingAt], [longestStreak] und
  /// [totalXp] fragen alle hier. Stünde die Regel dreimal da, zeigte die
  /// Kachel irgendwann eine andere Kette an, als die Erfahrung unterstellt.
  bool _continues(Day previous, Day day) {
    final gap = previous.daysUntil(day);
    if (gap == 1) return true;
    if (gap < 1) return false;

    var cursor = previous.next;
    while (cursor < day) {
      if (!_frozenDays.contains(cursor)) return false;
      cursor = cursor.next;
    }
    return true;
  }

  // --- Tagestruhe (ADR-0044) ---

  /// Die Tage, an denen die Truhe geöffnet wurde.
  Set<Day> get openedChests => _openedChests;

  bool hasOpenedChest(Day day) => _openedChests.contains(day);

  /// Ob sich die Truhe von [day] öffnen lässt: jede laufende Gewohnheit
  /// erledigt, und noch nicht geöffnet. Nach welchem Tag gefragt wird,
  /// entscheidet der Aufrufer — die Oberfläche fragt nur nach heute.
  bool canOpenChest(Day day) => isDayComplete(day) && !hasOpenedChest(day);

  /// Öffnet die Truhe von [day]. Ohne [canOpenChest] unverändert und ohne
  /// Inhalt.
  ({HabitTracker tracker, ChestContent? content}) openChest(Day day) {
    if (!canOpenChest(day)) return (tracker: this, content: null);
    return (
      tracker: _copyWith(openedChests: <Day>{..._openedChests, day}),
      content: DailyChest.forDay(day),
    );
  }

  /// Gold aus allen geöffneten Truhen.
  int get chestGold => _openedChests.fold(
        0,
        (sum, day) => sum + DailyChest.forDay(day).gold,
      );

  /// Streak-Eis aus allen geöffneten Truhen.
  int get chestFreezes => _openedChests.fold(
        0,
        (sum, day) => sum + DailyChest.forDay(day).freezes,
      );

  // --- Streak-Eis (Issue #46) ---

  /// Die Tage, die mit einem Streak-Eis gedeckt sind.
  Set<Day> get frozenDays => _frozenDays;

  bool isFrozen(Day day) => _frozenDays.contains(day);

  /// Wie viele Eis schon verbraucht sind.
  int get usedFreezes => _frozenDays.length;

  /// Wie viele noch da sind. Gerechnet, nicht gespeichert.
  int get freezesLeft =>
      StreakFreeze.remaining(usedFreezes, earned: chestFreezes);

  /// Ob sich [day] decken lässt.
  ///
  /// Nur vergangene Tage, an denen nichts steht: Heute ist noch nicht
  /// vorbei, und ein Tag mit Häkchen braucht keine Deckung. Dass der Tag
  /// tatsächlich eine Kette rettet, prüft die Oberfläche — das Modell
  /// verbietet es nicht, ein Eis zu verschwenden, es zeigt nur nirgends
  /// einen Knopf dafür.
  bool canFreeze(Day day, {required Day today}) {
    if (freezesLeft <= 0) return false;
    if (_frozenDays.contains(day)) return false;
    if (!(day < today)) return false;
    return checksOn(day) == 0;
  }

  /// Legt ein Streak-Eis auf [day].
  ///
  /// Gibt unverändert zurück, wenn [canFreeze] false ist — die
  /// Oberfläche fragt vorher und zeigt den Knopf sonst gar nicht.
  HabitTracker freeze(Day day, {required Day today}) {
    if (!canFreeze(day, today: today)) return this;
    return _copyWith(frozenDays: <Day>{..._frozenDays, day});
  }

  /// Der Tag, den ein Streak-Eis gerade noch retten kann — oder null.
  ///
  /// **Immer nur gestern.** Wer heute merkt, dass gestern nichts steht,
  /// soll reagieren können; wer nach zwei Wochen zurückkommt, soll seine
  /// Kette nicht rückwirkend zusammenkaufen. Das Eis verzeiht einen
  /// Aussetzer, es ersetzt kein Aufhören.
  ///
  /// Gibt nur dann einen Tag zurück, wenn dort auch etwas zu retten ist:
  /// Vorgestern muss eine Kette enden. Bei zwei Fehltagen hintereinander
  /// ist sie ohnehin gerissen, und ein Eis dort wäre verschenkt.
  Day? rescuableDay(Day today) {
    final gestern = today.previous;
    if (!canFreeze(gestern, today: today)) return null;

    final vorgestern = gestern.previous;
    for (final habitId in _checks.keys) {
      if (streakEndingAt(habitId, vorgestern) > 0) return gestern;
    }
    return null;
  }

  /// Nimmt ein Eis wieder herunter — der Vorrat wächst dadurch zurück.
  ///
  /// Dasselbe Zugeständnis wie bei [uncheck]: Ein Fehlgriff auf einem
  /// Handy ist ein Fehlgriff, keine Entscheidung.
  HabitTracker unfreeze(Day day) {
    if (!_frozenDays.contains(day)) return this;
    return _copyWith(frozenDays: <Day>{..._frozenDays}..remove(day));
  }

  // --- Was das nächste Häkchen einbringt (Issue #46) ---
  //
  // Die Oberfläche soll den Ertrag **vor** dem Tippen zeigen können und
  // ihn dafür nicht selbst ausrechnen. Was ein Häkchen wert ist, ist eine
  // Regel; Regeln stehen in diesem Package.

  /// Erfahrung für das nächste Häkchen an [today] — oder die, die das
  /// heutige schon gebracht hat.
  int xpForNextCheck(String habitId, Day today) {
    final difficulty =
        definitionFor(habitId)?.difficulty ?? HabitDifficulty.mittel;
    if (isChecked(habitId, today)) {
      return HabitRewards.xpFor(streakEndingAt(habitId, today), difficulty);
    }
    return HabitRewards.xpFor(currentStreak(habitId, today) + 1, difficulty);
  }

  /// Gold für das nächste Häkchen. Ohne Streak-Multiplikator (ADR-0008).
  int goldForNextCheck(String habitId, Day today) {
    return HabitRewards.goldFor(1);
  }

  /// Der nächste Meilenstein dieser Gewohnheit. Null am Deckel.
  StreakMilestone? nextMilestoneFor(String habitId, Day today) {
    return HabitRewards.nextMilestoneAfter(currentStreak(habitId, today));
  }

  /// Wie viele Häkchen noch bis dahin fehlen. 0 am Deckel.
  int checksToNextMilestone(String habitId, Day today) {
    final milestone = nextMilestoneFor(habitId, today);
    if (milestone == null) return 0;
    final fehlt = milestone.days - currentStreak(habitId, today);
    return fehlt < 1 ? 1 : fehlt;
  }

  /// Die längste Kette, die **gerade** läuft — über alle Gewohnheiten.
  ///
  /// Das Gegenstück zu [longestStreak]: Diese Zahl darf fallen, und das
  /// ist ihr Zweck. Der Charakterbildschirm zeigt beide nebeneinander —
  /// „16 Tage am Stück, Bestwert 23" sagt etwas, das keine der beiden
  /// Zahlen allein sagt.
  ///
  /// Rechnet bewusst über [currentStreak] statt über die Tage selbst:
  /// Wann eine Kette als lebend gilt, ist eine Regel, und sie steht dort
  /// schon. Zweimal formuliert wäre sie zweimal zu pflegen.
  int currentBestStreak(Day today) {
    var best = 0;
    for (final habitId in _checks.keys) {
      final streak = currentStreak(habitId, today);
      if (streak > best) best = streak;
    }
    return best;
  }

  /// Die längste Kette, die je gelaufen ist — über alle Gewohnheiten.
  ///
  /// **Bewusst nicht die laufende Streak.** An dieser Zahl hängen die
  /// Titel (ADR-0013), und dort gilt „einmal verdient heißt behalten".
  /// Eine gerissene Kette einen Titel wieder wegnehmen zu lassen wäre
  /// genau die Bestrafung fürs Verpassen, die das Konzept ausschließt
  /// (3.7) und wegen der der Multiplikator bei x2 gedeckelt wurde
  /// (ADR-0008).
  int get longestStreak {
    var best = 0;
    for (final days in _checks.values) {
      final sorted = days.toList()..sort();
      var streak = 0;
      Day? previous;
      for (final day in sorted) {
        streak = previous != null && _continues(previous, day) ? streak + 1 : 1;
        if (streak > best) best = streak;
        previous = day;
      }
    }
    return best;
  }

  // --- Ertrag ---

  /// Gesamte Erfahrung aus allen Häkchen, mit dem Multiplikator, der am
  /// jeweiligen Tag galt — und der Schwierigkeit der Gewohnheit.
  ///
  /// Eine Gewohnheit, die es nicht mehr gibt, zählt als
  /// [HabitDifficulty.mittel]: Ihre Häkchen bleiben so viel wert, wie sie
  /// vor ADR-0028 waren.
  int get totalXp => _xpWhere((_) => true);

  /// Erfahrung aus den Häkchen zwischen [from] und [to], beide
  /// eingeschlossen. **Die Kette zählt über die Grenze hinweg mit**: Das
  /// Montags-Häkchen einer Kette, die am Samstag begann, bringt den
  /// Multiplikator ihres dritten Tags, nicht den des ersten.
  int xpBetween(Day from, Day to) =>
      _xpWhere((day) => day >= from && day <= to);

  /// Die eine Rechnung hinter [totalXp] und [xpBetween]: Die Kette läuft
  /// immer über die ganze Historie, gezählt wird nur, was [counts] will.
  int _xpWhere(bool Function(Day day) counts) {
    var sum = 0;
    for (final entry in _checks.entries) {
      final difficulty =
          definitionFor(entry.key)?.difficulty ?? HabitDifficulty.mittel;
      final sorted = entry.value.toList()..sort();
      var streak = 0;
      Day? previous;
      for (final day in sorted) {
        streak = previous != null && _continues(previous, day) ? streak + 1 : 1;
        if (counts(day)) sum += HabitRewards.xpFor(streak, difficulty);
        previous = day;
      }
    }
    return sum;
  }

  /// Gold aus Häkchen **und** aus geöffneten Tagestruhen.
  int get totalGold => totalChecks * HabitRewards.goldPerCheck + chestGold;

  int get totalChecks {
    return _checks.values.fold(0, (sum, days) => sum + days.length);
  }

  // --- Was die Errungenschaften auslesen (ADR-0033) ---
  //
  // Alles hier ist **abgeleitet und steigt nur**. Das ist keine
  // Nettigkeit, sondern Punkt 3 des ADR: Eine Errungenschaft, deren
  // Bedingung wieder fallen kann, nähme jemandem etwas weg, das er schon
  // hatte. Gezählt wird deshalb nie die laufende Kette, sondern immer,
  // was **irgendwann einmal** stand.

  /// Wie viele Häkchen an [day] gesetzt wurden — über alle Gewohnheiten,
  /// auch über gestoppte und über die, die es nicht mehr gibt.
  int checksOn(Day day) {
    var count = 0;
    for (final days in _checks.values) {
      if (days.contains(day)) count++;
    }
    return count;
  }

  /// Tage, an denen mindestens [checks] Häkchen gesetzt wurden.
  ///
  /// **Bewusst nicht „alle erledigt".** [isDayComplete] vergleicht mit der
  /// *heutigen* Liste laufender Gewohnheiten; welche an einem vergangenen
  /// Tag liefen, steht nirgends. „Alles erledigt" ist damit rückwirkend
  /// nicht bestimmbar — und rückwirkend muss es sein.
  ///
  /// Der Preis steht im ADR: Wer nur drei Gewohnheiten führt, erreicht
  /// die Marke leichter als jemand mit fünf.
  int daysWithAtLeast(int checks) {
    if (checks < 1) return 0;
    return _allDays().where((day) => checksOn(day) >= checks).length;
  }

  /// Die längste ununterbrochene Folge solcher Tage.
  int longestRunWithAtLeast(int checks) {
    if (checks < 1) return 0;

    final days = _allDays().where((day) => checksOn(day) >= checks).toList();
    return _longestRun(days);
  }

  /// Häkchen auf **eigenen** Gewohnheiten mit diesem Grad.
  ///
  /// Vorlagen zählen nicht mit: Sie sind immer [HabitDifficulty.mittel],
  /// und der Grad ist die einzige Stelle, an der jemand sich selbst etwas
  /// abverlangt hat (ADR-0028).
  int checksOnCustomWith(HabitDifficulty difficulty) {
    var count = 0;
    for (final habit in _custom) {
      if (habit.difficulty != difficulty) continue;
      count += _checks[habit.id]?.length ?? 0;
    }
    return count;
  }

  /// Die längste Kette von Tagen mit Häkchen, die **nach** einer Pause
  /// von mindestens [pauseDays] Tagen begonnen hat.
  ///
  /// **Gerechnet über alle Gewohnheiten zusammen, nicht je einzelne.**
  /// Die Frage dahinter ist „hat jemand aufgehört und wieder angefangen",
  /// und aufgehört hat man, wenn gar nichts mehr kommt — nicht, wenn eine
  /// von fünf Ketten reißt.
  ///
  /// Die erste Kette zählt nie mit: Vor ihr liegt keine Pause, sondern
  /// der Anfang.
  int comebackStreakAfterPause(int pauseDays) {
    if (pauseDays < 1) return 0;

    final days = _allDays();
    if (days.length < 2) return 0;

    var best = 0;
    var run = 0;
    var counts = false;

    for (var i = 0; i < days.length; i++) {
      if (i == 0) {
        run = 1;
        counts = false;
        continue;
      }

      final gap = days[i - 1].daysUntil(days[i]);
      if (gap == 1) {
        run++;
      } else {
        // Eine Lücke von `gap` Tagen Abstand bedeutet `gap - 1` Tage, an
        // denen nichts passiert ist.
        run = 1;
        counts = gap - 1 >= pauseDays;
      }

      if (counts && run > best) best = run;
    }

    return best;
  }

  /// Alle Tage mit mindestens einem Häkchen, aufsteigend und ohne
  /// Wiederholung.
  List<Day> _allDays() {
    final days = <Day>{for (final set in _checks.values) ...set}.toList();
    days.sort();
    return days;
  }

  /// Die längste ununterbrochene Folge in einer **sortierten** Liste.
  static int _longestRun(List<Day> days) {
    var best = 0;
    var run = 0;
    Day? previous;
    for (final day in days) {
      run = previous != null && previous.daysUntil(day) == 1 ? run + 1 : 1;
      if (run > best) best = run;
      previous = day;
    }
    return best;
  }

  /// Die Kampfwerte, die sich aus der gesamten Historie ergeben.
  CharacterStats get stats => _statsWhere((_) => true);

  /// Die Kampfwerte, wie sie am Ende von [day] standen.
  CharacterStats statsUpTo(Day day) => _statsWhere((d) => d <= day);

  CharacterStats _statsWhere(bool Function(Day day) counts) {
    final zaehler = <HabitStat, int>{};
    for (final entry in _checks.entries) {
      final habit = definitionFor(entry.key);
      if (habit == null) continue;
      final n = entry.value.where(counts).length;
      zaehler[habit.stat] = (zaehler[habit.stat] ?? 0) + n;
    }
    return CharacterStats(zaehler);
  }

  // --- Wochenrückblick ---

  /// Die Woche (Montag bis Sonntag), in der [day] liegt. [today] trennt,
  /// was schon war, von dem, was noch kommt.
  WeekSummary weekOf(Day day, {required Day today}) {
    final start = day.startOfWeek;
    var ende = start;
    for (var i = 0; i < 6; i++) {
      ende = ende.next;
    }

    final tage = <WeekDay>[];
    var checks = 0;
    var gold = 0;
    var truhen = 0;
    var schatz = false;
    var eis = 0;
    var tag = start;
    for (var i = 0; i < 7; i++) {
      final n = checksOn(tag);
      checks += n;
      gold += n * HabitRewards.goldPerCheck;
      final truhe = hasOpenedChest(tag);
      if (truhe) {
        final inhalt = DailyChest.forDay(tag);
        truhen++;
        gold += inhalt.gold;
        eis += inhalt.freezes;
        if (inhalt.tier == ChestTier.schatz) schatz = true;
      }
      tage.add(
        WeekDay(
          day: tag,
          checks: n,
          state: tag > today
              ? WeekDayState.future
              : truhe
                  ? WeekDayState.chest
                  : n > 0
                      ? WeekDayState.some
                      : WeekDayState.none,
        ),
      );
      tag = tag.next;
    }

    final vorher = statsUpTo(start.previous);
    final nachher = statsUpTo(ende);
    return WeekSummary(
      start: start,
      end: ende,
      days: tage,
      checks: checks,
      xp: xpBetween(start, ende),
      gold: gold,
      chests: truhen,
      foundTreasure: schatz,
      freezesFound: eis,
      gains: <HabitStat, int>{
        for (final stat in HabitStat.values)
          stat: nachher.valueFor(stat) - vorher.valueFor(stat),
      },
      bestStreak: currentBestStreak(ende < today ? ende : today),
    );
  }
}
