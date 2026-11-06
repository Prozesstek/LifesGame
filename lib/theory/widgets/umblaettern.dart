import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// **Ein Blatt Buchpapier** — worauf eine Seite im Wissensbaum steht.
///
/// Altes, cremefarbenes Papier ([Palette.papier]), heller als das
/// Pergament der App, mit Fasern und ein paar Flecken. Links wölbt es
/// sich in den Buchrücken (die Falz), zu den Rändern hin ist es
/// abgegriffen. Den Einband und den Stapel darunter malt [Umblaettern].
///
/// Die Struktur ist **gesät**: Jedes Blatt hat dieselben Fasern, und
/// sie stehen still, wenn es umgeschlagen wird.
class BuchPapier extends StatelessWidget {
  const BuchPapier({this.child, super.key});

  final Widget? child;

  /// So breit wölbt sich das Blatt in den Rücken. Text rückt mindestens
  /// so weit ein.
  static const double falz = 22;

  @override
  Widget build(BuildContext context) {
    // **Papier und Text auf getrennten Ebenen.** Der Text schreibt sich
    // Wort für Wort; läge er auf derselben Ebene, malte jedes Bild davon
    // auch die gut tausend Fasern des Papiers neu (`gotchas.md`).
    final text = child;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const RepaintBoundary(
          child: CustomPaint(painter: _PapierMaler(), isComplex: true),
        ),
        if (text != null) RepaintBoundary(child: text),
      ],
    );
  }
}

class _PapierMaler extends CustomPainter {
  const _PapierMaler();

  @override
  void paint(Canvas canvas, Size size) {
    final flaeche = Offset.zero & size;
    canvas.drawRect(flaeche, Paint()..color = Palette.papier);

    final zufall = math.Random(1987);

    // Flecken: ein paar große, kaum sichtbare Wolken.
    for (var i = 0; i < 5; i++) {
      final mitte = Offset(
        zufall.nextDouble() * size.width,
        zufall.nextDouble() * size.height,
      );
      final radius = 30 + zufall.nextDouble() * 70;
      canvas.drawCircle(
        mitte,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Palette.papierFaser.withValues(alpha: 0.16),
              Palette.papierFaser.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: mitte, radius: radius)),
      );
    }

    // Fasern: kurze, feine Striche in alle Richtungen.
    final faser = Paint()
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    final anzahl = (size.width * size.height / 140).round();
    for (var i = 0; i < anzahl; i++) {
      final von = Offset(
        zufall.nextDouble() * size.width,
        zufall.nextDouble() * size.height,
      );
      final winkel = zufall.nextDouble() * math.pi;
      final laenge = 1.5 + zufall.nextDouble() * 4;
      faser.color = Palette.papierFaser.withValues(
        alpha: 0.10 + zufall.nextDouble() * 0.16,
      );
      canvas.drawLine(
        von,
        von + Offset(math.cos(winkel), math.sin(winkel)) * laenge,
        faser,
      );
    }

    // Abgegriffen: zu den Rändern hin dunkler.
    canvas.drawRect(
      flaeche,
      Paint()
        ..shader = RadialGradient(
          radius: 1.05,
          colors: <Color>[
            Palette.papierFaser.withValues(alpha: 0),
            Palette.papierFaser.withValues(alpha: 0.45),
          ],
          stops: const <double>[0.6, 1],
        ).createShader(flaeche),
    );

    // Die Falz: Das Blatt wölbt sich in den Rücken — ganz innen
    // dunkel, dann ein heller Rücken der Wölbung, dann flach.
    final falz = Rect.fromLTWH(0, 0, BuchPapier.falz * 1.6, size.height);
    canvas.drawRect(
      falz,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Palette.einbandDunkel.withValues(alpha: 0.55),
            Palette.einbandDunkel.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.18),
            Palette.einbandDunkel.withValues(alpha: 0.06),
            Palette.einbandDunkel.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.18, 0.38, 0.6, 1],
        ).createShader(falz),
    );

    // Die Schnittkante oben, rechts und unten.
    canvas.drawRect(
      flaeche.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Palette.papierFaser.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_PapierMaler oldDelegate) => false;
}

