import 'skill_area.dart';

/// Der Kampfwert, auf den eine Gewohnheit einzahlt.
///
/// Vier Werte, weil der Kampf genau vier kennt. Jede Gewohnheit speist
/// **einen** davon — nicht zwei, nicht anteilig. Sonst ist beim Abhaken
/// nicht mehr zu sehen, wofür man es tut.
///
/// **Welcher, entscheidet ihr Gebiet** (`SkillArea.kampfwert`,
/// ADR-0088). Bis dahin wählte man ihn selbst, und er hatte einen
/// eigenen Namen neben dem im Kampf (Stärke → Angriff). Jetzt heißt er,
/// was er tut; die Bezeichner bleiben, weil sie im Spielstand stehen.
enum HabitStat {
  /// Aus dem Gebiet Körper.
  staerke('Angriff'),

  /// Aus dem Gebiet Gesellschaft.
  ausdauer('Leben'),

  /// Aus dem Gebiet Wissenschaft.
  disziplin('Abwehr'),

  /// Aus dem Gebiet Geist — füllt in der Grube das Mana.
  klarheit('Mana');

  const HabitStat(this.label);

  /// Name des Werts, wie ihn der Spieler sieht — derselbe wie in der
  /// Grube.
  final String label;

  /// Das Gebiet, aus dem dieser Wert kommt — die Umkehrung von
  /// `SkillArea.kampfwert`, damit eine Anzeige sagen kann, woher er
  /// wächst.
  SkillArea get gebiet {
    return SkillArea.values.firstWhere((area) => area.kampfwert == this);
  }

  /// Liest den gespeicherten Namen. Null bei allem, was nicht passt —
  /// nachsichtig wie alles, was aus einem Spielstand kommt.
  static HabitStat? tryParse(String value) {
    for (final stat in values) {
      if (stat.name == value) return stat;
    }
    return null;
  }
}

/// Wie schwer sich eine Gewohnheit anfühlt — vom Spieler selbst gesetzt.
///
/// **Der Faktor ist bewusst eine schmale Spanne.** Er wirkt nur auf
/// Erfahrung, nicht auf Gold — dieselbe Trennung wie beim Streak. Und er
/// ist fest verdrahtet, nicht frei eingebbar: Wer sich seinen
/// Multiplikator selbst zuspricht, spricht sich am Ende die Levelkurve
/// zu, auf die vier andere Kurven angewiesen sind (ADR-0028).
enum HabitDifficulty {
  leicht('Leicht', 0.8),
  mittel('Mittel', 1.0),
  schwer('Schwer', 1.3);

  const HabitDifficulty(this.label, this.xpFactor);

  final String label;

  /// Faktor auf die Erfahrung eines Häkchens. Multipliziert sich mit dem
  /// Streak-Multiplikator.
  final double xpFactor;

  static HabitDifficulty? tryParse(String value) {
    for (final difficulty in values) {
      if (difficulty.name == value) return difficulty;
    }
    return null;
  }
}

/// Wie wichtig dem Spieler eine Gewohnheit ist.
///
/// **Für das Spiel folgenlos, und das ist der Zweck.** Sie ordnet die
/// Tagesliste und beschriftet eine Kachel — sie ändert weder Erfahrung
/// noch Gold noch Charakterwerte. `custom_habit_test.dart` hält das fest,
/// damit niemand später „nur ein bisschen" daran hängt.
enum HabitPriority {
  niedrig('Nebenbei', 0),
  normal('Normal', 1),
  hoch('Wichtig', 2);

  const HabitPriority(this.label, this.rank);

  final String label;

  /// Höher heißt weiter oben in der Tagesliste.
  final int rank;

  static HabitPriority? tryParse(String value) {
    for (final priority in values) {
      if (priority.name == value) return priority;
    }
    return null;
  }
}

/// Ob ein Tagesziel in einer Menge oder in Minuten gemessen wird.
enum HabitGoalKind {
  menge('Menge'),
  zeit('Zeit');

  const HabitGoalKind(this.label);

  final String label;

  static HabitGoalKind? tryParse(String value) {
    for (final kind in values) {
      if (kind.name == value) return kind;
    }
    return null;
  }
}

