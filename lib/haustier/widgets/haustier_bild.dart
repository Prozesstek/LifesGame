import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:habits/habits.dart';
import 'package:haustier/haustier.dart';

import 'haustier_schmuck.dart';

/// **Wie das Haustier aussieht** — Ei oder Tier, je nach Art, Stufe,
/// Laune, Prägung und Zubehör. **Die eine Stelle**, an der es gezeichnet
/// wird: Kommt ein echtes Grafikpaket, wird nur diese Datei getauscht.
///
/// **Ein Platzhalter** (22.10.2026), gezeichnet statt gemalt: Formen und
/// Farben, damit es atmen, blinzeln, schlafen und springen kann, ohne dass
/// es dafür Bilder gibt.
///
/// Es lebt in einer Schleife ([lebt]) und springt, sobald [sprung] wächst
/// — die Startseite zählt dafür die Häkchen von heute.
class HaustierBild extends StatefulWidget {
  const HaustierBild({
    required this.art,
    required this.stufe,
    required this.laune,
    this.praegung,
    this.zubehoer = const <ZubehoerPlatz, Zubehoer>{},
    this.groesse = 96,
    this.sprung = 0,
    super.key,
  });

  /// Ob es sich bewegt. **In Tests nicht** (`test/flutter_test_config.dart`):
  /// Eine Schleife ohne Ende ließe `pumpAndSettle` nie zur Ruhe kommen.
  static bool lebt = true;

  final HaustierArt art;
  final HaustierStufe stufe;
  final HaustierLaune laune;

  /// Das stärkste Gebiet — prägt ein ausgewachsenes Tier.
  final SkillArea? praegung;

  final Map<ZubehoerPlatz, Zubehoer> zubehoer;
  final double groesse;

  /// Wächst die Zahl, springt es einmal.
  final int sprung;

  @override
  State<HaustierBild> createState() => _HaustierBildState();
}

