import 'dart:math' as math;
import 'dart:ui';

import 'palette.dart';

/// **Eine fliegende Münze und ein Funke Erfahrung** — wie sie aussehen,
/// überall dasselbe.
///
/// Gezeichnet, nicht als Bild: Eine Münze dreht sich im Flug, und das
/// ist eine Breite, die sich jedes Bild ändert. Der Goldregen in der
/// Grube (`BeuteBild`) und das Häkchen auf der Startseite
/// (`BeuteFlug`) malen beide hier — dieselbe Sache, dasselbe Bild.
abstract final class MuenzBild {
  static const Color _muenze = Color(0xFFF5C542);
  static const Color _muenzRand = Color(0xFF9A6D12);
  static const Color _glanz = Color(0xFFFFF6D8);

  /// Der Funke trägt die Farbe der Erfahrung auf Leder, wie der Balken
  /// auf der Startseite.
  static const Color _funke = Palette.accentOnDark;
  static const Color _funkenKern = Color(0xFFFFE2B8);

  /// Die Grösse, für die die Strichstärken gewählt sind — die Münze der
  /// Grube. Andere Grössen rechnen von hier aus.
  static const double _bezugMuenze = 4.5;
  static const double _bezugFunke = 3;

  /// Eine Münze bei [mitte]. [drehung] ist der Kosinus ihres Winkels:
  /// 1 zeigt sie ganz, 0 von der Kante. [glimmt], solange sie fliegt.
  static void muenze(
    Canvas canvas,
    Offset mitte, {
    required double radius,
    required double drehung,
    bool glimmt = false,
  }) {
    final s = radius / _bezugMuenze;
    // Nie ganz auf null — eine Münze von der Kante ist ein Strich, kein
    // Nichts.
    final breite = radius * math.max(0.25, drehung.abs());
    if (glimmt) {
      canvas.drawCircle(
        mitte,
        radius + 3 * s,
        Paint()..color = _muenze.withValues(alpha: 0.25),
      );
    }
    final rund = Rect.fromCenter(
      center: mitte,
      width: breite * 2,
      height: radius * 2,
    );
    canvas.drawOval(rund, Paint()..color = _muenze);
    canvas.drawOval(
      rund,
      Paint()
        ..color = _muenzRand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * s,
    );
    // Der Glanz nur, wenn sie zum Bild zeigt.
    if (drehung > 0.55) {
      canvas.drawCircle(
        mitte.translate(-breite * 0.35, -radius * 0.35),
        1.2 * s,
        Paint()..color = _glanz,
      );
    }
  }

  /// Ein Funke bei [mitte], mit einer kurzen Spur von [spur] her — ohne
  /// sie sieht ein schneller Funke aus wie zwei. [flackern] zwischen 0,8
  /// und 1.
  static void funke(
    Canvas canvas,
    Offset mitte, {
    Offset? spur,
    double flackern = 1,
    double radius = _bezugFunke,
  }) {
    final s = radius / _bezugFunke;
    if (spur != null && (spur - mitte).distance > 0.5) {
      canvas.drawLine(
        spur,
        mitte,
        Paint()
          ..color = _funke.withValues(alpha: 0.55)
          ..strokeWidth = 3 * s
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      mitte,
      6 * s * flackern,
      Paint()..color = _funke.withValues(alpha: 0.3),
    );
    canvas.drawCircle(mitte, 3 * s, Paint()..color = _funke);
    canvas.drawCircle(mitte, 1.5 * s, Paint()..color = _funkenKern);
  }
}
