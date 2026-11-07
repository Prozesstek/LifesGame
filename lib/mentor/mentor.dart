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

  /// Der Laden (Rundgang, 07.11.2026).
  laden,

  /// Die Ausrüstung (Rundgang, 07.11.2026).
  ausruestung,
}

/// Ein Satz des Mentors.
///
/// **Er steht immer oben**, über dem, worum es geht (Issue #183): Man
/// liest von oben nach unten, erst der Satz, dann das Ziel. Bis dahin
/// stand er meist unten, gegenüber seinem Ziel.
class MentorSatz {
  const MentorSatz(this.text, {this.weiter = false});

  final String text;

  /// Ob ein Tipp irgendwohin weiterführt — dann zeigt unten rechts im
  /// Kasten ein kleines Zeichen, dass es weitergeht (06.11.2026).
  final bool weiter;
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
  /// Sein Kopf, quadratisch 256 × 256 (`PixelArt`) — im Kreis neben
  /// jedem Satz. **Seit dem 03.11.2026 Frederiks Figur**: ein alter
  /// Zauberer mit Kapuze, Bart und Stab. Fehlt die Datei, zeigt der
  /// Kreis einen gezeichneten Kopf.
  static const String bild = 'assets/Mentor/Mentor_Kopf.png';

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

  /// Was er sagt, während der Talentpunkt groß in der Mitte steht
  /// (06.11.2026).
  static const String talentpunkt =
      'Talentpunkte öffnen Seiten. Jedes Level bringt einen.';

  /// Was er bei [schritt] an [ort] sagt — null, wenn er dort schweigt.
  static MentorSatz? satz(Schritt? schritt, MentorOrt ort) {
    return switch ((schritt, ort)) {
      (Schritt.gewohnheit, MentorOrt.start) => const MentorSatz(
        'Willkommen! Was willst du jeden Tag tun?',
      ),
      (Schritt.abhaken, MentorOrt.start) => const MentorSatz(
        'Geschafft? Hak es ab!',
      ),
      (Schritt.gewohnheitenZeigen, MentorOrt.start) => const MentorSatz(
        'Hier findest du alle Gewohnheiten, auch neue.',
        weiter: true,
      ),
      (Schritt.talentpunkt || Schritt.ersteSeite, MentorOrt.start) =>
        const MentorSatz('Lies deine erste Seite.'),
      (Schritt.talentpunkt, MentorOrt.baum) => const MentorSatz(
        talentpunkt,
        weiter: true,
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
      (Schritt.faehigkeitenZeigen, MentorOrt.start) => const MentorSatz(
        'Hier liegen deine Fähigkeiten.',
        weiter: true,
      ),
      (Schritt.grube, MentorOrt.start) => const MentorSatz(
        'Ab in den Dungeon!',
      ),
      (Schritt.grube, MentorOrt.eingang) => const MentorSatz(
        'Besieg den Boss, nimm seine Beute.',
      ),
      (Schritt.gebiete, MentorOrt.start) => const MentorSatz(gebiete),
      // **Der Rundgang** (07.11.2026): Laden, Ausrüstung, Fähigkeiten.
      (Schritt.goldSammeln, MentorOrt.start) => const MentorSatz(
        'Hak noch etwas ab, dann reicht dein Gold.',
      ),
      (Schritt.laden, MentorOrt.start) => const MentorSatz(
        'Gönn dir was im Laden!',
      ),
      (Schritt.laden, MentorOrt.laden) => const MentorSatz(
        'Das hier ist für dich.',
      ),
      (Schritt.sperren, MentorOrt.start) => const MentorSatz(
        'Sperr dein Lieblingsstück.',
      ),
      (Schritt.sperren, MentorOrt.ausruestung) => const MentorSatz(
        'Tipp ein Stück an und sperr es.',
      ),
      (Schritt.geschenk, MentorOrt.start) => const MentorSatz(
        'Ein Geschenk für dich! Probier es aus.',
      ),
      (Schritt.geschenk, MentorOrt.faehigkeiten) => const MentorSatz(
        'Tausch Funkenstoß gegen dein Geschenk.',
      ),
      _ => null,
    };
  }
}
