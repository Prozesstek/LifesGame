import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'holz.dart';
import 'palette.dart';

/// Eine **Anschlagtafel** wie am Gemeindehaus: dunkle Bretter im
/// Holzrahmen, oben ein Schild (Wunsch vom 23.10.2026: „Dailies als
/// Tafel … mit so einem dunklen Holzhintergrund und vielleicht den
/// einzelnen Dailies als Steckbrief“).
///
/// Was darauf hängt, ist ein [Steckbrief] — die Tafel selbst trägt keine
/// Schrift außer auf dem Schild.
///
/// **Die Bretter sind gezeichnet**, nicht aus dem UI-Paket: Dort gibt es
/// nur helles Holz. Gezeichnet wird auf dem Raster der Bildpunkte
/// ([Holz.pixel]), damit die Tafel neben Rahmen und Planke nicht weich
/// aussieht.
class Anschlagtafel extends StatelessWidget {
  const Anschlagtafel({required this.schild, required this.child, super.key});

  /// Was auf dem Schild über der Tafel steht — hell auf Holz.
  final Widget schild;

  final Widget child;

  /// Wie weit das Schild über die Oberkante ragt: die halbe Planke.
  static const double schildUeberstand = Holz.plankeHoehe / 2;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: schildUeberstand),
          child: DecoratedBox(
            decoration: BoxDecoration(image: Holz.rahmenBild()),
            child: Padding(
              padding: const EdgeInsets.all(Holz.kartenRand),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: Holz.kante, width: 1.5),
                ),
                child: CustomPaint(
                  painter: const _Bretter(),
                  child: Padding(
                    // Oben bleibt die untere Hälfte des Schilds frei.
                    padding: const EdgeInsets.fromLTRB(
                      6,
                      schildUeberstand + 8,
                      6,
                      18,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: _Schild(child: schild)),
        ),
      ],
    );
  }
}

