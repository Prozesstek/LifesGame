import 'dart:math' as math;
import 'dart:ui';

import '../ui/palette.dart';
import 'beute_regen.dart';

/// Wie Münzen und Funken im Bild stehen — **nur Darstellung**, gerechnet
/// wird in [BeuteRegen].
///
/// Gezeichnet in Weltkoordinaten, also innerhalb der Kamera, über den
/// Figuren: Ein Stück, das zum Helden fliegt, soll nicht hinter ihm
/// verschwinden.
abstract final class BeuteBild {
  /// Halbmesser einer Münze. Klein genug für den Brunnen, gross genug,
  /// dass man sie sich drehen sieht.
  static const double muenzRadius = 4.5;

  static const Color _muenze = Color(0xFFF5C542);
  static const Color _muenzRand = Color(0xFF9A6D12);
  static const Color _glanz = Color(0xFFFFF6D8);

  /// Der Funke trägt die Farbe der Erfahrung auf Leder, wie der Balken
  /// auf der Startseite — dieselbe Sache, dasselbe Bild.
  static const Color _funke = Palette.accentOnDark;
  static const Color _funkenKern = Color(0xFFFFE2B8);

  static void zeichne(Canvas canvas, BeuteRegen regen) {
    for (final stueck in regen.stuecke) {
      switch (stueck.art) {
        case BeuteArt.gold:
          _muenzeZeichnen(canvas, stueck);
        case BeuteArt.erfahrung:
          _funkeZeichnen(canvas, stueck);
      }
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

    final mitte = Offset(m.x, m.y - m.z - 2);
    // Sie dreht sich: Die Breite folgt dem Kosinus, nie ganz auf null —
    // eine Münze von der Kante ist ein Strich, kein Nichts.
    final drehung = math.cos(m.alter * 14 + m.phase);
    final breite = muenzRadius * math.max(0.25, drehung.abs());
    if (m.fliegt) {
      canvas.drawCircle(
        mitte,
        muenzRadius + 3,
        Paint()..color = _muenze.withValues(alpha: 0.25),
      );
    }
    final rund = Rect.fromCenter(
      center: mitte,
      width: breite * 2,
      height: muenzRadius * 2,
    );
    canvas.drawOval(rund, Paint()..color = _muenze);
    canvas.drawOval(
      rund,
      Paint()
        ..color = _muenzRand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Der Glanz nur, wenn sie zum Bild zeigt.
    if (drehung > 0.55) {
      canvas.drawCircle(
        mitte.translate(-breite * 0.35, -muenzRadius * 0.35),
        1.2,
        Paint()..color = _glanz,
      );
    }
  }

  static void _funkeZeichnen(Canvas canvas, Beutestueck f) {
    final mitte = Offset(f.x, f.y);
    // Eine kurze Spur, wenn er fliegt: Ohne sie sieht ein schneller Funke
    // aus wie zwei.
    final spur = Offset(f.vorherX, f.vorherY);
    if (f.fliegt && (spur - mitte).distance > 0.5) {
      canvas.drawLine(
        spur,
        mitte,
        Paint()
          ..color = _funke.withValues(alpha: 0.55)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    // Er flackert leicht, aus seiner eigenen Zeit.
    final flackern = 0.8 + 0.2 * math.sin(f.alter * 30 + f.phase);
    canvas.drawCircle(
      mitte,
      6 * flackern,
      Paint()..color = _funke.withValues(alpha: 0.3),
    );
    canvas.drawCircle(mitte, 3, Paint()..color = _funke);
    canvas.drawCircle(mitte, 1.5, Paint()..color = _funkenKern);
  }
}
