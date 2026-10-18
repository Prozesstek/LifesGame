/// **Was am Lagerfeuer wartet** (ADR-0076) — reine Rechnung aus Zahlen,
/// die anderswo stehen.
///
/// Das Feuer erfindet nichts: Rückfrage, Truhe und Tagesaufgaben gab es
/// vorher an drei Stellen. Es sammelt sie, und es sagt, ob es brennt.
/// **Es erzeugt keine Zahl**, und was an ihm liegt, verfällt weiter um
/// Mitternacht.
class AmFeuer {
  const AmFeuer({
    required this.brennt,
    required this.rueckfrageOffen,
    required this.truheWartet,
    required this.aufgabenAbholbar,
  });

  /// Ab wie viel Uhr es brennt, auch wenn noch etwas offen ist.
  static const int abendAb = 18;

  /// Ob es brennt und einlädt — sonst glimmt es nur. **Offen ist es
  /// immer**: Wer morgens alles erledigt, wartet nicht bis zum Abend.
  final bool brennt;

  /// Die Rückfrage des Tages ist da und noch nicht beantwortet.
  final bool rueckfrageOffen;

  /// Der Tag ist geschafft und die Truhe noch zu.
  final bool truheWartet;

  /// Wie viele Tagesaufgaben erledigt und nicht abgeholt sind.
  final int aufgabenAbholbar;

  /// Wie viel wartet — die Zahl am Feuer auf der Startseite. Der
  /// Wochenrückblick und der Vorsatz für morgen zählen nicht mit: Sie
  /// verfallen nicht, und ohne Spur, ob man sie gesehen hat, stünde die
  /// Zahl sonst den ganzen Abend da.
  int get wartet =>
      (rueckfrageOffen ? 1 : 0) + (truheWartet ? 1 : 0) + aufgabenAbholbar;

  /// Ob es um [jetzt] brennt: ab [abendAb] Uhr oder sobald der Tag
  /// geschafft ist.
  static bool brenntUm(DateTime jetzt, {required bool tagGeschafft}) {
    return tagGeschafft || jetzt.hour >= abendAb;
  }
}
