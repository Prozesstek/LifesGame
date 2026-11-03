import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// **Die Bibliothek hinter der Theorie** (03.11.2026, Frederiks Bild):
/// dunkles, warmes Holz, Regale, Kamin und Sessel. Liegt hinter dem Baum
/// und hinter jeder Seite, die gelesen wird.
///
/// Füllt den Bildschirm und wird mittig beschnitten; ein Schleier aus
/// Leder dunkelt sie ab, damit davor Schrift auf Leder lesbar bleibt.
class Bibliothek extends StatelessWidget {
  const Bibliothek({required this.child, this.schleier = 0.45, super.key});

  final Widget child;

  /// Wie stark das Leder darüberliegt, 0 bis 1.
  final double schleier;

  static const String bild = 'assets/UI/Bibliothek.jpg';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.background,
        image: DecorationImage(
          image: const AssetImage(bild),
          fit: BoxFit.cover,
          // Weich skaliert: Das Bild ist gemalt, nicht auf Pixel gesetzt,
          // und liegt ohnehin unter einem Schleier.
          filterQuality: FilterQuality.medium,
          colorFilter: ColorFilter.mode(
            Palette.background.withValues(alpha: schleier),
            BlendMode.srcATop,
          ),
        ),
      ),
      child: child,
    );
  }
}
