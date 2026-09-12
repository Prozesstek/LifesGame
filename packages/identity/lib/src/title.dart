/// Ein Titel, der neben dem Namen steht.
///
/// Titel werden **verdient, nicht gewählt** — das ist der Kern von
/// ADR-0013. Wählbar ist nur, welchen der verdienten man trägt.
///
/// **Was hier seit ADR-0033 nicht mehr steht: die Bedingung.** Bis dahin
/// trug jeder Titel seine eigenen Schwellen (`requiredStreak` und zwei
/// weitere) und `TitleStats` reichte drei Zahlen herein. Beides ist
/// entfallen: Ein Titel ist jetzt die *Belohnung* einer Errungenschaft,
/// und die Bedingung steht dort — an genau einer Stelle.
///
/// Der Grund ist der Fallstrick aus `gotchas.md`. Stünde „30 Tage am
/// Stück" zweimal da, einmal als Titel und einmal als Errungenschaft,
/// wären es zwei Stellen, die dieselbe Frage beantworten — und die eine
/// würde irgendwann von der anderen abweichen.
///
/// Punkt 2 und 4 aus ADR-0014 gelten unverändert weiter: Die Bedingungen
/// hängen an der längsten je gelaufenen Kette, und der gespeicherte Titel
/// ist eine Wahl, die bei jeder Anzeige neu geprüft wird.
class CharacterTitle {
  const CharacterTitle({required this.id, required this.label});

  /// Stabiler Bezeichner für Speicherstände und Tests. Dieselbe Id trägt
  /// die Errungenschaft, die ihn vergibt.
  final String id;

  /// Der Wortlaut, wie ihn der Spieler sieht — „der Beständige".
  final String label;

  @override
  bool operator ==(Object other) {
    return other is CharacterTitle && other.id == id && other.label == label;
  }

  @override
  int get hashCode => Object.hash(id, label);

  @override
  String toString() => 'CharacterTitle($id)';
}
