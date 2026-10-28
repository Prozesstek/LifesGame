import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/palette.dart';
import '../../ui/sprung.dart';
import '../tages_flamme.dart';
import 'weekday_picker.dart';

/// **Die große Flamme in der Mitte**, wenn das erste Häkchen des Tages
/// die Tageskette trägt — wie bei Duolingo (28.10.2026).
///
/// Erst glimmt sie grau, dann zündet sie: Sie springt auf, ein Ring geht
/// nach außen, Funken platzen. Die Zahl rollt einen Tag höher, und unter
/// ihr fängt der Kreis von heute in der Woche Feuer. Dann flackert sie
/// kurz und blendet aus.
///
/// **Endet von selbst** nach [dauer]; ein Tipp irgendwohin blendet sie
/// sofort aus. Bis dahin nimmt sie jeden Tipp — sonst hakte ein zweiter
/// Tipp unter ihr eine Gewohnheit ab, die man gar nicht sieht.
///
/// Nur Darstellung: Was sie zeigt, steht in [TagesFlamme].
class TagesFlammeFeier extends StatefulWidget {
  const TagesFlammeFeier({
    required this.flamme,
    required this.onFertig,
    this.onZahl,
    super.key,
  });

  final TagesFlamme flamme;

  /// Sie ist ausgeblendet.
  final VoidCallback onFertig;

  /// Die Zahl springt um — dort gehören Klang und Stoß hin.
  final VoidCallback? onZahl;

  /// Woran Tests sie finden.
  static const Key feierKey = ValueKey<String>('tages-flamme');

  static const Duration dauer = Duration(milliseconds: 2600);

  /// Wie schnell sie nach einem Tipp verschwindet.
  static const Duration weg = Duration(milliseconds: 220);

  // Der Ablauf, in Sekunden ab dem Häkchen.
  static const double _ein = 0.22;
  static const double _zuenden = 0.18;
  static const double _zahl = 0.45;
  static const double _zahlSteht = 0.85;
  static const double _heute = 0.78;
  static const double _heuteSteht = 1.2;
  static const double _aus = 2.15;

  @override
  State<TagesFlammeFeier> createState() => _TagesFlammeFeierState();
}

