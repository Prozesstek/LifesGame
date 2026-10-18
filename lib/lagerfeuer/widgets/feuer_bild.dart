import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// **Das Lagerfeuer als Bild** (ADR-0076): ein Nachthimmel mit Sternen,
/// zwei Scheite, darüber Flammen, die flackern, und Funken, die steigen.
///
/// [brennt] heißt Abend oder geschaffter Tag; sonst **glimmt** es nur —
/// Glut auf den Scheiten, ein schwacher Schein, keine Flammen. Offen ist
/// es in beiden Fällen.
///
/// **Nur Bild**, wie der Schlund im Eingang (`EingangsGlut`): Es nimmt
/// keinen Tipp an und rechnet nichts.
class FeuerBild extends StatefulWidget {
  const FeuerBild({required this.brennt, this.hoehe = 230, super.key});

  final bool brennt;
  final double hoehe;

  /// Ob es flackert. **In Tests nicht** (`test/flutter_test_config.dart`):
  /// Eine Animation ohne Ende ließe `pumpAndSettle` nie zur Ruhe kommen.
  static bool flackert = true;

  /// Der Himmel oben; unten geht er ins Leder über ([Palette.background]),
  /// damit das Bild ohne Kante in den Bildschirm läuft.
  static const Color nachtOben = Color(0xFF0B1020);

  /// Ein Durchlauf. Flammen und Funken laufen in Teilern davon, damit der
  /// Übergang zum nächsten nicht springt.
  static const Duration _runde = Duration(seconds: 6);

  @override
  State<FeuerBild> createState() => _FeuerBildState();
}