/// Ein Tagesziel, das sich über den Tag füllt: „5 Gläser", „10 Minuten".
///
/// [step] ist, was **ein Tippen** auf das Plus hinzufügt. Bei einer Menge
/// ist das eins — ein Glas ist ein Glas. Bei Zeit wären zehn Tipps für
/// zehn Minuten Unfug, deshalb sind es [zeitSchritt] Minuten am Stück.
///
/// Seit ADR-0067 füllt die Oberfläche ein Zeitziel nicht mehr über das
/// Plus, sondern über einen Timer (`HabitTracker.startTimer`); der
/// Schritt gilt nur noch für `advance`.
class HabitGoal {
  const HabitGoal._({
    required this.kind,
    required this.target,
    required this.unit,
    required this.step,
  });

  /// Eine Menge mit eigener Einheit: 5 Gläser, 3 Seiten, 20 Liegestütze.
  factory HabitGoal.menge({required int target, required String unit}) {
    final beschriftung = unit.trim();
    return HabitGoal._(
      kind: HabitGoalKind.menge,
      target: _clampTarget(target),
      unit: beschriftung.isEmpty ? 'Mal' : beschriftung,
      step: 1,
    );
  }

  /// Eine Dauer in Minuten.
  factory HabitGoal.zeit({required int target}) {
    return HabitGoal._(
      kind: HabitGoalKind.zeit,
      target: _clampTarget(target),
      unit: 'Minuten',
      step: zeitSchritt,
    );
  }

  /// Wie viele Minuten ein Tippen bei einem Zeitziel hinzufügt.
  static const int zeitSchritt = 5;

  /// Obergrenze eines Ziels. Nicht als Gängelung, sondern damit die
  /// Kachel eine Zahl anzeigen kann, die auf ein Handy passt.
  static const int maxTarget = 999;

  static int _clampTarget(int target) {
    if (target < 1) return 1;
    return target > maxTarget ? maxTarget : target;
  }

  final HabitGoalKind kind;

  /// Wie viel für ein Häkchen nötig ist.
  final int target;

  /// Das Wort hinter der Zahl: „Gläser", „Minuten".
  final String unit;

  /// Was ein Tippen hinzufügt.
  final int step;

  /// „5 Gläser", „10 Minuten".
  String get label => '$target $unit';

  /// „3 / 5 Gläser".
  String progressLabel(int done) => '$done / $target $unit';

  Map<String, Object?> toJson() {
    return <String, Object?>{'kind': kind.name, 'target': target, 'unit': unit};
  }

  /// Liest ein gespeichertes Ziel. Null bei allem, was nicht passt.
  ///
  /// [step] wird **nicht** gelesen, sondern aus der Art abgeleitet: Er ist
  /// eine Regel, kein Nutzerzustand. Stünde er im Stand, ließe eine
  /// spätere Änderung an [zeitSchritt] alte Ziele zurück.
  static HabitGoal? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = json['kind'];
    final target = json['target'];
    if (kind is! String || target is! int) return null;

    final unit = json['unit'];
    return switch (HabitGoalKind.tryParse(kind)) {
      HabitGoalKind.zeit => HabitGoal.zeit(target: target),
      HabitGoalKind.menge => HabitGoal.menge(
          target: target,
          unit: unit is String ? unit : 'Mal',
        ),
      null => null,
    };
  }
}

/// Was der Spieler täglich abhakt — gleich, ob aus dem Baum oder selbst
/// angelegt.
///
/// Die Tagesliste, die Streak-Rechnung und der Speicher kennen nur diesen
/// Typ. `sealed`, damit die beiden Fälle vollständig bleiben: Kommt eine
/// dritte Herkunft dazu, meldet der Compiler jede Stelle, die sie noch
/// nicht kennt.
sealed class Habit {
  const Habit();

  /// Stabiler Bezeichner für Speicherstände und Tests.
  String get id;

  /// Der Wortlaut, den der Spieler abhakt.
  String get name;

  /// Der Kampfwert, auf den sie einzahlt — **der ihres Gebiets**
  /// (ADR-0088). Gerechnet, nie gespeichert: Kampfwerte, Tagesform und
  /// Wochenrückblick fragen hier, und ein Gebiet zählt damit auch für
  /// jedes Häkchen der Vergangenheit.
  HabitStat get stat;

  /// Das Gebiet, dessen Skill sie wachsen lässt (ADR-0085) und das ihren
  /// Kampfwert bestimmt (ADR-0088).
  ///
  /// Null nur bei einer eigenen Gewohnheit, die vor den Skills angelegt
  /// wurde und noch nicht gefragt ist — ihre Häkchen zählen dann für das
  /// Level, aber für keinen Skill, bis sie eins hat.
  SkillArea? get area;

  /// Ein Satz, warum diese Gewohnheit wirkt.
  String get why;

