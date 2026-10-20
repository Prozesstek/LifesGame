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

/// Wo sein Kasten steht: gegenüber dem, worauf er zeigt, damit er es
/// nicht zudeckt.
enum KastenLage { oben, unten }

/// Ein Satz des Mentors und wo er steht.
class MentorSatz {
  const MentorSatz(this.text, this.lage);

  final String text;
  final KastenLage lage;
}

/// Der Mentor, der neue Spieler durch den ersten Start führt (ADR-0079).
///
/// **Wer er ist und was er sagt, steht hier — an einer Stelle.** Die
/// Bildschirme fragen nur, ob er an ihrem Ort etwas zu sagen hat
/// ([satz]); was als Nächstes dran ist, rechnet [ErsterStart] aus dem
/// Stand. Seine Sätze sind die Ausnahme von ADR-0060: Er erklärt, und
/// er verschwindet, sobald der Weg gegangen ist.
abstract final class Mentor {
  /// Sein Bild, 64 × 64 wie alles Gezeichnete (`PixelArt`).
  ///
  /// **Noch ein Platzhalter**: Frederik schickt die Figur. Bis dahin
  /// zeigt der Kasten einen gezeichneten Kopf. Wer das Bild bringt,
  /// legt es nach `assets/Mentor/` und trägt den Pfad hier ein.
  static const String? bild = null;

  /// Was er im Beute-Dialog des ersten Siegs sagt. Den ersten
  /// Gegenstand legt das Spiel von selbst an (`Loadout._add`); der Satz
  /// steht deshalb dort und nicht als eigener Schritt.
  static const String ersteBeute =
      'Deine erste Beute! Leg sie an — Ausrüstung macht dich stärker.';

  /// Was er bei [schritt] an [ort] sagt — null, wenn er dort schweigt.
  static MentorSatz? satz(Schritt? schritt, MentorOrt ort) {
    return switch ((schritt, ort)) {
      (Schritt.gewohnheit, MentorOrt.start) => const MentorSatz(
        'Willkommen! Ich zeig dir, wie das hier läuft. Fang klein an: '
        'Was willst du jeden Tag tun?',
        KastenLage.unten,
      ),
      (Schritt.abhaken, MentorOrt.start) => const MentorSatz(
        'Hast du es heute getan? Dann hak es ab — jedes Häkchen bringt '
        'Erfahrung und Gold.',
        KastenLage.unten,
      ),
      (Schritt.ersteSeite, MentorOrt.start) => const MentorSatz(
        'Wissen macht dich stärker. Öffne die Theorie und lies deine '
        'erste Seite.',
        KastenLage.unten,
      ),
      (Schritt.ersteSeite, MentorOrt.baum) => const MentorSatz(
        'Eine Seite kostet einen Punkt, und jeder Aufstieg bringt einen '
        'neuen. Fang hier oben an.',
        KastenLage.unten,
      ),
      (Schritt.faehigkeitAnlegen, MentorOrt.start) => const MentorSatz(
        'Deine erste Seite hat dir eine Fähigkeit gebracht. Leg sie an!',
        KastenLage.unten,
      ),
      (Schritt.faehigkeitAnlegen, MentorOrt.faehigkeiten) => const MentorSatz(
        'Tipp auf deine neue Fähigkeit und leg sie auf den freien Platz — '
        'dann nimmst du sie mit in die Grube.',
        KastenLage.unten,
      ),
      (Schritt.grube, MentorOrt.start) => const MentorSatz(
        'Zeit für die Grube. Zeig, was du gelernt hast!',
        KastenLage.unten,
      ),
      (Schritt.grube, MentorOrt.eingang) => const MentorSatz(
        'Unten warten Gegner und ein Wächter. Besiegst du ihn, gehört '
        'seine Beute dir.',
        KastenLage.oben,
      ),
      _ => null,
    };
  }
}
