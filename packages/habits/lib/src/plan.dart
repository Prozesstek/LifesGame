import 'day.dart';

/// Ab wann welche Wochentage gelten.
///
/// Leere [weekdays] heißen **pausiert**: Die Gewohnheit ist gestoppt, und
/// kein Tag ist fällig.
class PlanChange {
  PlanChange({required this.from, required Set<int> weekdays})
      : weekdays = Set<int>.unmodifiable(weekdays);

  /// Der erste Tag, an dem [weekdays] gelten.
  final Day from;

  /// Wochentage wie bei [Day.weekday]: 1 ist Montag, 7 Sonntag.
  final Set<int> weekdays;

  bool get isPause => weekdays.isEmpty;
}

/// **Der Wochenplan einer Gewohnheit** (ADR-0064): an welchen Wochentagen
/// sie fällig ist — und seit wann.
///
/// **Eine Historie, kein Feld.** Ketten und Erfahrung werden aus der
/// Vergangenheit gerechnet. Stünde hier nur der Plan von heute, schriebe
/// jede Änderung die Vergangenheit um: Ein Tag, der gestern fällig war,
/// wäre es plötzlich nicht mehr, und das Level könnte nachträglich
/// fallen. Deshalb gilt jede Änderung **ab** einem Tag, und was davor
/// lag, bleibt, wie es war.
///
/// Ohne Eintrag ist jeder Tag fällig — so rechnet jeder Stand von vor
/// dem Wochenplan unverändert weiter.
class HabitPlan {
  HabitPlan(List<PlanChange> changes)
      : changes = List<PlanChange>.unmodifiable(
          changes.toList()..sort((a, b) => a.from.compareTo(b.from)),
        );

  const HabitPlan.empty() : changes = const <PlanChange>[];

  /// Jeder Wochentag — der Plan, solange niemand etwas anderes sagt.
  static const Set<int> everyDay = <int>{1, 2, 3, 4, 5, 6, 7};

  /// Ob [weekdays] ein gültiger Plan ist: mindestens ein Tag, nur 1 bis 7.
  static bool isValid(Set<int> weekdays) {
    return weekdays.isNotEmpty && weekdays.every(everyDay.contains);
  }

  /// Aufsteigend nach [PlanChange.from], je Tag höchstens ein Eintrag.
  final List<PlanChange> changes;

  bool get isEmpty => changes.isEmpty;

  /// Der Eintrag, der an [day] gilt — null, wenn noch keiner galt.
  PlanChange? changeOn(Day day) {
    PlanChange? current;
    for (final change in changes) {
      if (change.from > day) break;
      current = change;
    }
    return current;
  }

  /// Ob an [day] schon ein Eintrag galt.
  bool hasEntryBy(Day day) => changeOn(day) != null;

  /// Ob [day] nach Plan fällig ist. Ohne Eintrag: ja.
  bool isPlannedOn(Day day) {
    final change = changeOn(day);
    return change == null || change.weekdays.contains(day.weekday);
  }

  /// Ob die Gewohnheit an [day] pausiert.
  bool isPausedOn(Day day) => changeOn(day)?.isPause ?? false;

  /// Die zuletzt gewählten Wochentage — auch eine Änderung, die erst
  /// morgen gilt, und über eine Pause hinweg. Das ist, was der Spieler
  /// eingestellt hat.
  Set<int> get chosenWeekdays {
    for (final change in changes.reversed) {
      if (!change.isPause) return change.weekdays;
    }
    return everyDay;
  }

  /// Ein neuer Plan, in dem ab [from] die [weekdays] gelten.
  ///
  /// Was ab [from] schon eingetragen war, fällt heraus: Es gibt immer nur
  /// **eine** Zukunft. Ein Eintrag, der nichts ändert, wird nicht
  /// geschrieben.
  HabitPlan withChange(Day from, Set<int> weekdays) {
    final davor = <PlanChange>[
      for (final change in changes)
        if (change.from < from) change,
    ];
    final gilt = davor.isEmpty ? null : davor.last.weekdays;
    final gleich = gilt != null &&
        gilt.length == weekdays.length &&
        gilt.containsAll(weekdays);
    if (gleich) return HabitPlan(davor);
    return HabitPlan(<PlanChange>[
      ...davor,
      PlanChange(from: from, weekdays: weekdays),
    ]);
  }

  /// Derselbe Plan ohne alles, was erst nach [day] gilt.
  HabitPlan withoutChangesAfter(Day day) {
    return HabitPlan(<PlanChange>[
      for (final change in changes)
        if (change.from <= day) change,
    ]);
  }

  List<Object?> toJson() {
    return <Object?>[
      for (final change in changes)
        <String, Object?>{
          'from': change.from.toString(),
          'days': change.weekdays.toList()..sort(),
        },
    ];
  }

  /// Liest einen gespeicherten Plan. Unlesbares wird übersprungen, nie
  /// geworfen — dieselbe Nachsicht wie überall beim Laden.
  static HabitPlan fromJson(Object? json) {
    if (json is! List) return const HabitPlan.empty();

    final jeTag = <Day, PlanChange>{};
    for (final entry in json) {
      if (entry is! Map) continue;
      final from = entry['from'];
      final days = entry['days'];
      if (from is! String || days is! List) continue;
      final tag = Day.tryParse(from);
      if (tag == null) continue;
      final wochentage = <int>{
        for (final d in days)
          if (d is int && everyDay.contains(d)) d,
      };
      // Ein Eintrag, der nur Unlesbares enthielt, wäre eine Pause, die
      // niemand gesetzt hat.
      if (wochentage.isEmpty && days.isNotEmpty) continue;
      jeTag[tag] = PlanChange(from: tag, weekdays: wochentage);
    }
    return HabitPlan(jeTag.values.toList());
  }
}
