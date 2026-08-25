/// Was der Entwicklermodus verschenkt hat.
///
/// **Das ist eine bewusste Ausnahme von ADR-0008 und ADR-0011.** Dort steht,
/// dass Erfahrung, Gold und Charakterwerte *abgeleitet* werden und es keine
/// zweite Wahrheit geben darf. Genau deshalb gibt es keinen Ort, an den ein
/// „+500 XP" schreiben könnte — und genau deshalb steht dieser Zuschlag hier
/// getrennt und nicht in den echten Größen.
///
/// Der Unterschied zu einer zweiten Wahrheit ist die Sichtbarkeit: Die
/// Zuschläge sind ein eigener, benannter Summand. Der Charakterbildschirm
/// zeigt sie als „davon N aus Dev-Modus" aus, und `resetGrants()` setzt sie
/// vollständig zurück. Ein abgeleiteter Wert bleibt damit nachvollziehbar,
/// statt still verfälscht zu sein.
///
/// Sie leben ausschließlich im **Dev-Spielstand** (siehe `save_slot.dart`).
/// Der echte Stand kann sie nicht enthalten.
class DebugGrants {
  const DebugGrants({
    this.bonusXp = 0,
    this.bonusGold = 0,
    this.bonusTheoryPoints = 0,
    this.bonusAbilityPoints = 0,
    this.unlockedAbilityIds = const <String>{},
  });

  const DebugGrants.none() : this();

  /// Erfahrung obendrauf. Das Level ergibt sich weiterhin aus der Kurve —
  /// es gibt keinen Knopf, der eine Stufe direkt setzt, sondern nur einen,
  /// der die fehlende Erfahrung bis dorthin schenkt.
  final int bonusXp;

  /// Gold obendrauf. Deckt auch die Preise geschenkter Ausrüstung ab, damit
  /// „geschenkt" nicht über [Loadout.spentGold] wieder abgezogen wird.
  final int bonusGold;

  /// Theoriepunkte obendrauf, zum Öffnen von Baumknoten (ADR-0019).
  final int bonusTheoryPoints;

  /// Fähigkeitspunkte obendrauf (ADR-0013).
  ///
  /// **Noch ohne Wirkung.** Das Feature ist nicht gebaut; der Wert wird
  /// gespeichert und angezeigt, damit der Knopf beim Nachziehen nicht
  /// nachträglich in den Spielstand eingreifen muss.
  final int bonusAbilityPoints;

  /// Fähigkeiten, die ohne ihre Bedingung als freigeschaltet gelten.
  final Set<String> unlockedAbilityIds;

  bool get isEmpty {
    return bonusXp == 0 &&
        bonusGold == 0 &&
        bonusTheoryPoints == 0 &&
        bonusAbilityPoints == 0 &&
        unlockedAbilityIds.isEmpty;
  }

  bool get isNotEmpty => !isEmpty;

  DebugGrants copyWith({
    int? bonusXp,
    int? bonusGold,
    int? bonusTheoryPoints,
    int? bonusAbilityPoints,
    Set<String>? unlockedAbilityIds,
  }) {
    return DebugGrants(
      bonusXp: bonusXp ?? this.bonusXp,
      bonusGold: bonusGold ?? this.bonusGold,
      bonusTheoryPoints: bonusTheoryPoints ?? this.bonusTheoryPoints,
      bonusAbilityPoints: bonusAbilityPoints ?? this.bonusAbilityPoints,
      unlockedAbilityIds: unlockedAbilityIds ?? this.unlockedAbilityIds,
    );
  }

  /// Addiert etwas dazu. Negative Beträge sind erlaubt — man will beim
  /// Testen auch wieder herunterkommen —, aber keine Größe fällt unter
  /// null: Ein negativer Zuschlag wäre kein Testwerkzeug mehr, sondern eine
  /// Strafe, die es im Spiel nicht gibt.
  DebugGrants plus({
    int xp = 0,
    int gold = 0,
    int theoryPoints = 0,
    int abilityPoints = 0,
  }) {
    int atLeastZero(int value) => value < 0 ? 0 : value;

    return copyWith(
      bonusXp: atLeastZero(bonusXp + xp),
      bonusGold: atLeastZero(bonusGold + gold),
      bonusTheoryPoints: atLeastZero(bonusTheoryPoints + theoryPoints),
      bonusAbilityPoints: atLeastZero(bonusAbilityPoints + abilityPoints),
    );
  }

  DebugGrants withUnlockedAbilities(Iterable<String> ids) {
    return copyWith(
      unlockedAbilityIds: <String>{...unlockedAbilityIds, ...ids},
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'xp': bonusXp,
      'gold': bonusGold,
      'theoryPoints': bonusTheoryPoints,
      'abilityPoints': bonusAbilityPoints,
      'abilities': unlockedAbilityIds.toList()..sort(),
    };
  }

  /// Liest die Zuschläge. Wie überall im Spielstand gilt: Was nicht lesbar
  /// ist, fehlt einfach (ADR-0010).
  factory DebugGrants.fromJson(Map<String, Object?> json) {
    int number(Object? value) => value is int && value > 0 ? value : 0;

    final abilities = json['abilities'];

    return DebugGrants(
      bonusXp: number(json['xp']),
      bonusGold: number(json['gold']),
      bonusTheoryPoints: number(json['theoryPoints']),
      bonusAbilityPoints: number(json['abilityPoints']),
      unlockedAbilityIds: abilities is List
          ? <String>{...abilities.whereType<String>()}
          : const <String>{},
    );
  }
}
