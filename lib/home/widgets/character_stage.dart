import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import 'level_card.dart';
import '../../ui/holz.dart';

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
  const CharacterStage({
    required this.level,
    required this.gold,
    this.helmId,
    super.key,
  });

  final PlayerLevel level;
  final int gold;

  /// Die Item-Id des getragenen Helms, oder `null` ohne Helm.
  final String? helmId;

  /// Wo die Figur liegt: die Grundfigur im 64 × 64-Stil, noch ohne
  /// Kleidung. Kommt später eine Fassung mit Rüstung dazu, ist das eine
  /// Datei mehr im selben Ordner und keine Änderung an `pubspec.yaml`.
  static const String assetPath = 'assets/character/Charakter.png';

  /// Helm-Id → Zeichnung **auf der Figur**, nicht das Ladenbild.
  ///
  /// Jede Datei liegt auf derselben 256er-Fläche wie [assetPath] und
  /// sitzt deckungsgleich darüber — kein Versatz, keine Rechnung. Ein
  /// neuer Helm ohne Eintrag hier steht im Laden, nur die Figur trägt
  /// ihn nicht; `test/character_stage_test.dart` meldet das.
  static const Map<String, String> helmOverlays = <String, String>{
    'gear-lederkappe': 'assets/character/Charakter_Lederkappe.png',
    'gear-eisenhaube': 'assets/character/Charakter_Eisenhaube.png',
    'gear-schuppenhaube': 'assets/character/Charakter_Schuppenhaube.png',
    'gear-visierhelm': 'assets/character/Charakter_Visierhelm.png',
    'gear-turnierhelm': 'assets/character/Charakter_Turnierhelm.png',
    'gear-drachenhelm': 'assets/character/Charakter_Drachenhelm.png',
    'gear-runenkrone': 'assets/character/Charakter_Runenkrone.png',
    'gear-krone-des-hochwaechters':
        'assets/character/Charakter_KroneDesHochwaechters.png',
  };

  @override
  Widget build(BuildContext context) {
    return HolzKarte(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(child: _Figur(helmId: helmId)),
          ),
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
  const _Figur({required this.helmId});

  final String? helmId;

  @override
  Widget build(BuildContext context) {
    final String? helm = CharacterStage.helmOverlays[helmId];
    // Die Zeichnung ist quadratisch und bekommt die kürzere Seite der
    // Fläche. Ob hart oder weich skaliert wird, entscheidet `PixelArt`.
    // Der Helm bekommt dieselbe Seite und liegt damit genau auf dem Kopf.
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            PixelArt(
              assetPath: CharacterStage.assetPath,
              side: side,
              fallback: const _KeineFigur(),
            ),
            if (helm != null)
              PixelArt(
                key: ValueKey<String>(helm),
                assetPath: helm,
                side: side,
                fallback: const SizedBox.shrink(),
              ),
          ],
        );
      },
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
