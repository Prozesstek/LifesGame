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
/// **Abschliessen, nicht öffnen.** Einen Knoten zu öffnen kostet einen
/// Theoriepunkt; die Fähigkeit gibt es erst, wenn seine Seite auch
/// bestanden ist. ADR-0013 nennt das den einzigen Anreiz im ganzen
/// Spiel, ein Thema wirklich fertig zu machen.
///
/// Seit ADR-0019 ist das eine **Knoten**-Id, keine Zweig-Id mehr — der
/// Baum ist jetzt ein Graph aus einzelnen Seiten. Dass jede Id drüben
/// existiert, prüft `test/abilities_seam_test.dart` in der App.
final class FromTheory extends AbilitySource {
  const FromTheory(this.nodeId);

  final String nodeId;
}

/// Eine Fähigkeit: welcher Move, und woher man ihn bekommt.
///
/// **Was hier bewusst nicht steht: was die Fähigkeit tut.** Schaden,
/// Energie und Wirkung stehen in `package:combat` — hier steht nur, wie
/// man an sie kommt. Verbunden sind beide Seiten über [moveId], und mehr
/// als ein Wort ist diese Verbindung nicht. Genau deshalb prüft ein
/// eigener Test in der App, dass jede Id drüben ankommt (gleiche Naht wie
/// `Lesson.unlocksHabit` ↔ `HabitTemplate.name`).

/// Wie selten — und damit wie stark — eine Fähigkeit ist.
///
/// **Ein Etikett, keine Mechanik.** Die Seltenheit schaltet nichts frei
/// und rechnet nichts aus; woran eine Fähigkeit hängt, steht in
/// [AbilitySource]. Sie ordnet die Auswahl und sagt dem Spieler, was er
/// vor sich hat (ADR-0022).
enum Rarity {
  common('Gewöhnlich'),
  uncommon('Ungewöhnlich'),
  rare('Selten'),
  epic('Episch'),
  legendary('Legendär');

  const Rarity(this.label);

  final String label;
}

class Ability {
  const Ability({
    required this.moveId,
    required this.source,
    required this.requirement,
    this.rarity = Rarity.common,
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

  /// Wie stark diese Fähigkeit ist. Ordnet die Auswahl, schaltet nichts
  /// frei (ADR-0022).
  final Rarity rarity;

  /// Ob diese Fähigkeit frei wählbar ist.
  ///
  /// Waffenfähigkeiten sind es nicht: Sie sitzen in Slot 1 und folgen aus
  /// der Ausrüstung (ADR-0013).
  bool get isChoosable => source is! FromWeapon;

  bool isUnlockedBy(AbilityProgress progress) {
    return switch (source) {
      FromWeapon(:final weaponId) => progress.equippedWeaponId == weaponId,
      FromStreak(:final days) => progress.longestStreak >= days,
      FromTheory(:final nodeId) => progress.passedNodeIds.contains(nodeId),
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
    this.passedNodeIds = const <String>{},
  });

  const AbilityProgress.empty() : this();

  /// Was gerade im Waffenplatz liegt. Null heisst: keine angelegt.
  final String? equippedWeaponId;

  /// Die längste je gelaufene Kette, **nicht** die laufende. Eine
  /// Fähigkeit aus einer Streak-Marke bleibt, auch wenn die Kette reisst
  /// (ADR-0013, `konzept.md` 3.7).
  final int longestStreak;

  /// Theorieknoten, deren Seite bestanden ist.
  ///
  /// **Bestanden, nicht bezahlt.** Ein geöffneter Knoten hat nur einen
  /// Punkt gekostet; gelernt ist er erst, wenn die drei Fragen sitzen
  /// (ADR-0013, ADR-0019).
  final Set<String> passedNodeIds;
}
