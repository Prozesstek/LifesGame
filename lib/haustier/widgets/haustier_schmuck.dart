import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:habits/habits.dart';
import 'package:haustier/haustier.dart';

/// **Was ein Haustier trägt und woran man sein Gebiet erkennt** — Hüte,
/// Halsschmuck, Spielzeug und die Prägung (22.10.2026, Platzhalter).
///
/// Ausgelagert aus `haustier_bild.dart`, das sonst über 800 Zeilen läge.
/// Gezeichnet wird in den Einheiten des Malers dort: 100 × 100.

/// Die Kontur jeder Form.
const Color tierKontur = Color(0xFF2B1A10);

/// Die Farbe der Prägung — dieselben vier Gebiete wie die Skills
/// (ADR-0085).
Color praegungsFarbe(SkillArea area) {
  return switch (area) {
    SkillArea.koerper => const Color(0xFFC0392B),
    SkillArea.geist => const Color(0xFF8E5BD0),
    SkillArea.wissenschaft => const Color(0xFF3A7BD5),
    SkillArea.gesellschaft => const Color(0xFF3E9A55),
  };
}

/// Womit gezeichnet wird: Füllung, Kontur, eine Form mit beidem.
class Stift {
  const Stift();

  Paint fuell(Color c) => Paint()..color = c;

  Paint get linie => Paint()
    ..color = tierKontur
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void form(Canvas c, Path p, Color farbe) {
    c.drawPath(p, fuell(farbe));
    c.drawPath(p, linie);
  }

  void oval(Canvas c, Offset m, double w, double h, Color farbe) {
    form(
      c,
      Path()..addOval(Rect.fromCenter(center: m, width: w, height: h)),
      farbe,
    );
  }

  void stern(Canvas c, Offset m, double r, Color farbe) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final w = i * math.pi / 4 - math.pi / 2;
      final rr = i.isEven ? r : r * 0.4;
      final q = m + Offset(math.cos(w) * rr, math.sin(w) * rr);
      if (i == 0) {
        p.moveTo(q.dx, q.dy);
      } else {
        p.lineTo(q.dx, q.dy);
      }
    }
    p.close();
    c.drawPath(p, fuell(farbe));
  }
}

void malePraegung(
  Canvas c,
  Stift s,
  SkillArea area,
  double k,
  Offset kopf,
  Offset bauch,
) {
  final farbe = praegungsFarbe(area);
  switch (area) {
    case SkillArea.koerper:
      // Ein Stirnband.
      c.drawRect(
        Rect.fromCenter(
          center: kopf.translate(0, -16 * k * 0.45),
          width: 30 * k,
          height: 4 * k,
        ),
        s.fuell(farbe),
      );
    case SkillArea.geist:
      // Ein leuchtender Punkt auf der Stirn.
      c.drawCircle(
        kopf.translate(0, -16 * k * 0.55),
        5 * k,
        s.fuell(farbe.withValues(alpha: 0.35)),
      );
      c.drawCircle(kopf.translate(0, -16 * k * 0.55), 2.4 * k, s.fuell(farbe));
    case SkillArea.wissenschaft:
      // Eine Brille.
      final glas = s.linie
        ..color = farbe
        ..strokeWidth = 1.4;
      for (final seite in <double>[-1, 1]) {
        c.drawCircle(
          kopf.translate(seite * 16 * k * 0.4, -16 * k * 0.05),
          5 * k,
          glas,
        );
      }
    case SkillArea.gesellschaft:
      // Ein Herz am Bauch.
      final m = bauch;
      final g = 5 * k;
      final herz = Path()
        ..moveTo(m.dx, m.dy + g)
        ..cubicTo(
          m.dx - g * 2,
          m.dy - g * 0.2,
          m.dx - g,
          m.dy - g * 1.6,
          m.dx,
          m.dy - g * 0.5,
        )
        ..cubicTo(
          m.dx + g,
          m.dy - g * 1.6,
          m.dx + g * 2,
          m.dy - g * 0.2,
          m.dx,
          m.dy + g,
        )
        ..close();
      c.drawPath(herz, s.fuell(farbe));
  }
}

void maleHals(Canvas c, Stift s, Zubehoer z, double k, Offset m) {
  switch (z.id) {
    case 'halstuch':
      final tuch = Path()
        ..moveTo(m.dx - 14 * k, m.dy)
        ..lineTo(m.dx + 14 * k, m.dy)
        ..lineTo(m.dx, m.dy + 12 * k)
        ..close();
      s.form(c, tuch, const Color(0xFFC0392B));
    case 'glocke':
      c.drawLine(
        m.translate(-12 * k, 0),
        m.translate(12 * k, 0),
        s.linie
          ..color = const Color(0xFF8B2E2E)
          ..strokeWidth = 3 * k,
      );
      s.oval(c, m.translate(0, 5 * k), 8 * k, 8 * k, const Color(0xFFF2C94C));
  }
}

