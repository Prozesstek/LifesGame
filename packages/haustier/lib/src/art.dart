/// Welches Ei man gewählt hat — und damit, was daraus schlüpft.
///
/// **Drei zur Wahl** (Frederik, 22.10.2026, gegen die Empfehlung eines
/// einzigen Drachen): Wer selbst wählt, hängt mehr daran. Der Preis ist
/// dreimal so viel Grafik.
enum HaustierArt {
  drache('Drache'),
  eule('Eule'),
  katze('Katze');

  const HaustierArt(this.label);

  /// Wie die Art heißt — und der Name des Tiers, bis man ihm einen gibt.
  final String label;

  /// Liest den gespeicherten Namen. Null bei allem, was nicht passt.
  static HaustierArt? tryParse(Object? value) {
    for (final art in values) {
      if (art.name == value) return art;
    }
    return null;
  }
}
