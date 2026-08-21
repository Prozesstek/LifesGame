import 'package:combat/combat.dart';

/// Wie ein Move aussieht.
///
/// **Diese Datei ist die Grenze zwischen Regel und Bild.** In
/// `packages/combat` steht, was ein Move *tut* — Schaden, Energie,
/// Statuseffekt. Hier steht ausschließlich, wie er *aussieht*. Beides
/// getrennt zu halten ist der Grund, warum eine neue Animation die
/// Kampfbalance nicht anfassen kann (ADR-0002).
///
/// Ein neuer Move braucht hier einen Eintrag. Fehlt er, greift
/// [MoveAnimation.melee] — sichtbar, aber unauffällig. Ein Move ohne
/// Animation soll nicht unsichtbar sein.
class MoveAnimation {
  const MoveAnimation({
    required this.windUp,
    required this.impact,
    this.kind = MoveVisual.melee,
  });

  /// Wie lange die Ausholbewegung dauert, bevor etwas passiert.
  final double windUp;

  /// Wann der Treffer sitzt, gerechnet ab Beginn des Moves.
  ///
  /// Bei einem Geschoss ist das der Einschlag, nicht der Abschuss — die
  /// Figur zuckt, wenn der Pfeil ankommt.
  final double impact;

  final MoveVisual kind;

  /// Gesamtdauer, nach der die nächste Bewegung anfangen darf.
  double get duration => impact + 0.24;

  bool get isProjectile => kind == MoveVisual.projectile;

  /// Bogenschuss: spannen, schießen, der Pfeil braucht seine Flugzeit.
  static const MoveAnimation bow = MoveAnimation(
    windUp: 0.42,
    impact: 0.78,
    kind: MoveVisual.projectile,
  );

  /// Nahkampf: ausholen und treffen, ohne Flugzeit dazwischen.
  static const MoveAnimation melee = MoveAnimation(windUp: 0.16, impact: 0.28);

  /// Schwerer Schlag: langsamer angesetzt, damit er sich schwer anfühlt.
  static const MoveAnimation heavy = MoveAnimation(windUp: 0.3, impact: 0.46);

  /// Stützen und Sammeln: keine Ausholbewegung, nur Haltung.
  static const MoveAnimation support = MoveAnimation(
    windUp: 0,
    impact: 0.3,
    kind: MoveVisual.support,
  );

  /// Welche Animation zu welchem Move gehört.
  ///
  /// Die Zuordnung läuft über die Id, nicht über den Namen: Namen sind
  /// Anzeigetext und dürfen sich ändern, Ids nicht.
  static MoveAnimation forId(String moveId) {
    return switch (moveId) {
      'basic_attack' => bow,
      'heavy_attack' => heavy,
      'poison_strike' => melee,
      'mend' => support,
      _ => melee,
    };
  }

  static MoveAnimation forMove(Move move) => forId(move.id);
}

/// Die Art der Darstellung — bestimmt, welche Haltung die Figur einnimmt.
enum MoveVisual {
  /// Ausfallschritt zum Gegner.
  melee,

  /// Bogen spannen, Geschoss losschicken.
  projectile,

  /// Geduckte Haltung, kein Angriff.
  support,
}