void maleHut(Canvas c, Stift s, Zubehoer z, double k, Offset kopf, double r) {
  final oben = kopf.translate(0, -r * 0.82);
  switch (z.id) {
    case 'schleife':
      final mitte = oben.translate(r * 0.55, r * 0.1);
      for (final seite in <double>[-1, 1]) {
        final flugel = Path()
          ..moveTo(mitte.dx, mitte.dy)
          ..lineTo(mitte.dx + seite * 8 * k, mitte.dy - 5 * k)
          ..lineTo(mitte.dx + seite * 8 * k, mitte.dy + 5 * k)
          ..close();
        s.form(c, flugel, const Color(0xFFE47E90));
      }
      s.oval(c, mitte, 4 * k, 4 * k, const Color(0xFFD45D74));
    case 'strohhut':
      s.oval(
        c,
        oben.translate(0, 2 * k),
        r * 2.3,
        r * 0.5,
        const Color(0xFFE8C45A),
      );
      final krone = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: oben.translate(0, -3 * k),
              width: r * 1.2,
              height: r * 0.7,
            ),
            Radius.circular(3 * k),
          ),
        );
      s.form(c, krone, const Color(0xFFE8C45A));
      c.drawRect(
        Rect.fromCenter(
          center: oben.translate(0, -1 * k),
          width: r * 1.2,
          height: 2.5 * k,
        ),
        s.fuell(const Color(0xFFC0392B)),
      );
    case 'zauberhut':
      final hut = Path()
        ..moveTo(oben.dx - r * 0.95, oben.dy + 3 * k)
        ..lineTo(oben.dx + r * 0.25, oben.dy - r * 1.9)
        ..lineTo(oben.dx + r * 0.95, oben.dy + 3 * k)
        ..close();
      s.form(c, hut, const Color(0xFF5B3FA0));
      s.stern(c, oben.translate(0, -r * 0.55), 4 * k, const Color(0xFFF2C94C));
    case 'krone':
      final krone = Path()
        ..moveTo(oben.dx - r * 0.8, oben.dy + 2 * k)
        ..lineTo(oben.dx - r * 0.8, oben.dy - r * 0.6)
        ..lineTo(oben.dx - r * 0.4, oben.dy - r * 0.2)
        ..lineTo(oben.dx, oben.dy - r * 0.8)
        ..lineTo(oben.dx + r * 0.4, oben.dy - r * 0.2)
        ..lineTo(oben.dx + r * 0.8, oben.dy - r * 0.6)
        ..lineTo(oben.dx + r * 0.8, oben.dy + 2 * k)
        ..close();
      s.form(c, krone, const Color(0xFFF2C94C));
      c.drawCircle(
        oben.translate(0, -r * 0.2),
        2 * k,
        s.fuell(const Color(0xFFC0392B)),
      );
  }
}

void maleSpielzeug(
  Canvas c,
  Stift s,
  Zubehoer z, {
  required double t,
  required double boden,
}) {
  final m = Offset(84, boden - 5);
  switch (z.id) {
    case 'ball':
      final roll = math.sin(t * 2 * math.pi) * 2;
      s.oval(c, m.translate(roll, 0), 11, 11, const Color(0xFFE74C3C));
      c.drawLine(
        m.translate(roll - 5.5, 0),
        m.translate(roll + 5.5, 0),
        s.linie
          ..color = Colors.white
          ..strokeWidth = 1.6,
      );
    case 'kissen':
      final kissen = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(50, boden + 1),
              width: 70,
              height: 9,
            ),
            const Radius.circular(4),
          ),
        );
      s.form(c, kissen, const Color(0xFF7F8FD6));
    case 'kristall':
      final glanz = 0.6 + 0.4 * math.sin(t * 2 * math.pi).abs();
      final kristall = Path()
        ..moveTo(m.dx, m.dy - 10)
        ..lineTo(m.dx + 5, m.dy - 2)
        ..lineTo(m.dx, m.dy + 5)
        ..lineTo(m.dx - 5, m.dy - 2)
        ..close();
      c.drawCircle(
        m.translate(0, -3),
        9,
        s.fuell(const Color(0xFF7FE0F0).withValues(alpha: 0.3 * glanz)),
      );
      s.form(c, kristall, const Color(0xFF7FE0F0));
  }
}