/// **Der Einband und der Stapel** unter dem obersten Blatt: Leder mit
/// Narben und einer eingeprägten Linie, darauf die Kanten der übrigen
/// Seiten.
///
/// **Am Rand sieht man, wo man ist** (03.11.2026): rechts die Kanten
/// dessen, was noch kommt, links hinter dem Rücken die des Gelesenen.
class _EinbandMaler extends CustomPainter {
  const _EinbandMaler({required this.links, required this.rechts});

  /// Wie viele Kanten links und rechts hervorschauen.
  final int links;
  final int rechts;

  @override
  void paint(Canvas canvas, Size size) {
    malEinband(canvas, size);

    final seite = Umblaettern.innen.deflateRect(Offset.zero & size);
    final s = Umblaettern.stapelSchritt;
    for (var i = rechts; i >= 1; i--) {
      _kante(
        canvas,
        Rect.fromLTRB(
          seite.left,
          seite.top + i * 0.7,
          seite.right + i * s,
          seite.bottom + i * 0.7,
        ),
        i / Umblaettern.stapel,
      );
    }
    for (var i = links; i >= 1; i--) {
      _kante(
        canvas,
        Rect.fromLTRB(
          seite.left - i * s,
          seite.top + i * 0.7,
          seite.right,
          seite.bottom + i * 0.7,
        ),
        i / Umblaettern.stapel,
      );
    }
  }

  /// Eine Seitenkante, je tiefer, desto dunkler.
  void _kante(Canvas canvas, Rect kante, double tiefe) {
    canvas.drawRect(
      kante,
      Paint()
        ..color = Color.lerp(
          Palette.papier,
          Palette.papierFaser,
          0.25 + tiefe * 0.5,
        )!,
    );
    canvas.drawRect(
      kante,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = Palette.papierFaser,
    );
  }

  /// Leder mit Narben und eingeprägter Linie — auch der Deckel des
  /// geschlossenen Buchs ([BuchDeckel]).
  static void malEinband(Canvas canvas, Size size) {
    final aussen = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(
      aussen,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.6),
          radius: 1.3,
          colors: <Color>[Palette.einband, Palette.einbandDunkel],
        ).createShader(Offset.zero & size),
    );

    // Narben im Leder.
    final zufall = math.Random(73);
    final narbe = Paint();
    final anzahl = (size.width * size.height / 260).round();
    for (var i = 0; i < anzahl; i++) {
      narbe.color = (zufall.nextBool() ? Colors.black : Colors.white)
          .withValues(alpha: 0.05 + zufall.nextDouble() * 0.06);
      canvas.drawCircle(
        Offset(
          zufall.nextDouble() * size.width,
          zufall.nextDouble() * size.height,
        ),
        0.6 + zufall.nextDouble() * 0.9,
        narbe,
      );
    }

    // Die eingeprägte Linie am Rand des Deckels.
    canvas.drawRRect(
      aussen.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Palette.goldOnDark.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_EinbandMaler alt) =>
      alt.links != links || alt.rechts != rechts;
}

/// **Der Deckel des geschlossenen Buchs**: dasselbe Leder wie der
/// Einband, darauf in Gold, was auf dem Rücken stünde.
class BuchDeckel extends StatelessWidget {
  const BuchDeckel({required this.titel, this.zeichen, super.key});

  final String titel;
  final IconData? zeichen;

