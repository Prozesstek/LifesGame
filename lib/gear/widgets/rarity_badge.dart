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
  const RarityBadge({required this.rarity, this.faded = false, super.key});

  final GearRarity rarity;

  /// Ein bereits gekauftes Stück tritt zurück — die Marke blasst mit,
  /// sonst leuchtet sie über einer grauen Karte.
  final bool faded;

  /// Welche Farbe zu welcher Stufe gehört.
  static Color colorOf(GearRarity rarity) {
    return switch (rarity) {
      GearRarity.common => const Color(0xFF5A4E3C),
      GearRarity.uncommon => const Color(0xFF265A31),
      GearRarity.rare => const Color(0xFF2A4E86),
    };
  }

  @override
  Widget build(BuildContext context) {
    final farbe = colorOf(rarity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: farbe.withValues(alpha: faded ? 0.10 : 0.18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: farbe.withValues(alpha: faded ? 0.3 : 0.7)),
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: farbe.withValues(alpha: faded ? 0.6 : 1),
        ),
      ),
    );
  }
}
