import 'dart:ui' as ui;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../ui/palette.dart';
import 'action_game.dart';

/// Was der Held von der Grube schon gesehen hat.
///
/// **Nur Darstellung, keine Spielregel.** Die Welt weiss nichts davon;
/// deshalb steht es hier und nicht in `action_combat`. Gesehen ist ein
/// Feld, sobald der Held einmal nah genug war — und es bleibt gesehen.
class MinimapFog {
  /// Wie weit der Held um sich herum aufdeckt, in Feldern. Etwas mehr als
  /// ein halber Bildschirm: Die Karte soll zeigen, was man gerade sah,
  /// nicht, was hinter der nächsten Ecke kommt.
  static const int revealTiles = 6;

  final Set<int> _seen = <int>{};

  int _width = 0;

  /// Deckt alles im Umkreis von [position] auf.
  void reveal(Level level, Vec2 position) {
    _width = level.width;
    final (mx, my) = tileOf(position);
    const r = revealTiles;
    for (var y = my - r; y <= my + r; y++) {
      for (var x = mx - r; x <= mx + r; x++) {
        if (x < 0 || y < 0 || x >= level.width || y >= level.height) continue;
        final dx = x - mx;
        final dy = y - my;
        if (dx * dx + dy * dy > r * r) continue;
        _seen.add(y * level.width + x);
      }
    }
  }

  bool isSeen(int x, int y) => _width > 0 && _seen.contains(y * _width + x);

  int get seenCount => _seen.length;

  /// Der aufgedeckte Boden als fertiges Bild — neu gemalt nur, wenn ein
  /// Feld dazukam oder die Größe wechselt. Sonst wären es in jedem Bild
  /// hunderte Rechtecke für etwas, das sich kaum ändert.
  ui.Picture? _boden;
  int _bodenStand = -1;
  double _bodenZelle = 0;

  /// Gibt das Bild frei, wenn der Lauf endet.
  void dispose() {
    _boden?.dispose();
    _boden = null;
  }

  ui.Picture bodenBild(Level level, double cell, Paint wand, Paint boden) {
    final alt = _boden;
    if (alt != null && _bodenStand == seenCount && _bodenZelle == cell) {
      return alt;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final index in _seen) {
      final x = index % _width;
      final y = index ~/ _width;
      canvas.drawRect(
        Rect.fromLTWH(x * cell, y * cell, cell, cell),
        level.isWallAt(x, y) ? wand : boden,
      );
    }
    alt?.dispose();
    _bodenStand = seenCount;
    _bodenZelle = cell;
    return _boden = recorder.endRecording();
  }

  /// Auf welchem Feld ein Punkt liegt.
  static (int, int) tileOf(Vec2 position) {
    const feld = ActionBalance.tileSize;
    return ((position.x / feld).floor(), (position.y / feld).floor());
  }

  /// Ob ein Gegner auf der Karte erscheint: nur, wer gerade im Umkreis
  /// steht. Ein Punkt, der hinter drei Wänden wandert, verriete zu viel.
  static bool shows(Vec2 hero, Vec2 enemy) {
    const reichweite = revealTiles * ActionBalance.tileSize;
    return hero.distanceTo(enemy) <= reichweite;
  }
}

/// Die kleine Karte oben links in der Grube.
class PitMinimap extends StatelessWidget {
  const PitMinimap({super.key, required this.game});

  final ActionGame game;

  /// Die grösste Kante der Karte, in Punkten.
  static const double maxSide = 84;

  @override
  Widget build(BuildContext context) {
    final level = game.sim.level;
    final zelle = level.width == 0
        ? 1.0
        : (maxSide / level.width < maxSide / level.height
              ? maxSide / level.width
              : maxSide / level.height);

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Palette.background.withValues(alpha: 0.75),
          border: Border.all(color: Palette.textOnDarkDim, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        // Kein eigener Takt: Die Karte steht in der Kopfzeile und baut
        // sich mit ihr neu (`ActionGame.anzeige`).
        child: CustomPaint(
          size: Size(level.width * zelle, level.height * zelle),
          painter: _MinimapPainter(
            level: game.sim.level,
            fog: game.fog,
            hero: game.sim.heroView.position,
            enemies: <Vec2>[
              for (final view in game.sim.views)
                if (view.faction == Faction.gegner) view.position,
            ],
            cell: zelle,
          ),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.level,
    required this.fog,
    required this.hero,
    required this.enemies,
    required this.cell,
  });

  final Level level;
  final MinimapFog fog;
  final Vec2 hero;
  final List<Vec2> enemies;
  final double cell;

  static final Paint _boden = Paint()..color = Palette.textOnDarkDim;
  static final Paint _wand = Paint()..color = Palette.backgroundRaised;
  static final Paint _held = Paint()..color = Palette.goldOnDark;
  static final Paint _gegner = Paint()..color = Palette.enemyOnDark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(fog.bodenBild(level, cell, _wand, _boden));

    final massstab = cell / ActionBalance.tileSize;
    for (final gegner in enemies) {
      if (!MinimapFog.shows(hero, gegner)) continue;
      canvas.drawCircle(
        Offset(gegner.x * massstab, gegner.y * massstab),
        1.6,
        _gegner,
      );
    }
    canvas.drawCircle(Offset(hero.x * massstab, hero.y * massstab), 2.4, _held);
  }

  // Bei jedem Neubau der Kopfzeile: Der Held läuft, der Boden kommt
  // fertig aus `MinimapFog.bodenBild`.
  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) => true;
}