  @override
  Widget build(BuildContext context) {
    final icon = zeichen;
    return CustomPaint(
      painter: const _DeckelMaler(),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 56, color: Palette.goldOnDark),
              const SizedBox(height: 20),
            ],
            Text(
              titel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                height: 1.25,
                fontWeight: FontWeight.bold,
                color: Palette.goldOnDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckelMaler extends CustomPainter {
  const _DeckelMaler();

  @override
  void paint(Canvas canvas, Size size) {
    _EinbandMaler.malEinband(canvas, size);
    // Der Rücken links: ein dunkler Streifen mit zwei Bünden.
    final ruecken = Rect.fromLTWH(0, 0, 18, size.height);
    canvas.drawRect(
      ruecken,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Colors.black.withValues(alpha: 0.45),
            Colors.black.withValues(alpha: 0),
          ],
        ).createShader(ruecken),
    );
    final bund = Paint()
      ..color = Palette.goldOnDark.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    for (final y in <double>[0.2, 0.8]) {
      canvas.drawLine(
        Offset(4, size.height * y),
        Offset(16, size.height * y),
        bund,
      );
    }
  }

  @override
  bool shouldRepaint(_DeckelMaler oldDelegate) => false;
}

enum _Richtung { vor, zurueck }

/// **Blättern wie in einem Buch**: Das Blatt dreht sich am Rücken (dem
/// linken Rand) aus der Seite heraus und gibt die nächste frei; zurück
/// legt sich das vorige Blatt wieder darüber.
///
/// Der Finger zieht das Blatt mit — halb umgeschlagen losgelassen fällt
/// es zurück oder schlägt ganz um, je nachdem, wie weit es war und wie
/// schnell der Wisch. **Ein Eselsohr unten** zeigt, wohin es geht, und
/// schlägt auf Tipp um: rechts vor, links zurück. Über die letzte Seite
/// hinaus kommt [onSchluss] — dort schließt sich das Buch.
///
/// **Gezeichnet als Drehung in 3D** um die linke Kante, mit Tiefe: Die
/// freie Kante kommt dem Auge entgegen, das Blatt dunkelt, je steiler
/// es steht, und wirft einen Schatten auf die Seite darunter. Bei 90°
/// steht es auf der Kante und ist fertig umgeschlagen.
///
/// Jede Seite trägt einen Schlüssel ihrer Nummer: Liegt sie erst unten
/// und dann oben, bleibt ihr Zustand — der Text, der sich gerade
/// schreibt, beginnt nicht von vorn.
class Umblaettern extends StatefulWidget {
  const Umblaettern({
    required this.anzahl,
    required this.seite,
    this.onGeblaettert,
    this.onRascheln,
    this.onSchluss,
    super.key,
  });

  final int anzahl;

  /// Der Inhalt von Seite `i`, ohne Papier. `aktiv` ist sie, wenn sie
  /// oben liegt und nichts sich bewegt.
  final Widget Function(BuildContext context, int i, bool aktiv) seite;

  /// Eine Seite ist ganz umgeschlagen; das ist jetzt die oberste.
  final ValueChanged<int>? onGeblaettert;

  /// Ein Blatt beginnt sich zu bewegen — Zeit für den Klang.
  final VoidCallback? onRascheln;

  /// Auf der letzten Seite weiter: Wisch oder Eselsohr. Ohne ihn hat die
  /// letzte Seite kein Eselsohr nach rechts.
  final VoidCallback? onSchluss;

  /// So lange braucht ein ganzes Umblättern.
  static const Duration dauer = Duration(milliseconds: 560);

  /// Wie stark die Kante dem Auge entgegenkommt (Perspektive).
  static const double tiefe = 0.0008;

  /// So weit muss der Finger ziehen, in Seitenbreiten, bis das Blatt
  /// steht.
  static const double zugweg = 0.85;

  /// Ab dieser Geschwindigkeit schlägt ein Wisch um, egal wie weit.
  static const double schwung = 300;

  /// Wie viele Seitenkanten höchstens je Seite hervorschauen, wie weit
  /// jede versetzt ist, und wie viele Kanten eine Seite des Buchs zählt.
  static const int stapel = 6;
  static const double stapelSchritt = 2;
  static const int kantenJeSeite = 2;

