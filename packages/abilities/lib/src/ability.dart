/// Woher eine Fähigkeit kommt.
///
/// Drei Quellen, wie ADR-0013 sie festlegt: die getragene Waffe, eine
/// Streak-Marke, ein abgeschlossener Theorieknoten. Als versiegelte
/// Klassen und nicht als Enum mit Zusatzfeldern, weil jede Quelle etwas
/// anderes braucht — dieselbe Bauform wie `MoveEffect` in
/// `package:combat`.
sealed class AbilitySource {
  const AbilitySource();
}

/// Kommt mit einer Waffe. Wird nicht gewählt: Slot 1 trägt, was angelegt
/// ist (ADR-0013).
final class FromWeapon extends AbilitySource {
  const FromWeapon(this.weaponId);

  /// Naht zu `package:gear`. Dass diese Id dort existiert, prüft
  /// `test/abilities_seam_test.dart` in der App — hier ist sie nur ein
  /// Wort.
  final String weaponId;
}

/// Kommt von einer Streak-Marke. Einmal verdient, für immer behalten
/// (ADR-0013) — deshalb hängt die Bedingung an der **längsten je**
/// gelaufenen Kette, nicht an der laufenden.
final class FromStreak extends AbilitySource {
  const FromStreak(this.days);

  final int days;
}

/// Kommt von einem abgeschlossenen Theorieknoten.
///
/// **Knoten gibt es noch nicht** — der Baum wird erst mit ADR-0012 zu
/// einem. Bis dahin steht hier die Id eines Zweigs. Beim Umbau wandert
/// die Bedingung mit, die Fähigkeit bleibt. Gleiche Übergangslösung wie
/// beim Titel „der Wissbegierige" (ADR-0014).
final class FromTheory extends AbilitySource {
  const FromTheory(this.branchId);

  final String branchId;
}

/// Von Anfang an da.
///
/// **Ein Übergang, kein Entwurf.** ADR-0017 ordnet Kraftschlag, Zehrung,
/// Sammeln und Atemzug den Knoten Sport, Ernährung, Schlaf und Erholung
/// zu — die alle vier unter *Körper* liegen und die es als eigene Knoten
/// erst mit ADR-0012 gibt. Sie hier hinter den Zweig „Körper" zu sperren
/// hiesse, vier Fähigkeiten an eine Bedingung zu hängen, die sie
/// gleichzeitig freigäbe: keine Entscheidung, nur eine Wartezeit.
///
/// Solange der Baum kein Baum ist, sind sie offen. Sobald er einer ist,
/// bekommt jede ihren Knoten.
final class FromStart extends AbilitySource {
  const FromStart();
}

/// Eine Fähigkeit: welcher Move, und woher man ihn bekommt.
///
/// **Was hier bewusst nicht steht: was die Fähigkeit tut.** Schaden,
/// Energie und Wirkung stehen in `package:combat` — hier steht nur, wie
/// man an sie kommt. Verbunden sind beide Seiten über [moveId], und mehr
/// als ein Wort ist diese Verbindung nicht. Genau deshalb prüft ein
/// eigener Test in der App, dass jede Id drüben ankommt (gleiche Naht wie
/// `Lesson.unlocksHabit` ↔ `HabitTemplate.name`).
class Ability {
  const Ability({
    required this.moveId,
    required this.source,
    required this.requirement,
  });

  /// Naht zu `package:combat`. Kein Name, keine Zahlen — die stehen dort.
  final String moveId;

  final AbilitySource source;

  /// Die Bedingung im Klartext, für gesperrte Einträge in der Auswahl.
  ///
  /// Steht als Text daneben statt aus der Quelle erzeugt zu werden: Der
  /// Laden und der Titelkatalog machen es genauso, und eine Bedingung
  /// muss lesbar sein, nicht nur korrekt.
  final String requirement;

  /// Ob diese Fähigkeit frei wählbar ist.
  ///
  /// Waffenfähigkeiten sind es nicht: Sie sitzen in Slot 1 und folgen aus
  /// der Ausrüstung (ADR-0013).
  bool get isChoosable => source is! FromWeapon;

  bool isUnlockedBy(AbilityProgress progress) {
    return switch (source) {
      FromStart() => true,
      FromWeapon(:final weaponId) => progress.equippedWeaponId == weaponId,
      FromStreak(:final days) => progress.longestStreak >= days,
      FromTheory(:final branchId) =>
        progress.completedBranchIds.contains(branchId),
    };
  }
}

/// Der Fortschritt, an dem sich entscheidet, was offen ist.
///
/// **Warum eine eigene kleine Klasse und nicht die echten Objekte.**
/// Dieses Package kennt weder `package:gear` noch `package:habits` noch
/// `package:theory` — sonst wäre es kein reines Dart-Package mehr und die
/// Schichtregel aus `CLAUDE.md` wäre nur noch Vereinbarung. Die App reicht
/// drei Angaben herein. Gleiche Bauform wie `TitleStats` (ADR-0014).
class AbilityProgress {
  const AbilityProgress({
    this.equippedWeaponId,
    this.longestStreak = 0,
    this.completedBranchIds = const <String>{},
  });

  const AbilityProgress.empty() : this();

  /// Was gerade im Waffenplatz liegt. Null heisst: keine angelegt.
  final String? equippedWeaponId;

  /// Die längste je gelaufene Kette, **nicht** die laufende. Eine
  /// Fähigkeit aus einer Streak-Marke bleibt, auch wenn die Kette reisst
  /// (ADR-0013, `konzept.md` 3.7).
  final int longestStreak;

  /// Zweige, in denen jede Lektion bestanden ist.
  ///
  /// **Abschliessen, nicht öffnen** — ADR-0013 nennt das den einzigen
  /// Anreiz im ganzen Spiel, ein Thema fertig zu machen.
  final Set<String> completedBranchIds;
}
