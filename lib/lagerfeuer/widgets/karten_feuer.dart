import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../ui/palette.dart';
import 'feuer_bild.dart';

/// **Das Feuer auf der Karte der Startseite lebt** (16.11.2026, Frederik:
/// „Gerne Lagerfeuer und Heute, es darf aber nicht so viel Leistung
/// ziehen“): Die Flammen flackern, Funken steigen, und ein warmer Schein
/// liegt über der Karte und atmet mit.
///
/// **Sparsam gebaut**: höchstens [bilderJeSekunde] Bilder je Sekunde, eine
/// eigene Ebene (`gotchas.md`) — neu gemalt wird nur die Fläche der Karte,
/// nie die Seite darum. Gebaut wird dabei nichts, der Maler hört selbst
/// auf den Takt. In Tests und ohne Bewegung im System steht das Bild
/// ([FeuerBild.flackert]).
///
/// **Nur Darstellung**, nimmt keinen Tipp an.
class KartenFeuer extends StatefulWidget {
  const KartenFeuer({required this.brennt, super.key});

  final bool brennt;

  /// Die Seite des Feuers und wo es auf der Karte sitzt — die Karte hält
  /// dort denselben Platz frei.
  static const double seite = 56;
  static const double links = 8;

  static const int bilderJeSekunde = 12;

  /// Der Augenblick, auf dem das Bild steht, wenn es nicht flackert.
  static const double stand = 1.8;

  @override
  State<KartenFeuer> createState() => _KartenFeuerState();
}

class _KartenFeuerState extends State<KartenFeuer>
    with SingleTickerProviderStateMixin {
  // In `initState` angelegt, nicht faul (`gotchas.md`).
  late final Ticker _takt;
  late final ValueNotifier<int> _schritt;

  @override
  void initState() {
    super.initState();
    _schritt = ValueNotifier<int>(-1);
    _takt = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (FeuerBild.flackert && !ruhig) {
      if (!_takt.isActive) _takt.start();
    } else {
      _takt.stop();
      _schritt.value = -1;
    }
  }

  void _tick(Duration vergangen) {
    final schritt =
        vergangen.inMilliseconds * KartenFeuer.bilderJeSekunde ~/ 1000;
    if (schritt != _schritt.value) _schritt.value = schritt;
  }

  @override
  void dispose() {
    _takt.dispose();
    _schritt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _KartenFeuerMaler(_schritt, brennt: widget.brennt),
        ),
      ),
    );
  }
}

class _KartenFeuerMaler extends CustomPainter {
  _KartenFeuerMaler(this.schritt, {required this.brennt})
    : super(repaint: schritt);

  final ValueNotifier<int> schritt;
  final bool brennt;

  /// Wie weit der Schein über die Karte reicht.
  static const double _reichweite = 190;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final steht = schritt.value < 0;
    final zeit = steht
        ? KartenFeuer.stand
        : schritt.value / KartenFeuer.bilderJeSekunde;

    const seite = KartenFeuer.seite;
    final feld = Offset(KartenFeuer.links, (size.height - seite) / 2);
    final mitte = feld + const Offset(seite / 2, seite * 0.62);

    // Der Schein über der Karte: zwei Wellen übereinander, damit er nicht
    // wie ein Pendel atmet.
    final flackern = steht
        ? 1.0
        : 0.86 + 0.1 * math.sin(zeit * 7.3) + 0.04 * math.sin(zeit * 13.1);
    final staerke = (brennt ? 0.3 : 0.1) * flackern;
    canvas
      ..clipRect(Offset.zero & size)
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Palette.tintLava.withValues(alpha: staerke),
              Palette.tintLava.withValues(alpha: staerke * 0.35),
              Palette.tintLava.withValues(alpha: 0),
            ],
            stops: const <double>[0, 0.4, 1],
          ).createShader(Rect.fromCircle(center: mitte, radius: _reichweite)),
      )
      ..translate(feld.dx, feld.dy);

    FeuerMaler(
      brennt: brennt,
      zeit: zeit,
      himmel: false,
    ).paint(canvas, const Size.square(seite));
  }

  @override
  bool shouldRepaint(_KartenFeuerMaler alt) =>
      alt.brennt != brennt || alt.schritt != schritt;
}