class _TagesFlammeFeierState extends State<TagesFlammeFeier>
    with TickerProviderStateMixin {
  // In `initState`, nicht faul (`gotchas.md`).
  late final AnimationController _lauf;
  late final AnimationController _weg;
  bool _zahlGemeldet = false;

  double get _sekunden =>
      _lauf.value * TagesFlammeFeier.dauer.inMicroseconds / 1e6;

  @override
  void initState() {
    super.initState();
    _lauf = AnimationController(vsync: this, duration: TagesFlammeFeier.dauer)
      ..addListener(_meldeZahl)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFertig();
      });
    _weg = AnimationController(vsync: this, duration: TagesFlammeFeier.weg)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFertig();
      });
    _lauf.forward();
  }

  void _meldeZahl() {
    if (_zahlGemeldet || _sekunden < TagesFlammeFeier._zahl + 0.08) return;
    _zahlGemeldet = true;
    widget.onZahl?.call();
  }

  void _ueberspringen() {
    if (_weg.isAnimating || _weg.isCompleted) return;
    _lauf.stop();
    _weg.forward();
  }

  @override
  void dispose() {
    _lauf.dispose();
    _weg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flamme = widget.flamme;
    return Semantics(
      key: TagesFlammeFeier.feierKey,
      liveRegion: true,
      label: '${flamme.nachher} Tage am Stück',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _ueberspringen,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_lauf, _weg]),
          builder: (context, _) {
            final s = _sekunden;
            final ein = Sprung.abschnitt(s, 0, TagesFlammeFeier._ein);
            final aus = Sprung.abschnitt(
              s,
              TagesFlammeFeier._aus,
              TagesFlammeFeier.dauer.inMilliseconds / 1000,
            );
            final sichtbar = (ein * (1 - aus) * (1 - _weg.value)).clamp(
              0.0,
              1.0,
            );
            return CustomPaint(
              painter: _SchleierMaler(sichtbar),
              child: Opacity(
                opacity: sichtbar,
                child: Transform.translate(
                  // Beim Ausblenden steigt alles ein Stück, wie Rauch.
                  offset: Offset(0, -24 * (aus + _weg.value)),
                  child: Center(
                    child: _Mitte(flamme: flamme, s: s),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Flamme, Zahl und Woche untereinander.
class _Mitte extends StatelessWidget {
  const _Mitte({required this.flamme, required this.s});

  final TagesFlamme flamme;
  final double s;

  static const Size _flammeGroesse = Size(150, 180);

  @override
  Widget build(BuildContext context) {
    final zuendung = Sprung.abschnitt(
      s,
      TagesFlammeFeier._zuenden,
      TagesFlammeFeier._zuenden + 0.22,
    );
    // Vor dem Zünden wächst die Glut heran, danach springt sie auf.
    final gross = s < TagesFlammeFeier._zuenden
        ? Sprung.feder(s / TagesFlammeFeier._zuenden * 0.35, von: 0.55)
        : Sprung.stoss(
            Sprung.abschnitt(s, TagesFlammeFeier._zuenden, 1.1),
            hoehe: 0.32,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox.fromSize(
          size: _flammeGroesse,
          child: CustomPaint(
            painter: _GlutMaler(s: s, zuendung: zuendung),
            foregroundPainter: _FunkenMaler(s: s),
            child: Transform.scale(
              scale: gross,
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                painter: _FlammenMaler(s: s, zuendung: zuendung),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _Zahl(flamme: flamme, s: s),
        const SizedBox(height: 18),
        _Woche(woche: flamme.woche, s: s),
      ],
    );
  }
}

/// Die Zahl der Kette: Die alte steigt hinaus, die neue springt von
/// unten herein. Am allerersten Tag springt die Eins einfach auf.
class _Zahl extends StatelessWidget {
  const _Zahl({required this.flamme, required this.s});

  final TagesFlamme flamme;
  final double s;

  static const double _hoehe = 84;

  @override
  Widget build(BuildContext context) {
    final rollen = Sprung.abschnitt(
      s,
      TagesFlammeFeier._zahl,
      TagesFlammeFeier._zahlSteht,
    );
    final rein = Curves.easeOutCubic.transform(rollen);
    final neuGross = Sprung.feder(rollen, von: 0.4);
    return SizedBox(
      height: _hoehe,
      width: 220,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (flamme.rollt && rollen < 1)
              Transform.translate(
                offset: Offset(0, -_hoehe * 0.7 * rein),
                child: Opacity(
                  opacity: 1 - rein,
                  child: _ziffer('${flamme.vorher}', Palette.textOnDarkDim),
                ),
              ),
            if (rollen > 0)
              Transform.translate(
                offset: Offset(0, flamme.rollt ? _hoehe * 0.7 * (1 - rein) : 0),
                child: Transform.scale(
                  scale: neuGross,
                  child: Opacity(
                    opacity: rein,
                    child: _ziffer('${flamme.nachher}', Palette.tintFunke),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ziffer(String text, Color farbe) {
    return Text(
      text,
      maxLines: 1,
      style: TextStyle(
        fontSize: 68,
        height: 1.1,
        fontWeight: FontWeight.w900,
        color: farbe,
        shadows: const <Shadow>[
          Shadow(color: Color(0xCC1A0E05), offset: Offset(2, 3)),
          Shadow(color: Color(0x99F08A3C), blurRadius: 18),
        ],
      ),
    );
  }
}

/// Montag bis Sonntag. Was die Kette getragen hat, brennt; heute fängt
/// gerade Feuer.
class _Woche extends StatelessWidget {
  const _Woche({required this.woche, required this.s});

  final List<FlammenTag> woche;
  final double s;

  @override
  Widget build(BuildContext context) {
    final heute = Sprung.abschnitt(
      s,
      TagesFlammeFeier._heute,
      TagesFlammeFeier._heuteSteht,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.goldOnDark.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 0; i < woche.length; i++)
              _Tag(name: Wochentage.kurz(i + 1), art: woche[i], heute: heute),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.name, required this.art, required this.heute});

  final String name;
  final FlammenTag art;

  /// Wie weit der Kreis von heute schon brennt, 0 bis 1.
  final double heute;

  static const double _kreis = 28;

  @override
  Widget build(BuildContext context) {
    final istHeute = art == FlammenTag.heute;
    final brennt = art == FlammenTag.brennt || (istHeute && heute > 0);
    final (Color? fuellung, IconData? zeichen) = switch (art) {
      FlammenTag.brennt => (Palette.tintLava, Icons.check_rounded),
      FlammenTag.eis => (Palette.tintEis, Icons.ac_unit_rounded),
      FlammenTag.heute when heute > 0 => (
        Palette.tintLava,
        Icons.check_rounded,
      ),
      _ => (null, null),
    };
    final rand = switch (art) {
      FlammenTag.heute => Palette.tintFunke,
      FlammenTag.kommt => Palette.textOnDarkDim.withValues(alpha: 0.3),
      _ => Palette.textOnDarkDim.withValues(alpha: 0.5),
    };
    final gross = istHeute && heute > 0 ? Sprung.feder(heute, von: 0.2) : 1.0;

    return SizedBox(
      width: 38,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: istHeute ? FontWeight.w900 : FontWeight.w600,
              color: istHeute ? Palette.tintFunke : Palette.textOnDarkDim,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox.square(
            dimension: _kreis + 8,
            child: CustomPaint(
              painter: istHeute && heute > 0 && heute < 1
                  ? _RingMaler(heute)
                  : null,
              child: Center(
                child: Transform.scale(
                  scale: gross,
                  child: Container(
                    width: _kreis,
                    height: _kreis,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fuellung,
                      border: fuellung == null
                          ? Border.all(color: rand, width: 2)
                          : null,
                      boxShadow: brennt
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x88F08A3C),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: zeichen == null
                        ? null
                        : Icon(zeichen, size: 18, color: Palette.background),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Der Ring, der vom Kreis von heute nach außen springt.
class _RingMaler extends CustomPainter {
  const _RingMaler(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = size.center(Offset.zero);
    canvas.drawCircle(
      mitte,
      size.shortestSide / 2 * (0.7 + 0.6 * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - t)
        ..color = Palette.tintFunke.withValues(alpha: 1 - t),
    );
  }

  @override
  bool shouldRepaint(_RingMaler alt) => alt.t != t;
}

/// Der Grund: dunkel um die Mitte, zum Rand hin heller — die Leiste oben
/// bleibt zu sehen, damit man die Münzen ankommen sieht.
class _SchleierMaler extends CustomPainter {
  const _SchleierMaler(this.sichtbar);

  final double sichtbar;

  @override
  void paint(Canvas canvas, Size size) {
    if (sichtbar <= 0) return;
    final flaeche = Offset.zero & size;
    canvas.drawRect(
      flaeche,
      Paint()
        ..shader = RadialGradient(
          radius: 0.8,
          colors: <Color>[
            Palette.background.withValues(alpha: 0.94 * sichtbar),
            Palette.background.withValues(alpha: 0.62 * sichtbar),
          ],
        ).createShader(flaeche),
    );
  }

  @override
  bool shouldRepaint(_SchleierMaler alt) => alt.sichtbar != sichtbar;
}

/// Der Schein hinter der Flamme und der Ring, der beim Zünden nach außen
/// geht.
class _GlutMaler extends CustomPainter {
  const _GlutMaler({required this.s, required this.zuendung});

  final double s;
  final double zuendung;

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = Offset(size.width / 2, size.height * 0.62);
    final r = size.shortestSide / 2;

    // Der Schein atmet, solange sie brennt.
    if (zuendung > 0) {
      final atmen = 1 + 0.06 * math.sin(s * 7);
      final weit = r * 2 * atmen;
      canvas.drawCircle(
        mitte,
        weit,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Palette.tintLava.withValues(alpha: 0.75 * zuendung),
              Palette.tintLava.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: mitte, radius: weit)),
      );
    }

    final ring = Sprung.abschnitt(
      s,
      TagesFlammeFeier._zuenden,
      TagesFlammeFeier._zuenden + 0.7,
    );
    if (ring > 0 && ring < 1) {
      final weg = Curves.easeOutCubic.transform(ring);
      canvas.drawCircle(
        mitte,
        r * (0.5 + 1.6 * weg),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * (1 - weg)
          ..color = Palette.tintFunke.withValues(alpha: 0.9 * (1 - weg)),
      );
    }
  }

  @override
  bool shouldRepaint(_GlutMaler alt) => alt.s != s || alt.zuendung != zuendung;
}

/// Die Flamme selbst: eine große Zunge mit einer kleinen an der Seite,
/// darin ein heller Kern. Grau, solange sie nur glimmt.
class _FlammenMaler extends CustomPainter {
  const _FlammenMaler({required this.s, required this.zuendung});

  final double s;
  final double zuendung;

  static final Color _glutAussen = Palette.textOnDarkDim.withValues(
    alpha: 0.55,
  );
  static final Color _glutInnen = Palette.muted.withValues(alpha: 0.6);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Erst wenn sie brennt, flackert sie.
    final flackern = zuendung * math.sin(s * 11) * 0.035;
    final neigen = zuendung * math.sin(s * 6.3) * 0.04;

    final aussen = Path()
      ..moveTo(0.5 * w, h)
      ..cubicTo(0.12 * w, h, 0.02 * w, 0.72 * h, 0.13 * w, 0.52 * h)
      ..cubicTo(
        0.18 * w,
        0.43 * h,
        (0.2 + neigen) * w,
        0.37 * h,
        (0.22 + neigen) * w,
        (0.27 - flackern) * h,
      )
      ..cubicTo(0.3 * w, 0.35 * h, 0.33 * w, 0.41 * h, 0.36 * w, 0.46 * h)
      ..cubicTo(
        0.38 * w,
        0.3 * h,
        (0.46 + neigen) * w,
        0.14 * h,
        (0.6 + neigen) * w,
        (0.0 + flackern) * h,
      )
      ..cubicTo(0.63 * w, 0.2 * h, 0.98 * w, 0.38 * h, 0.92 * w, 0.7 * h)
      ..cubicTo(0.88 * w, 0.92 * h, 0.72 * w, h, 0.5 * w, h)
      ..close();
    final flaeche = Offset.zero & size;
    canvas.drawPath(
      aussen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(_glutAussen, Palette.tintFunke, zuendung)!,
            Color.lerp(_glutAussen, Palette.tintLava, zuendung)!,
          ],
        ).createShader(flaeche),
    );

    canvas.drawPath(
      _tropfen(w, h, breite: 0.5, hoehe: 0.52 - flackern, neigen: neigen),
      Paint()..color = Color.lerp(_glutInnen, Palette.tintFunke, zuendung)!,
    );
    if (zuendung > 0) {
      canvas.drawPath(
        _tropfen(w, h, breite: 0.28, hoehe: 0.3 - flackern, neigen: neigen),
        Paint()..color = Palette.tintStern.withValues(alpha: zuendung),
      );
    }
  }

  /// Ein Kern, unten rund, oben spitz, auf dem Boden der Flamme.
  Path _tropfen(
    double w,
    double h, {
    required double breite,
    required double hoehe,
    required double neigen,
  }) {
    final fuss = h * 0.97;
    final halb = breite * w / 2;
    final spitze = Offset((0.52 + neigen * 0.6) * w, fuss - hoehe * h);
    return Path()
      ..moveTo(0.5 * w, fuss)
      ..cubicTo(
        0.5 * w - halb * 1.25,
        fuss,
        0.5 * w - halb * 1.1,
        fuss - hoehe * h * 0.55,
        spitze.dx,
        spitze.dy,
      )
      ..cubicTo(
        0.5 * w + halb * 1.1,
        fuss - hoehe * h * 0.55,
        0.5 * w + halb * 1.25,
        fuss,
        0.5 * w,
        fuss,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_FlammenMaler alt) =>
      alt.s != s || alt.zuendung != zuendung;
}

/// Funken: beim Zünden platzen sie nach allen Seiten, danach steigen sie
/// einzeln von der Spitze auf. Ohne Zufall — jeder Funke hat seinen Takt.
class _FunkenMaler extends CustomPainter {
  const _FunkenMaler({required this.s});

  final double s;

  static const int _platzen = 14;
  static const int _steigen = 9;
  static const List<Color> _farben = <Color>[
    Palette.tintFunke,
    Palette.tintLava,
    Palette.tintStern,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = Offset(size.width / 2, size.height * 0.55);
    final r = size.shortestSide / 2;

    final p = Sprung.abschnitt(
      s,
      TagesFlammeFeier._zuenden,
      TagesFlammeFeier._zuenden + 1.1,
    );
    if (p > 0 && p < 1) {
      final weg = Curves.easeOutCubic.transform(p);
      for (var i = 0; i < _platzen; i++) {
        final winkel = -math.pi / 2 + (i / _platzen) * 2 * math.pi + i * 0.17;
        final weit = r * (0.6 + (0.9 + 0.35 * (i % 3)) * weg);
        final fallen = r * 0.5 * p * p;
        canvas.drawCircle(
          mitte +
              Offset(math.cos(winkel) * weit, math.sin(winkel) * weit + fallen),
          3.6 * (1 - p) + 0.6,
          Paint()..color = _farben[i % 3].withValues(alpha: 1 - p),
        );
      }
    }

    // Danach steigen sie, bis die Flamme ausblendet.
    final ab = TagesFlammeFeier._zuenden + 0.3;
    if (s < ab) return;
    for (var i = 0; i < _steigen; i++) {
      const takt = 0.9;
      final phase = ((s - ab) / takt + i / _steigen) % 1;
      final seite = math.sin(i * 2.3) * r * 0.35;
      final wackeln = math.sin((s + i) * 5) * r * 0.08;
      final fuss = Offset(mitte.dx + seite, size.height * 0.3);
      canvas.drawCircle(
        fuss + Offset(wackeln, -phase * r * 1.1),
        2.4 * (1 - phase) + 0.4,
        Paint()..color = _farben[i % 3].withValues(alpha: 0.9 * (1 - phase)),
      );
    }
  }

  @override
  bool shouldRepaint(_FunkenMaler alt) => alt.s != s;
}
