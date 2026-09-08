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
class RarityBadge extends StatelessWidget {
  const RarityBadge({required this.rarity, this.faded = false, super.key});

  final GearRarity rarity;

  /// Ein bereits gekauftes Stück tritt zurück — die Marke blasst mit,
  /// sonst leuchtet sie über einer grauen Karte.
  final bool faded;

  /// Welche Farbe zu welcher Stufe gehört.
  static Color colorOf(GearRarity rarity) {
    return switch (rarity) {
      GearRarity.common => const Color(0xFF9AA3B5),
      GearRarity.uncommon => const Color(0xFF5BD98A),
      GearRarity.rare => const Color(0xFF5B8DEF),
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
