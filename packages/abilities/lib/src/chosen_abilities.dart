/// Was der Spieler auf die freien Slots gelegt hat.
///
/// **Nur die freien.** Slot 1 steht nicht hier: Er trägt, was die Waffe
/// mitbringt, und folgt damit aus der Ausrüstung statt aus einer Wahl
/// (ADR-0013). Ihn mitzuspeichern wäre eine zweite Wahrheit über etwas,
/// das sich bereits aus dem Inventar ergibt.
///
/// **Wie viele Slots offen sind, weiss diese Klasse nicht.** Das steht in
/// `package:progression` (`AbilitySlots`), weil es eine Eigenschaft des
/// Levels ist (ADR-0016). Hier steht eine Liste; wie lang sie sein darf,
/// entscheidet die Oberfläche.
///
/// **Ob das Gewählte verdient ist, wird hier ebenfalls nicht geprüft.**
/// Gleiche Trennung wie beim Titel: Der Spielstand hält eine Wahl, die
/// Bedingung gilt genau einmal — beim Zusammenstellen des Kampfes
/// (ADR-0014). Ein von Hand bearbeiteter Spielstand bringt so keine
/// unverdiente Fähigkeit ein, und umgekehrt bleibt eine Wahl erhalten,
/// statt beim Laden still gelöscht zu werden.
class ChosenAbilities {
  ChosenAbilities({List<String> moveIds = const <String>[]})
      : _moveIds = List<String>.unmodifiable(moveIds);

  const ChosenAbilities.empty() : _moveIds = const <String>[];

  final List<String> _moveIds;

  /// Die gewählten Move-Ids, in der Reihenfolge der freien Slots.
  List<String> get moveIds => _moveIds;

  bool get isEmpty => _moveIds.isEmpty;

  int get length => _moveIds.length;

  /// Was auf dem freien Slot [index] liegt. Null, wenn nichts.
  String? at(int index) {
    if (index < 0 || index >= _moveIds.length) return null;
    return _moveIds[index];
  }

  bool contains(String moveId) => _moveIds.contains(moveId);

  /// Legt [moveId] auf den freien Slot [index].
  ///
  /// **Dieselbe Fähigkeit kann nicht zweimal liegen.** Lag sie vorher
  /// woanders, wird sie dort weggenommen — sonst müsste der Spieler erst
  /// aufräumen, bevor er umstellen kann. Zwei gleiche Knöpfe im Kampf
  /// wären ausserdem eine Wahl, die keine ist.
  ChosenAbilities withAt(int index, String moveId) {
    if (index < 0) return this;

    final next = <String?>[..._moveIds];
    while (next.length <= index) {
      next.add(null);
    }

    for (var i = 0; i < next.length; i++) {
      if (i != index && next[i] == moveId) next[i] = null;
    }
    next[index] = moveId;

    return ChosenAbilities(moveIds: _compact(next));
  }

  /// Räumt den freien Slot [index].
  ChosenAbilities clearedAt(int index) {
    if (index < 0 || index >= _moveIds.length) return this;

    final next = <String?>[..._moveIds];
    next[index] = null;

    return ChosenAbilities(moveIds: _compact(next));
  }

  /// Streicht alles, was [isAllowed] nicht durchlässt.
  ///
  /// Für den Weg in den Kampf: Was nicht mehr verdient ist, kommt nicht
  /// mit. Der Spielstand bleibt davon unberührt.
  ChosenAbilities whereAllowed(bool Function(String moveId) isAllowed) {
    return ChosenAbilities(
      moveIds: <String>[
        for (final id in _moveIds)
          if (isAllowed(id)) id,
      ],
    );
  }

  /// Leere Plätze am Ende fallen weg, Lücken in der Mitte bleiben nicht
  /// bestehen: Eine Liste mit Löchern wäre eine zweite Art, „leer" zu
  /// sagen.
  static List<String> _compact(List<String?> raw) {
    return <String>[
      for (final id in raw)
        if (id != null && id.isNotEmpty) id,
    ];
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{'moves': _moveIds};
  }

  /// Liest die Wahl. Was nicht lesbar ist, fehlt einfach — dieselbe
  /// Nachsicht wie im übrigen Spielstand (ADR-0010).
  factory ChosenAbilities.fromJson(Map<String, Object?> json) {
    final raw = json['moves'];
    if (raw is! List) return const ChosenAbilities.empty();

    final seen = <String>{};
    return ChosenAbilities(
      moveIds: <String>[
        for (final entry in raw)
          if (entry is String && entry.isNotEmpty && seen.add(entry)) entry,
      ],
    );
  }
}