  /// Wirkt auf die Erfahrung je Häkchen.
  HabitDifficulty get difficulty;

  /// Das Tagesziel, oder null für ein schlichtes Häkchen.
  HabitGoal? get goal;

  /// Für das Spiel folgenlos — ordnet nur die Liste.
  HabitPriority get priority;

  /// Ob der Spieler sie selbst angelegt hat.
  bool get isCustom;

  /// Wie viel für ein Häkchen an einem Tag nötig ist. Ohne Ziel ist das
  /// eins: einmal tippen, fertig.
  int get requiredProgress => goal?.target ?? 1;
}

/// Eine Gewohnheits-Vorlage, wie sie der Skillbaum freischaltet.
///
/// Vorlagen sind **Inhalt**: Sie stehen im Katalog, sind an eine Lektion
/// gebunden und ändern sich nur mit einer neuen Programmversion. Was der
/// Spieler selbst erfindet, ist ein [CustomHabit] und liegt im Spielstand.
///
/// Vorlagen haben bewusst immer [HabitDifficulty.mittel] und keine
/// Menge als Ziel: Damit ist ihr Ertrag exakt derselbe wie vor ADR-0028,
/// und die Levelkurve bleibt unverändert gültig. Eine **Dauer** dürfen
/// sie tragen ([timerMinutes], ADR-0067) — sie ändert, wie abgehakt
/// wird, nicht, was ein Häkchen bringt.
class HabitTemplate extends Habit {
  const HabitTemplate({
    required this.id,
    required this.name,
    required this.area,
    required this.branchId,
    required this.why,
    this.timerMinutes,
  });

  @override
  final String id;

  /// Identisch mit dem `unlocksHabit` der freischaltenden Lektion —
  /// geprüft in `test/habits_theory_test.dart`.
  @override
  final String name;

  @override
  HabitStat get stat => area.kampfwert;

  /// Das Gebiet ihrer Lektion — dieselbe Wurzel, unter der die Lektion
  /// im Baum hängt. Geprüft in `test/skills_test.dart`.
  @override
  final SkillArea area;

  /// Der Theoriezweig, aus dem die Vorlage stammt.
  final String branchId;

  /// Die Lektion hat es erklärt, die Erinnerung gehört auf die Kachel.
  @override
  final String why;

  @override
  HabitDifficulty get difficulty => HabitDifficulty.mittel;

  /// Wie viele Minuten der Timer dieser Vorlage läuft — null für alle,
  /// die mit einem Tipp abgehakt werden.
  final int? timerMinutes;

  @override
  HabitGoal? get goal {
    final minuten = timerMinutes;
    return minuten == null ? null : HabitGoal.zeit(target: minuten);
  }

  @override
  HabitPriority get priority => HabitPriority.normal;

  @override
  bool get isCustom => false;
}

/// Eine Gewohnheit, die der Spieler selbst angelegt hat.
///
/// **Nicht änderbar, was eine Zahl erzeugt.** Gebiet, Schwierigkeit und
/// Ziel stehen mit dem Anlegen fest; Name, Begründung und Priorität lassen
/// sich nachbessern ([editable]). Der Grund ist die Ableitung: Erfahrung
/// und Kampfwerte werden aus der Historie *gerechnet*, nicht mitgezählt
/// (ADR-0008). Wer die Schwierigkeit nachträglich hochsetzt, schriebe
/// damit jedes Häkchen der Vergangenheit um.
///
/// **Das Gebiet gehört dazu** (ADR-0085), mit einer Ausnahme: Wer eine
/// Gewohnheit vor den Skills angelegt hat, wählt ihr Gebiet einmal nach
/// ([withArea]). Danach steht es fest — ein Skill darf nur wachsen, sonst
/// nähme ein Wechsel einen Titel wieder weg.
class CustomHabit extends Habit {
  const CustomHabit({
    required this.id,
    required this.name,
    required this.area,
    required this.difficulty,
    this.statOhneGebiet,
    this.goal,
    this.priority = HabitPriority.normal,
    this.why = '',
  }) : assert(
          area != null || statOhneGebiet != null,
          'Ohne Gebiet braucht sie den Wert, den sie früher gewählt hatte.',
        );

  @override
  final String id;

  @override
  final String name;

  /// Der Wert, den sie trug, bevor das Gebiet ihn bestimmte (ADR-0088).
  /// Zählt nur, solange sie kein Gebiet hat — also nur in Ständen von vor
  /// ADR-0085, bis die Startseite einmal gefragt hat.
  final HabitStat? statOhneGebiet;

