import 'dart:math' as math;
import 'dart:ui';

import '../ui/muenz_bild.dart';
import 'beute_regen.dart';

/// Wie Münzen und Funken im Bild stehen — **nur Darstellung**, gerechnet
/// wird in [BeuteRegen].
///
/// Gezeichnet in Weltkoordinaten, also innerhalb der Kamera, über den
/// Figuren: Ein Stück, das zum Helden fliegt, soll nicht hinter ihm
/// verschwinden. Münze und Funke selbst stehen in [MuenzBild], dort
/// malt auch das Häkchen auf der Startseite.
abstract final class BeuteBild {
  /// Halbmesser einer Münze. Klein genug für den Brunnen, gross genug,
  /// dass man sie sich drehen sieht.
  static const double muenzRadius = 4.5;

  static void zeichne(Canvas canvas, BeuteRegen regen) {
    for (final stueck in regen.stuecke) {
      final sichtbar = stueck.sichtbar;
      if (sichtbar <= 0) continue;
      // Was die Niederlage nimmt, verblasst (ADR-0084). Eine Ebene nur
      // dann, sonst kostete jede Münze eine.
      if (sichtbar < 1) {
        canvas.saveLayer(
          null,
          Paint()..color = Color.fromRGBO(0, 0, 0, sichtbar),
        );
      }
      switch (stueck.art) {
        case BeuteArt.gold:
          _muenzeZeichnen(canvas, stueck);
        case BeuteArt.erfahrung:
          _funkeZeichnen(canvas, stueck);
      }
      if (sichtbar < 1) canvas.restore();
    }
  }

  static void _muenzeZeichnen(Canvas canvas, Beutestueck m) {
    // Der Schatten bleibt am Boden und wird kleiner, je höher sie springt.
    final hoehe = (m.z / 40).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(m.x, m.y + 3),
        width: muenzRadius * 2 * (1 - 0.4 * hoehe),
        height: muenzRadius * (1 - 0.4 * hoehe),
      ),
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.3),
    );
    MuenzBild.muenze(
      canvas,
      Offset(m.x, m.y - m.z - 2),
      radius: muenzRadius,
      // Sie dreht sich: Die Breite folgt dem Kosinus.
      drehung: math.cos(m.alter * 14 + m.phase),
      glimmt: m.fliegt,
    );
  }

  static void _funkeZeichnen(Canvas canvas, Beutestueck f) {
    MuenzBild.funke(
      canvas,
      Offset(f.x, f.y),
      // Eine Spur nur, wenn er fliegt.
      spur: f.fliegt ? Offset(f.vorherX, f.vorherY) : null,
      // Er flackert leicht, aus seiner eigenen Zeit.
      flackern: 0.8 + 0.2 * math.sin(f.alter * 30 + f.phase),
    );
  }
}