/// Das Schild über der Tafel: eine Planke, darauf helle Schrift.
class _Schild extends StatelessWidget {
  const _Schild({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(image: Holz.plankeBild()),
      child: SizedBox(
        height: Holz.plankeHoehe,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Center(
            widthFactor: 1,
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: Palette.textOnDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                // Wie auf den Holzknöpfen: ohne Rand verschwimmt helle
                // Schrift auf der Maserung.
                shadows: <Shadow>[
                  Shadow(color: Color(0xCC1A0E05), offset: Offset(1, 1)),
                ],
              ),
              child: IconTheme.merge(
                data: const IconThemeData(color: Palette.textOnDark),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Senkrechte Bretter mit Fugen, Maserung und Nägeln.
///
/// **Gesät, nicht zufällig**: Dieselbe Tafel sieht bei jedem Neubau
/// gleich aus. Die Bretter hängen nur an der Breite.
class _Bretter extends CustomPainter {
  const _Bretter();

  /// Wie breit ein Brett ungefähr ist, in Bildpunkten.
  static const int _brett = 22;

  @override
  void paint(Canvas canvas, Size size) {
    const p = Holz.pixel;
    final pinsel = Paint()..isAntiAlias = false;
    final spalten = (size.width / p).ceil();
    final zeilen = (size.height / p).ceil();
    final wuerfel = math.Random(23);

    // Die Maserung läuft in ganzen Stücken und endet unter dem Rand —
    // ohne Grenze hinge sie unten aus dem Rahmen.
    canvas
      ..clipRect(Offset.zero & size)
      ..drawRect(Offset.zero & size, pinsel..color = Palette.tafelFuge);

    var x = 0;
    var nr = 0;
    while (x < spalten) {
      final breite = _brett - 3 + wuerfel.nextInt(7);
      final ende = math.min(x + breite, spalten);
      final links = x * p;
      // Ein Bildpunkt bleibt Fuge.
      final rechts = math.max(links + p, (ende - 1) * p);
      final farbe = Palette.tafelBretter[nr % Palette.tafelBretter.length];

      canvas
        ..drawRect(
          Rect.fromLTRB(links, 0, rechts, size.height),
          pinsel..color = farbe,
        )
        ..drawRect(
          Rect.fromLTRB(links, 0, links + p, size.height),
          pinsel..color = Palette.tafelKante,
        );

      _maserung(canvas, pinsel, wuerfel, x + 2, ende - 3, zeilen);
      _naegel(canvas, pinsel, size, x, ende);

      x = ende;
      nr++;
    }
  }

  /// Drei Linien je Brett, die stufig hin und her wandern.
  void _maserung(
    Canvas canvas,
    Paint pinsel,
    math.Random wuerfel,
    int von,
    int bis,
    int zeilen,
  ) {
    if (bis <= von) return;
    const p = Holz.pixel;
    pinsel.color = Palette.tafelMaserung;
    for (var linie = 0; linie < 3; linie++) {
      var spalte = von + wuerfel.nextInt(bis - von + 1);
      var y = 0;
      while (y < zeilen) {
        final lauf = 4 + wuerfel.nextInt(12);
        canvas.drawRect(Rect.fromLTWH(spalte * p, y * p, p, lauf * p), pinsel);
        y += lauf;
        spalte = (spalte + wuerfel.nextInt(3) - 1).clamp(von, bis);
      }
    }
  }

  /// Oben und unten ein Nagel, wo die Querlatte dahinter sitzt.
  void _naegel(Canvas canvas, Paint pinsel, Size size, int von, int bis) {
    const p = Holz.pixel;
    final mitte = (von + (bis - von) ~/ 2 - 1) * p;
    for (final y in <double>[3 * p, size.height - 5 * p]) {
      canvas
        ..drawRect(
          Rect.fromLTWH(mitte, y, 2 * p, 2 * p),
          pinsel..color = Palette.nagel,
        )
        ..drawRect(
          Rect.fromLTWH(mitte, y, p, p),
          pinsel..color = Palette.nagelLicht,
        );
    }
  }

  @override
  bool shouldRepaint(_Bretter alt) => false;
}

/// Ein Blatt an der [Anschlagtafel]: Pergament mit gerissener
/// Unterkante, oben eine Reißzwecke, leicht schief angeheftet.
///
/// Ist es [abgestempelt], liegt ein Stempel darüber. **Er schlägt nur
/// auf, wenn er gerade dazukommt** — wer die Tafel öffnet, sieht ihn
/// liegen.
class Steckbrief extends StatefulWidget {
  const Steckbrief({
    required this.child,
    this.neigung = 0,
    this.saat = 0,
    this.abgestempelt = false,
    super.key,
  });

  final Widget child;

  /// Wie schief das Blatt hängt, im Bogenmaß.
  final double neigung;

  /// Woraus die Risskante gewürfelt wird — jedes Blatt reißt anders.
  final int saat;

  final bool abgestempelt;

  /// Woran Tests den Stempel finden.
  static const Key stempelKey = ValueKey<String>('steckbrief-stempel');

  /// Wie groß die Reißzwecke ist; sie ragt zur Hälfte über das Blatt.
  static const double zwecke = 14;

  /// Wie tief die Risskante höchstens einschneidet.
  static const double riss = 6;

  static const Duration aufschlag = Duration(milliseconds: 280);

  @override
  State<Steckbrief> createState() => _SteckbriefState();
}

class _SteckbriefState extends State<Steckbrief>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stempel;

  @override
  void initState() {
    super.initState();
    _stempel = AnimationController(
      vsync: this,
      duration: Steckbrief.aufschlag,
      value: widget.abgestempelt ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(Steckbrief alt) {
    super.didUpdateWidget(alt);
    if (widget.abgestempelt == alt.abgestempelt) return;
    if (!widget.abgestempelt) {
      _stempel.value = 0;
      return;
    }
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (ruhig) {
      _stempel.value = 1;
    } else {
      _stempel.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _stempel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final papier = widget.abgestempelt
        ? Palette.surfaceRaised
        : Palette.surface;

    return Transform.rotate(
      angle: widget.neigung,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: Steckbrief.zwecke / 2),
            child: CustomPaint(
              painter: _Blatt(saat: widget.saat, farbe: papier),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  8,
                  12,
                  8,
                  10 + Steckbrief.riss,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    widget.child,
                    // **Über dem Bild, nicht über dem Satz**: Abgeholt
                    // bleibt lesbar, was es war.
                    if (widget.abgestempelt)
                      Positioned(
                        top: -_Stempel.ueberstand,
                        right: -_Stempel.ueberstand,
                        child: IgnorePointer(child: _aufschlagend()),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _Zwecke()),
          ),
        ],
      ),
    );
  }

  /// Der Stempel fällt groß und durchsichtig herab und sitzt dann.
  Widget _aufschlagend() {
    return AnimatedBuilder(
      animation: _stempel,
      builder: (context, child) {
        final t = Curves.easeIn.transform(_stempel.value);
        return Opacity(
          opacity: (t * 2).clamp(0.0, 1.0),
          child: Transform.scale(scale: 1 + 0.9 * (1 - t), child: child),
        );
      },
      child: const _Stempel(key: Steckbrief.stempelKey),
    );
  }
}

/// Ein Häkchen im Doppelring, in grüner Tinte, schräg aufgedrückt.
class _Stempel extends StatelessWidget {
  const _Stempel({super.key});

  static const double _seite = 50;

  /// Wie weit er oben rechts über den Inhalt hinausragt.
  static const double ueberstand = 6;

  @override
  Widget build(BuildContext context) {
    final tinte = Palette.success.withValues(alpha: 0.85);
    return Transform.rotate(
      angle: -0.3,
      child: Container(
        width: _seite,
        height: _seite,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: tinte, width: 3),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: tinte, width: 1.2),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 30,
            color: tinte,
            semanticLabel: 'Abgeholt',
          ),
        ),
      ),
    );
  }
}