class _FeuerBildState extends State<FeuerBild>
    with SingleTickerProviderStateMixin {
  // In `initState`, nicht faul (`gotchas.md`).
  late final AnimationController _takt;

  @override
  void initState() {
    super.initState();
    _takt = AnimationController(
      vsync: this,
      duration: FeuerBild._runde,
      // Ohne Flackern steht das Bild auf einem schönen Augenblick.
      value: 0.3,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Wer Bewegung abgeschaltet hat, bekommt das stehende Bild.
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (FeuerBild.flackert && !ruhig) {
      if (!_takt.isAnimating) _takt.repeat();
    } else {
      _takt.stop();
    }
  }

  @override
  void dispose() {
    _takt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ein eigener Knoten: Ohne ihn verschmölze die Beschriftung mit allem,
    // was darunter steht — Truhe und Aufgaben läsen sich als ein Satz.
    return Semantics(
      container: true,
      label: widget.brennt ? 'Das Feuer brennt' : 'Das Feuer glimmt',
      excludeSemantics: true,
      child: SizedBox(
        height: widget.hoehe,
        width: double.infinity,
        child: IgnorePointer(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _takt,
              builder: (context, _) => CustomPaint(
                painter: FeuerMaler(
                  brennt: widget.brennt,
                  zeit: _takt.value * FeuerBild._runde.inSeconds,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Malt Himmel, Scheite, Flammen und Funken. Öffentlich, damit auch die
/// kleine Karte auf der Startseite dasselbe Feuer zeigt.
class FeuerMaler extends CustomPainter {
  FeuerMaler({required this.brennt, required this.zeit, this.himmel = true});

  final bool brennt;

  /// Sekunden im Durchlauf, 0 bis 6.
  final double zeit;

  /// Ob der Nachthimmel mitgemalt wird — die Karte bringt ihren eigenen
  /// Grund mit.
  final bool himmel;

  static const Color _flammeAussen = Palette.tintLava;
  static const Color _flammeMitte = Palette.tintFunke;
  static const Color _flammeInnen = Palette.tintStern;

  @override
  void paint(Canvas canvas, Size size) {
    if (himmel) _himmel(canvas, size);
    final basis = Offset(size.width / 2, size.height * 0.84);
    final mass = math.min(size.width, size.height);
    _schein(canvas, basis, mass);
    _scheite(canvas, basis, mass);
    if (brennt) {
      _flammen(canvas, basis, mass);
      _funken(canvas, basis, mass);
    } else {
      _glut(canvas, basis, mass);
    }
  }

  void _himmel(Canvas canvas, Size size) {
    final flaeche = Offset.zero & size;
    canvas.drawRect(
      flaeche,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[FeuerBild.nachtOben, Palette.background],
        ).createShader(flaeche),
    );
    // Sterne an festen Stellen, jeder mit eigenem Funkeln.
    final zufall = math.Random(7);
    for (var i = 0; i < 28; i++) {
      final x = zufall.nextDouble() * size.width;
      final y = zufall.nextDouble() * size.height * 0.55;
      final funkeln =
          0.45 + 0.55 * (0.5 + 0.5 * math.sin(zeit * 2 + i * 1.3)).abs();
      canvas.drawCircle(
        Offset(x, y),
        0.6 + zufall.nextDouble() * 0.9,
        Paint()..color = Palette.textOnDark.withValues(alpha: 0.55 * funkeln),
      );
    }
  }

  /// Der Lichtschein um das Feuer — hell, wenn es brennt, schwach, wenn
  /// es glimmt.
  void _schein(Canvas canvas, Offset basis, double mass) {
    final atem = 0.85 + 0.15 * math.sin(zeit * math.pi * 2 / 1.5);
    final staerke = brennt ? 0.5 * atem : 0.18 * atem;
    final mitte = Offset(basis.dx, basis.dy - mass * 0.18);
    final radius = mass * (brennt ? 0.62 : 0.4);
    canvas.drawCircle(
      mitte,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            _flammeAussen.withValues(alpha: staerke),
            _flammeAussen.withValues(alpha: staerke * 0.3),
            _flammeAussen.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: mitte, radius: radius)),
    );
  }

  /// Zwei gekreuzte Scheite.
  void _scheite(Canvas canvas, Offset basis, double mass) {
    final laenge = mass * 0.5;
    final dicke = mass * 0.075;
    for (final winkel in <double>[-0.32, 0.32]) {
      canvas
        ..save()
        ..translate(basis.dx, basis.dy)
        ..rotate(winkel);
      final scheit = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: laenge, height: dicke),
        Radius.circular(dicke / 2),
      );
      canvas
        ..drawRRect(scheit, Paint()..color = Palette.rahmenHolzDunkel)
        ..drawRRect(
          scheit.deflate(dicke * 0.22),
          Paint()..color = Palette.rahmenHolzHell.withValues(alpha: 0.6),
        )
        ..restore();
    }
  }

  void _flammen(Canvas canvas, Offset basis, double mass) {
    final grund = basis.translate(0, -mass * 0.03);
    // Drei Zungen, die mittlere am höchsten, jede mit eigenem Takt.
    final zungen = <(double versatz, double hoehe, double phase)>[
      (-0.11, 0.32, 1.7),
      (0.11, 0.3, 3.1),
      (0, 0.46, 0),
    ];
    for (final (versatz, hoehe, phase) in zungen) {
      final flackern = 1 + 0.12 * math.sin(zeit * 9 + phase);
      final neigung = math.sin(zeit * 3 + phase) * mass * 0.035;
      final fuss = grund.translate(versatz * mass, 0);
      final h = hoehe * mass * flackern;
      final b = mass * (versatz == 0 ? 0.24 : 0.16);
      for (final (anteil, farbe) in <(double, Color)>[
        (1, _flammeAussen),
        (0.7, _flammeMitte),
        (0.42, _flammeInnen),
      ]) {
        canvas.drawPath(
          _zunge(fuss, b * anteil, h * anteil, neigung * anteil),
          Paint()..color = farbe.withValues(alpha: 0.92),
        );
      }
    }
  }

  /// Eine Flammenzunge: unten breit, oben spitz, die Spitze neigt sich.
  Path _zunge(Offset fuss, double breite, double hoehe, double neigung) {
    final spitze = Offset(fuss.dx + neigung, fuss.dy - hoehe);
    return Path()
      ..moveTo(fuss.dx - breite / 2, fuss.dy)
      ..cubicTo(
        fuss.dx - breite * 0.62,
        fuss.dy - hoehe * 0.45,
        spitze.dx - breite * 0.12,
        spitze.dy + hoehe * 0.32,
        spitze.dx,
        spitze.dy,
      )
      ..cubicTo(
        spitze.dx + breite * 0.12,
        spitze.dy + hoehe * 0.32,
        fuss.dx + breite * 0.62,
        fuss.dy - hoehe * 0.45,
        fuss.dx + breite / 2,
        fuss.dy,
      )
      ..close();
  }

  /// Funken steigen, schwanken und verlöschen. Jeder hat seinen Takt
  /// (1,5, 2 oder 3 s — Teiler des Durchlaufs).
  void _funken(Canvas canvas, Offset basis, double mass) {
    const takte = <double>[1.5, 2, 3];
    for (var i = 0; i < 12; i++) {
      final takt = takte[i % takte.length];
      final t = ((zeit / takt) + (i * 0.618) % 1) % 1;
      final start = ((i * 0.37) % 1 - 0.5) * mass * 0.22;
      final x = basis.dx + start + math.sin(t * math.pi * 2 + i) * mass * 0.04;
      final y = basis.dy - mass * 0.15 - t * mass * 0.75;
      final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(x, y),
        1 + 1.4 * (1 - t),
        Paint()..color = _flammeInnen.withValues(alpha: alpha),
      );
    }
  }

  /// Ohne Flammen: Glut auf den Scheiten, die langsam atmet.
  void _glut(Canvas canvas, Offset basis, double mass) {
    for (var i = 0; i < 7; i++) {
      final x = basis.dx + (i - 3) * mass * 0.035;
      final y = basis.dy - mass * 0.02 - (i.isEven ? 0 : mass * 0.025);
      final atem = 0.5 + 0.5 * math.sin(zeit * 2 + i * 1.9);
      canvas.drawCircle(
        Offset(x, y),
        mass * 0.018,
        Paint()
          ..color = _flammeAussen.withValues(alpha: 0.35 + 0.5 * atem)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(FeuerMaler alt) =>
      alt.zeit != zeit || alt.brennt != brennt || alt.himmel != himmel;
}
