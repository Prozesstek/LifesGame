import 'package:flutter/material.dart';
import 'package:gear/gear.dart';
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
    this.worn = const <String>[],
    super.key,
  });

  final PlayerLevel level;
  final int gold;

  /// Die Item-Ids der angelegten Stücke, in beliebiger Reihenfolge.
  /// Übereinander gelegt wird nach [layers], nicht nach dieser Liste.
  final List<String> worn;

  /// Wo die Figur liegt: die Grundfigur im 64 × 64-Stil, ohne Kleidung.
  static const String assetPath = 'assets/character/Charakter.png';

  /// In welcher Reihenfolge die Plätze auf der Figur liegen, von unten
  /// nach oben. Die Rüstung reicht bis unter den Helm, die Waffe liegt
  /// vor der Rüstung.
  static const List<GearSlot> layers = <GearSlot>[
    GearSlot.ruestung,
    GearSlot.waffe,
    GearSlot.helm,
  ];

  /// Item-Id → Zeichnung **auf der Figur**, nicht das Ladenbild.
  ///
  /// Jede Datei liegt auf derselben 256er-Fläche wie [assetPath] und
  /// sitzt deckungsgleich darüber — kein Versatz, keine Rechnung. Ein
  /// neues Stück ohne Eintrag hier steht im Laden, nur die Figur trägt
  /// es nicht; `test/character_stage_test.dart` meldet das für jeden
  /// Platz in [layers].
  ///
  /// **Die Helme sind gezeichnet, Rüstungen und Waffen erzeugt**, aus den
  /// Ladenbildern mit `tool/figur_ausruestung.py`. Wer eine davon von
  /// Hand ersetzt, nimmt sie dort aus der Liste.
  static const Map<String, String> overlays = <String, String>{
    // Helm — gezeichnet
    'gear-lederkappe': 'assets/character/Charakter_Lederkappe.png',
    'gear-eisenhaube': 'assets/character/Charakter_Eisenhaube.png',
    'gear-schuppenhaube': 'assets/character/Charakter_Schuppenhaube.png',
    'gear-visierhelm': 'assets/character/Charakter_Visierhelm.png',
    'gear-turnierhelm': 'assets/character/Charakter_Turnierhelm.png',
    'gear-drachenhelm': 'assets/character/Charakter_Drachenhelm.png',
    'gear-runenkrone': 'assets/character/Charakter_Runenkrone.png',
    'gear-krone-des-hochwaechters':
        'assets/character/Charakter_KroneDesHochwaechters.png',
    // Rüstung — erzeugt
    'gear-lederwams': 'assets/character/Charakter_Lederwams.png',
    'gear-gestepptes-wams': 'assets/character/Charakter_GesteppteWams.png',
    'gear-schuppenpanzer': 'assets/character/Charakter_Schuppenpanzer.png',
    'gear-kettenpanzer': 'assets/character/Charakter_Kettenpanzer.png',
    'gear-plattenharnisch': 'assets/character/Charakter_Plattenharnisch.png',
    'gear-drachenschuppenpanzer':
        'assets/character/Charakter_Drachenschuppenpanzer.png',
    'gear-runenharnisch': 'assets/character/Charakter_Runenharnisch.png',
    'gear-titanenpanzer': 'assets/character/Charakter_Titanenpanzer.png',
    // Waffe — erzeugt
    'gear-kurzbogen': 'assets/character/Charakter_Kurzbogen.png',
    'gear-uebungsklinge': 'assets/character/Charakter_Uebungsklinge.png',
    'gear-streitkolben': 'assets/character/Charakter_Streitkolben.png',
    'gear-geschliffene-klinge':
        'assets/character/Charakter_GeschliffeneKlinge.png',
    'gear-kriegsstab': 'assets/character/Charakter_Kriegsstab.png',
    'gear-zweihaender': 'assets/character/Charakter_Zweihaender.png',
    'gear-langbogen': 'assets/character/Charakter_Langbogen.png',
    'gear-sonnenklinge': 'assets/character/Charakter_Sonnenklinge.png',
  };

  /// Die Zeichnungen, die über der Figur liegen, von unten nach oben.
  static List<String> overlaysFor(Iterable<String> worn) {
    final ids = worn.toSet();
    return <String>[
      for (final slot in layers)
        for (final item in GearCatalog.forSlot(slot))
          if (ids.contains(item.id) && overlays[item.id] != null)
            overlays[item.id]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return HolzKarte(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(child: _Figur(overlays: overlaysFor(worn))),
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
  const _Figur({required this.overlays});

  final List<String> overlays;

  @override
  Widget build(BuildContext context) {
    // Die Zeichnung ist quadratisch und bekommt die kürzere Seite der
    // Fläche. Ob hart oder weich skaliert wird, entscheidet `PixelArt`.
    // Jedes Stück bekommt dieselbe Seite und liegt damit deckungsgleich.
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
            for (final bild in overlays)
              PixelArt(
                key: ValueKey<String>(bild),
                assetPath: bild,
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
