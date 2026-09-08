/// Die Art eines Zuges — wofuer man ihn drueckt.
///
/// **Gibt es, damit ein Ausruestungs-Set auf *eine* Art wirken kann statt
/// auf alles.** Ein Set, das jede Faehigkeit gleich verstaerkt, ist nur
/// ein groesserer Bonus; man nimmt das staerkste und ist fertig. Ein Set,
/// das nur Umgebungen billiger macht, lohnt sich dagegen genau dann, wenn
/// die drei Plaetze passend belegt sind — und damit ist es eine
/// Entscheidung im Sinn von ADR-0013.
enum MoveKind {
  /// Richtet direkten Schaden an.
  angriff('Angriff'),

  /// Legt eine Umgebung. Die teuerste Art, und die mit der laengsten
  /// Wirkung.
  umgebung('Umgebung'),

  /// Alles, was den Anwender staerkt statt den Gegner zu treffen:
  /// heilen, schuetzen, reinigen, die Zeit dehnen.
  schutz('Schutz');

  const MoveKind(this.label);

  final String label;
}
