import 'rewards.dart';

/// Das **Streak-Eis**: ein Tag darf ausfallen, ohne dass die Kette reißt.
///
/// Es ist ein Gegenstand, kein Nachlass. Der Unterschied ist wichtig: Eine
/// Kette, die von selbst einen Fehltag verzeiht, ist keine Kette mehr —
/// dann hieße „30 Tage am Stück" nur noch „irgendwann in den letzten
/// vierzig Tagen". Ein Eis ist knapp, es wird sichtbar verbraucht, und
/// genau deshalb bleibt die Aussage der Streak erhalten.
///
/// **Ein Eis deckt einen Kalendertag, und zwar für alle Gewohnheiten.**
/// Die Rückmeldung aus Issue #46 lautet „ein Tag ausfallen lassen", nicht
/// „eine Gewohnheit ausfallen lassen". Wer krank im Bett liegt, hakt
/// nichts ab — ihm fünf Eis abzunehmen wäre die Strafe, die das Eis
/// gerade verhindern soll.
///
/// **Ein gedeckter Tag zählt nicht mit.** Die Kette läuft über ihn
/// hinweg, wird aber nicht länger: Eine Kette aus dreißig Tagen mit einem
/// Eis besteht aus neunundzwanzig Häkchen. Das Eis schenkt keinen
/// Fortschritt, es bewahrt nur den, der schon da war — Erfahrung, Gold
/// und Charakterwerte hängen weiterhin ausschließlich an echten Häkchen.
abstract final class StreakFreeze {
  /// Wie der Gegenstand im Spiel heißt.
  static const String name = 'Streak-Eis';

  /// Ein Satz, der sagt, was es tut.
  static const String description =
      'Deckt einen verpassten Tag ab. Die Kette läuft weiter, wird aber '
      'nicht länger — Erfahrung gibt es nur für echte Häkchen.';

  /// Wie viele Eis jemand zum Start bekommt.
  ///
  /// **Die Quelle danach ist die Tagestruhe** (ADR-0044, Issue #46): Eine
  /// von gut zwölf Truhen enthält eines ([ChestTier.eis]). Der eine zum
  /// Start bleibt, damit der Gegenstand vorkommt, bevor die erste
  /// Eis-Truhe fällt.
  static const int lifetimeStock = 1;

  /// Wie viele Eis noch übrig sind, wenn [used] schon verbraucht und
  /// [earned] aus Truhen dazugekommen sind.
  ///
  /// Abgeleitet statt gezählt — dieselbe Bauform wie Erfahrung und Gold
  /// (ADR-0008). Gespeichert wird die **Historie** der gedeckten Tage;
  /// der Vorrat ergibt sich daraus. Ein gespeicherter Bestand könnte von
  /// der Historie abweichen, eine Historie *ist* der Bestand.
  static int remaining(int used, {int earned = 0}) {
    final left = lifetimeStock + earned - (used < 0 ? 0 : used);
    return left < 0 ? 0 : left;
  }
}
