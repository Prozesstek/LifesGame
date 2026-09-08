import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../ui/palette.dart';
import 'level_card.dart';

/// Die Figur in der Mitte des Startbildschirms, mit ihren Zahlen darunter.
///
/// **Warum Level und Gold hier stehen und nicht oben.** Die fünf Kreise
/// haben keinen Platz mehr für die Statuszahlen, die vorher auf jeder
/// Kachel standen. Sie unter die Figur zu legen macht aus zwei Dingen
/// eines: Das ist dein Charakter, und das sind seine Zahlen. Eine
/// Statuszeile am oberen Rand hätte dieselbe Information getragen, aber
/// als Kopfzeile eines Menüs — und ein Menü ist der Bildschirm gerade
/// nicht mehr.
class CharacterStage extends StatelessWidget {
  const CharacterStage({required this.level, required this.gold, super.key});

  final PlayerLevel level;
  final int gold;

  /// Wo die Figur liegt. Der Dateiname ist bewusst allgemein: Kommt
  /// später eine zweite Pose oder eine mit Rüstung dazu, ist das eine
  /// Datei mehr im selben Ordner und keine Änderung an `pubspec.yaml`.
  static const String assetPath = 'assets/character/hero.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.surfaceRaised, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Expanded(child: Center(child: _Figur())),
          const SizedBox(height: 10),
          LevelCard(level: level, gold: gold),
        ],
      ),
    );
  }
}

/// Das Bild selbst — oder ein Platzhalter, wenn es fehlt.
///
/// **Der Platzhalter ist kein Beiwerk.** Die Bilder dieses Projekts sind
/// schon einmal wieder aus dem Repo geflogen (Sitzung 27.08.), und ein
/// `Image.asset` auf eine fehlende Datei wirft. Ein Startbildschirm, der
/// wegen eines fehlenden Bildes gar nicht erscheint, wäre der teuerste
/// denkbare Preis für eine Zeichnung.
class _Figur extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      CharacterStage.assetPath,
      fit: BoxFit.contain,
      // Pixelgrafik: hart skalieren, nicht weichzeichnen.
      filterQuality: FilterQuality.none,
      errorBuilder: (context, error, stack) => const _KeineFigur(),
    );
  }
}

class _KeineFigur extends StatelessWidget {
  const _KeineFigur();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.person_outline, size: 56, color: Palette.muted),
          SizedBox(height: 8),
          Text(
            'Noch kein Bild',
            style: TextStyle(fontSize: 12, color: Palette.muted),
          ),
        ],
      ),
    );
  }
}
