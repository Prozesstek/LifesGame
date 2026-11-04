import 'dart:math' as math;

import 'package:flutter/material.dart';

/// **Die übrigen Holzteile, gemalt wie der Rahmen** (ADR-0099): Planke,
/// Knopf, Seil, Balken. Dieselben Farben, dieselbe Maserung, Licht von oben
/// links — nichts wird gedehnt, jeder Bildpunkt wird für die Größe
/// ausgerechnet.
abstract final class HolzTon {
  static const Color kante = Color(0xFF130505);
  static const Color tief = Color(0xFF5D3A2B);
  static const Color schatten = Color(0xFF894D2D);
  static const Color holz = Color(0xFFA8602F);
  static const Color licht = Color(0xFFC0803C);
  static const Color glanz = Color(0xFFDDA05A);
  static const Color messingHell = Color(0xFFF3DC95);
  static const Color messing = Color(0xFFC9A04A);
  static const Color messingTief = Color(0xFF6E5420);
  static const Color rinne = Color(0xFF2A1810);
  static const Color seilHell = Color(0xFFD9B57A);
  static const Color seil = Color(0xFFA67C47);
  static const Color seilTief = Color(0xFF6B4A26);

  /// Die Maserung: lange, unregelmäßige Fasern, nie im Takt. Über 1,15 eine
  /// dunkle Faser, unter −1,45 eine helle.
  static double faser(int laengs, int quer) =>
      math.sin(laengs * 0.23 + quer * 2.1) +
      math.sin(laengs * 0.071 + quer * 5.3);
}

/// Ein Raster aus Bildpunkten, das sich auf eine Fläche malt.
abstract class _PixelMaler extends CustomPainter {
  const _PixelMaler(this.pixel);

  /// Logische Punkte je Bildpunkt.
  final double pixel;

  /// Die Farbe des Bildpunkts — null lässt ihn frei.
  Color? farbe(int x, int y, int w, int h);

  @override
  void paint(Canvas canvas, Size size) {
    final w = (size.width / pixel).round();
    final h = (size.height / pixel).round();
    if (w < 4 || h < 4) return;
    final pw = size.width / w, ph = size.height / h;
    final pfade = <Color, Path>{};
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final c = farbe(x, y, w, h);
        if (c == null) continue;
        (pfade[c] ??= Path()).addRect(
          Rect.fromLTWH(x * pw, y * ph, pw + 0.01, ph + 0.01),
        );
      }
    }
    final p = Paint()..isAntiAlias = false;
    pfade.forEach((c, pfad) => canvas.drawPath(pfad, p..color = c));
  }
}

/// **Die Planke** — Hintergrund jedes Hauptknopfs und des Schilds: ein
/// Brett mit abgeschrägten Ecken, langer Maserung und je Ende einem
/// Messingnagel.
class PlankenMaler extends _PixelMaler {
  const PlankenMaler({double pixel = 2}) : super(pixel);

  @override
  Color? farbe(int x, int y, int w, int h) {
    final l = x, r = w - 1 - x, o = y, u = h - 1 - y;
    // Abgeschrägte Ecken, zwei Bildpunkte.
    if (math.min(l, r) + math.min(o, u) < 2) return null;
    if (l == 0 || r == 0 || o == 0 || u == 0) return HolzTon.kante;
    if (math.min(l, r) + math.min(o, u) == 2) return HolzTon.kante;
    // Nägel an beiden Enden, in der Mitte der Höhe.
    final mitteY = h ~/ 2;
    for (final nx in <int>[3, w - 5]) {
      if (x == nx && y == mitteY - 1) return HolzTon.messingHell;
      if ((x == nx + 1 && y == mitteY - 1) || (x == nx && y == mitteY)) {
        return HolzTon.messing;
      }
      if (x == nx + 1 && y == mitteY) return HolzTon.messingTief;
    }
    // Licht oben, Schatten unten, die Enden etwas dunkler.
    if (o == 1) return HolzTon.glanz;
    if (u == 1) return HolzTon.tief;
    if (u == 2) return HolzTon.schatten;
    if (l == 1 || r == 1) return HolzTon.schatten;
    // Ruhiger als am Rahmen: Auf einer Planke steht Schrift.
    final f = HolzTon.faser(x, y);
    if (f > 1.55) return HolzTon.schatten;
    if (f < -1.75) return HolzTon.glanz;
    return y < h / 2 ? HolzTon.licht : HolzTon.holz;
  }

  @override
  bool shouldRepaint(PlankenMaler alt) => alt.pixel != pixel;
}

/// **Der Knopf** — ein Holzklotz mit abgeschrägten Ecken. Gedrückt dreht
/// sich das Licht um: oben links Schatten, unten rechts Glanz.
class KnopfMaler extends _PixelMaler {
  const KnopfMaler({this.gedrueckt = false, double pixel = 3}) : super(pixel);

  final bool gedrueckt;

