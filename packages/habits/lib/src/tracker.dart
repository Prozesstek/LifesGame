import 'catalog.dart';
import 'character_stats.dart';
import 'daily_chest.dart';
import 'daily_form.dart';
import 'daily_quests.dart';
import 'day.dart';
import 'habit.dart';
import 'plan.dart';
import 'rewards.dart';
import 'stack.dart';
import 'streak_freeze.dart';
import 'streak_rule.dart';
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
    Map<String, String> cues = const <String, String>{},
    Map<Day, Set<String>> claimedQuests = const <Day, Set<String>>{},
    Map<String, HabitPlan> plans = const <String, HabitPlan>{},
    Map<String, String> anchors = const <String, String>{},
    Map<String, String> treats = const <String, String>{},
  })  : _activeIds = List<String>.unmodifiable(activeIds),
        _checks = _frozenChecks(checks),
        _progress = _frozenProgress(progress),
        _custom = List<CustomHabit>.unmodifiable(custom),
        _frozenDays = Set<Day>.unmodifiable(frozenDays),
        _openedChests = Set<Day>.unmodifiable(openedChests),
        _cues = Map<String, String>.unmodifiable(cues),
        _claimedQuests = Map<Day, Set<String>>.unmodifiable(<Day, Set<String>>{
          for (final entry in claimedQuests.entries)
            entry.key: Set<String>.unmodifiable(entry.value),
        }),
        _plans = Map<String, HabitPlan>.unmodifiable(<String, HabitPlan>{
          for (final entry in plans.entries)
            if (!entry.value.isEmpty) entry.key: entry.value,
        }),
        _anchors = Map<String, String>.unmodifiable(anchors),
        _treats = Map<String, String>.unmodifiable(treats);

  const HabitTracker.empty()
      : _activeIds = const <String>[],
        _checks = const <String, Set<Day>>{},
        _progress = const <String, Map<Day, int>>{},
        _custom = const <CustomHabit>[],
        _frozenDays = const <Day>{},
        _openedChests = const <Day>{},
        _cues = const <String, String>{},
        _claimedQuests = const <Day, Set<String>>{},
        _plans = const <String, HabitPlan>{},
        _anchors = const <String, String>{},
        _treats = const <String, String>{};

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

    final cues = <String, String>{};
    final rawCues = json['cues'];
    if (rawCues is Map) {
      for (final entry in rawCues.entries) {
        final habitId = entry.key;
        final text = entry.value;
        if (habitId is! String || text is! String || !bekannt(habitId)) {
          continue;
        }
        final bereinigt = _cleanCue(text);
        if (bereinigt != null) cues[habitId] = bereinigt;
      }
    }

    final belohnungen = <String, String>{};
    final rawTreats = json['treats'];
    if (rawTreats is Map) {
      for (final entry in rawTreats.entries) {
        final habitId = entry.key;
        final text = entry.value;
        if (habitId is! String || text is! String || !bekannt(habitId)) {
          continue;
        }
        final bereinigt = _cleanCue(text);
        if (bereinigt != null) belohnungen[habitId] = bereinigt;
      }
    }

    final abgeholt = <Day, Set<String>>{};
    final rawQuests = json['quests'];
    if (rawQuests is Map) {
      for (final entry in rawQuests.entries) {
        final key = entry.key;
        final ids = entry.value;
        if (key is! String || ids is! List) continue;
        final day = Day.tryParse(key);
        if (day == null) continue;
        final gueltig = <String>{
          for (final id in ids)
            if (id is String && QuestKind.values.any((k) => k.name == id)) id,
        };
        if (gueltig.isNotEmpty) abgeholt[day] = gueltig;
      }
    }

    // Die Obergrenze wird beim Laden erzwungen, nicht nur beim Anlegen:
    // Ein Stand aus einer Version mit anderer Grenze darf sie nicht
    // unterlaufen.
    final begrenzt = ids.length > HabitRewards.maxActiveHabits
        ? ids.sublist(0, HabitRewards.maxActiveHabits)
        : ids;

    // Kopplungen (ADR-0065): nur zwischen Bekanntem, und nie im Kreis.
    // Ein Auslöser als Satz gewinnt gegen einen Anker — beides zugleich
    // gibt es nicht.
    final anker = <String, String>{};
    final rawAnchors = json['anchors'];
    if (rawAnchors is Map) {
      for (final entry in rawAnchors.entries) {
        final habitId = entry.key;
        final anchorId = entry.value;
        if (habitId is! String || anchorId is! String) continue;
        if (!bekannt(habitId) || !bekannt(anchorId)) continue;
        if (cues.containsKey(habitId)) continue;
        if (HabitStacks.wouldCycle(anker, habitId, anchorId)) continue;
        anker[habitId] = anchorId;
      }
    }

    final plaene = <String, HabitPlan>{};
    final rawPlans = json['plans'];
    if (rawPlans is Map) {
      for (final entry in rawPlans.entries) {
        final habitId = entry.key;
        if (habitId is! String) continue;
        final plan = HabitPlan.fromJson(entry.value);
        if (!plan.isEmpty) plaene[habitId] = plan;
      }
    }
    // Ein Stand von vor dem Wochenplan (ADR-0064) kennt keine Pausen. Was
    // dort gestoppt ist, gälte ohne Eintrag als jeden Tag fällig und
    // jeden Tag verpasst — und machte jeden Ruhetag der anderen zunichte.
    // Es pausiert deshalb seit dem Tag nach seinem letzten Häkchen.
    for (final entry in checks.entries) {
      if (begrenzt.contains(entry.key) || plaene.containsKey(entry.key)) {
        continue;
      }
      final letzter = entry.value.reduce((a, b) => a > b ? a : b);
      plaene[entry.key] = HabitPlan(<PlanChange>[
        PlanChange(from: letzter.next, weekdays: const <int>{}),
      ]);
    }

    return HabitTracker(
      activeIds: begrenzt,
      checks: checks,
      progress: progress,
      custom: custom,
      frozenDays: frozen,
      openedChests: truhen,
      cues: cues,
      claimedQuests: abgeholt,
      plans: plaene,
      anchors: anker,
      treats: belohnungen,
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

  /// Je Gewohnheit der **Auslöser**: wann oder wonach sie drankommt
  /// (ADR-0052) — „nach dem Zähneputzen".
  ///
  /// Eine Zeile Text, keine Uhrzeit und kein Plan. Er gilt für Vorlagen
  /// **und** eigene Gewohnheiten und steht deshalb hier, nicht am
  /// [CustomHabit]: Eine Vorlage gehört dem Katalog, ihr Auslöser dem
  /// Spieler. Er erzeugt keine Zahl und darf sich darum jederzeit
  /// ändern.
  final Map<String, String> _cues;

  /// Je Tag die abgeholten Tagesaufgaben (ADR-0055) — eine **Historie**
  /// wie die geöffneten Truhen. Was eine Aufgabe verlangte, steht über
  /// `DailyQuests.forDay` fest; gespeichert wird nur das Abholen, denn
  /// nur das bringt etwas ein.
  final Map<Day, Set<String>> _claimedQuests;

  /// Je Gewohnheit der **Wochenplan** (ADR-0064): an welchen Wochentagen
  /// sie fällig ist, seit wann — und wann sie pausiert. Eine Historie wie
  /// alles andere hier; ohne Eintrag ist jeder Tag fällig.
  final Map<String, HabitPlan> _plans;

  /// Je Gewohnheit ihr **Anker** (ADR-0065): die Gewohnheit, nach der
  /// sie drankommt. Wie der Auslöser ein Stück Nutzerzustand, das keine
  /// Zahl erzeugt — und sein Gegenstück: Eine Gewohnheit hat einen Satz
  /// **oder** einen Anker, nie beides.
  final Map<String, String> _anchors;

  /// Je Gewohnheit, was es danach gibt (ADR-0066) — eine Zeile Text wie
  /// der Auslöser, und wie er ohne jede Zahl.
  final Map<String, String> _treats;

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
      if (_cues.isNotEmpty) 'cues': <String, Object?>{..._cues},
      if (_claimedQuests.isNotEmpty)
        'quests': <String, Object?>{
          for (final day in _claimedQuests.keys.toList()..sort())
            day.toString(): (_claimedQuests[day]!.toList()..sort()),
        },
      if (_anchors.isNotEmpty) 'anchors': <String, Object?>{..._anchors},
      if (_treats.isNotEmpty) 'treats': <String, Object?>{..._treats},
      if (_plans.isNotEmpty)
        'plans': <String, Object?>{
          for (final entry in _plans.entries) entry.key: entry.value.toJson(),
        },
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
  ///
  /// Nur, was an [day] **fällig** ist (ADR-0064): Eine Gewohnheit mit
  /// Montag, Mittwoch, Freitag steht dienstags nicht da.
  ///
  /// Gekoppelte Gewohnheiten stehen unter ihrem Anker, und ein Stapel
  /// bleibt zusammen ([stackOn], ADR-0065).
  List<Habit> dailyListOn(Day day) {
    return List<Habit>.unmodifiable(<Habit>[
      for (final eintrag in stackOn(day)) eintrag.habit,
    ]);
  }

  /// Die Tagesliste für [day] samt Einrückung — und was **jetzt dran**
  /// ist, weil sein Anker abgehakt wurde. Die Ordnung selbst steht in
  /// [HabitStacks.order].
  List<StackedHabit> stackOn(Day day) {
    final faellig =
        activeHabitsByPriority.where((h) => isDueOn(h.id, day)).toList();
    return HabitStacks.order(
      faellig,
      _anchors,
      isDone: (habit) => isChecked(habit.id, day),
    );
  }

  // --- Koppeln (ADR-0065) ---

  /// Die Gewohnheit, nach der [habitId] drankommt — oder null.
  String? anchorFor(String habitId) => _anchors[habitId];

  /// Ob [habitId] an [anchorId] hängen darf: beide bekannt, nicht
  /// dieselbe, und kein Kreis über die Kette der Anker.
  bool canAnchor(String habitId, String anchorId) {
    if (definitionFor(habitId) == null) return false;
    if (definitionFor(anchorId) == null) return false;
    return !HabitStacks.wouldCycle(_anchors, habitId, anchorId);
  }

  /// Woran sich [habitId] koppeln ließe: die laufenden Gewohnheiten, in
  /// der Reihenfolge der Liste, ohne sie selbst und ohne alles, was
  /// einen Kreis schlösse.
  List<Habit> anchorCandidatesFor(String habitId) {
    return List<Habit>.unmodifiable(<Habit>[
      for (final habit in activeHabitsByPriority)
        if (canAnchor(habitId, habit.id)) habit,
    ]);
  }

  /// Koppelt [habitId] an [anchorId]; null löst die Kopplung.
  ///
  /// **Ein Anker ersetzt den Satz** — und umgekehrt ([setCue]). Beides
  /// beantwortet dieselbe Frage, „wann machst du das?", und zwei
  /// Antworten wären eine zu viel.
  ///
  /// Gibt unverändert zurück, wenn [canAnchor] es verbietet.
  HabitTracker setAnchor(String habitId, String? anchorId) {
    if (anchorId == null) {
      if (!_anchors.containsKey(habitId)) return this;
      return _copyWith(anchors: <String, String>{..._anchors}..remove(habitId));
    }
    if (!canAnchor(habitId, anchorId)) return this;
    if (_anchors[habitId] == anchorId && !_cues.containsKey(habitId)) {
      return this;
    }
    return _copyWith(
      anchors: <String, String>{..._anchors, habitId: anchorId},
      cues: <String, String>{..._cues}..remove(habitId),
    );
  }

  /// Wie lang ein Auslöser höchstens sein darf.
  ///
  /// Er steht auf der Kachel in einer Zeile. Was länger ist, ist kein
  /// Auslöser mehr, sondern ein Plan.
  static const int maxCueLength = 60;

  /// Der Auslöser von [habitId] — oder null, wenn keiner festgelegt ist.
  String? cueFor(String habitId) => _cues[habitId];

  /// Legt den Auslöser von [habitId] fest; leer oder null entfernt ihn.
  ///
  /// Eine unbekannte Id ändert nichts — dieselbe Nachsicht wie beim
  /// Laden. Überlanges wird gekürzt statt abgelehnt.
  HabitTracker setCue(String habitId, String? text) {
    if (definitionFor(habitId) == null) return this;

    final bereinigt = text == null ? null : _cleanCue(text);
    if (bereinigt == _cues[habitId]) return this;

    final next = <String, String>{..._cues};
    if (bereinigt == null) {
      next.remove(habitId);
      return _copyWith(cues: next);
    }
    next[habitId] = bereinigt;
    // Ein Satz ersetzt den Anker (ADR-0065).
    return _copyWith(
      cues: next,
      anchors: _anchors.containsKey(habitId)
          ? (<String, String>{..._anchors}..remove(habitId))
          : null,
    );
  }

  /// Was es **danach** gibt — „Kaffee", „eine Folge" (ADR-0066) — oder
  /// null, wenn nichts festgelegt ist.
  ///
  /// Das Versuchungsbündel aus der zweiten Regel: Was man tun muss, hängt
  /// an etwas, das man tun will. Wie der Auslöser eine Zeile Text, die
  /// **keine Zahl erzeugt** — die App gibt die Belohnung nicht und prüft
  /// sie nicht, sie erinnert nur daran.
  String? treatFor(String habitId) => _treats[habitId];

  /// Legt die Belohnung von [habitId] fest; leer oder null entfernt sie.
  ///
  /// Dieselben Regeln wie [setCue]: eine Zeile, höchstens
  /// [maxCueLength] Zeichen, eine unbekannte Id ändert nichts. Vom
  /// Auslöser unabhängig — sie steht neben Satz **und** Anker.
  HabitTracker setTreat(String habitId, String? text) {
    if (definitionFor(habitId) == null) return this;

    final bereinigt = text == null ? null : _cleanCue(text);
    if (bereinigt == _treats[habitId]) return this;

    final next = <String, String>{..._treats};
    if (bereinigt == null) {
      next.remove(habitId);
    } else {
      next[habitId] = bereinigt;
    }
    return _copyWith(treats: next);
  }

  static String? _cleanCue(String text) {
    final eineZeile = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (eineZeile.isEmpty) return null;
    return eineZeile.length > maxCueLength
        ? eineZeile.substring(0, maxCueLength).trimRight()
        : eineZeile;
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
  ///
  /// [today] trägt den Start in den Wochenplan ein und **beendet eine
  /// Pause**: Ab heute gelten wieder die zuletzt gewählten Wochentage. Die
  /// App reicht ihn immer herein. Ohne ihn geht es nur bei einer
  /// Gewohnheit, die nie gestoppt wurde — eine pausierte ohne Datum
  /// fortzusetzen wirft, statt still weiter zu pausieren.
  HabitTracker activate(String habitId, {Day? today}) {
    if (!canActivate(habitId)) return this;

    final plan = _plans[habitId] ?? const HabitPlan.empty();
    if (today == null) {
      if (plan.changes.any((change) => change.isPause)) {
        throw StateError(
          'Gewohnheit "$habitId" pausiert — activate braucht today.',
        );
      }
      return _copyWith(activeIds: <String>[..._activeIds, habitId]);
    }

    // Erst die Zukunft räumen (eine Pause, die morgen begonnen hätte),
    // dann eintragen, ab wann sie läuft.
    final bisHeute = plan.withoutChangesAfter(today);
    final next = bisHeute.hasEntryBy(today) && !bisHeute.isPausedOn(today)
        ? bisHeute
        : bisHeute.withChange(today, plan.chosenWeekdays);
    return _copyWith(
      activeIds: <String>[..._activeIds, habitId],
      plans: <String, HabitPlan>{..._plans, habitId: next},
    );
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
  ///
  /// **Die Kette bleibt stehen** (ADR-0064): Ab morgen pausiert die
  /// Gewohnheit, und eine Pause trägt die Kette wie ein Ruhetag. Heute
  /// bleibt fällig — wer eine offene Gewohnheit stoppt, hat sie heute
  /// verpasst, und der Tag gilt nicht als erledigt.
  HabitTracker deactivate(String habitId, {required Day today}) {
    if (!isActive(habitId)) return this;
    final plan = _plans[habitId] ?? const HabitPlan.empty();
    return _copyWith(
      activeIds: _activeIds.where((id) => id != habitId).toList(),
      plans: <String, HabitPlan>{
        ..._plans,
        habitId: plan.withChange(today.next, const <int>{}),
      },
    );
  }

  // --- Wochenplan (ADR-0064) ---

  /// Ob [habitId] an [day] nach ihrem Plan fällig ist. Ohne Plan: jeden
  /// Tag. **Die einzige Stelle, die das beantwortet** — Tagesliste, Truhe,
  /// Tagesform, Aufgaben und Ketten fragen alle hier.
  bool isDueOn(String habitId, Day day) {
    return _plans[habitId]?.isPlannedOn(day) ?? true;
  }

  /// Die Wochentage, die der Spieler für [habitId] gewählt hat — auch
  /// wenn die Änderung erst morgen gilt.
  Set<int> weekdaysFor(String habitId) {
    return _plans[habitId]?.chosenWeekdays ?? HabitPlan.everyDay;
  }

  /// Legt die Wochentage von [habitId] fest.
  ///
  /// **Gilt ab morgen.** Gälte es ab heute, nähme man abends den heutigen
  /// Tag aus dem Plan und öffnete die Truhe ohne Häkchen. Nur eine
  /// Gewohnheit, an der noch nie etwas abgehakt wurde, bekommt ihren Plan
  /// sofort — sie hat nichts, was sich damit retten ließe.
  ///
  /// Gibt unverändert zurück, wenn die Gewohnheit nicht läuft oder
  /// [weekdays] kein gültiger Plan ist.
  HabitTracker setWeekdays(
    String habitId,
    Set<int> weekdays, {
    required Day today,
  }) {
    if (!isActive(habitId) || !HabitPlan.isValid(weekdays)) return this;
    final gewaehlt = weekdaysFor(habitId);
    if (gewaehlt.length == weekdays.length && gewaehlt.containsAll(weekdays)) {
      return this;
    }

    final ab = weekdaysChangeFrom(habitId, today);
    final plan = _plans[habitId] ?? const HabitPlan.empty();
    return _copyWith(
      plans: <String, HabitPlan>{
        ..._plans,
        habitId: plan.withChange(ab, weekdays),
      },
    );
  }

  /// Ab welchem Tag eine Änderung der Wochentage an [today] gälte — die
  /// Oberfläche sagt es, bevor jemand bestätigt.
  Day weekdaysChangeFrom(String habitId, Day today) {
    return checksFor(habitId) == 0 ? today : today.next;
  }

  /// Was an [day] zu erledigen ist: die laufenden Gewohnheiten, die fällig
  /// sind — **und** die, die heute gestoppt wurden. Stoppen gilt ab
  /// morgen; sonst wäre es der Knopf, der den Tag fertig macht.
  List<String> dueIdsOn(Day day) {
    return <String>[
      for (final id in <String>{..._activeIds, ..._plans.keys})
        if (isDueOn(id, day) && (isActive(id) || _stoppedAfter(id, day))) id,
    ];
  }

  /// Ob eine nicht laufende Gewohnheit erst **nach** [day] pausiert — an
  /// [day] selbst lief sie dann noch.
  bool _stoppedAfter(String habitId, Day day) {
    final plan = _plans[habitId];
    if (plan == null || plan.isEmpty) return false;
    final letzte = plan.changes.last;
    return letzte.isPause && letzte.from > day;
  }

  Day? _firstCheck(String habitId) {
    final days = _checks[habitId];
    if (days == null || days.isEmpty) return null;
    return days.reduce((a, b) => a < b ? a : b);
  }

  /// Ob [habitId] an [day] **für die Tageskette** fällig war: nach Plan,
  /// und überhaupt schon im Spiel — seit dem ersten Eintrag im Plan oder
  /// dem ersten Häkchen. Davor gab es sie nicht, und was es nicht gab,
  /// kann niemand verpasst haben.
  bool _wasDueOn(String habitId, Day? firstCheck, Day day) {
    if (!isDueOn(habitId, day)) return false;
    if (_plans[habitId]?.hasEntryBy(day) ?? false) return true;
    return firstCheck != null && firstCheck <= day;
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

  /// Ob an [day] alles Fällige erledigt ist ([dueIdsOn]).
  ///
  /// Ein Tag, an dem **nichts** fällig ist, ist nicht erledigt, sondern
  /// ein Ruhetag: keine Truhe, keine Tagesform (ADR-0064). Sonst lohnte
  /// es sich, möglichst viele freie Tage einzuplanen.
  bool isDayComplete(Day day) {
    final due = dueIdsOn(day);
    return due.isNotEmpty && due.every((id) => isChecked(id, day));
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
    _mussAbhakbarSein(habitId, day);
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
  /// Wirft, wenn die Gewohnheit gar nicht läuft oder an [day] nicht
  /// fällig ist — das wäre ein Fehler in der Oberfläche, kein
  /// Nutzerfehler. Ein zweites Häkchen am selben Tag ist dagegen harmlos
  /// und ändert nichts.
  CheckResult check(String habitId, Day day) {
    _mussAbhakbarSein(habitId, day);

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

  /// **Nicht fällig heißt nicht abhakbar** (ADR-0064). Ein freiwilliges
  /// Häkchen am falschen Tag wäre der Weg, eine Kette zu bauen, die an
  /// sechs von sieben Tagen nicht fallen kann.
  void _mussAbhakbarSein(String habitId, Day day) {
    if (!isActive(habitId)) {
      throw StateError('Gewohnheit "$habitId" läuft nicht.');
    }
    if (!isDueOn(habitId, day)) {
      throw StateError('Gewohnheit "$habitId" ist am $day nicht fällig.');
    }
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
    Map<String, String>? cues,
    Map<Day, Set<String>>? claimedQuests,
    Map<String, HabitPlan>? plans,
    Map<String, String>? anchors,
    Map<String, String>? treats,
  }) {
    return HabitTracker(
      activeIds: activeIds ?? _activeIds,
      checks: checks ?? _checks,
      progress: progress ?? _progress,
      custom: custom ?? _custom,
      frozenDays: frozenDays ?? _frozenDays,
      openedChests: openedChests ?? _openedChests,
      cues: cues ?? _cues,
      claimedQuests: claimedQuests ?? _claimedQuests,
      plans: plans ?? _plans,
      anchors: anchors ?? _anchors,
      treats: treats ?? _treats,
    );
  }

  static StreakMilestone? _milestoneCrossedBy(int before, int after) {
    for (final milestone in HabitRewards.streakMilestones) {
      if (before < milestone.days && after >= milestone.days) return milestone;
    }
    return null;
  }

  // --- Streaks ---

  /// Die Kette von [habitId] am Ende von [day] (ADR-0064).
  ///
  /// Gezählt werden **erledigte fällige Tage**, nicht Kalendertage:
  ///
  /// - Ein Tag außerhalb des Wochenplans, eine Pause und ein Streak-Eis
  ///   **tragen** die Kette, verlängern sie aber nicht ([StreakFreeze]).
  /// - Ein verpasster fälliger Tag lässt sie auf die **Stufe darunter**
  ///   fallen, nicht auf null ([HabitRewards.streakAfterMiss]).
  int streakEndingAt(String habitId, Day day) {
    final first = _firstCheck(habitId);
    if (first == null || day < first) return 0;
    return StreakRule.walk(
      from: first,
      to: day,
      stateOf: (cursor) => _habitDay(habitId, cursor),
    );
  }

  /// Was [day] für die Kette von [habitId] bedeutet — **die einzige
  /// Stelle, die das entscheidet**. [streakEndingAt], [longestStreak] und
  /// [totalXp] fragen alle hier.
  StreakDay _habitDay(String habitId, Day day) {
    if (isChecked(habitId, day)) return StreakDay.done;
    if (_frozenDays.contains(day)) return StreakDay.carried;
    return isDueOn(habitId, day) ? StreakDay.missed : StreakDay.carried;
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
  /// Gestern muss eine Gewohnheit fällig gewesen sein, deren Kette
  /// vorgestern noch stand. Wo nichts fällig war, fällt auch nichts.
  Day? rescuableDay(Day today) {
    final gestern = today.previous;
    if (!canFreeze(gestern, today: today)) return null;

    final vorgestern = gestern.previous;
    var etwasFaellig = false;
    for (final habitId in _checks.keys) {
      if (!isDueOn(habitId, gestern)) continue;
      etwasFaellig = true;
      if (streakEndingAt(habitId, vorgestern) > 0) return gestern;
    }
    // Die Tageskette kann auch dann fallen, wenn die fällige Gewohnheit
    // selbst keine Kette hatte — getragen von einer anderen, die gestern
    // frei hatte.
    if (etwasFaellig && dayStreakEndingAt(vorgestern) > 0) return gestern;
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

  // --- Tagesaufgaben (ADR-0055) ---

  /// Ob die Aufgabe [questId] an [day] schon abgeholt ist.
  bool isQuestClaimed(Day day, String questId) =>
      _claimedQuests[day]?.contains(questId) ?? false;

  /// Wie viele Aufgaben je abgeholt wurden — die Quelle ihrer Schlüssel.
  int get claimedQuestCount =>
      _claimedQuests.values.fold(0, (sum, ids) => sum + ids.length);

  /// Holt [quest] an [day] ab — nur wenn sie erledigt und noch nicht
  /// abgeholt ist. Sonst ändert sich nichts.
  ///
  /// Ob sie erledigt ist, prüft der Aufrufer über `DailyQuests.forDay`:
  /// Die Rückfrage, die dort mitzählt, kennt dieses Package nicht.
  HabitTracker claimQuest(Day day, DailyQuest quest) {
    if (!quest.isDone || isQuestClaimed(day, quest.id)) return this;
    return _copyWith(
      claimedQuests: <Day, Set<String>>{
        ..._claimedQuests,
        day: <String>{...?_claimedQuests[day], quest.id},
      },
    );
  }

  // --- Tageskette (ADR-0055) ---

  /// Die Tage mit mindestens einem Häkchen, egal an welcher Gewohnheit.
  Set<Day> get _activeDays => <Day>{
        for (final days in _checks.values) ...days,
      };

  /// Ob an [day] irgendetwas abgehakt ist.
  bool hasCheckOn(Day day) => _checks.values.any((d) => d.contains(day));

  /// Die **Tageskette** am Ende von [day]: Tage mit mindestens einem
  /// Häkchen, egal an welcher Gewohnheit.
  ///
  /// **Warum es sie neben den Ketten je Gewohnheit gibt.** Die eine Zahl,
  /// die man schützen will — die Flamme bei Duolingo. Wer eine von fünf
  /// Gewohnheiten auslässt, hat den Tag trotzdem geschafft, und diese
  /// Kette sagt das. Die Ketten je Gewohnheit bleiben für die
  /// Multiplikatoren.
  ///
  /// Dieselbe Regel wie dort ([StreakRule]): Ein Streak-Eis und ein
  /// **Ruhetag** — ein Tag, an dem nichts fällig war — tragen die Kette,
  /// verlängern sie aber nicht; ein verpasster Tag lässt sie eine Stufe
  /// fallen.
  int dayStreakEndingAt(Day day) {
    final first = _firstActiveDay;
    if (first == null || day < first) return 0;
    final days = _activeDays;
    final ersteHaekchen = _firstChecks;
    return StreakRule.walk(
      from: first,
      to: day,
      stateOf: (cursor) => _dayState(days, ersteHaekchen, cursor),
    );
  }

  /// Je Gewohnheit ihr erstes Häkchen — einmal je Gang durch die Tage
  /// gerechnet, nicht an jedem Tag neu.
  Map<String, Day> get _firstChecks => <String, Day>{
        for (final id in _checks.keys)
          if (_firstCheck(id) case final first?) id: first,
      };

  Day? get _firstActiveDay {
    Day? first;
    for (final days in _checks.values) {
      for (final day in days) {
        if (first == null || day < first) first = day;
      }
    }
    return first;
  }

  StreakDay _dayState(
    Set<Day> activeDays,
    Map<String, Day> firstChecks,
    Day day,
  ) {
    if (activeDays.contains(day)) return StreakDay.done;
    if (_frozenDays.contains(day)) return StreakDay.carried;
    final faellig = <String>{...firstChecks.keys, ..._plans.keys}
        .any((id) => _wasDueOn(id, firstChecks[id], day));
    return faellig ? StreakDay.missed : StreakDay.carried;
  }

  /// Die Tageskette, die heute noch zählt — dieselbe Regel wie bei
  /// [currentStreak]: Sie stirbt erst, wenn der Tag vorbei ist.
  int currentDayStreak(Day today) {
    if (hasCheckOn(today)) return dayStreakEndingAt(today);
    return dayStreakEndingAt(today.previous);
  }

  /// Die längste Tageskette, die je gelaufen ist. Darf nur steigen.
  int get longestDayStreak {
    final first = _firstActiveDay;
    if (first == null) return 0;
    final days = _activeDays;
    final ersteHaekchen = _firstChecks;
    final last = days.reduce((a, b) => a > b ? a : b);
    var best = 0;
    StreakRule.walk(
      from: first,
      to: last,
      stateOf: (cursor) => _dayState(days, ersteHaekchen, cursor),
      onDone: (_, streak) {
        if (streak > best) best = streak;
      },
    );
    return best;
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
    _walkAll((_, __, streak) {
      if (streak > best) best = streak;
    });
    return best;
  }

  /// Geht die Kette jeder Gewohnheit von ihrem ersten bis zu ihrem
  /// letzten Häkchen ab und meldet jeden erledigten Tag.
  void _walkAll(void Function(String habitId, Day day, int streak) onDone) {
    for (final entry in _checks.entries) {
      if (entry.value.isEmpty) continue;
      final habitId = entry.key;
      StreakRule.walk(
        from: entry.value.reduce((a, b) => a < b ? a : b),
        to: entry.value.reduce((a, b) => a > b ? a : b),
        stateOf: (cursor) => _habitDay(habitId, cursor),
        onDone: (day, streak) => onDone(habitId, day, streak),
      );
    }
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
    _walkAll((habitId, day, streak) {
      if (!counts(day)) return;
      final difficulty =
          definitionFor(habitId)?.difficulty ?? HabitDifficulty.mittel;
      sum += HabitRewards.xpFor(streak, difficulty);
    });
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