  @override
  HabitStat get stat => area?.kampfwert ?? statOhneGebiet ?? HabitStat.staerke;

  /// Pflicht beim Anlegen, nicht null in neuen Ständen. `required`, obwohl
  /// es null sein darf: Ein Standardwert hier wäre der Fehler aus
  /// `gotchas.md` — [editable] oder [withArea] verlöre es unbemerkt.
  @override
  final SkillArea? area;

  @override
  final HabitDifficulty difficulty;

  @override
  final HabitGoal? goal;

  @override
  final HabitPriority priority;

  /// Freiwillig. Eine Vorlage bekommt ihre Begründung aus der Lektion,
  /// eine eigene Gewohnheit kennt sie selbst — aufgeschrieben hält sie
  /// länger.
  @override
  final String why;

  @override
  bool get isCustom => true;

  /// Das Präfix, an dem eine eigene Id erkennbar ist.
  static const String idPrefix = 'eigen-';

  /// Die nächste freie Id neben [existing].
  ///
  /// Zählt hoch statt zufällig zu würfeln: Eine Id landet im Spielstand,
  /// und ein Stand, der sich reproduzieren lässt, ist im Test etwas wert.
  /// Vergebene Nummern werden nie wiederverwendet — sonst erbte eine neue
  /// Gewohnheit die Häkchen einer alten.
  static String nextId(Iterable<String> existing) {
    var highest = 0;
    for (final id in existing) {
      if (!id.startsWith(idPrefix)) continue;
      final number = int.tryParse(id.substring(idPrefix.length));
      if (number != null && number > highest) highest = number;
    }
    return '$idPrefix${highest + 1}';
  }

  /// Eine Kopie mit geänderten **folgenlosen** Feldern.
  ///
  /// Gebiet, Schwierigkeit und Ziel fehlen hier mit Absicht — siehe oben.
  CustomHabit editable({String? name, String? why, HabitPriority? priority}) {
    return CustomHabit(
      id: id,
      name: name ?? this.name,
      statOhneGebiet: statOhneGebiet,
      area: area,
      difficulty: difficulty,
      goal: goal,
      priority: priority ?? this.priority,
      why: why ?? this.why,
    );
  }

  /// Eine Kopie mit Gebiet — **nur, solange sie keins hat**. Hat sie
  /// schon eins, bleibt sie, wie sie ist.
  CustomHabit withArea(SkillArea value) {
    if (area != null) return this;
    return CustomHabit(
      id: id,
      name: name,
      statOhneGebiet: statOhneGebiet,
      area: value,
      difficulty: difficulty,
      goal: goal,
      priority: priority,
      why: why,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      // Der Wert, der gerade gilt. Mit Gebiet wird er beim Laden nicht
      // gelesen; er steht da, damit ein älterer Stand der App den
      // Eintrag nicht verwirft.
      'stat': stat.name,
      if (area != null) 'area': area!.name,
      'difficulty': difficulty.name,
      'priority': priority.name,
      'why': why,
      if (goal != null) 'goal': goal!.toJson(),
    };
  }

  /// Liest eine gespeicherte Gewohnheit. Null, wenn Id oder Name fehlen
  /// oder weder Gebiet noch Wert dastehen — ohne sie wäre sie nicht
  /// anzeigbar. Alles Übrige fällt auf einen Standard zurück, statt den
  /// Eintrag zu verwerfen.
  static CustomHabit? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    final stat = json['stat'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.trim().isEmpty) return null;

    // Fehlt in Ständen von vor ADR-0085; die Startseite fragt dann.
    final gebiet = SkillArea.tryParse(json['area']);
    final wert = stat is String ? HabitStat.tryParse(stat) : null;
    if (gebiet == null && wert == null) return null;

    final schwierigkeit = json['difficulty'];
    final prioritaet = json['priority'];
    final begruendung = json['why'];

    return CustomHabit(
      id: id,
      name: name.trim(),
      statOhneGebiet: wert,
      area: gebiet,
      difficulty: schwierigkeit is String
          ? HabitDifficulty.tryParse(schwierigkeit) ?? HabitDifficulty.mittel
          : HabitDifficulty.mittel,
      goal: HabitGoal.fromJson(json['goal']),
      priority: prioritaet is String
          ? HabitPriority.tryParse(prioritaet) ?? HabitPriority.normal
          : HabitPriority.normal,
      why: begruendung is String ? begruendung : '',
    );
  }
}