  @override
  Color? farbe(int x, int y, int w, int h) {
    final l = x, r = w - 1 - x, o = y, u = h - 1 - y;
    if (math.min(l, r) + math.min(o, u) < 2) return null;
    if (l == 0 || r == 0 || o == 0 || u == 0) return HolzTon.kante;
    if (math.min(l, r) + math.min(o, u) == 2) return HolzTon.kante;
    final obenLinks = o == 1 || l == 1;
    final untenRechts = u == 1 || r == 1;
    if (obenLinks && !untenRechts) {
      return gedrueckt ? HolzTon.tief : HolzTon.glanz;
    }
    if (untenRechts && !obenLinks) {
      return gedrueckt ? HolzTon.licht : HolzTon.tief;
    }
    if (u == 2 || r == 2) return gedrueckt ? HolzTon.holz : HolzTon.schatten;
    final f = HolzTon.faser(x * 3, y);
    if (f > 1.3) return HolzTon.schatten;
    return gedrueckt ? HolzTon.schatten : HolzTon.holz;
  }

  @override
  bool shouldRepaint(KnopfMaler alt) =>
      alt.gedrueckt != gedrueckt || alt.pixel != pixel;
}

/// **Das Seil** über einem Dialog: zwei gedrehte Stränge vom Messingring
/// zu den oberen Ecken, unten je ein Knoten.
class SeilMaler extends _PixelMaler {
  const SeilMaler({double pixel = 2}) : super(pixel);

  @override
  Color? farbe(int x, int y, int w, int h) {
    final mx = w ~/ 2;
    // Der Ring oben in der Mitte.
    final dr = math.sqrt(math.pow(x - mx + 0.5, 2) + math.pow(y - 4.5, 2));
    if (dr <= 5.2 && dr >= 2.2) {
      if (dr > 4.4) return HolzTon.kante;
      return y < 4 ? HolzTon.messingHell : HolzTon.messing;
    }
    // Zwei Stränge vom Ring zu den Enden unten.
    final ziel = h - 3;
    final links = x < mx;
    final ende = links ? 3 : w - 4;
    if (y >= ziel && (x - ende).abs() <= 3) {
      // Der Knoten unten.
      if (y == h - 1 || (x - ende).abs() == 3) return HolzTon.kante;
      return y == ziel ? HolzTon.seilHell : HolzTon.seilTief;
    }
    // Abstand zur Seillinie, quer zu ihr gemessen.
    final ax = mx + (links ? -2.0 : 1.0), ay = 8.0;
    final bx = ende.toDouble(), by = ziel.toDouble();
    final dx = bx - ax, dy = by - ay;
    final t = ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy);
    if (t < 0 || t > 1) return null;
    final abstand =
        ((x - ax) * dy - (y - ay) * dx).abs() / math.sqrt(dx * dx + dy * dy);
    if (abstand > 2.2) return null;
    if (abstand > 1.4) return HolzTon.kante;
    // Gedreht: schräge Bänder quer über den Strang.
    final band = ((x + y * (links ? 1 : -1)) ~/ 1 % 3 + 3) % 3;
    return band == 0
        ? HolzTon.seilTief
        : band == 1
        ? HolzTon.seil
        : HolzTon.seilHell;
  }

  @override
  bool shouldRepaint(SeilMaler alt) => alt.pixel != pixel;
}

/// **Der Balken** — die Holzfassung um Leben, Erfahrung und Fortschritt:
/// innen eine dunkle Rinne, an den Enden Messingkappen. Die Füllung malt
/// der Code ([rinneLinks] … [rinneHoehe]).
class BalkenMaler extends _PixelMaler {
  const BalkenMaler({double pixel = 1}) : super(pixel);

  static const int hoehe = 12;
  static const int rinneLinks = 5, rinneRechts = 5;
  static const int rinneOben = 3, rinneHoehe = 6;

  @override
  Color? farbe(int x, int y, int w, int h) {
    final l = x, r = w - 1 - x, o = y, u = h - 1 - y;
    if (math.min(l, r) + math.min(o, u) < 2) return null;
    if (l == 0 || r == 0 || o == 0 || u == 0) return HolzTon.kante;
    if (math.min(l, r) + math.min(o, u) == 2) return HolzTon.kante;
    // Messingkappen an beiden Enden.
    if (l <= 3 || r <= 3) {
      if (o == 1 || l == 1 || r == 1) return HolzTon.messingHell;
      if (u == 1) return HolzTon.messingTief;
      return HolzTon.messing;
    }
    // Die Rinne mit dunklem Rand.
    final inRinne =
        x >= rinneLinks &&
        x < w - rinneRechts &&
        y >= rinneOben &&
        y < rinneOben + rinneHoehe;
    if (inRinne) {
      return y == rinneOben ? HolzTon.kante : HolzTon.rinne;
    }
    if (o == 1) return HolzTon.glanz;
    if (u == 1) return HolzTon.tief;
    if (y == rinneOben + rinneHoehe) return HolzTon.licht;
    final f = HolzTon.faser(x, y);
    if (f > 1.15) return HolzTon.schatten;
    return y < rinneOben ? HolzTon.licht : HolzTon.holz;
  }

  @override
  bool shouldRepaint(BalkenMaler alt) => alt.pixel != pixel;
}