/// Die Reißzwecke: ein Messingkopf mit Glanz und Schatten.
class _Zwecke extends StatelessWidget {
  const _Zwecke();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: Steckbrief.zwecke,
      child: CustomPaint(painter: _ZweckeMaler()),
    );
  }
}

class _ZweckeMaler extends CustomPainter {
  const _ZweckeMaler();

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas
      ..drawCircle(
        mitte + const Offset(1.5, 2),
        r,
        Paint()..color = Palette.blattSchatten,
      )
      ..drawCircle(mitte, r, Paint()..color = Palette.messing)
      ..drawCircle(
        mitte,
        r - 0.6,
        Paint()
          ..color = Palette.messingSchatten
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      )
      ..drawCircle(
        mitte - Offset(r * 0.3, r * 0.3),
        r * 0.32,
        Paint()..color = Palette.messingLicht,
      );
  }

  @override
  bool shouldRepaint(_ZweckeMaler alt) => false;
}

/// Das Papier: Schatten auf den Brettern, Fläche, ein gedruckter Rand
/// und eine Unterkante, an der es abgerissen ist.
class _Blatt extends CustomPainter {
  const _Blatt({required this.saat, required this.farbe});

  final int saat;
  final Color farbe;

  /// Wie weit ein Zahn der Risskante reicht.
  static const double _zahn = 5;

  Path _umriss(Size size) {
    final wuerfel = math.Random(saat * 31 + 5);
    final unten = size.height - Steckbrief.riss;
    final pfad = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, unten + wuerfel.nextDouble() * Steckbrief.riss);
    var x = size.width;
    while (x > 0) {
      x = math.max(0, x - _zahn - wuerfel.nextDouble() * _zahn);
      pfad.lineTo(x, unten + wuerfel.nextDouble() * Steckbrief.riss);
    }
    return pfad..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final umriss = _umriss(size);
    canvas
      ..drawPath(
        umriss.shift(const Offset(2, 3)),
        Paint()..color = Palette.blattSchatten,
      )
      ..drawPath(umriss, Paint()..color = farbe)
      // Der gedruckte Rand eines Aushangs — er endet vor dem Riss.
      ..drawRect(
        Rect.fromLTRB(4, 4, size.width - 4, size.height - Steckbrief.riss - 4),
        Paint()
          ..color = Palette.textDim.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_Blatt alt) => alt.saat != saat || alt.farbe != farbe;
}
