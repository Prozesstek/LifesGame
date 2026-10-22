/// Was das Haustier gerade tut — **aus dem heutigen Tag, nie aus der
/// Vergangenheit**.
///
/// **Es leidet nie** (Frederik, 22.10.2026): Ohne Häkchen wartet es oder
/// schläft, es wird nicht traurig, nicht krank und läuft nicht weg. Ein
/// Tier, das unter einem verpassten Tag leidet, wäre genau der Verlust,
/// den die Skills gerade abgeschafft haben (ADR-0085). Der Tag beginnt für
/// es jeden Morgen neu.
enum HaustierLaune {
  /// Nachts, gleich was abgehakt ist.
  schlaeft('schläft'),

  /// Heute ist etwas fällig, und noch nichts erledigt.
  wartet('wartet'),

  /// Mindestens ein Häkchen heute.
  munter('munter'),

  /// Alles Fällige erledigt — „In Form“.
  spielt('spielt'),

  /// Heute ist nichts fällig: ein Ruhetag (ADR-0064).
  ruht('ruht');

  const HaustierLaune(this.label);

  final String label;

  /// Ab welcher Stunde es schläft, und bis wann.
  static const int schlafAb = 22;
  static const int schlafBis = 6;

  /// Die Laune zu einem Tag: [faellig] Gewohnheiten, davon [erledigt],
  /// um [stunde] Uhr.
  static HaustierLaune aus({
    required int faellig,
    required int erledigt,
    required int stunde,
  }) {
    if (stunde >= schlafAb || stunde < schlafBis) return schlaeft;
    if (faellig <= 0) return ruht;
    if (erledigt >= faellig) return spielt;
    if (erledigt > 0) return munter;
    return wartet;
  }
}
