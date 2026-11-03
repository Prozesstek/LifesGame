import '../home/erster_start.dart';

/// Wo der Mentor gerade spricht — je Bildschirm einer.
enum MentorOrt {
  /// Die Startseite.
  start,

  /// Der Wissensbaum.
  baum,

  /// Der Bildschirm der Fähigkeiten.
  faehigkeiten,

  /// Der Eingang zur Grube.
  eingang,
}

/// Ein Satz des Mentors.
///
/// **Er steht immer oben**, über dem, worum es geht (Issue #183): Man
/// liest von oben nach unten, erst der Satz, dann das Ziel. Bis dahin
/// stand er meist unten, gegenüber seinem Ziel.
class MentorSatz {
  const MentorSatz(this.text);

  final String text;
}

/// Der Mentor, der neue Spieler durch den ersten Start führt (ADR-0079).
///
/// **Wer er ist und was er sagt, steht hier — an einer Stelle.** Die
/// Bildschirme fragen nur, ob er an ihrem Ort etwas zu sagen hat
/// ([satz]); was als Nächstes dran ist, rechnet [ErsterStart] aus dem
/// Stand. Seine Sätze sind die Ausnahme von ADR-0060: Er erklärt, und
/// er verschwindet, sobald der Weg gegangen ist. **Seit ADR-0095 nur
/// noch ein paar Wörter** — wohin es geht, zeigen Licht und gelber
/// Punkt.
abstract final class Mentor {
  /// Sein Bild, 64 × 64 wie alles Gezeichnete (`PixelArt`).
  ///
  /// **Noch ein Platzhalter**: Frederik schickt die Figur. Bis dahin
  /// zeigt der Kasten einen gezeichneten Kopf. Wer das Bild bringt,
  /// legt es nach `assets/Mentor/` und trägt den Pfad hier ein.
  static const String? bild = null;

  /// Was er im Beute-Dialog des ersten Siegs sagt. Den ersten
  /// Gegenstand legt das Spiel von selbst an (`Loadout._add`); der Satz
  /// steht deshalb dort und nicht als eigener Schritt. Danach sagt er nur
  /// noch [gebiete] — also sagt er hier auch, was der Sieg an Plätzen
  /// gebracht hat (ADR-0093).
  static const String ersteBeute =
      'Deine erste Beute! Leg sie an. Und: zwei neue Plätze für '
      'Gewohnheiten.';

  /// **Sein letzter Satz** (Issue #183): Die Gebiete werden am Ende
  /// erklärt, nicht am Anfang — dort stand bis dahin neben jedem
  /// Vorschlag das Zeichen seines Kampfwerts, ohne dass man wusste,
  /// wofür. Er steht, bis eine zweite Gewohnheit angelegt ist.
  static const String gebiete =
      'Gewohnheiten füllen ihr Gebiet, jedes stärkt im Kampf. Leg eine '
      'zweite an!';

  /// Was er bei [schritt] an [ort] sagt — null, wenn er dort schweigt.
  static MentorSatz? satz(Schritt? schritt, MentorOrt ort) {
    return switch ((schritt, ort)) {
      (Schritt.gewohnheit, MentorOrt.start) => const MentorSatz(
        'Willkommen! Was willst du jeden Tag tun?',
      ),
      (Schritt.abhaken, MentorOrt.start) => const MentorSatz(
        'Geschafft? Hak es ab!',
      ),
      (Schritt.ersteSeite, MentorOrt.start) => const MentorSatz(
        'Lies deine erste Seite.',
      ),
      (Schritt.ersteSeite, MentorOrt.baum) => const MentorSatz(
        'Hier geht es los. Eine Seite, ein Punkt.',
      ),
      (Schritt.faehigkeitAnlegen, MentorOrt.start) => const MentorSatz(
        'Neue Fähigkeit! Leg sie an.',
      ),
      (Schritt.faehigkeitAnlegen, MentorOrt.faehigkeiten) => const MentorSatz(
        'Leg sie auf den freien Platz.',
      ),
      (Schritt.grube, MentorOrt.start) => const MentorSatz(
        'Ab in den Dungeon!',
      ),
      (Schritt.grube, MentorOrt.eingang) => const MentorSatz(
        'Besieg den Boss, nimm seine Beute.',
      ),
      (Schritt.gebiete, MentorOrt.start) => const MentorSatz(gebiete),
      _ => null,
    };
  }
}