class _HaustierBildState extends State<HaustierBild>
    with TickerProviderStateMixin {
  late final AnimationController _leben;
  late final AnimationController _sprung;

  @override
  void initState() {
    super.initState();
    _leben = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _sprung = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (HaustierBild.lebt && !ruhig) {
      if (!_leben.isAnimating) _leben.repeat();
    } else {
      _leben.stop();
    }
  }

  @override
  void didUpdateWidget(HaustierBild alt) {
    super.didUpdateWidget(alt);
    if (widget.sprung > alt.sprung) _sprung.forward(from: 0);
  }

  @override
  void dispose() {
    _leben.dispose();
    _sprung.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${widget.art.label}, ${widget.stufe.label}, '
          '${widget.laune.label}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: widget.groesse,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_leben, _sprung]),
          builder: (context, _) => CustomPaint(
            painter: _TierMaler(
              art: widget.art,
              stufe: widget.stufe,
              laune: widget.laune,
              praegung: widget.praegung,
              zubehoer: widget.zubehoer,
              t: _leben.value,
              sprung: _sprung.isAnimating ? _sprung.value : 0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Die Farben einer Art: Körper, Bauch, Zeichnung, Besonderes.
class _Farben {
  const _Farben(this.koerper, this.bauch, this.zeichnung, this.besonders);

  final Color koerper;
  final Color bauch;
  final Color zeichnung;
  final Color besonders;

  static _Farben von(HaustierArt art) {
    return switch (art) {
      HaustierArt.drache => const _Farben(
        Color(0xFF5E9E4A),
        Color(0xFFBBDA8C),
        Color(0xFF3B7431),
        Color(0xFFEDDDAE),
      ),
      HaustierArt.eule => const _Farben(
        Color(0xFF9A6B45),
        Color(0xFFE6CC9F),
        Color(0xFF6B472B),
        Color(0xFFE5A23A),
      ),
      HaustierArt.katze => const _Farben(
        Color(0xFFE39A52),
        Color(0xFFF6DAB5),
        Color(0xFFB66C2C),
        Color(0xFFE47E90),
      ),
    };
  }
}

class _TierMaler extends CustomPainter {
  _TierMaler({
    required this.art,
    required this.stufe,
    required this.laune,
    required this.praegung,
    required this.zubehoer,
    required this.t,
    required this.sprung,
  });

  final HaustierArt art;
  final HaustierStufe stufe;
  final HaustierLaune laune;
  final SkillArea? praegung;
  final Map<ZubehoerPlatz, Zubehoer> zubehoer;

  /// Wo die Schleife steht, 0..1.
  final double t;

  /// Wo ein Sprung steht, 0..1; 0 ohne Sprung.
  final double sprung;

  static const double _boden = 90;

  static const Stift _s = Stift();

  Paint _fuell(Color c) => _s.fuell(c);

  Paint get _linie => _s.linie;

  void _form(Canvas c, Path p, Color farbe) => _s.form(c, p, farbe);

  void _oval(Canvas c, Offset m, double w, double h, Color farbe) =>
      _s.oval(c, m, w, h, farbe);

  bool get _liegt =>
      laune == HaustierLaune.schlaeft || laune == HaustierLaune.ruht;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final welle = math.sin(t * 2 * math.pi);
    final hopser = laune == HaustierLaune.spielt
        ? (math.sin(t * 4 * math.pi).abs() * 7)
        : 0.0;
    final springt = sprung > 0 ? math.sin(sprung * math.pi) * 16 : 0.0;
    final lift = hopser + springt;

    // Schatten am Boden: kleiner, je höher es ist.
    final schatten = 1 - (lift / 30).clamp(0.0, 0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(50, _boden + 2),
        width: 46 * schatten,
        height: 6 * schatten,
      ),
      _fuell(const Color(0x33000000)),
    );

    if (zubehoer[ZubehoerPlatz.spielzeug] case final Zubehoer z) {
      maleSpielzeug(canvas, _s, z, t: t, boden: _boden);
    }

    if (stufe == HaustierStufe.ei) {
      _ei(canvas, welle, lift);
    } else {
      _tier(canvas, welle, lift);
    }

    if (laune == HaustierLaune.schlaeft) _zzz(canvas);
    if (laune == HaustierLaune.spielt || sprung > 0) _funkeln(canvas);
    canvas.restore();
  }

  // --- Ei ---

  void _ei(Canvas c, double welle, double lift) {
    final farben = _Farben.von(art);
    final wackeln = laune == HaustierLaune.schlaeft ? 0.0 : welle * 0.08;
    c.save();
    c.translate(50, _boden - lift);
    c.rotate(
      wackeln + (sprung > 0 ? math.sin(sprung * 6 * math.pi) * 0.15 : 0),
    );
    final ei = Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(0, -22), width: 34, height: 44),
      );
    c.drawPath(ei, _fuell(farben.bauch));
    c.save();
    c.clipPath(ei);
    // Die Zeichnung verrät, was darin steckt.
    final zeichnung = _fuell(farben.zeichnung);
    switch (art) {
      case HaustierArt.drache:
        for (final p in <Offset>[
          const Offset(-8, -30),
          const Offset(6, -20),
          const Offset(-4, -10),
          const Offset(9, -35),
        ]) {
          c.drawCircle(p, 4, zeichnung);
        }
      case HaustierArt.eule:
        for (var i = 0; i < 9; i++) {
          c.drawCircle(
            Offset(-10.0 + (i % 3) * 10, -36.0 + (i ~/ 3) * 11),
            1.8,
            zeichnung,
          );
        }
      case HaustierArt.katze:
        for (var i = 0; i < 4; i++) {
          c.drawRect(Rect.fromLTWH(-20, -40.0 + i * 10, 40, 3.5), zeichnung);
        }
    }
    c.restore();
    c.drawPath(ei, _linie);
    // Ein Glanz.
    c.drawOval(
      Rect.fromCenter(center: const Offset(-7, -33), width: 6, height: 10),
      _fuell(const Color(0x66FFFFFF)),
    );
    c.restore();
  }

  // --- Tier ---

  double get _groesse => switch (stufe) {
    HaustierStufe.ei => 0.5,
    HaustierStufe.schluepfling => 0.6,
    HaustierStufe.jung => 0.74,
    HaustierStufe.ausgewachsen => 0.86,
    HaustierStufe.praechtig => 0.94,
    HaustierStufe.uralt => 1.0,
  };

  void _tier(Canvas c, double welle, double lift) {
    final f = _Farben.von(art);
    final k = _groesse;
    final atmen = welle * (_liegt ? 0.6 : 1.2);
    final bobben = laune == HaustierLaune.munter ? welle.abs() * 2 : 0.0;

    final koerperB = (_liegt ? 50 : 42) * k;
    final koerperH = (_liegt ? 28 : 36) * k + atmen;
    final koerperY = _boden - koerperH / 2 - lift - bobben;
    final kopfR = 16 * k;
    final kopf = _liegt
        ? Offset(50 + koerperB * 0.32, koerperY - koerperH * 0.18)
        : Offset(50, koerperY - koerperH / 2 - kopfR * 0.45);

    // Uralt: ein goldener Schein hinter allem.
    if (stufe == HaustierStufe.uralt) {
      c.drawCircle(
        Offset(50, koerperY - 6 * k),
        44 * k,
        _fuell(const Color(0x33F2C94C)),
      );
    }

    // Der Umhang liegt hinter dem Körper.
    if (zubehoer[ZubehoerPlatz.hals]?.id == 'umhang') {
      final umhang = Path()
        ..moveTo(50 - koerperB * 0.3, koerperY - koerperH * 0.35)
        ..lineTo(50 - koerperB * 0.62, _boden - lift)
        ..lineTo(50 + koerperB * 0.62, _boden - lift)
        ..lineTo(50 + koerperB * 0.3, koerperY - koerperH * 0.35)
        ..close();
      _form(c, umhang, const Color(0xFF6A3D9A));
    }

    _schwanzUndFluegel(c, f, k, koerperB, koerperH, koerperY);

    // Körper und Bauch.
    _oval(c, Offset(50, koerperY), koerperB, koerperH, f.koerper);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(50, koerperY + koerperH * 0.12),
        width: koerperB * 0.58,
        height: koerperH * 0.62,
      ),
      _fuell(f.bauch),
    );

    // Der Schlüpfling trägt noch die untere Schale.
    if (stufe == HaustierStufe.schluepfling) {
      final schale = Path()
        ..moveTo(50 - koerperB * 0.62, koerperY)
        ..lineTo(50 - koerperB * 0.4, koerperY - 4)
        ..lineTo(50 - koerperB * 0.2, koerperY + 1)
        ..lineTo(50, koerperY - 4)
        ..lineTo(50 + koerperB * 0.2, koerperY + 1)
        ..lineTo(50 + koerperB * 0.4, koerperY - 4)
        ..lineTo(50 + koerperB * 0.62, koerperY)
        ..quadraticBezierTo(
          50 + koerperB * 0.6,
          _boden - lift,
          50,
          _boden - lift,
        )
        ..quadraticBezierTo(
          50 - koerperB * 0.6,
          _boden - lift,
          50 - koerperB * 0.62,
          koerperY,
        )
        ..close();
      _form(c, schale, _Farben.von(art).bauch);
    }

    if (zubehoer[ZubehoerPlatz.hals] case final Zubehoer hals
        when hals.id != 'umhang') {
      maleHals(c, _s, hals, k, Offset(50, koerperY - koerperH * 0.42));
    }

    _kopf(c, f, k, kopf, kopfR);

    // Die Prägung **nach** dem Kopf: Stirnband, Punkt und Brille sitzen
    // darauf und lagen vorher unsichtbar dahinter (beim Ansehen gefunden).
    if (praegung case final SkillArea area) {
      malePraegung(c, _s, area, k, kopf, Offset(50, koerperY + koerperH * 0.1));
    }

    if (zubehoer[ZubehoerPlatz.kopf] case final Zubehoer hut) {
      maleHut(c, _s, hut, k, kopf, kopfR);
    }
  }

  void _schwanzUndFluegel(
    Canvas c,
    _Farben f,
    double k,
    double b,
    double h,
    double y,
  ) {
    final schlag = math.sin(t * 2 * math.pi * 2) * 0.25;
    switch (art) {
      case HaustierArt.drache:
        final schwanz = Path()
          ..moveTo(50 + b * 0.38, y + h * 0.2)
          ..quadraticBezierTo(
            50 + b * 0.9,
            y + h * 0.45,
            50 + b * 0.85,
            y - h * 0.1,
          )
          ..lineTo(50 + b * 0.98, y - h * 0.22)
          ..lineTo(50 + b * 0.74, y - h * 0.08)
          ..quadraticBezierTo(
            50 + b * 0.7,
            y + h * 0.3,
            50 + b * 0.3,
            y + h * 0.35,
          )
          ..close();
        _form(c, schwanz, f.koerper);
        for (final seite in <double>[-1, 1]) {
          final w = seite * (1 + (laune == HaustierLaune.spielt ? schlag : 0));
          final fluegel = Path()
            ..moveTo(50 + seite * b * 0.25, y - h * 0.25)
            ..lineTo(50 + w * b * 0.78, y - h * 0.75)
            ..lineTo(50 + w * b * 0.62, y - h * 0.2)
            ..lineTo(50 + w * b * 0.52, y - h * 0.38)
            ..lineTo(50 + seite * b * 0.32, y + h * 0.05)
            ..close();
          _form(c, fluegel, f.zeichnung);
        }
      case HaustierArt.eule:
        for (final seite in <double>[-1, 1]) {
          final w = laune == HaustierLaune.spielt ? schlag * 8 : 0.0;
          c.save();
          c.translate(50 + seite * b * 0.45, y);
          c.rotate(seite * (0.25 + w * 0.05));
          _oval(c, Offset.zero, b * 0.32, h * 0.7, f.zeichnung);
          c.restore();
        }
      case HaustierArt.katze:
        final wedeln = math.sin(t * 2 * math.pi) * 6 * k;
        final schwanz = Path()
          ..moveTo(50 + b * 0.4, y + h * 0.3)
          ..quadraticBezierTo(
            50 + b * 0.95,
            y + h * 0.2,
            50 + b * 0.8 + wedeln,
            y - h * 0.55,
          )
          ..quadraticBezierTo(
            50 + b * 0.82 + wedeln,
            y - h * 0.7,
            50 + b * 0.7 + wedeln,
            y - h * 0.5,
          )
          ..quadraticBezierTo(
            50 + b * 0.78,
            y + h * 0.05,
            50 + b * 0.32,
            y + h * 0.15,
          )
          ..close();
        _form(c, schwanz, f.koerper);
    }
  }

  void _kopf(Canvas c, _Farben f, double k, Offset m, double r) {
    // Ohren und Hörner zuerst — sie liegen hinter dem Kopf.
    switch (art) {
      case HaustierArt.drache:
        for (final s in <double>[-1, 1]) {
          final horn = Path()
            ..moveTo(m.dx + s * r * 0.35, m.dy - r * 0.7)
            ..lineTo(m.dx + s * r * 0.62, m.dy - r * 1.45)
            ..lineTo(m.dx + s * r * 0.75, m.dy - r * 0.55)
            ..close();
          _form(c, horn, f.besonders);
        }
      case HaustierArt.eule:
        for (final s in <double>[-1, 1]) {
          final buschel = Path()
            ..moveTo(m.dx + s * r * 0.3, m.dy - r * 0.8)
            ..lineTo(m.dx + s * r * 0.85, m.dy - r * 1.35)
            ..lineTo(m.dx + s * r * 0.85, m.dy - r * 0.45)
            ..close();
          _form(c, buschel, f.zeichnung);
        }
      case HaustierArt.katze:
        for (final s in <double>[-1, 1]) {
          final ohr = Path()
            ..moveTo(m.dx + s * r * 0.2, m.dy - r * 0.8)
            ..lineTo(m.dx + s * r * 0.82, m.dy - r * 1.3)
            ..lineTo(m.dx + s * r * 0.92, m.dy - r * 0.35)
            ..close();
          _form(c, ohr, f.koerper);
          c.drawPath(
            Path()
              ..moveTo(m.dx + s * r * 0.4, m.dy - r * 0.75)
              ..lineTo(m.dx + s * r * 0.78, m.dy - r * 1.08)
              ..lineTo(m.dx + s * r * 0.82, m.dy - r * 0.55)
              ..close(),
            _fuell(f.besonders),
          );
        }
    }

    _oval(c, m, r * 2, r * 1.85, f.koerper);
    _gesicht(c, f, k, m, r);
  }

  void _gesicht(Canvas c, _Farben f, double k, Offset m, double r) {
    final augenY = m.dy - r * 0.05;
    final abstand = art == HaustierArt.eule ? r * 0.42 : r * 0.38;
    final zu = laune == HaustierLaune.schlaeft;
    final halb = laune == HaustierLaune.ruht;
    // Blinzeln: einmal in jeder Schleife, kurz.
    final blinzelt = !zu && !halb && (t % 1) > 0.92;
    final froh = laune == HaustierLaune.spielt || sprung > 0;

    for (final s in <double>[-1, 1]) {
      final auge = Offset(m.dx + s * abstand, augenY);
      if (art == HaustierArt.eule) {
        _oval(c, auge, r * 0.72, r * 0.72, const Color(0xFFFFF4D6));
      }
      if (zu || blinzelt || froh) {
        final bogen = Path();
        if (froh && !zu) {
          // Fröhlich: ^ ^
          bogen
            ..moveTo(auge.dx - r * 0.16, auge.dy + r * 0.06)
            ..lineTo(auge.dx, auge.dy - r * 0.12)
            ..lineTo(auge.dx + r * 0.16, auge.dy + r * 0.06);
        } else {
          bogen
            ..moveTo(auge.dx - r * 0.17, auge.dy)
            ..quadraticBezierTo(
              auge.dx,
              auge.dy + r * 0.14,
              auge.dx + r * 0.17,
              auge.dy,
            );
        }
        c.drawPath(bogen, _linie..strokeWidth = 1.6);
        continue;
      }
      final ar = r * (art == HaustierArt.eule ? 0.22 : 0.17);
      c.drawCircle(auge, ar, _fuell(tierKontur));
      if (halb) {
        c.drawRect(
          Rect.fromLTWH(
            auge.dx - ar - 0.5,
            auge.dy - ar - 0.5,
            ar * 2 + 1,
            ar + 0.5,
          ),
          _fuell(f.koerper),
        );
      } else {
        c.drawCircle(
          auge.translate(-ar * 0.35, -ar * 0.35),
          ar * 0.38,
          _fuell(Colors.white),
        );
      }
    }

    final mund = Offset(m.dx, m.dy + r * 0.38);
    switch (art) {
      case HaustierArt.eule:
        final schnabel = Path()
          ..moveTo(mund.dx - r * 0.12, mund.dy - r * 0.12)
          ..lineTo(mund.dx + r * 0.12, mund.dy - r * 0.12)
          ..lineTo(mund.dx, mund.dy + r * 0.12)
          ..close();
        _form(c, schnabel, f.besonders);
      case HaustierArt.katze:
        c.drawCircle(
          mund.translate(0, -r * 0.12),
          r * 0.08,
          _fuell(f.besonders),
        );
        final schnurr = _linie..strokeWidth = 0.8;
        for (final s in <double>[-1, 1]) {
          c.drawLine(
            mund.translate(s * r * 0.25, -r * 0.05),
            mund.translate(s * r * 0.85, -r * 0.15),
            schnurr,
          );
          c.drawLine(
            mund.translate(s * r * 0.25, r * 0.03),
            mund.translate(s * r * 0.85, r * 0.08),
            schnurr,
          );
        }
      case HaustierArt.drache:
        for (final s in <double>[-1, 1]) {
          c.drawCircle(
            mund.translate(s * r * 0.12, -r * 0.08),
            r * 0.04,
            _fuell(tierKontur),
          );
        }
    }
    if (laune != HaustierLaune.wartet && laune != HaustierLaune.schlaeft) {
      final laecheln = Path()
        ..moveTo(mund.dx - r * 0.18, mund.dy + r * 0.08)
        ..quadraticBezierTo(
          mund.dx,
          mund.dy + r * 0.28,
          mund.dx + r * 0.18,
          mund.dy + r * 0.08,
        );
      c.drawPath(laecheln, _linie..strokeWidth = 1.2);
    }
  }

  /// Drei Z, die aufsteigen und verblassen — **als Linien, nicht als
  /// Schrift**: Eine Schrift sähe je nach Gerät anders aus und erschien
  /// in der Vorschau als Kästchen.
  void _zzz(Canvas c) {
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1;
      final p = Offset(66 + phase * 14, 40 - phase * 26);
      final g = 2.5 + phase * 2.5;
      final z = Path()
        ..moveTo(p.dx - g, p.dy - g)
        ..lineTo(p.dx + g, p.dy - g)
        ..lineTo(p.dx - g, p.dy + g)
        ..lineTo(p.dx + g, p.dy + g);
      c.drawPath(
        z,
        _s.linie
          ..color = Color.fromRGBO(91, 110, 180, 1 - phase)
          ..strokeWidth = 1.6,
      );
    }
  }

  void _funkeln(Canvas c) {
    for (var i = 0; i < 4; i++) {
      final winkel = t * 2 * math.pi + i * math.pi / 2;
      final p = Offset(50 + math.cos(winkel) * 38, 46 + math.sin(winkel) * 22);
      _s.stern(c, p, 2.6, const Color(0xFFF2C94C));
    }
  }

  @override
  bool shouldRepaint(_TierMaler alt) {
    return alt.t != t ||
        alt.sprung != sprung ||
        alt.art != art ||
        alt.stufe != stufe ||
        alt.laune != laune ||
        alt.praegung != praegung ||
        alt.zubehoer != zubehoer;
  }
}
