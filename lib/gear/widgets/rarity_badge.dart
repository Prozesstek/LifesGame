import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

/// Die Seltenheit eines Ausrüstungsstücks als kleine Marke.
///
/// **Reine Darstellung.** Was eine Seltenheit bedeutet, steht in
/// `package:gear`; hier steht nur, welche Farbe sie bekommt.
///
/// Die Farben folgen der Gewohnheit aus Rollenspielen — grau, grün,
/// blau —, weil sie dort für dieselbe Reihenfolge stehen und niemand sie
/// lernen muss.
///
/// **Sie sind dunkler, seit die Karten Pergament sind.** Die hellen
/// Töne, die auf einer schwarzen Karte leuchteten, verschwinden auf
/// Beige fast vollständig; die Reihenfolge grau → grün → blau bleibt,
/// nur eine Blende tiefer. Die Marke muss lesbar sein, nicht hübsch:
/// Sie ist seit ADR-0029 die Regel, nach der „teurer heißt besser"
/// überhaupt noch gilt.
class RarityBadge extends StatelessWidget {
  /// Die Marke eines Ausrüstungsstücks.
  RarityBadge({required GearRarity rarity, this.faded = false, super.key})
    : stufe = rarity.index,
      label = rarity.label;

  /// Dieselbe Marke für eine Fähigkeit.
  ///
  /// **Es gibt zwei Aufzählungen mit denselben fünf Stufen** —
  /// `GearRarity` für Ausrüstung, `Rarity` in `package:abilities` für
  /// Fähigkeiten. Die Marke nimmt deshalb Nummer und Wortlaut statt
  /// eines der beiden Typen: Sie müsste sonst beide Packages kennen,
  /// oder es gäbe sie zweimal — und dann hätte dieselbe Stufe
  /// irgendwann zwei Farben.
  const RarityBadge.stufe({
    required this.stufe,
    required this.label,
    this.faded = false,
    super.key,
  });

  /// Die Nummer der Stufe in ihrer Reihe, von gewöhnlich (0) aufwärts.
  final int stufe;

  /// Der Wortlaut — „Selten", „Episch".
  final String label;

  /// Ein bereits gekauftes Stück tritt zurück — die Marke blasst mit,
  /// sonst leuchtet sie über einer grauen Karte.
  final bool faded;

  /// Welche Farbe zu welcher Stufe gehört — **die einzige Tabelle**, in
  /// zwei Spalten: [_farben] für Schrift, [_rahmen] für Ränder.
  ///
  /// Die Reihenfolge grau → grün → blau → lila → gold ist die aus
  /// Rollenspielen; `rarity_test.dart` hält fest, dass beide
  /// Aufzählungen gleich viele Stufen haben und keine zwei sich eine
  /// Farbe teilen.
  ///
  /// **Der Schriftton ist dunkel genug für Pergament.** Ein Name in
  /// dieser Farbe muss sich lesen lassen wie jeder andere Text. Das Gold
  /// ist deshalb ein gebranntes: Ein leuchtendes hätte auf Beige kaum
  /// halb so viel Kontrast wie nötig.
  static const List<Color> _farben = <Color>[
    Color(0xFF5A4E3C),
    Color(0xFF265A31),
    Color(0xFF2A4E86),
    // Lila und Gold, wie in jedem Spiel, das die beiden Stufen kennt --
    // eine Konvention, die man nicht erklaeren muss.
    Color(0xFF6A2E9A),
    Color(0xFF804400),
  ];

  /// Dieselben fünf Stufen, **kräftiger, für den Rahmen eines Stücks**.
  ///
  /// Ein Rand trägt keine Schrift und steht zwischen Pergament und
  /// Leder; er darf leuchten, wo der Schriftton es nicht darf. An ihm
  /// erkennt man die Stufe, bevor man den Namen liest.
  static const List<Color> _rahmen = <Color>[
    Color(0xFF7D7466),
    Color(0xFF2E8B3D),
    Color(0xFF2F6FD0),
    Color(0xFF8E3FD0),
    Color(0xFFD9900A),
  ];

  /// Wie breit der Rahmen eines Stücks ist — überall derselbe.
  static const double rahmenBreite = 2;

  /// Die Farbe zu einer Stufennummer — für alles, was keine
  /// [GearRarity] hat.
  static Color colorOfStufe(int stufe) => _farben[stufe];

  /// Der Schriftton einer Stufe: die Marke und der Name eines Stücks.
  static Color colorOf(GearRarity rarity) => colorOfStufe(rarity.index);

  /// Der Rahmenton zu einer Stufennummer.
  static Color rahmenOfStufe(int stufe) => _rahmen[stufe];

  /// Der Rahmenton einer Stufe: der Rand um ein Stück.
  static Color rahmenOf(GearRarity rarity) => rahmenOfStufe(rarity.index);

  @override
  Widget build(BuildContext context) {
    final farbe = colorOfStufe(stufe);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: farbe.withValues(alpha: faded ? 0.10 : 0.18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: farbe.withValues(alpha: faded ? 0.3 : 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: farbe.withValues(alpha: faded ? 0.6 : 1),
        ),
      ),
    );
  }
}