  /// Wo das Blatt im Einband liegt: rundum Leder, links und rechts Platz
  /// für die Kanten des Stapels.
  static const EdgeInsets innen = EdgeInsets.fromLTRB(
    10 + stapel * stapelSchritt,
    10,
    10 + stapel * stapelSchritt,
    14,
  );

  /// Wie groß ein Eselsohr ist.
  static const double ohr = 34;

  static const Key ohrVorKey = ValueKey<String>('eselsohr-vor');
  static const Key ohrZurueckKey = ValueKey<String>('eselsohr-zurueck');

  @override
  State<Umblaettern> createState() => UmblaetternState();
}

class UmblaetternState extends State<Umblaettern>
    with SingleTickerProviderStateMixin {
  /// Wie weit das bewegte Blatt umgeschlagen ist: 0 liegt, 1 steht.
  late final AnimationController _blatt;
  int _hier = 0;
  _Richtung? _richtung;
  double _breite = 1;

  /// Ob ein Zug über die letzte Seite hinaus schon gemeldet ist.
  bool _schlussGemeldet = false;

  /// Die Seite, die oben liegt.
  int get hier => _hier;

  bool get _ruhig => MediaQuery.disableAnimationsOf(context);

  bool get _amEnde => _hier >= widget.anzahl - 1;

  @override
  void initState() {
    super.initState();
    _blatt = AnimationController(vsync: this, duration: Umblaettern.dauer);
  }

  @override
  void dispose() {
    _blatt.dispose();
    super.dispose();
  }

  /// Zur nächsten Seite; auf der letzten kommt [Umblaettern.onSchluss].
  void vor() {
    if (_richtung != null) return;
    if (_amEnde) {
      widget.onSchluss?.call();
      return;
    }
    setState(() => _richtung = _Richtung.vor);
    _blatt.value = 0;
    widget.onRascheln?.call();
    _laufen(1, Curves.easeInOut);
  }

  /// Zur vorigen Seite.
  void zurueck() {
    if (_richtung != null || _hier == 0) return;
    setState(() => _richtung = _Richtung.zurueck);
    _blatt.value = 1;
    widget.onRascheln?.call();
    _laufen(0, Curves.easeInOut);
  }

  Future<void> _laufen(double ziel, Curve kurve) async {
    final rest = (ziel - _blatt.value).abs();
    final ms = _ruhig ? 0 : (Umblaettern.dauer.inMilliseconds * rest).round();
    await _blatt.animateTo(
      ziel,
      duration: Duration(milliseconds: ms),
      curve: kurve,
    );
    if (mounted) _fertig();
  }

  void _fertig() {
    final richtung = _richtung;
    final stand = _blatt.value;
    final vorher = _hier;
    setState(() {
      if (richtung == _Richtung.vor && stand >= 1) {
        _hier++;
      } else if (richtung == _Richtung.zurueck && stand <= 0) {
        _hier--;
      }
      _richtung = null;
      _blatt.value = 0;
    });
    if (_hier != vorher) widget.onGeblaettert?.call(_hier);
  }

  void _ziehen(DragUpdateDetails d) {
    if (_blatt.isAnimating) return;
    final dx = d.primaryDelta ?? 0;
    if (_richtung == null) {
      if (dx < 0 && !_amEnde) {
        setState(() => _richtung = _Richtung.vor);
        _blatt.value = 0;
      } else if (dx > 0 && _hier > 0) {
        setState(() => _richtung = _Richtung.zurueck);
        _blatt.value = 1;
      } else {
        // Über die letzte Seite hinaus: einmal je Zug.
        if (dx < 0 && _amEnde && !_schlussGemeldet) {
          _schlussGemeldet = true;
          widget.onSchluss?.call();
        }
        return;
      }
      widget.onRascheln?.call();
    }
    // Nach links ziehen schlägt um, nach rechts legt es zurück.
    _blatt.value = (_blatt.value - dx / (_breite * Umblaettern.zugweg)).clamp(
      0.0,
      1.0,
    );
  }

  void _loslassen(double tempo) {
    _schlussGemeldet = false;
    if (_richtung == null || _blatt.isAnimating) return;
    final ziel = tempo < -Umblaettern.schwung
        ? 1.0
        : tempo > Umblaettern.schwung
        ? 0.0
        : (_blatt.value >= 0.5 ? 1.0 : 0.0);
    _laufen(ziel, Curves.easeOut);
  }

  /// Wie viele Kanten für [seiten] Seiten hervorschauen.
  int _kanten(int seiten) =>
      math.min(seiten * Umblaettern.kantenJeSeite, Umblaettern.stapel);

  @override
  Widget build(BuildContext context) {
    // Einband und Stapel liegen still; nur die Blätter darauf bewegen
    // sich. Was sich beim Umschlagen aus dem Buch hebt, schneidet der
    // Rand des Einbands ab.
    final vorDa = !_amEnde || widget.onSchluss != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _ziehen,
      onHorizontalDragEnd: (d) => _loslassen(d.primaryVelocity ?? 0),
      onHorizontalDragCancel: () => _loslassen(0),
      child: CustomPaint(
        painter: _EinbandMaler(
          links: _kanten(_hier),
          rechts: _kanten(widget.anzahl - 1 - _hier),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: Umblaettern.innen,
            child: LayoutBuilder(
              builder: (context, grenzen) {
                _breite = grenzen.maxWidth;
                return AnimatedBuilder(
                  animation: _blatt,
                  builder: (context, _) => Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ..._lagen(context),
                      // Die Eselsohren nur, wenn das Blatt ruht.
                      if (_richtung == null && vorDa)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _Eselsohr(
                            key: Umblaettern.ohrVorKey,
                            rechts: true,
                            label: _amEnde ? 'Buch schließen' : 'Umblättern',
                            onTap: vor,
                          ),
                        ),
                      if (_richtung == null && _hier > 0)
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: _Eselsohr(
                            key: Umblaettern.ohrZurueckKey,
                            rechts: false,
                            label: 'Zurückblättern',
                            onTap: zurueck,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _lagen(BuildContext context) {
    final richtung = _richtung;
    if (richtung == null) return <Widget>[_lage(context, _hier, aktiv: true)];

    final (unten, oben) = richtung == _Richtung.vor
        ? (_hier + 1, _hier)
        : (_hier, _hier - 1);
    final stand = _blatt.value;
    final winkel = stand * math.pi / 2;

    // Wo die freie Kante des Blatts im Bild steht — dort beginnt sein
    // Schatten auf der Seite darunter.
    final w = 1 - Umblaettern.tiefe * _breite * math.sin(winkel);
    final kante = _breite * math.cos(winkel) / w;

    return <Widget>[
      _lage(
        context,
        unten,
        kante: kante,
        schatten: 0.4 * math.sin(stand * math.pi),
      ),
      _lage(context, oben, winkel: winkel),
    ];
  }

  Widget _lage(
    BuildContext context,
    int i, {
    bool aktiv = false,
    double winkel = 0,
    double kante = 0,
    double schatten = 0,
  }) {
    return _Lage(
      key: ValueKey<int>(i),
      winkel: winkel,
      kante: kante,
      schatten: schatten,
      // Jedes Blatt einmal gemalt, gedreht wird nur das Bild davon.
      child: RepaintBoundary(
        child: BuchPapier(child: widget.seite(context, i, aktiv)),
      ),
    );
  }
}

/// **Das Eselsohr**: eine umgeknickte Ecke unten, in der Richtung, in die
/// es weitergeht. Ein Tipp darauf blättert.
class _Eselsohr extends StatelessWidget {
  const _Eselsohr({
    required this.rechts,
    required this.label,
    required this.onTap,
    super.key,
  });

  final bool rechts;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Größer als das Ohr selbst, damit der Daumen es trifft.
        child: SizedBox.square(
          dimension: Umblaettern.ohr + 18,
          child: Align(
            alignment: rechts ? Alignment.bottomRight : Alignment.bottomLeft,
            child: CustomPaint(
              size: const Size.square(Umblaettern.ohr),
              painter: _OhrMaler(rechts: rechts),
            ),
          ),
        ),
      ),
    );
  }
}

class _OhrMaler extends CustomPainter {
  const _OhrMaler({required this.rechts});

  final bool rechts;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Die Ecke, die fehlt: dort sieht man den Einband.
    final ecke = rechts
        ? (Path()
            ..moveTo(w, 0)
            ..lineTo(w, h)
            ..lineTo(0, h)
            ..close())
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(w, h)
            ..lineTo(0, h)
            ..close());
    canvas.drawPath(ecke, Paint()..color = Palette.einbandDunkel);
    // Der umgeknickte Teil: die Rückseite des Papiers, etwas dunkler,
    // mit Schatten darunter.
    final knick = rechts
        ? (Path()
            ..moveTo(w, 0)
            ..lineTo(0, h)
            ..lineTo(0, 0)
            ..close())
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(w, 0)
            ..lineTo(w, h)
            ..close());
    canvas.drawShadow(knick, Colors.black, 3, false);
    canvas.drawPath(
      knick,
      Paint()
        ..shader = LinearGradient(
          begin: rechts ? Alignment.topLeft : Alignment.topRight,
          end: rechts ? Alignment.bottomRight : Alignment.bottomLeft,
          colors: const <Color>[Palette.papier, Palette.papierFaser],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      knick,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Palette.papierFaser,
    );
  }

  @override
  bool shouldRepaint(_OhrMaler alt) => alt.rechts != rechts;
}

/// Ein Blatt im Stapel — flach oder gedreht. **Immer derselbe Aufbau**,
/// damit eine Seite ihren Zustand behält, wenn sie von unten nach oben
/// wandert.
class _Lage extends StatelessWidget {
  const _Lage({
    required this.winkel,
    required this.kante,
    required this.schatten,
    required this.child,
    super.key,
  });

  /// Wie weit das Blatt am Rücken gedreht ist, 0 bis 90°.
  final double winkel;

  /// Wo die Kante des Blatts darüber steht, und wie dunkel ihr Schatten.
  final double kante;
  final double schatten;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, Umblaettern.tiefe)
      ..rotateY(winkel);
    return Transform(
      alignment: Alignment.centerLeft,
      transform: matrix,
      child: CustomPaint(
        foregroundPainter: _Schatten(
          dunkel: 0.22 * math.sin(winkel),
          kante: kante,
          staerke: schatten,
        ),
        child: child,
      ),
    );
  }
}

/// Das Licht auf einem Blatt: dunkler, je steiler es steht, und der
/// Schatten des Blatts darüber, rechts von dessen Kante.
class _Schatten extends CustomPainter {
  const _Schatten({
    required this.dunkel,
    required this.kante,
    required this.staerke,
  });

  final double dunkel;
  final double kante;
  final double staerke;

  /// So breit fällt der Schatten neben der Kante.
  static const double breite = 44;

  @override
  void paint(Canvas canvas, Size size) {
    if (dunkel > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Palette.background.withValues(alpha: dunkel),
      );
    }
    if (staerke > 0) {
      final streifen = Rect.fromLTWH(kante, 0, breite, size.height);
      canvas.drawRect(
        streifen,
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              Palette.background.withValues(alpha: staerke),
              Palette.background.withValues(alpha: 0),
            ],
          ).createShader(streifen),
      );
    }
  }

  @override
  bool shouldRepaint(_Schatten alt) =>
      alt.dunkel != dunkel || alt.kante != kante || alt.staerke != staerke;
}
